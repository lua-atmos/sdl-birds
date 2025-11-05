local sdl = require "atmos.env.sdl"
local SDL = require "SDL"
local IMG = require "SDL.image"

local _,REN = sdl.window {
	title  = "Birds - 09 (blink)",
	width  = 640,
	height = 480,
    flags  = { SDL.flags.OpenGL },
}

local UP; do
    local sfc = assert(IMG.load("res/bird-up.png"))
    UP = assert(REN:createTextureFromSurface(sfc))
end

local DN; do
    local sfc = assert(IMG.load("res/bird-dn.png"))
    DN = assert(REN:createTextureFromSurface(sfc))
end

local W,H; do
    local _,_,a,b = UP:query()
    local _,_,c,d = DN:query()
    assert(a==c and b==d)
    W,H = a,b
end

math.randomseed()

function Bird (y, speed)
    local rect = { x=0, y=y, w=W, h=H }
    task().rect  = rect
    task().alive = true
    local img = DN
    watching(function(it) return rect.x>640 end, function ()
        watching('collided', function ()
            par (
                function ()
                    local ang = 0
                    every('clock', function (_,ms)
                        local v = ms * speed
                        rect.x = rect.x + (v/1000)
                        rect.y = y - ((speed/5) * math.sin(ang))
                        ang = ang + ((3.14*v)/100000)
                        local tmp = math.floor(((ang+(3.14/2))/3.14))
                        img = (tmp%2 == 0) and UP or DN
                    end)
                end,
                function ()
                    every('sdl.draw', function ()
                        REN:copy(img, nil, sdl.ints(rect))
                    end)
                end
            )
        end)
        task().alive = false
        watching(function () return rect.y>480-H end, function ()
            par(function ()
                every('clock', function (_,ms)
                    rect.y = rect.y + (ms * 0.5)
                end)
            end, function ()
                every('sdl.draw', function ()
                    REN:copy(DN, nil, sdl.ints(rect))
                end)
            end)
        end)
        watching(clock{s=1}, function ()
            while true do
                await(clock{ms=100})
                watching(clock{ms=100}, function ()
                    every('sdl.draw', function ()
                        REN:copy(DN, nil, sdl.ints(rect))
                    end)
                end)
            end
        end)
    end)
end

sdl.ren = REN
call(function ()
    local birds <close> = tasks(5)
    par (
        function ()
            every (clock{ms=500}, function ()
                spawn_in(birds, Bird, math.random(0,480), 100 + math.random(0,100))
            end)
        end,
        function ()
            every ('clock', function (_,ms)
                for _,b1 in getmetatable(birds).__pairs(birds) do
                    for _,b2 in getmetatable(birds).__pairs(birds) do
                        local col = (b1~=b2) and SDL.hasIntersection(sdl.ints(b1.rect), sdl.ints(b2.rect))
                        if col then
                            emit_in(b1, 'collided')
                            emit_in(b2, 'collided')
                            break
                        end
                    end
                end
            end)
        end
    )
end)

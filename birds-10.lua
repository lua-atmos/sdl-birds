local SDL = require "SDL"
local IMG = require "SDL.image"

require "atmos"
local env = require "atmos.env.sdl"

local point_vs_rect = env.point_vs_rect

local _ <close> = defer(function ()
    IMG.quit()
    SDL.quit()
end)

local WIN = assert(SDL.createWindow {
	title  = "Birds - 10 (tracking)",
	width  = 640,
	height = 480,
    flags  = { SDL.flags.OpenGL },
})
local REN = assert(SDL.createRenderer(WIN,-1))

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
    pub().rect  = rect
    pub().alive = true
    local img = DN
    watching(true, function(it) return rect.x>640 end, function ()
        watching('collided', function ()
            par (
                function ()
                    local ang = 0
                    every('step', function (ms)
                        local v = ms * speed
                        rect.x = math.floor(rect.x + (v/1000))
                        rect.y = math.floor(y - ((speed/5) * math.sin(ang)))
                        ang = ang + ((3.14*v)/100000)
                        local tmp = math.floor(((ang+(3.14/2))/3.14))
                        img = (tmp%2 == 0) and UP or DN
                    end)
                end,
                function ()
                    every('SDL.Draw', function ()
                        REN:copy(img, nil, rect)
                    end)
                end
            )
        end)
        pub().alive = false
        watching(true, function () return rect.y>480-H end, function ()
            par(function ()
                every('step', function (ms)
                    rect.y = math.floor(rect.y + (ms * 0.5))
                end)
            end, function ()
                every('SDL.Draw', function ()
                    REN:copy(DN, nil, rect)
                end)
            end)
        end)
        watching(clock{s=1}, function ()
            while true do
                await(clock{ms=100})
                watching(clock{ms=100}, function ()
                    every('SDL.Draw', function ()
                        REN:copy(DN, nil, rect)
                    end)
                end)
            end
        end)
    end)
end

spawn(function ()
    local birds <close> = tasks(5)
    par (
        function ()
            every (clock{ms=500}, function ()
                spawn_in(birds, Bird, math.random(0,480), 100 + math.random(0,100))
            end)
        end,
        function ()
            every ('step', function (ms)
                for _,b1 in getmetatable(birds).__pairs(birds) do
                    for _,b2 in getmetatable(birds).__pairs(birds) do
                        local col = (b1~=b2) and pub(b1).alive and pub(b2).alive and SDL.hasIntersection(pub(b1).rect, pub(b2).rect)
                        if col then
                            emit_in(b1, 'collided')
                            emit_in(b2, 'collided')
                            break
                        end
                    end
                end
            end)
        end,
        function ()
            while true do
                local bird = catch ('Track', function ()
                    every (SDL.event.MouseButtonDown, function (evt)
                        for _,b in getmetatable(birds).__pairs(birds) do
                            if pub(b).alive and point_vs_rect(evt,pub(b).rect) then
                                throw { 'Track', b }
                            end
                        end
                    end)
                end)
                watching (bird, function ()
                    local l = {
                        x1=640/2, y1=480,
                    }
                    every ('SDL.Draw', function ()
                        l.x2 = pub(bird).rect.x + (W/2)
                        l.y2 = pub(bird).rect.y + (H/2)
                        REN:setDrawColor(0xFFFFFFFF)
                        REN:drawLine(l)
                        REN:setDrawColor(0x00000000)
                    end)
                end)
            end
        end
    )
end)

env.loop(REN)

local SDL = require "SDL"
local IMG = require "SDL.image"

local sdl = require "atmos.env.sdl"

local point_vs_rect = sdl.point_vs_rect
local evt_vs_key    = sdl.evt_vs_key

local _ <close> = defer(function ()
    IMG.quit()
    SDL.quit()
end)

local WIN = assert(SDL.createWindow {
	title  = "Birds - 11 (pause)",
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
    task().rect  = rect
    task().alive = true
    local img = DN
    watching(function(it) return rect.x>640 end, function ()
        watching('collided', function ()
            par (
                function ()
                    local ang = 0
                    every('sdl.step', function (_,ms)
                        local v = ms * speed
                        rect.x = math.floor(rect.x + (v/1000))
                        rect.y = math.floor(y - ((speed/5) * math.sin(ang)))
                        ang = ang + ((3.14*v)/100000)
                        local tmp = math.floor(((ang+(3.14/2))/3.14))
                        img = (tmp%2 == 0) and UP or DN
                    end)
                end,
                function ()
                    every('sdl.draw', function ()
                        REN:copy(img, nil, rect)
                    end)
                end
            )
        end)
        task().alive = false
        watching(function () return rect.y>480-H end, function ()
            par(function ()
                every('sdl.step', function (_,ms)
                    rect.y = math.floor(rect.y + (ms * 0.5))
                end)
            end, function ()
                every('sdl.draw', function ()
                    REN:copy(DN, nil, rect)
                end)
            end)
        end)
        watching(clock{s=1}, function ()
            while true do
                await(clock{ms=100})
                watching(clock{ms=100}, function ()
                    every('sdl.draw', function ()
                        REN:copy(DN, nil, rect)
                    end)
                end)
            end
        end)
    end)
end

sdl.ren = REN
call(function ()
    par (function ()
        toggle('Show', function ()
            local birds <close> = tasks(5)
            par (
                function ()
                    every (clock{ms=500}, function ()
                        spawn_in(birds, Bird, math.random(0,480), 100 + math.random(0,100))
                    end)
                end,
                function ()
                    every ('sdl.step', function (ms)
                        for _,b1 in getmetatable(birds).__pairs(birds) do
                            for _,b2 in getmetatable(birds).__pairs(birds) do
                                local col = (b1~=b2) and b1.alive and b2.alive and SDL.hasIntersection(b1.rect, b2.rect)
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
                        local _,_,bird = catch ('Track', function ()
                            every (SDL.event.MouseButtonDown, function (evt)
                                for _,b in getmetatable(birds).__pairs(birds) do
                                    if b.alive and point_vs_rect(evt,b.rect) then
                                        throw('Track', b)
                                    end
                                end
                            end)
                        end)
                        watching (bird, function ()
                            local l = {
                                x1=640/2, y1=480,
                            }
                            every ('sdl.draw', function ()
                                l.x2 = bird.rect.x + (W/2)
                                l.y2 = bird.rect.y + (H/2)
                                REN:setDrawColor(0xFFFFFFFF)
                                REN:drawLine(l)
                                REN:setDrawColor(0x00000000)
                            end)
                        end)
                    end
                end
            )
        end)
    end, function ()
        while true do
            await(SDL.event.KeyDown, function (e) return evt_vs_key(e,'P') end)
            emit('Show', false)
            watching(SDL.event.KeyDown, function (e) return evt_vs_key(e,'P') end, function ()
                local sfc = assert(IMG.load("res/pause.png"))
                local img = assert(REN:createTextureFromSurface(sfc))
                local _,_,w,h = img:query()
                local r = {
                    x = math.floor(640/2 - w/2),
                    y = math.floor(480/2 - h/2),
                    w=w, h=h
                }
                every('sdl.draw', function ()
                    REN:copy(img, nil, r)
                end)
            end)
            emit('Show', true)
        end
    end)
end)

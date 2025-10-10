local SDL = require "SDL"
local IMG = require "SDL.image"

local sdl = require "atmos.env.sdl"

local _ <close> = defer(function ()
    IMG.quit()
    SDL.quit()
end)

local WIN = assert(SDL.createWindow {
	title  = "Birds - 05 (termination)",
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
    local xx  = 0
    local yy  = y
    local img = DN
    watching(function() return xx>640 end, function ()
        par (
            function ()
                local ang = 0
                every('clock', function (_,ms)
                    local v = ms * speed
                    xx = xx + (v/1000)
                    yy = y - ((speed/5) * math.sin(ang))
                    ang = ang + ((3.14*v)/100000)
                    local tmp = math.floor(((ang+(3.14/2))/3.14))
                    img = (tmp%2 == 0) and UP or DN
                end)
            end,
            function ()
                every('sdl.draw', function ()
                    REN:copy(img, nil, {
                        x = math.floor(xx),
                        y = math.floor(yy),
                        w = W,
                        h = H
                    })
                end)
            end
        )
    end)
end

sdl.ren = REN
call(function ()
    local birds = tasks(5)
    every (clock{ms=500}, function ()
        spawn_in(birds, Bird, math.random(0,480), 100 + math.random(0,100))
    end)
end)

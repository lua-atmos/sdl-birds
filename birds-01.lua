local SDL = require "SDL"
local IMG = require "SDL.image"

local sdl = require "atmos.env.sdl"

local _ <close> = defer(function ()
    IMG.quit()
    SDL.quit()
end)

local WIN = assert(SDL.createWindow {
	title  = "Birds - 01 (task)",
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

function Bird (y, speed)
    local xx  = 0
    local yy  = y
    local img = DN
    par (
        function ()
            local ang = 0
            every('sdl.step', function (_,ms)
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
end

sdl.ren = REN
call(function ()
    spawn(Bird, 150, 100)
    spawn(Bird, 350, 200)
    await(false)
end)

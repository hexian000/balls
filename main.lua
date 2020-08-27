conf = require("conf")

function _G.printf(...)
    print(string.format(...))
end

function _G.check(expr)
    if conf.debug and expr then
        error(expr)
    end
end

local exp60 = 1.0 / math.exp(1.0 / 60.0)
function _G.avg60(s, v)
    return exp60 * s + (1.0 - exp60) * v
end

require("physics")
require("game")
require("graphics")

function love.run()
    if love.load then
        love.load(love.arg.parseGameArguments(arg), arg)
    end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then
        love.timer.step()
    end

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then
            dt = love.timer.step()
        end

        -- Call update and draw
        if love.update then
            love.update(dt)
        end -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then
                love.draw()
            end

            love.graphics.present()
        end

        -- if love.timer then love.timer.sleep(0.001) end
    end
end

local TYPE_PLAYER = 1
local TYPE_ENEMY = 2
local TYPE_BONUS = 3

function love.load()
    love.window.setTitle("Balls")
    -- love.window.setFullscreen(true)
    width, height = love.graphics.getDimensions()
    math.randomseed(os.time())

    controller = {}
    if love.mouse.isCursorSupported() then
        controller.getPosition = love.mouse.getPosition
    else
        controller.getPosition = love.touch.getPosition
    end

    max_balls = 0
    balls = {{
        x = 0,
        y = 0,
        r = conf.radius,
        type = TYPE_PLAYER
    }}
end

local function is_visible(body)
    local x, y, r = body.x, body.y, body.r
    return (x >= -r and x <= width + r) and (y >= -r and y <= height + r)
end

local function is_escape(body)
    local x, y = body.x - width / 2.0, body.y - height / 2.0
    return (x * body.vx + y * body.vy) > 0.0
end

local function is_overlap_any(ball)
    for i = 1, max_balls do
        local another = balls[i]
        if another and is_overlap(ball, another, 1e-3) then
            return true
        end
    end
    return false
end

local function spawn_enemy(ball)
    local r = conf.radius
    ball = ball or {}
    for i = 1, 3 do
        local angle = 2.0 * math.pi * math.random()
        local dx, dy = math.cos(angle), math.sin(angle)
        local d = math.sqrt(width * width + height * height) / 2.0 + r + 1.0
        local v = math.random(conf.min_speed, conf.max_speed)
        ball.x, ball.y = width / 2.0 + dx * d, height / 2.0 + dy * d
        ball.vx, ball.vy = -dx * v, -dy * v
        ball.r = r
        ball.collision = 0.0
        ball.mark = false
        ball.type = TYPE_ENEMY
        if not is_overlap_any(ball) then
            return ball
        end
    end
    return nil
end

updT, drwT = 0.0, 0.0
colC = 0.0
spawn_counter = 0.0

function love.update(dt)
    local begin = love.timer.getTime()

    balls[1].x, balls[1].y = controller.getPosition()

    local escaped = 0
    for i = 1, max_balls do
        local ball = balls[i]
        if ball and ball.type == TYPE_ENEMY then
            if not is_visible(ball) and is_escape(ball) then
                -- respawn
                balls[i] = spawn_enemy(ball)
            else
                ball.collision = math.max(ball.collision - dt, 0.0)
            end
        end
    end

    if updT < 10e-3 then
        spawn_counter = spawn_counter + dt
        if spawn_counter > 0.1 then
            spawn_counter = spawn_counter - 0.1
            local enemy = spawn_enemy()
            if enemy then
                for i = 1, max_balls do
                    if not balls[i] then
                        balls[i] = enemy
                        enemy = nil
                        break
                    end
                end
                if enemy then
                    max_balls = max_balls + 1
                    balls[max_balls] = enemy
                end
            end
        end
    end

    local count = simulate(dt, balls, max_balls)

    love.graphics.setBackgroundColor(0, 0, 0, 1)

    colC = avg60(colC, count)
    updT = avg60(updT, love.timer.getTime() - begin)
end

local color_by_type = {
    [TYPE_PLAYER] = function(g, ball)
    end,
    [TYPE_ENEMY] = function(g, ball)
        if ball.collision > 0.0 then
            local c = math.pow(conf.collision_animation, 1.0 - ball.collision)
            local nc = 1.0 - c
            g.setColor(1.0 * c + 0.25 * nc, 0.28 * nc, 0.80 * nc)
        else
            g.setColor(0.25, 0.28, 0.80)
        end
    end,
    [TYPE_BONUS] = function(g, ball)
    end
}

function love.draw()
    local begin = love.timer.getTime()

    local g = love.graphics

    for i = 1, max_balls do
        local ball = balls[i]
        if ball then
            if ball.mark then
                g.setColor(0.0, 1.0, 0.0)
            else
                color_by_type[ball.type](g, ball)
            end
            g.circle("fill", ball.x, ball.y, ball.r)
        end
    end

    -- g.setColor(0.0, 0.64, 0.91)
    -- g.circle("fill", x, y, r)

    g.setColor(0.0, 1.0, 0.0)
    g.print(string.format("%s\n%d fps updT: %.1f ms drwT: %.1f ms colC: %.1f", conf.version, love.timer.getFPS(),
                updT * 1e+3, drwT * 1e+3, colC), 10, 10)

    drwT = avg60(drwT, love.timer.getTime() - begin)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
end

TYPE_ENEMY = 1
TYPE_BONUS = 2

function love.load()
    love.window.setTitle("Balls")
    love.window.setFullscreen(true)
    width, height = love.graphics.getDimensions()
    love.mouse.setVisible(false)
    math.randomseed(os.time())

    player = {
        x = width / 2.0,
        y = height / 2.0,
        r = conf.radius,
        collision = 0.0,
        hp = 1.0,
        active = true,
        type = TYPE_PLAYER
    }
    max_balls = 0
    balls = {}

    effect_warn = 0.0
    effect_dead = 0.0
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

local function take_damage(damage)
    player.collision = 1.0
    local hp = player.hp - damage
    if hp < 0.0 then
        player.active = false
        effect_warn = 0.5
        effect_dead = 2.0
    elseif hp < 0.2 then
        effect_warn = 0.5
    end
    player.hp = hp
end

local update_by_type = {
    [TYPE_ENEMY] = function(dt, ball)
        if not is_visible(ball) and is_escape(ball) then
            -- respawn
            return spawn_enemy(ball)
        end
        if player.active and is_overlap(ball, player, 1e-3) then
            take_damage(conf.damage_normal)
            return nil
        end
        ball.collision = math.max(ball.collision - dt, 0.0)
        return ball
    end,
    [TYPE_BONUS] = function(dt, ball)
        if player.active and is_overlap(ball, player, 1e-3) then
            return nil
        end
        return ball
    end
}

function love.mousemoved(x, y, dx, dy, istouch)
    if player.active then
        player.x, player.y = x, y
    end
end

function love.update(dt)
    local begin = love.timer.getTime()

    width, height = love.graphics.getDimensions()

    if player.active then
        player.hp = math.min(player.hp + conf.base_heal * dt, 1.0)
    end
    player.collision = math.max(player.collision - dt, 0.0)

    local escaped = 0
    for i = 1, max_balls do
        local ball = balls[i]
        if ball then
            balls[i] = update_by_type[ball.type](dt, ball)
        end
    end

    if player.active and player.hp <= 0.0 then
        player.active = false
        effect_dead = 2.0
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

    if effect_dead > 0.0 then
        effect_dead = effect_dead - dt
    end

    if effect_warn > 0.0 then
        effect_warn = effect_warn - dt
        love.graphics.setBackgroundColor(effect_warn, 0, 0, 1)
    else
        love.graphics.setBackgroundColor(0, 0, 0, 1)
    end

    colC = avg60(colC, count)
    updT = avg60(updT, love.timer.getTime() - begin)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
end

local draw_by_type = {
    [TYPE_ENEMY] = function(g, ball)
        if ball.effect_collide > 0.0 then
            local c = math.pow(conf.effect_collide, 1.0 - ball.effect_collide)
            local nc = 1.0 - c
            g.setColor(1.0 * c + 0.25 * nc, 0.28 * nc, 0.80 * nc)
        else
            g.setColor(0.25, 0.28, 0.80)
        end
        g.circle("fill", ball.x, ball.y, ball.r)
    end,
    [TYPE_BONUS] = function(g, ball)
    end
}

function love.draw()
    local begin = love.timer.getTime()

    local g = love.graphics
    local active = 0
    for i = 1, max_balls do
        local ball = balls[i]
        if ball then
            active = active + 1
            if ball.mark then
                g.setColor(0.0, 1.0, 0.0)
                g.circle("fill", ball.x, ball.y, ball.r)
            else
                draw_by_type[ball.type](g, ball)
            end
        end
    end

    -- draw player
    if player.active then
        local c
        if player.effect_collide > 0.0 then
            c = math.pow(conf.effect_collide, 1.0 - player.effect_collide)
        else
            c = 0.0
        end
        local nc = 1.0 - c
        g.setColor(1.0 * c + 0.00 * nc, 0.64 * nc, 0.91 * nc)
        g.circle("fill", player.x, player.y, player.r)

        g.setColor(1.0 * c + 0.13 * nc, 1.69 * nc, 0.30 * nc)
        g.rectangle("fill", 0.0, height - 10.0, width * player.hp, 10.0)
    end

    if effect_dead > 0.0 then
        if effect_dead > 1.0 then
            g.setColor(0.0, 0.0, 0.0, 2.0 - effect_dead)
        else
            g.setColor(1.0, 1.0, 1.0, effect_dead)
        end
        g.rectangle("fill", 0.0, 0.0, width, height)
    end

    -- debug
    g.setColor(0.0, 1.0, 0.0)
    g.print(string.format("%s [%s]\n  %s\n%d fps updT: %.1f ms drwT: %.1f ms colC: %.1f bodC: %d/%d",
                conf.title, conf.version, conf.homepage,
                love.timer.getFPS(), updT * 1e+3, drwT * 1e+3, colC, active, max_balls), 10, 10)

    drwT = avg60(drwT, love.timer.getTime() - begin)
end

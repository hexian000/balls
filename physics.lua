function is_overlap(b1, b2, tol)
    local x, y = b1.x - b2.x, b1.y - b2.y
    local d = b1.r + b2.r + tol
    return x * x + y * y < d * d
end

local function has_collision(b1, b2, dt)
    local r = b1.r + b2.r
    local dpx, dpy = b2.x - b1.x, b2.y - b1.y
    local dvx, dvy = b2.vx - b1.vx, b2.vy - b1.vy
    local a = dvx * dvx + dvy * dvy
    local b = 2.0 * (dvx * dpx + dvy * dpy)
    local c = dpx * dpx + dpy * dpy - r * r
    local d = b * b - 4.0 * a * c
    if d >= 0.0 then
        a = 2.0 * a
        d = math.sqrt(d)
        local t1, t2 = (-b + d) / a, (-b - d) / a
        if t1 < 0.0 or t1 > dt or a * t1 + b >= 0.0 then
            t1 = nil
        end
        if t2 < 0.0 or t2 > dt or a * t2 + b >= 0.0 then
            t2 = nil
        end
        local t = t1 or t2
        if not t then
            return nil
        end
        b1.effect_collide, b2.effect_collide = 1.0, 1.0
        if t1 and t2 then
            return math.min(t1, t2)
        end
        return t
    end
    return nil
end

local function project(x, y, px, py)
    local pn = math.sqrt(px * px + py * py)
    px, py = px / pn, py / pn
    local m = x * px + y * py
    return m * px, m * py
end

local function solve_collision(ct, c1, c2)
    local pvx1, pvy1 = project(c1.vx, c1.vy, c1.x - c2.x, c1.y - c2.y)
    local nvx1, nvy1 = c1.vx - pvx1, c1.vy - pvy1
    local pvx2, pvy2 = project(c2.vx, c2.vy, c1.x - c2.x, c1.y - c2.y)
    local nvx2, nvy2 = c2.vx - pvx2, c2.vy - pvy2

    c1.vx, c1.vy = nvx1 + pvx2, nvy1 + pvy2
    c2.vx, c2.vy = nvx2 + pvx1, nvy2 + pvy1
end

local function advance(dt, bodies, n)
    if dt <= 0.0 then
        return
    end
    for i = 1, n do
        local body = bodies[i]
        if body then
            body.x = body.x + body.vx * dt
            body.y = body.y + body.vy * dt
            body.effect_collide = math.max(body.effect_collide - dt, 0.0)
        end
    end
end

local function dist(b1, b2)
    local dx, dy = b1.x - b2.x, b1.y - b2.y
    return math.sqrt(dx * dx + dy * dy)
end

function simulate(dt, bodies, n)
    local touched
    local count = 0
    repeat
        touched = false
        local ct, c1, c2
        -- collision check
        for i = 1, n do
            if bodies[i] then
                for j = i + 1, n do
                    if bodies[j] then
                        local t = has_collision(bodies[i], bodies[j], dt)
                        if t and (not ct or t < ct) then
                            ct, c1, c2 = t, bodies[i], bodies[j]
                        end
                    end
                end
            end
        end
        if ct then
            count = count + 1
            advance(ct, bodies, n)
            solve_collision(ct, c1, c2)
            dt = dt - ct
            touched = true
        end
    until not touched
    advance(dt, bodies, n)
    return count
end

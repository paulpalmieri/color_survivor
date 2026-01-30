--[[
    Particle System
    Regular particles and FX particles
]]

local Config = require("src.config")
local Game = require("src.game")

local Particles = {}

function Particles.spawn(config)
    local p = {
        x = config.x,
        y = config.y,
        vx = config.vx or (math.random() - 0.5) * 480,
        vy = config.vy or (math.random() - 0.5) * 480,
        color = config.color,
        life = config.lifetime or 0.5,
        maxLife = config.lifetime or 0.5,
        radius = config.radius or math.random(10, 20),  -- world units
        shrink = config.shrink or false,
        seed = math.random(1000),
        wobblePhase = math.random() * math.pi * 2,
        wobbleSpeed = 8 + math.random() * 6,
        wobbleAmount = Config.PARTICLE_WOBBLE_AMOUNT.min + math.random() * (Config.PARTICLE_WOBBLE_AMOUNT.max - Config.PARTICLE_WOBBLE_AMOUNT.min),  -- world units, NOT scaled
        radiusWobble = 0,
        tumbleSpeed = (math.random() - 0.5) * 15,
        tumbleAngle = math.random() * math.pi * 2
    }
    table.insert(Game.particles, p)
end

function Particles.spawnDeath(x, y, color, count)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(120, 360)
        Particles.spawn({
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = color,
            lifetime = 0.8,
            radius = math.random(Config.PARTICLE_DEATH_RADIUS.min, Config.PARTICLE_DEATH_RADIUS.max),
            shrink = true
        })
    end
end

function Particles.spawnSplatter(x, y, color, count)
    for i = 1, count do
        Particles.spawn({
            x = x,
            y = y,
            vx = (math.random() - 0.5) * 600,
            vy = (math.random() - 0.5) * 600,
            color = color,
            lifetime = 0.2,
            radius = math.random(Config.PARTICLE_SPLATTER_RADIUS.min, Config.PARTICLE_SPLATTER_RADIUS.max),
            shrink = true
        })
    end
end

function Particles.spawnFizzle(x, y, color)
    Particles.spawn({
        x = x,
        y = y,
        vx = (math.random() - 0.5) * 240,
        vy = (math.random() - 0.5) * 240 - 120,
        color = color,
        lifetime = 0.3,
        radius = math.random(Config.PARTICLE_SPLATTER_RADIUS.min, Config.PARTICLE_SPLATTER_RADIUS.max),
        shrink = true
    })
end

function Particles.spawnPaintMixFX(x, y, bulletColor, enemyColor, bvx, bvy, hitType)
    -- Small paint droplets on hit
    local count = hitType == "absorbed" and math.random(2, 3) or math.random(3, 5)

    for _ = 1, count do
        local a = math.random() * math.pi * 2
        local sp = 90 + math.random() * 120  -- world-unit speeds
        Particles.spawn({
            x = x + (math.random() - 0.5) * 10,
            y = y + (math.random() - 0.5) * 10,
            vx = math.cos(a) * sp,
            vy = math.sin(a) * sp,
            color = enemyColor,
            lifetime = 0.2 + math.random() * 0.15,
            radius = math.random(Config.PARTICLE_PAINTMIX_RADIUS.min, Config.PARTICLE_PAINTMIX_RADIUS.max),
            shrink = true
        })
    end
end

function Particles.update(dt)
    for i = #Game.particles, 1, -1 do
        local p = Game.particles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 480 * dt

        p.wobblePhase = p.wobblePhase + p.wobbleSpeed * dt
        p.radiusWobble = math.sin(p.wobblePhase) * p.wobbleAmount
        p.tumbleAngle = p.tumbleAngle + p.tumbleSpeed * dt

        if p.life <= 0 then
            table.remove(Game.particles, i)
        end
    end
end

function Particles.updateFX(dt)
    for i = #Game.fxParticles, 1, -1 do
        local p = Game.fxParticles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 480 * dt
        if p.life <= 0 then
            table.remove(Game.fxParticles, i)
        end
    end
end

function Particles.drawFX()
    for _, p in ipairs(Game.fxParticles) do
        local viewX, viewY = p.x - Game.camera.x, p.y - Game.camera.y
        local margin = 20 * Config.SCALE
        if viewX < -margin or viewX > Game.VIEWPORT_WIDTH + margin or viewY < -margin or viewY > Game.VIEWPORT_HEIGHT + margin then
            goto continue
        end
        local effectiveZoom = Game.getEffectiveZoom()
        local px, py = viewX * effectiveZoom, viewY * effectiveZoom
        local alpha = p.life / p.maxLife
        local worldRadius = p.shrink and (p.radius * Config.SCALE * alpha) or (p.radius * Config.SCALE)
        local screenRadius = worldRadius * effectiveZoom
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", px, py, screenRadius)
        ::continue::
    end
end

return Particles

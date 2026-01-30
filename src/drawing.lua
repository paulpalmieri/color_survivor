--[[
    Drawing System
    High-level drawing functions for game entities
]]

local Config = require("src.config")
local Game = require("src.game")
local Rendering = require("src.rendering")

local Drawing = {}

function Drawing.drawBlobs()
    local entitiesByColor = {}
    for colorName, _ in pairs(Config.COLORS) do
        entitiesByColor[colorName] = {enemies = {}, projectiles = {}, particles = {}}
    end

    for _, e in ipairs(Game.enemies) do
        if entitiesByColor[e.color] then
            table.insert(entitiesByColor[e.color].enemies, e)
        end
    end

    for _, p in ipairs(Game.projectiles) do
        if entitiesByColor[p.color] then
            table.insert(entitiesByColor[p.color].projectiles, p)
        end
    end

    for _, p in ipairs(Game.particles) do
        if entitiesByColor[p.color] then
            table.insert(entitiesByColor[p.color].particles, p)
        end
    end

    for colorName, entities in pairs(entitiesByColor) do
        -- Render enemies WITHOUT noise (clean edges)
        local enemyEntities = {}
        for _, e in ipairs(entities.enemies) do
            table.insert(enemyEntities, {
                x = e.x,
                y = e.y,
                vx = e.vx,
                vy = e.vy,
                baseRadius = e.baseRadius,
                radiusWobble = e.radiusWobble,
                pulseTimer = e.pulseTimer,
                pulseAmount = e.pulseAmount,
                radiusOffset = e.radiusOffset,
                membranePhase = e.membranePhase,
                membraneAmp = e.membraneAmp
            })
        end
        if #enemyEntities > 0 then
            Rendering.renderColorBlobs(colorName, enemyEntities,
                function(e) return e.baseRadius end,
                function(e) return e.intensity or Config.BLOB_INTENSITY end,
                false  -- no noise for enemies
            )
        end

        -- Render projectiles and particles WITH noise (paint splatter edges)
        local splatterEntities = {}
        for _, p in ipairs(entities.projectiles) do
            table.insert(splatterEntities, {
                x = p.x,
                y = p.y,
                vx = p.vx,
                vy = p.vy,
                baseRadius = p.baseRadius,
                radiusWobble = p.radiusWobble,
                membranePhase = p.membranePhase,
                membraneSpeed = p.membraneSpeed
            })
        end

        for _, p in ipairs(entities.particles) do
            local alpha = p.life / p.maxLife
            local radius = p.radius + (p.radiusWobble or 0)  -- already in world units
            if p.shrink then
                radius = radius * alpha
            end
            local speed = math.sqrt(p.vx * p.vx + p.vy * p.vy)
            local stretch = 1 + math.min(speed / 150, 0.4)
            table.insert(splatterEntities, {
                x = p.x,
                y = p.y,
                baseRadius = radius,
                radiusWobble = 0,
                intensity = Config.BLOB_INTENSITY * alpha,
                useCustomDeform = true,
                customStretchX = stretch,
                customStretchY = 1 / stretch,
                customAngle = p.tumbleAngle or math.atan2(p.vy, p.vx)
            })
        end

        if #splatterEntities > 0 then
            Rendering.renderColorBlobs(colorName, splatterEntities,
                function(e) return e.baseRadius end,
                function(e) return e.intensity or Config.BLOB_INTENSITY end,
                true  -- noise for projectiles and particles
            )
        end
    end

    -- Render player separately
    local player = Game.player
    do
        local pulseSize = math.sin(player.pulsePhase) * 0.8
        local dashSquish = 0
        if player.dashing then
            dashSquish = 0.15
        end

        local organicRadius = player.baseRadius + player.radiusWobble + pulseSize
        local asymStretchX = 1 + player.asymX
        local asymStretchY = 1 + player.asymY

        local finalStretchX = player.stretchAmount * (1 + player.deformOffset + dashSquish) * asymStretchX
        local finalStretchY = player.squishAmount * (1 - player.deformOffset * 0.5 - dashSquish * 0.5) * asymStretchY

        local jitterPosX = player.x + player.jitterX
        local jitterPosY = player.y + player.jitterY

        local organicIntensity = Config.BLOB_INTENSITY + player.intensityNoise

        local playerEntities = {{
            x = jitterPosX,
            y = jitterPosY,
            baseRadius = organicRadius,
            radiusWobble = 0,
            useCustomDeform = true,
            customStretchX = finalStretchX,
            customStretchY = finalStretchY,
            customAngle = player.stretchAngle,
            membranePhase = player.membranePhase,
            membraneAmp = player.membraneAmp,
            intensity = organicIntensity
        }}
        Rendering.renderColorBlobs(player.color, playerEntities,
            function(e) return e.baseRadius end,
            function(e) return e.intensity or Config.BLOB_INTENSITY end,
            false  -- no noise for player
        )
    end
end

function Drawing.drawTelegraphLines()
    local prevStyle = love.graphics.getLineStyle()
    local effectiveZoom = Game.getEffectiveZoom()
    love.graphics.setLineStyle("rough")
    for _, e in ipairs(Game.enemies) do
        if e.type == "dasher" and e.telegraphTimer > 0 then
            local ex, ey = (e.x - Game.camera.x) * effectiveZoom, (e.y - Game.camera.y) * effectiveZoom
            local alpha = 0.5 * (e.telegraphTimer / 0.5)
            local c = Config.COLORS[e.color]
            love.graphics.setColor(c[1], c[2], c[3], alpha)
            love.graphics.setLineWidth(2 * effectiveZoom)

            local dx, dy = e.targetX - e.x, e.targetY - e.y
            local fullLen = math.sqrt(dx * dx + dy * dy)
            if fullLen < 1 then goto continueTelegraph end

            local dashDist = 1200 * 0.3
            local len = math.min(fullLen, dashDist)
            local dashLen = 24 * effectiveZoom
            local gapLen = 18 * effectiveZoom
            local stepX, stepY = (dx / fullLen) * effectiveZoom, (dy / fullLen) * effectiveZoom
            local traveled = 0
            local screenLen = len * effectiveZoom
            while traveled < screenLen do
                local segEnd = math.min(traveled + dashLen, screenLen)
                love.graphics.line(
                    ex + (stepX / effectiveZoom) * traveled, ey + (stepY / effectiveZoom) * traveled,
                    ex + (stepX / effectiveZoom) * segEnd, ey + (stepY / effectiveZoom) * segEnd
                )
                traveled = segEnd + gapLen
            end
            ::continueTelegraph::
        end
    end
    love.graphics.setLineStyle(prevStyle)
end

function Drawing.drawBackground()
    local effectiveZoom = Game.getEffectiveZoom()
    local worldGridSize = 32 * Config.SCALE
    local screenGridSize = worldGridSize * effectiveZoom
    love.graphics.setColor(0.88, 0.86, 0.82, 0.5)
    love.graphics.setLineWidth(1)

    local gridOffsetX = (Game.camera.x % worldGridSize) * effectiveZoom
    local gridOffsetY = (Game.camera.y % worldGridSize) * effectiveZoom

    for x = -gridOffsetX, Game.RENDER_WIDTH, screenGridSize do
        love.graphics.line(x, 0, x, Game.RENDER_HEIGHT)
    end
    for y = -gridOffsetY, Game.RENDER_HEIGHT, screenGridSize do
        love.graphics.line(0, y, Game.RENDER_WIDTH, y)
    end

    love.graphics.setColor(0.75, 0.72, 0.68, 1)
    love.graphics.setLineWidth(2 * effectiveZoom)
    love.graphics.rectangle("line", -Game.camera.x * effectiveZoom, -Game.camera.y * effectiveZoom,
                            Config.ARENA_WIDTH * effectiveZoom, Config.ARENA_HEIGHT * effectiveZoom)
end

return Drawing

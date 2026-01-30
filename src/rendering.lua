--[[
    Rendering System
    Blob rendering, soft circles, shader operations
]]

local Config = require("src.config")
local Game = require("src.game")

local Rendering = {}

-- Resources (initialized in init)
Rendering.colorBuffers = {}
Rendering.thresholdShader = nil
Rendering.stencilShader = nil
Rendering.softCircleImage = nil

-- Color wheel canvases
Rendering.colorWheelCanvas = nil
Rendering.colorWheelMasks = {}

-- Create soft circle texture
local function createSoftCircleImage()
    local size = Config.SOFT_CIRCLE_SIZE
    local center = size / 2
    local imageData = love.image.newImageData(size, size)

    for y = 0, size - 1 do
        for x = 0, size - 1 do
            local dx = x - center + 0.5
            local dy = y - center + 0.5
            local dist = math.sqrt(dx * dx + dy * dy)
            local normalized = dist / center

            local value = math.max(0, 1 - normalized)
            value = value * value * (3 - 2 * value)

            imageData:setPixel(x, y, value, value, value, 1)
        end
    end

    return love.graphics.newImage(imageData)
end

-- Create/recreate color buffers at current window size
function Rendering.createColorBuffers()
    local w, h = love.graphics.getDimensions()
    Game.RENDER_WIDTH = w
    Game.RENDER_HEIGHT = h

    -- VIEWPORT stays fixed (everyone sees same game area)
    -- RENDER_SCALE adjusts drawing to fit current window
    Game.RENDER_SCALE = h / Config.BASE_HEIGHT

    for colorName, _ in pairs(Config.COLORS) do
        Rendering.colorBuffers[colorName] = love.graphics.newCanvas(w, h)
    end
end

-- Create/recreate color wheel canvases at appropriate size for uiScale
function Rendering.createColorWheelBuffers(uiScale)
    uiScale = uiScale or 1
    local baseSize = Config.COLOR_WHEEL.canvasSize
    local cwSize = math.ceil(baseSize * uiScale)

    Rendering.colorWheelCanvas = love.graphics.newCanvas(cwSize, cwSize)
    Rendering.colorWheelMasks = {
        red = love.graphics.newCanvas(cwSize, cwSize),
        yellow = love.graphics.newCanvas(cwSize, cwSize),
        blue = love.graphics.newCanvas(cwSize, cwSize),
        shadow = love.graphics.newCanvas(cwSize, cwSize),
    }
    Rendering.colorWheelScale = uiScale
end

function Rendering.init()
    Rendering.createColorBuffers()

    Rendering.thresholdShader = love.graphics.newShader("threshold.glsl")
    Rendering.stencilShader = love.graphics.newShader("threshold_stencil.glsl")
    Rendering.softCircleImage = createSoftCircleImage()

    -- Color wheel canvases (initial creation at base scale)
    local winH = love.graphics.getHeight()
    local uiScale = math.max(winH / 1080, 0.5)
    Rendering.createColorWheelBuffers(uiScale)
end

function Rendering.drawSoftCircle(x, y, radius, intensity)
    local scale = (radius * 2) / Rendering.softCircleImage:getWidth()
    love.graphics.setColor(intensity, intensity, intensity, 1)
    love.graphics.draw(Rendering.softCircleImage, x, y, 0, scale, scale,
        Rendering.softCircleImage:getWidth() / 2, Rendering.softCircleImage:getHeight() / 2)
end

function Rendering.drawSoftCircleStretched(x, y, radius, intensity, stretchX, stretchY, angle)
    local baseScale = (radius * 2) / Rendering.softCircleImage:getWidth()
    local scaleX = baseScale * stretchX
    local scaleY = baseScale * stretchY
    love.graphics.setColor(intensity, intensity, intensity, 1)
    love.graphics.draw(Rendering.softCircleImage, x, y, angle, scaleX, scaleY,
        Rendering.softCircleImage:getWidth() / 2, Rendering.softCircleImage:getHeight() / 2)
end

function Rendering.renderColorBlobs(colorName, entities, getRadius, getIntensity, useNoise)
    local buffer = Rendering.colorBuffers[colorName]
    local color = Config.COLORS[colorName]
    local effectiveZoom = Game.getEffectiveZoom()
    local noiseEnabled = useNoise and 1.0 or 0.0

    love.graphics.setCanvas(buffer)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("add")

    for _, entity in ipairs(entities) do
        local radius = getRadius(entity)
        local intensity = getIntensity and getIntensity(entity) or Config.BLOB_INTENSITY

        local wobbleOffset = entity.radiusWobble or 0
        local worldRadius = radius + wobbleOffset

        local stretchX, stretchY, angle = 1, 1, 0
        if entity.useCustomDeform then
            stretchX = entity.customStretchX or 1
            stretchY = entity.customStretchY or 1
            angle = entity.customAngle or 0
        elseif entity.vx and entity.vy then
            local speed = math.sqrt(entity.vx * entity.vx + entity.vy * entity.vy)
            local stretchFactor = 1 + math.min(speed / (Config.PLAYER_MAX_SPEED * 2.5), 0.3)
            stretchX = stretchFactor
            stretchY = 1 / stretchFactor
            if speed > 1 then
                angle = math.atan2(entity.vy, entity.vx)
            end
        end

        if entity.pulseTimer and entity.pulseTimer > 0 then
            local pulseAdd = entity.pulseAmount * Config.SCALE * (entity.pulseTimer / 0.15)
            worldRadius = worldRadius + pulseAdd
        end

        if entity.radiusOffset and entity.radiusOffset ~= 0 then
            worldRadius = worldRadius + entity.radiusOffset * Config.SCALE
        end

        local viewX = entity.x - Game.camera.x
        local viewY = entity.y - Game.camera.y
        if viewX < -worldRadius * 2 or viewX > Game.VIEWPORT_WIDTH + worldRadius * 2 or
           viewY < -worldRadius * 2 or viewY > Game.VIEWPORT_HEIGHT + worldRadius * 2 then
            goto continue
        end

        local screenX = viewX * effectiveZoom
        local screenY = viewY * effectiveZoom
        local drawRadius = worldRadius * effectiveZoom

        local memPhase = entity.membranePhase or (Game.gameTime * 3)

        if worldRadius > Config.MINI_LOBE_THRESHOLD then
            -- Large blob rendering: 5 lobes + 3 organelles
            local numLobes = 5
            local cosA, sinA = math.cos(angle), math.sin(angle)

            Rendering.drawSoftCircleStretched(screenX, screenY, drawRadius * 0.85, intensity * 0.9, stretchX, stretchY, angle)

            for i = 1, numLobes do
                local lobePhase = memPhase * (0.7 + i * 0.15) + (i * 2.39996)
                local lobeDist = drawRadius * (0.25 + math.sin(lobePhase) * 0.12)
                local lobeAngle = (i / numLobes) * math.pi * 2 + math.sin(lobePhase * 0.7) * 0.3

                local localX = math.cos(lobeAngle) * lobeDist
                local localY = math.sin(lobeAngle) * lobeDist

                local rotX = localX * cosA - localY * sinA
                local rotY = localX * sinA + localY * cosA
                local stretchedX = rotX * stretchX
                local stretchedY = rotY * stretchY
                local finalX = stretchedX * cosA + stretchedY * sinA
                local finalY = -stretchedX * sinA + stretchedY * cosA

                local lobeRadius = drawRadius * (0.55 + math.sin(lobePhase * 1.3) * 0.1)
                local lobeIntensity = intensity * (0.85 + math.sin(lobePhase * 0.9) * 0.1)

                Rendering.drawSoftCircle(screenX + finalX, screenY + finalY, lobeRadius, lobeIntensity)
            end

            local numOrganelles = 3
            for i = 1, numOrganelles do
                local orgPhase = memPhase * (1.1 + i * 0.2)
                local orbitAngle = (i / numOrganelles) * math.pi * 2 + orgPhase * 0.8
                local orbitDist = drawRadius * (0.2 + math.sin(orgPhase * 1.5 + i) * 0.1)

                local localX = math.cos(orbitAngle) * orbitDist
                local localY = math.sin(orbitAngle) * orbitDist

                local rotX = localX * cosA - localY * sinA
                local rotY = localX * sinA + localY * cosA
                local stretchedX = rotX * stretchX
                local stretchedY = rotY * stretchY
                local finalX = stretchedX * cosA + stretchedY * sinA
                local finalY = -stretchedX * sinA + stretchedY * cosA

                local orgRadius = drawRadius * (0.35 + math.sin(orgPhase * 2 + i * 1.7) * 0.08)
                local orgIntensity = intensity * (0.6 + math.sin(orgPhase * 1.5 + i * 2.3) * 0.15)

                Rendering.drawSoftCircle(screenX + finalX, screenY + finalY, orgRadius, orgIntensity)
            end
        elseif worldRadius > (3 * Config.SCALE) then
            -- Mini-lobe rendering for small entities (projectiles)
            local numLobes = Config.MINI_LOBE_COUNT
            local cosA, sinA = math.cos(angle), math.sin(angle)

            -- Smaller core
            Rendering.drawSoftCircleStretched(screenX, screenY,
                drawRadius * Config.MINI_LOBE_CORE_SCALE,
                intensity * 0.95, stretchX, stretchY, angle)

            -- Mini lobes (no organelles)
            for i = 1, numLobes do
                local lobePhase = memPhase * (1.2 + i * 0.3) + (i * 3.14159)
                local lobeDist = drawRadius * (Config.MINI_LOBE_ORBIT_DIST + math.sin(lobePhase) * 0.08)
                local lobeAngle = (i / numLobes) * math.pi * 2 + math.sin(lobePhase * 0.9) * 0.4

                local localX = math.cos(lobeAngle) * lobeDist
                local localY = math.sin(lobeAngle) * lobeDist

                -- Apply rotation and stretch (same as large lobes)
                local rotX = localX * cosA - localY * sinA
                local rotY = localX * sinA + localY * cosA
                local stretchedX = rotX * stretchX
                local stretchedY = rotY * stretchY
                local finalX = stretchedX * cosA + stretchedY * sinA
                local finalY = -stretchedX * sinA + stretchedY * cosA

                local lobeRadius = drawRadius * Config.MINI_LOBE_RADIUS
                local lobeIntensity = intensity * 0.9

                Rendering.drawSoftCircle(screenX + finalX, screenY + finalY, lobeRadius, lobeIntensity)
            end
        else
            -- Very small: just draw core
            Rendering.drawSoftCircleStretched(screenX, screenY, drawRadius, intensity, stretchX, stretchY, angle)
        end
        ::continue::
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()

    love.graphics.setShader(Rendering.thresholdShader)
    Rendering.thresholdShader:send("threshold", Config.BLOB_THRESHOLD)
    Rendering.thresholdShader:send("blobColor", color)
    Rendering.thresholdShader:send("noiseEnabled", noiseEnabled)
    Rendering.thresholdShader:send("noiseScale", Config.NOISE_SCALE)
    Rendering.thresholdShader:send("noiseAmount", Config.NOISE_AMOUNT)
    Rendering.thresholdShader:send("noiseTime", (Game.gameTime or 0) * Config.NOISE_SPEED)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(buffer, 0, 0)
    love.graphics.setShader()
end

return Rendering

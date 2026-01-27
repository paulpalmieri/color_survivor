--[[
    Color Survivor
    A Vampire Survivors-style bullet hell with color-switching mechanics
    Soft-circle threshold blob rendering system
]]

-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================

-- Pixel art rendering dimensions
GAME_WIDTH = 320
GAME_HEIGHT = 180
WINDOW_WIDTH = 960   -- 320 * 3
WINDOW_HEIGHT = 540  -- 180 * 3

-- Color palette - saturated, distinct colors
COLORS = {
    red = {0.95, 0.25, 0.3},
    cyan = {0.2, 0.85, 0.9},
    yellow = {0.95, 0.9, 0.2},
}
COLOR_ORDER = {"red", "cyan", "yellow"}
BACKGROUND = {0.95, 0.93, 0.88}  -- off-white/cream canvas color

-- Player settings (scaled for 320x180 canvas)
PLAYER_RADIUS = 14
PLAYER_MAX_SPEED = 80
PLAYER_ACCEL = 480
PLAYER_DECEL = 320
PLAYER_MAX_HP = 100
COLOR_SWITCH_COOLDOWN = 1.0

-- Projectile settings
PROJECTILE_SPEED = 160
PROJECTILE_RADIUS = 5
FIRE_RATE = 4
PROJECTILE_DAMAGE = 25

-- Enemy settings
ENEMY_CONTACT_DAMAGE = 15
ENEMY_RADIUS = 12
DASHER_RADIUS = 14
SPAWN_MARGIN = 20

-- XP settings
XP_MAGNET_RANGE = 32
XP_MAGNET_SPEED = 120
XP_PER_SHARD = 10
XP_SHARD_RADIUS = 2

-- Blob rendering
SOFT_CIRCLE_SIZE = 64
BLOB_THRESHOLD = 0.35
BLOB_INTENSITY = 1.0  -- How bright each blob center is

-- ============================================================================
-- RENDERING RESOURCES
-- ============================================================================

local gameCanvas = nil
local colorBuffers = {}  -- One buffer per color
local thresholdShader = nil
local softCircleImage = nil
local font = nil
local fontSmall = nil
local fontLarge = nil

-- ============================================================================
-- GAME STATE
-- ============================================================================

local gameState = "play"
local screenShake = {amount = 0, duration = 0}
local gameTime = 0

-- ============================================================================
-- ENTITY TABLES
-- ============================================================================

local player = {}
local enemies = {}
local projectiles = {}
local shards = {}
local particles = {}

-- Projectile pool for performance
local projectilePool = {}

-- Level/upgrade system
local levelUpChoices = {}
local upgrades = {
    fireRate = 1,
    moveSpeed = 1,
    damage = 1,
    projectileCount = 1,
    cooldownReduction = 0,
    maxHp = 0
}

-- Wave system
local waveTime = 0
local spawnTimer = 0
local baseSpawnRate = 1.5

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function normalize(x, y)
    local len = math.sqrt(x * x + y * y)
    if len > 0 then
        return x / len, y / len
    end
    return 0, 0
end

local function getColorIndex(colorName)
    for i, name in ipairs(COLOR_ORDER) do
        if name == colorName then return i end
    end
    return 1
end

local function shakeScreen(amount, duration)
    screenShake.amount = math.max(screenShake.amount, amount)
    screenShake.duration = math.max(screenShake.duration, duration)
end

local function screenToGame(sx, sy)
    local scale = math.min(WINDOW_WIDTH / GAME_WIDTH, WINDOW_HEIGHT / GAME_HEIGHT)
    return sx / scale, sy / scale
end

-- ============================================================================
-- SOFT CIRCLE TEXTURE GENERATION
-- ============================================================================

local function createSoftCircleImage()
    local size = SOFT_CIRCLE_SIZE
    local center = size / 2
    local imageData = love.image.newImageData(size, size)

    for y = 0, size - 1 do
        for x = 0, size - 1 do
            local dx = x - center + 0.5
            local dy = y - center + 0.5
            local dist = math.sqrt(dx * dx + dy * dy)
            local normalized = dist / center

            -- Radial gradient: bright center, fades to transparent at edges
            local value = math.max(0, 1 - normalized)
            -- Gentle falloff (not too aggressive)
            value = value * value * (3 - 2 * value)  -- smoothstep for nice merging

            imageData:setPixel(x, y, value, value, value, 1)
        end
    end

    return love.graphics.newImage(imageData)
end

-- ============================================================================
-- BLOB RENDERING SYSTEM
-- ============================================================================

local function drawSoftCircle(x, y, radius, intensity)
    local scale = (radius * 2) / softCircleImage:getWidth()
    love.graphics.setColor(intensity, intensity, intensity, 1)
    love.graphics.draw(softCircleImage, x, y, 0, scale, scale,
        softCircleImage:getWidth() / 2, softCircleImage:getHeight() / 2)
end

local function drawSoftCircleStretched(x, y, radius, intensity, stretchX, stretchY, angle)
    local baseScale = (radius * 2) / softCircleImage:getWidth()
    local scaleX = baseScale * stretchX
    local scaleY = baseScale * stretchY
    love.graphics.setColor(intensity, intensity, intensity, 1)
    love.graphics.draw(softCircleImage, x, y, angle, scaleX, scaleY,
        softCircleImage:getWidth() / 2, softCircleImage:getHeight() / 2)
end

local function renderColorBlobs(colorName, entities, getRadius, getIntensity)
    local buffer = colorBuffers[colorName]
    local color = COLORS[colorName]

    -- Step 1: Clear buffer and draw soft circles
    love.graphics.setCanvas(buffer)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("add")

    for _, entity in ipairs(entities) do
        local radius = getRadius(entity)
        local intensity = getIntensity and getIntensity(entity) or BLOB_INTENSITY

        -- Calculate wobble
        local wobbleOffset = 0
        if entity.radiusWobble then
            wobbleOffset = entity.radiusWobble
        end
        local drawRadius = radius + wobbleOffset

        -- Calculate squash/stretch from velocity (or use custom values)
        local stretchX, stretchY, angle = 1, 1, 0
        if entity.useCustomDeform then
            stretchX = entity.customStretchX or 1
            stretchY = entity.customStretchY or 1
            angle = entity.customAngle or 0
        elseif entity.vx and entity.vy then
            local speed = math.sqrt(entity.vx * entity.vx + entity.vy * entity.vy)
            local stretchFactor = 1 + math.min(speed / 200, 0.3)
            stretchX = stretchFactor
            stretchY = 1 / stretchFactor
            if speed > 1 then
                angle = math.atan2(entity.vy, entity.vx)
            end
        end

        -- Add pulse effect if entity has one
        if entity.pulseTimer and entity.pulseTimer > 0 then
            local pulseAdd = entity.pulseAmount * (entity.pulseTimer / 0.15)
            drawRadius = drawRadius + pulseAdd
        end

        -- Add damage flinch effect
        if entity.radiusOffset and entity.radiusOffset ~= 0 then
            drawRadius = drawRadius + entity.radiusOffset
        end

        -- Draw main blob
        drawSoftCircleStretched(entity.x, entity.y, drawRadius, intensity, stretchX, stretchY, angle)

        -- For larger entities, add molecular sub-blobs (organelles)
        if drawRadius > 8 and not entity.isProjectile then
            local numOrganelles = 4
            local memPhase = entity.membranePhase or (gameTime * 3)
            local memAmp = entity.membraneAmp or 0.5

            for i = 1, numOrganelles do
                -- Each organelle orbits at different speed and phase
                local orbitAngle = (i / numOrganelles) * math.pi * 2 + memPhase * (0.8 + i * 0.1)
                local orbitDist = drawRadius * (0.35 + math.sin(memPhase * 1.3 + i) * 0.15)

                -- Organelle position relative to center (before stretch transform)
                local localX = math.cos(orbitAngle) * orbitDist
                local localY = math.sin(orbitAngle) * orbitDist

                -- Apply stretch transformation
                local cosA, sinA = math.cos(angle), math.sin(angle)
                local rotX = localX * cosA - localY * sinA
                local rotY = localX * sinA + localY * cosA
                local stretchedX = rotX * stretchX
                local stretchedY = rotY * stretchY
                local finalX = stretchedX * cosA + stretchedY * sinA
                local finalY = -stretchedX * sinA + stretchedY * cosA

                -- Organelle size pulses independently
                local orgRadius = drawRadius * (0.45 + math.sin(memPhase * 2 + i * 1.7) * 0.1)
                local orgIntensity = intensity * (0.7 + math.sin(memPhase * 1.5 + i * 2.3) * 0.15)

                drawSoftCircle(entity.x + finalX, entity.y + finalY, orgRadius, orgIntensity)
            end

            -- Add membrane wobble circles around the perimeter (disabled)
            --[[local numMembranePoints = 6
            for i = 1, numMembranePoints do
                local mAngle = (i / numMembranePoints) * math.pi * 2 + memPhase * 0.5
                local mDist = drawRadius * (0.85 + math.sin(memPhase * 2 + i * 1.1) * memAmp * 0.15)

                local localX = math.cos(mAngle) * mDist
                local localY = math.sin(mAngle) * mDist

                -- Apply stretch
                local cosA, sinA = math.cos(angle), math.sin(angle)
                local rotX = localX * cosA - localY * sinA
                local rotY = localX * sinA + localY * cosA
                local stretchedX = rotX * stretchX
                local stretchedY = rotY * stretchY
                local finalX = stretchedX * cosA + stretchedY * sinA
                local finalY = -stretchedX * sinA + stretchedY * cosA

                local mRadius = drawRadius * 0.35
                local mIntensity = intensity * 0.5

                drawSoftCircle(entity.x + finalX, entity.y + finalY, mRadius, mIntensity)
            end--]]
        end
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()

    -- Step 2: Apply threshold shader and draw to game canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.setShader(thresholdShader)
    thresholdShader:send("threshold", BLOB_THRESHOLD)
    thresholdShader:send("blobColor", color)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(buffer, 0, 0)
    love.graphics.setShader()
end

-- ============================================================================
-- PARTICLE SYSTEM
-- ============================================================================

local function spawnParticle(config)
    local p = {
        x = config.x,
        y = config.y,
        vx = config.vx or (math.random() - 0.5) * 80,
        vy = config.vy or (math.random() - 0.5) * 80,
        color = config.color,
        life = config.lifetime or 0.5,
        maxLife = config.lifetime or 0.5,
        radius = config.radius or math.random(1, 3),
        shrink = config.shrink or false,
        seed = math.random(1000),
        -- Organic wobble
        wobblePhase = math.random() * math.pi * 2,
        wobbleSpeed = 8 + math.random() * 6,  -- faster for particles
        wobbleAmount = 0.4 + math.random() * 0.3,
        radiusWobble = 0,
        -- Tumble rotation
        tumbleSpeed = (math.random() - 0.5) * 15,
        tumbleAngle = math.random() * math.pi * 2
    }
    table.insert(particles, p)
end

local function spawnDeathParticles(x, y, color, count)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(20, 60)
        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = color,
            lifetime = 0.8,
            radius = math.random(2, 5),
            shrink = true
        })
    end
end

local function spawnSplatterParticles(x, y, color, count)
    for i = 1, count do
        spawnParticle({
            x = x,
            y = y,
            vx = (math.random() - 0.5) * 100,
            vy = (math.random() - 0.5) * 100,
            color = color,
            lifetime = 0.2,
            radius = 2,
            shrink = true
        })
    end
end

local function spawnFizzleParticle(x, y, color)
    spawnParticle({
        x = x,
        y = y,
        vx = (math.random() - 0.5) * 40,
        vy = (math.random() - 0.5) * 40 - 20,
        color = color,
        lifetime = 0.3,
        radius = 2,
        shrink = true
    })
end

-- ============================================================================
-- PLAYER
-- ============================================================================

local function initPlayer()
    local seed = math.random(1000)
    player = {
        x = GAME_WIDTH / 2,
        y = GAME_HEIGHT / 2,
        vx = 0, vy = 0,
        prevVx = 0, prevVy = 0,
        color = "red",
        colorCooldown = 0,
        hp = PLAYER_MAX_HP + upgrades.maxHp,
        maxHp = PLAYER_MAX_HP + upgrades.maxHp,
        fireTimer = 0,
        xp = 0,
        level = 1,
        xpToLevel = 100,
        invincible = 0,
        seed = seed,
        baseRadius = PLAYER_RADIUS,
        -- Organic deformation properties
        stretchAngle = 0,
        stretchAmount = 1,
        squishAmount = 1,
        deformVel = 0,
        deformOffset = 0,
        -- Multi-layer organic wobble system
        wobbles = {
            {phase = math.random() * math.pi * 2, speed = 2.3, amount = 1.2},
            {phase = math.random() * math.pi * 2, speed = 3.7, amount = 0.8},
            {phase = math.random() * math.pi * 2, speed = 5.1, amount = 0.5},
        },
        -- Membrane ripple (wave traveling around the blob)
        membranePhase = 0,
        membraneSpeed = 4 + math.random() * 2,
        membraneAmp = 0.8,
        -- Asymmetric blob offset (makes it not perfectly round)
        asymX = (math.random() - 0.5) * 0.3,
        asymY = (math.random() - 0.5) * 0.3,
        asymDriftX = 0,
        asymDriftY = 0,
        -- Brownian jitter
        jitterX = 0,
        jitterY = 0,
        jitterTargetX = 0,
        jitterTargetY = 0,
        -- Internal pulsing (like a heartbeat)
        pulsePhase = math.random() * math.pi * 2,
        pulseSpeed = 1.5 + math.random() * 0.5,
        -- Random intensity flicker
        intensityNoise = 0,
    }
end

local function switchColor(direction)
    if player.colorCooldown > 0 then return end

    local currentIndex = getColorIndex(player.color)
    local newIndex = currentIndex + direction
    if newIndex < 1 then newIndex = 3 end
    if newIndex > 3 then newIndex = 1 end

    player.color = COLOR_ORDER[newIndex]
    player.colorCooldown = COLOR_SWITCH_COOLDOWN * (1 - upgrades.cooldownReduction * 0.15)
end

local function setColorDirect(index)
    if player.colorCooldown > 0 then return end
    if player.color == COLOR_ORDER[index] then return end

    player.color = COLOR_ORDER[index]
    player.colorCooldown = COLOR_SWITCH_COOLDOWN * (1 - upgrades.cooldownReduction * 0.15)
end

local function updatePlayer(dt)
    -- Store previous velocity for direction change detection
    player.prevVx = player.vx
    player.prevVy = player.vy

    local ix, iy = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then iy = -1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then iy = 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then ix = -1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then ix = 1 end

    if ix ~= 0 and iy ~= 0 then
        ix, iy = ix * 0.707, iy * 0.707
    end

    local maxSpeed = PLAYER_MAX_SPEED * (1 + (upgrades.moveSpeed - 1) * 0.2)

    if ix ~= 0 then
        player.vx = player.vx + ix * PLAYER_ACCEL * dt
    else
        if player.vx > 0 then
            player.vx = math.max(0, player.vx - PLAYER_DECEL * dt)
        else
            player.vx = math.min(0, player.vx + PLAYER_DECEL * dt)
        end
    end

    if iy ~= 0 then
        player.vy = player.vy + iy * PLAYER_ACCEL * dt
    else
        if player.vy > 0 then
            player.vy = math.max(0, player.vy - PLAYER_DECEL * dt)
        else
            player.vy = math.min(0, player.vy + PLAYER_DECEL * dt)
        end
    end

    local speed = math.sqrt(player.vx * player.vx + player.vy * player.vy)
    if speed > maxSpeed then
        player.vx = player.vx / speed * maxSpeed
        player.vy = player.vy / speed * maxSpeed
    end

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    player.x = math.max(PLAYER_RADIUS, math.min(GAME_WIDTH - PLAYER_RADIUS, player.x))
    player.y = math.max(PLAYER_RADIUS, math.min(GAME_HEIGHT - PLAYER_RADIUS, player.y))

    if player.colorCooldown > 0 then
        player.colorCooldown = player.colorCooldown - dt
    end

    if player.invincible > 0 then
        player.invincible = player.invincible - dt
    end

    player.fireTimer = player.fireTimer - dt
    if love.mouse.isDown(1) and player.fireTimer <= 0 then
        fireProjectile()
        player.fireTimer = 1 / (FIRE_RATE * upgrades.fireRate)
    end

    -- === ORGANIC MOLECULAR ANIMATION ===

    -- Multi-layer wobble (sum of multiple sine waves at different frequencies)
    local totalWobble = 0
    for _, w in ipairs(player.wobbles) do
        w.phase = w.phase + w.speed * dt
        totalWobble = totalWobble + math.sin(w.phase) * w.amount
    end
    player.radiusWobble = totalWobble

    -- Membrane ripple phase (continuous wave around the perimeter)
    player.membranePhase = player.membranePhase + player.membraneSpeed * dt

    -- Asymmetric drift (the blob's shape slowly morphs)
    player.asymDriftX = player.asymDriftX + (math.random() - 0.5) * dt * 2
    player.asymDriftY = player.asymDriftY + (math.random() - 0.5) * dt * 2
    player.asymDriftX = player.asymDriftX * 0.98  -- drift back toward center
    player.asymDriftY = player.asymDriftY * 0.98
    player.asymX = math.sin(gameTime * 0.7) * 0.15 + player.asymDriftX
    player.asymY = math.cos(gameTime * 0.9) * 0.15 + player.asymDriftY

    -- Brownian motion jitter (random micro-movements)
    if math.random() < dt * 8 then  -- occasionally pick new target
        player.jitterTargetX = (math.random() - 0.5) * 0.8
        player.jitterTargetY = (math.random() - 0.5) * 0.8
    end
    player.jitterX = lerp(player.jitterX, player.jitterTargetX, dt * 12)
    player.jitterY = lerp(player.jitterY, player.jitterTargetY, dt * 12)

    -- Internal pulse (heartbeat-like throb)
    player.pulsePhase = player.pulsePhase + player.pulseSpeed * dt

    -- Intensity flicker (subtle brightness variation)
    player.intensityNoise = lerp(player.intensityNoise, (math.random() - 0.5) * 0.15, dt * 6)

    -- Organic deformation update
    local currentSpeed = math.sqrt(player.vx * player.vx + player.vy * player.vy)
    local prevSpeed = math.sqrt(player.prevVx * player.prevVx + player.prevVy * player.prevVy)

    -- Target stretch based on speed
    local targetStretch = 1 + math.min(currentSpeed / 200, 0.3)
    local targetSquish = 1 / targetStretch

    -- Target angle based on velocity
    local targetAngle = player.stretchAngle
    if currentSpeed > 5 then
        targetAngle = math.atan2(player.vy, player.vx)
    end

    -- Detect direction changes (dot product of old and new velocity)
    if prevSpeed > 10 and currentSpeed > 10 then
        local dot = (player.vx * player.prevVx + player.vy * player.prevVy) / (currentSpeed * prevSpeed)
        -- If direction changed significantly (dot < 0.7 means > 45 degree change)
        if dot < 0.7 then
            -- Add a squish impulse proportional to direction change
            local impulse = (1 - dot) * 0.3
            player.deformVel = player.deformVel + impulse * 15
        end
    end

    -- Spring physics for deform offset (creates bouncy squash on direction change)
    local stiffness = 180
    local damping = 12
    local springForce = -stiffness * player.deformOffset - damping * player.deformVel
    player.deformVel = player.deformVel + springForce * dt
    player.deformOffset = player.deformOffset + player.deformVel * dt
    player.deformOffset = math.max(-0.4, math.min(0.4, player.deformOffset))

    -- Smooth interpolation of stretch values
    player.stretchAmount = lerp(player.stretchAmount, targetStretch, dt * 8)
    player.squishAmount = lerp(player.squishAmount, targetSquish, dt * 8)

    -- Smooth angle interpolation (handle wrapping)
    local angleDiff = targetAngle - player.stretchAngle
    -- Normalize angle difference to [-pi, pi]
    while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
    while angleDiff < -math.pi do angleDiff = angleDiff + math.pi * 2 end
    player.stretchAngle = player.stretchAngle + angleDiff * dt * 10
end

local function damagePlayer(amount)
    if player.invincible > 0 then return end

    player.hp = player.hp - amount
    player.invincible = 0.5
    shakeScreen(2, 0.15)

    if player.hp <= 0 then
        player.hp = 0
        gameState = "dead"
    end
end

-- ============================================================================
-- PROJECTILES
-- ============================================================================

local function getPooledProjectile()
    for i, p in ipairs(projectilePool) do
        if not p.active then
            return p
        end
    end
    local p = {active = false}
    table.insert(projectilePool, p)
    return p
end

function fireProjectile()
    local sx, sy = love.mouse.getPosition()
    local mx, my = screenToGame(sx, sy)
    local dx, dy = mx - player.x, my - player.y
    dx, dy = normalize(dx, dy)

    local count = upgrades.projectileCount
    local spreadAngle = 0.15

    for i = 1, count do
        local offset = (i - 1) - (count - 1) / 2
        local angle = math.atan2(dy, dx) + offset * spreadAngle

        local p = getPooledProjectile()
        p.active = true
        p.x = player.x
        p.y = player.y
        p.vx = math.cos(angle) * PROJECTILE_SPEED
        p.vy = math.sin(angle) * PROJECTILE_SPEED
        p.color = player.color
        p.seed = math.random(1000)
        p.baseRadius = PROJECTILE_RADIUS
        p.radiusWobble = 0
        p.wobbleSpeed = 5 + math.random() * 3
        p.wobbleAmount = 0.5
        -- Bullet dying state (for absorbed effect)
        p.dying = false
        p.deathTimer = 0

        table.insert(projectiles, p)
    end
end

local function updateProjectiles(dt)
    for i = #projectiles, 1, -1 do
        local p = projectiles[i]

        if p.dying then
            p.deathTimer = p.deathTimer - dt
            -- Shrink radius as it dies
            p.baseRadius = PROJECTILE_RADIUS * (p.deathTimer / 0.1)
            if p.deathTimer <= 0 then
                p.active = false
                table.remove(projectiles, i)
            end
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt

            -- Update wobble
            p.radiusWobble = math.sin(gameTime * p.wobbleSpeed) * p.wobbleAmount

            if p.x < -50 or p.x > GAME_WIDTH + 50 or p.y < -50 or p.y > GAME_HEIGHT + 50 then
                p.active = false
                table.remove(projectiles, i)
            end
        end
    end
end

-- ============================================================================
-- ENEMIES
-- ============================================================================

local function spawnEnemy(enemyType)
    local side = math.random(1, 4)
    local x, y
    if side == 1 then
        x, y = math.random(0, GAME_WIDTH), -SPAWN_MARGIN
    elseif side == 2 then
        x, y = GAME_WIDTH + SPAWN_MARGIN, math.random(0, GAME_HEIGHT)
    elseif side == 3 then
        x, y = math.random(0, GAME_WIDTH), GAME_HEIGHT + SPAWN_MARGIN
    else
        x, y = -SPAWN_MARGIN, math.random(0, GAME_HEIGHT)
    end

    local colorCounts = {red = 0, cyan = 0, yellow = 0}
    for _, e in ipairs(enemies) do
        colorCounts[e.color] = colorCounts[e.color] + 1
    end

    local minCount = math.min(colorCounts.red, colorCounts.cyan, colorCounts.yellow)
    local candidates = {}
    for _, c in ipairs(COLOR_ORDER) do
        if colorCounts[c] <= minCount + 2 then
            table.insert(candidates, c)
        end
    end
    local color = candidates[math.random(#candidates)]
    local seed = math.random(1000)

    local baseRadius = enemyType == "dasher" and DASHER_RADIUS or ENEMY_RADIUS

    local enemy = {
        x = x, y = y,
        vx = 0, vy = 0,
        color = color,
        type = enemyType or "drifter",
        hp = enemyType == "dasher" and 40 or 25,
        seed = seed,
        baseRadius = baseRadius,
        -- Multi-layer organic wobble
        wobbles = {
            {phase = math.random() * math.pi * 2, speed = 2.0 + math.random() * 1.5, amount = 1.0},
            {phase = math.random() * math.pi * 2, speed = 3.5 + math.random() * 1.5, amount = 0.6},
            {phase = math.random() * math.pi * 2, speed = 5.0 + math.random() * 2, amount = 0.4},
        },
        radiusWobble = 0,
        -- Membrane ripple
        membranePhase = math.random() * math.pi * 2,
        membraneSpeed = 3 + math.random() * 3,
        membraneAmp = 0.6 + math.random() * 0.4,
        -- Pulse effect (when absorbing bullet)
        pulseTimer = 0,
        pulseAmount = 2,
        -- Damage flinch effect
        radiusOffset = 0,
        radiusRecovery = 0,
        -- Dasher specific
        dashCooldown = math.random() * 2 + 1,
        dashing = false,
        dashTimer = 0,
        telegraphTimer = 0,
        targetX = 0, targetY = 0
    }

    table.insert(enemies, enemy)
end

local function updateEnemies(dt)
    for i = #enemies, 1, -1 do
        local e = enemies[i]

        -- Update pulse timer (absorption effect)
        if e.pulseTimer > 0 then
            e.pulseTimer = e.pulseTimer - dt
        end

        -- Update radius recovery (damage flinch)
        if e.radiusRecovery > 0 then
            e.radiusRecovery = e.radiusRecovery - dt
            if e.radiusRecovery <= 0 then
                e.radiusOffset = 0
            else
                -- Lerp back to normal
                e.radiusOffset = -3 * (e.radiusRecovery / 0.1)
            end
        end

        if e.type == "drifter" then
            local dx, dy = player.x - e.x, player.y - e.y
            dx, dy = normalize(dx, dy)
            local speed = 24
            e.vx = dx * speed
            e.vy = dy * speed

        elseif e.type == "dasher" then
            if e.dashing then
                e.dashTimer = e.dashTimer - dt
                if e.dashTimer <= 0 then
                    e.dashing = false
                    e.dashCooldown = 2
                    e.vx, e.vy = 0, 0
                end
            elseif e.telegraphTimer > 0 then
                e.telegraphTimer = e.telegraphTimer - dt
                e.vx, e.vy = 0, 0
                if e.telegraphTimer <= 0 then
                    e.dashing = true
                    e.dashTimer = 0.3
                    local dx, dy = e.targetX - e.x, e.targetY - e.y
                    dx, dy = normalize(dx, dy)
                    e.vx = dx * 200
                    e.vy = dy * 200
                end
            else
                e.dashCooldown = e.dashCooldown - dt
                if e.dashCooldown <= 0 then
                    e.telegraphTimer = 0.5
                    e.targetX = player.x
                    e.targetY = player.y
                else
                    local dx, dy = player.x - e.x, player.y - e.y
                    dx, dy = normalize(dx, dy)
                    e.vx = dx * 12
                    e.vy = dy * 12
                end
            end
        end

        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt

        -- Multi-layer organic wobble
        local totalWobble = 0
        for _, w in ipairs(e.wobbles) do
            w.phase = w.phase + w.speed * dt
            totalWobble = totalWobble + math.sin(w.phase) * w.amount
        end
        e.radiusWobble = totalWobble

        -- Update membrane phase
        e.membranePhase = e.membranePhase + e.membraneSpeed * dt

        -- Check collision with player (only matching color damages)
        local dist = distance(e.x, e.y, player.x, player.y)
        if dist < PLAYER_RADIUS + e.baseRadius and e.color == player.color then
            damagePlayer(ENEMY_CONTACT_DAMAGE)
        end
    end
end

-- ============================================================================
-- XP SHARDS
-- ============================================================================

local function spawnShard(x, y)
    table.insert(shards, {
        x = x, y = y,
        vx = (math.random() - 0.5) * 40,
        vy = (math.random() - 0.5) * 40,
        seed = math.random(1000)
    })
end

local function updateShards(dt)
    for i = #shards, 1, -1 do
        local s = shards[i]

        s.vx = s.vx * 0.95
        s.vy = s.vy * 0.95

        local dist = distance(s.x, s.y, player.x, player.y)
        if dist < XP_MAGNET_RANGE then
            local dx, dy = player.x - s.x, player.y - s.y
            dx, dy = normalize(dx, dy)
            local pull = (1 - dist / XP_MAGNET_RANGE) * XP_MAGNET_SPEED
            s.vx = s.vx + dx * pull * dt * 10
            s.vy = s.vy + dy * pull * dt * 10
        end

        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt

        if dist < PLAYER_RADIUS + XP_SHARD_RADIUS then
            player.xp = player.xp + XP_PER_SHARD
            table.remove(shards, i)

            if player.xp >= player.xpToLevel then
                player.xp = player.xp - player.xpToLevel
                player.level = player.level + 1
                player.xpToLevel = math.floor(player.xpToLevel * 1.5)
                triggerLevelUp()
            end
        end
    end
end

local function drawShards(time)
    for _, s in ipairs(shards) do
        local shimmer = 0.8 + math.sin(time * 5 + s.seed) * 0.2
        love.graphics.setColor(shimmer, shimmer, shimmer * 0.9, 1)
        love.graphics.circle("fill", s.x, s.y, XP_SHARD_RADIUS)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", s.x - 1, s.y - 1, XP_SHARD_RADIUS * 0.5)
    end
end

-- ============================================================================
-- LEVEL UP SYSTEM
-- ============================================================================

local UPGRADE_DEFS = {
    {id = "fireRate", name = "Rapid Fire", desc = "+25% fire rate"},
    {id = "moveSpeed", name = "Swift Feet", desc = "+20% move speed"},
    {id = "damage", name = "Power Shot", desc = "+30% damage"},
    {id = "projectileCount", name = "Multi Shot", desc = "+1 projectile"},
    {id = "cooldownReduction", name = "Quick Change", desc = "-15% color cooldown"},
    {id = "maxHp", name = "Vitality", desc = "+25 max HP (heals)"}
}

function triggerLevelUp()
    gameState = "levelup"
    levelUpChoices = {}

    local available = {}
    for i, u in ipairs(UPGRADE_DEFS) do
        table.insert(available, i)
    end

    for i = 1, 3 do
        local idx = math.random(#available)
        table.insert(levelUpChoices, UPGRADE_DEFS[available[idx]])
        table.remove(available, idx)
    end
end

local function applyUpgrade(choice)
    local id = choice.id
    if id == "fireRate" then
        upgrades.fireRate = upgrades.fireRate + 0.25
    elseif id == "moveSpeed" then
        upgrades.moveSpeed = upgrades.moveSpeed + 0.2
    elseif id == "damage" then
        upgrades.damage = upgrades.damage + 0.3
    elseif id == "projectileCount" then
        upgrades.projectileCount = upgrades.projectileCount + 1
    elseif id == "cooldownReduction" then
        upgrades.cooldownReduction = upgrades.cooldownReduction + 1
    elseif id == "maxHp" then
        upgrades.maxHp = upgrades.maxHp + 25
        player.maxHp = PLAYER_MAX_HP + upgrades.maxHp
        player.hp = player.maxHp
    end

    gameState = "play"
end

-- ============================================================================
-- COLLISION SYSTEM
-- ============================================================================

local function checkCollisions()
    for i = #projectiles, 1, -1 do
        local p = projectiles[i]
        if p.dying then goto continue end  -- Skip dying bullets

        for j = #enemies, 1, -1 do
            local e = enemies[j]
            local dist = distance(p.x, p.y, e.x, e.y)
            local bulletRadius = p.baseRadius + (p.radiusWobble or 0)
            local enemyRadius = e.baseRadius + (e.radiusWobble or 0)

            if dist < bulletRadius + enemyRadius then
                if p.color == e.color then
                    -- MATCHING COLOR: Pierce + Damage
                    local dmg = PROJECTILE_DAMAGE * upgrades.damage
                    e.hp = e.hp - dmg

                    -- Bullet slows slightly (for feel)
                    p.vx = p.vx * 0.95
                    p.vy = p.vy * 0.95

                    -- Enemy flinch effect
                    e.radiusOffset = -3
                    e.radiusRecovery = 0.1

                    -- Spawn splatter particles
                    spawnSplatterParticles(p.x, p.y, e.color, 4)

                    if e.hp <= 0 then
                        spawnDeathParticles(e.x, e.y, e.color, 8)
                        spawnShard(e.x, e.y)
                        shakeScreen(1, 0.1)
                        table.remove(enemies, j)
                    end

                    -- Bullet continues (pierces)
                else
                    -- WRONG COLOR: Absorbed
                    p.dying = true
                    p.deathTimer = 0.1

                    -- Enemy pulse (swells like it ate something)
                    e.pulseTimer = 0.15
                    e.pulseAmount = 2

                    spawnFizzleParticle(p.x, p.y, p.color)
                    break  -- Bullet is dying, stop checking
                end
            end
        end
        ::continue::
    end
end

-- ============================================================================
-- PARTICLES UPDATE
-- ============================================================================

local function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 80 * dt

        -- Organic wobble
        p.wobblePhase = p.wobblePhase + p.wobbleSpeed * dt
        p.radiusWobble = math.sin(p.wobblePhase) * p.wobbleAmount

        -- Tumbling rotation
        p.tumbleAngle = p.tumbleAngle + p.tumbleSpeed * dt

        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

-- ============================================================================
-- SPAWNING SYSTEM
-- ============================================================================

local function updateSpawning(dt)
    waveTime = waveTime + dt
    spawnTimer = spawnTimer - dt

    local spawnRate = baseSpawnRate - math.min(waveTime / 120, 1) * 0.8

    if spawnTimer <= 0 then
        spawnTimer = spawnRate

        local enemyType = "drifter"
        if math.random() < 0.3 then
            enemyType = "dasher"
        end

        spawnEnemy(enemyType)

        local extraEnemies = math.floor(waveTime / 45)
        for i = 1, extraEnemies do
            if math.random() < 0.5 then
                spawnEnemy("drifter")
            end
        end
    end
end

-- ============================================================================
-- DRAWING FUNCTIONS
-- ============================================================================

local function drawBlobs()
    -- Group entities by color
    local entitiesByColor = {
        red = {enemies = {}, projectiles = {}, particles = {}},
        cyan = {enemies = {}, projectiles = {}, particles = {}},
        yellow = {enemies = {}, projectiles = {}, particles = {}}
    }

    -- Sort enemies by color
    for _, e in ipairs(enemies) do
        if entitiesByColor[e.color] then
            table.insert(entitiesByColor[e.color].enemies, e)
        end
    end

    -- Sort projectiles by color
    for _, p in ipairs(projectiles) do
        if entitiesByColor[p.color] then
            table.insert(entitiesByColor[p.color].projectiles, p)
        end
    end

    -- Sort particles by color
    for _, p in ipairs(particles) do
        if entitiesByColor[p.color] then
            table.insert(entitiesByColor[p.color].particles, p)
        end
    end

    -- Render each color's blobs
    for colorName, entities in pairs(entitiesByColor) do
        local allEntities = {}

        -- Add enemies (with organic membrane data)
        for _, e in ipairs(entities.enemies) do
            table.insert(allEntities, {
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

        -- Add projectiles
        for _, p in ipairs(entities.projectiles) do
            table.insert(allEntities, {
                x = p.x,
                y = p.y,
                vx = p.vx,
                vy = p.vy,
                baseRadius = p.baseRadius,
                radiusWobble = p.radiusWobble,
                isProjectile = true
            })
        end

        -- Add particles (with organic tumble)
        for _, p in ipairs(entities.particles) do
            local alpha = p.life / p.maxLife
            local radius = p.radius + (p.radiusWobble or 0)
            if p.shrink then
                radius = radius * alpha
            end
            -- Particles get slight stretch based on velocity + tumble
            local speed = math.sqrt(p.vx * p.vx + p.vy * p.vy)
            local stretch = 1 + math.min(speed / 150, 0.4)
            table.insert(allEntities, {
                x = p.x,
                y = p.y,
                baseRadius = radius,
                radiusWobble = 0,
                intensity = BLOB_INTENSITY * alpha,
                useCustomDeform = true,
                customStretchX = stretch,
                customStretchY = 1 / stretch,
                customAngle = p.tumbleAngle or math.atan2(p.vy, p.vx),
                isProjectile = true  -- small, no sub-blobs
            })
        end

        if #allEntities > 0 then
            renderColorBlobs(colorName, allEntities,
                function(e) return e.baseRadius end,
                function(e) return e.intensity or BLOB_INTENSITY end
            )
        end
    end

    -- Render player separately (on top) with full organic deformation
    if player.invincible <= 0 or math.floor(player.invincible * 10) % 2 ~= 0 then
        -- Internal pulse adds subtle size variation
        local pulseSize = math.sin(player.pulsePhase) * 0.8

        -- Combine all organic effects
        local organicRadius = player.baseRadius + player.radiusWobble + pulseSize

        -- Asymmetric stretch (blob is never perfectly round)
        local asymStretchX = 1 + player.asymX
        local asymStretchY = 1 + player.asymY

        -- Combine with velocity-based deformation
        local finalStretchX = player.stretchAmount * (1 + player.deformOffset) * asymStretchX
        local finalStretchY = player.squishAmount * (1 - player.deformOffset * 0.5) * asymStretchY

        -- Apply Brownian jitter to position
        local jitterPosX = player.x + player.jitterX
        local jitterPosY = player.y + player.jitterY

        -- Intensity with organic flicker
        local organicIntensity = BLOB_INTENSITY + player.intensityNoise

        local playerEntities = {{
            x = jitterPosX,
            y = jitterPosY,
            baseRadius = organicRadius,
            radiusWobble = 0,  -- already included in organicRadius
            useCustomDeform = true,
            customStretchX = finalStretchX,
            customStretchY = finalStretchY,
            customAngle = player.stretchAngle,
            -- Pass membrane data for advanced rendering
            membranePhase = player.membranePhase,
            membraneAmp = player.membraneAmp,
            intensity = organicIntensity
        }}
        renderColorBlobs(player.color, playerEntities,
            function(e) return e.baseRadius end,
            function(e) return e.intensity or BLOB_INTENSITY end
        )
    end
end

local function drawTelegraphLines()
    -- Draw dasher telegraph lines as pixelated dashed lines
    local prevStyle = love.graphics.getLineStyle()
    love.graphics.setLineStyle("rough")
    for _, e in ipairs(enemies) do
        if e.type == "dasher" and e.telegraphTimer > 0 then
            local alpha = 0.5 * (e.telegraphTimer / 0.5)
            local c = COLORS[e.color]
            love.graphics.setColor(c[1], c[2], c[3], alpha)
            love.graphics.setLineWidth(2)
            -- Draw dashed line pixel by pixel (capped to actual dash distance)
            local dx, dy = e.targetX - e.x, e.targetY - e.y
            local fullLen = math.sqrt(dx * dx + dy * dy)
            if fullLen < 1 then goto continueTelegraph end
            local dashDist = 200 * 0.3  -- dash speed * dash duration
            local len = math.min(fullLen, dashDist)
            local dashLen = 4
            local gapLen = 3
            local stepX, stepY = dx / fullLen, dy / fullLen
            local traveled = 0
            while traveled < len do
                local segEnd = math.min(traveled + dashLen, len)
                love.graphics.line(
                    e.x + stepX * traveled, e.y + stepY * traveled,
                    e.x + stepX * segEnd, e.y + stepY * segEnd
                )
                traveled = segEnd + gapLen
            end
            ::continueTelegraph::
        end
    end
    love.graphics.setLineStyle(prevStyle)
end

local function drawCooldownIndicator()
    if player.colorCooldown > 0 then
        local maxCooldown = COLOR_SWITCH_COOLDOWN * (1 - upgrades.cooldownReduction * 0.15)
        local progress = 1 - (player.colorCooldown / maxCooldown)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.arc("line", "open", player.x, player.y, PLAYER_RADIUS + 3,
            -math.pi/2, -math.pi/2 + progress * math.pi * 2)
    end
end

-- ============================================================================
-- UI DRAWING
-- ============================================================================

local function drawUI()
    love.graphics.setFont(font)

    -- HP bar - sharp pixel rectangles, 1px border
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", 18, 18, 204, 24)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", 20, 20, 200, 20)

    local hpRatio = player.hp / player.maxHp
    local c = COLORS[player.color]
    love.graphics.setColor(c[1], c[2], c[3], 1)
    love.graphics.rectangle("fill", 20, 20, 200 * hpRatio, 20)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP " .. player.hp .. "/" .. player.maxHp, 25, 19)

    -- XP bar
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", 18, 44, 204, 14)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", 20, 46, 200, 10)

    love.graphics.setColor(0.8, 0.8, 0.4, 1)
    love.graphics.rectangle("fill", 20, 46, 200 * (player.xp / player.xpToLevel), 10)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("LVL " .. player.level, 25, 57)

    -- Color indicator - sharp box
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 102, 18, 84, 34)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 100, 20, 80, 30)

    love.graphics.setColor(c[1], c[2], c[3], 1)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 95, 25, 20, 20)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Q/E", WINDOW_WIDTH - 70, 24)

    -- Tutorial text
    if waveTime < 10 then
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0, 0, 0, 0.7 * (1 - waveTime / 10))
        love.graphics.printf("WASD Move | Mouse Aim | LMB Shoot | Q/E Switch Color", 0, WINDOW_HEIGHT - 26, WINDOW_WIDTH, "center")
        love.graphics.setFont(font)
    end
end

local function drawLevelUpScreen()
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("LEVEL UP!", 0, 80, WINDOW_WIDTH, "center")

    love.graphics.setFont(font)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Choose an upgrade:", 0, 135, WINDOW_WIDTH, "center")

    local buttonX = WINDOW_WIDTH / 2 - 150
    for i, choice in ipairs(levelUpChoices) do
        local y = 180 + (i - 1) * 80
        local mx, my = love.mouse.getPosition()
        local hover = mx > buttonX and mx < buttonX + 300 and my > y and my < y + 60

        -- Black border, white fill
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", buttonX - 2, y - 2, 304, 64)

        if hover then
            love.graphics.setColor(0.85, 0.85, 0.85, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.rectangle("fill", buttonX, y, 300, 60)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(i .. ". " .. choice.name, buttonX, y + 8, 300, "center")
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.printf(choice.desc, buttonX, y + 34, 300, "center")
        love.graphics.setFont(font)
    end
end

local function drawDeathScreen()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.printf("GAME OVER", 0, 180, WINDOW_WIDTH, "center")

    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Level " .. player.level, 0, 260, WINDOW_WIDTH, "center")
    love.graphics.printf("Survived " .. math.floor(waveTime) .. "s", 0, 290, WINDOW_WIDTH, "center")

    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Press R to Restart", 0, 370, WINDOW_WIDTH, "center")
end

-- ============================================================================
-- GAME RESET
-- ============================================================================

local function resetGame()
    enemies = {}
    projectiles = {}
    shards = {}
    particles = {}
    waveTime = 0
    spawnTimer = 0
    gameTime = 0

    upgrades = {
        fireRate = 1,
        moveSpeed = 1,
        damage = 1,
        projectileCount = 1,
        cooldownReduction = 0,
        maxHp = 0
    }

    initPlayer()
    gameState = "play"
end

-- ============================================================================
-- LOVE CALLBACKS
-- ============================================================================

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setBackgroundColor(BACKGROUND)
    math.randomseed(os.time())

    -- Create game canvas
    gameCanvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)

    -- Create color buffers (one per color)
    for colorName, _ in pairs(COLORS) do
        colorBuffers[colorName] = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)
    end

    -- Load threshold shader
    thresholdShader = love.graphics.newShader("threshold.glsl")

    -- Create soft circle texture
    softCircleImage = createSoftCircleImage()

    -- Load pixel font
    fontSmall = love.graphics.newFont("m5x7.ttf", 16)
    fontSmall:setFilter("nearest", "nearest")
    font = love.graphics.newFont("m5x7.ttf", 24)
    font:setFilter("nearest", "nearest")
    fontLarge = love.graphics.newFont("m5x7.ttf", 48)
    fontLarge:setFilter("nearest", "nearest")
    love.graphics.setFont(font)

    initPlayer()
end

function love.update(dt)
    dt = math.min(dt, 1/30)
    gameTime = gameTime + dt

    if screenShake.duration > 0 then
        screenShake.duration = screenShake.duration - dt
        if screenShake.duration <= 0 then
            screenShake.amount = 0
        end
    end

    if gameState == "play" then
        updatePlayer(dt)
        updateProjectiles(dt)
        updateEnemies(dt)
        updateShards(dt)
        updateParticles(dt)
        checkCollisions()
        updateSpawning(dt)
    elseif gameState == "levelup" then
        updateParticles(dt)
    end
end

function love.draw()
    local time = love.timer.getTime()

    -- Draw to game canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(BACKGROUND)

    love.graphics.push()
    if screenShake.amount > 0 then
        local dx = (math.random() - 0.5) * screenShake.amount * 2
        local dy = (math.random() - 0.5) * screenShake.amount * 2
        love.graphics.translate(dx, dy)
    end

    -- Draw XP shards (not part of blob system)
    drawShards(time)

    -- Draw telegraph lines
    drawTelegraphLines()

    -- Draw all blobs (enemies, projectiles, particles, player)
    drawBlobs()

    -- Draw cooldown indicator on player
    drawCooldownIndicator()

    love.graphics.pop()

    love.graphics.setCanvas()

    -- Draw scaled to window (centered)
    love.graphics.setColor(1, 1, 1, 1)
    local scale = math.min(
        love.graphics.getWidth() / GAME_WIDTH,
        love.graphics.getHeight() / GAME_HEIGHT
    )
    love.graphics.draw(gameCanvas,
        love.graphics.getWidth()/2,
        love.graphics.getHeight()/2,
        0, scale, scale,
        GAME_WIDTH/2, GAME_HEIGHT/2
    )

    drawUI()

    if gameState == "levelup" then
        drawLevelUpScreen()
    elseif gameState == "dead" then
        drawDeathScreen()
    end
end

function love.keypressed(key)
    if gameState == "play" then
        if key == "q" then
            switchColor(-1)
        elseif key == "e" then
            switchColor(1)
        elseif key == "1" then
            setColorDirect(1)
        elseif key == "2" then
            setColorDirect(2)
        elseif key == "3" then
            setColorDirect(3)
        elseif key == "escape" then
            love.event.quit()
        end
    elseif gameState == "levelup" then
        if key == "1" and levelUpChoices[1] then
            applyUpgrade(levelUpChoices[1])
        elseif key == "2" and levelUpChoices[2] then
            applyUpgrade(levelUpChoices[2])
        elseif key == "3" and levelUpChoices[3] then
            applyUpgrade(levelUpChoices[3])
        end
    elseif gameState == "dead" then
        if key == "r" then
            resetGame()
        elseif key == "escape" then
            love.event.quit()
        end
    end
end

function love.mousepressed(x, y, button)
    if gameState == "levelup" and button == 1 then
        local buttonX = WINDOW_WIDTH / 2 - 150
        for i, choice in ipairs(levelUpChoices) do
            local cy = 180 + (i - 1) * 80
            if x > buttonX and x < buttonX + 300 and y > cy and y < cy + 60 then
                applyUpgrade(choice)
                break
            end
        end
    end
end

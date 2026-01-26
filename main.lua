--[[
    Color Survivor
    A Vampire Survivors-style bullet hell with color-switching mechanics
]]

-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================

COLORS = {
    magenta = {1, 0.2, 0.6},
    cyan = {0.2, 0.9, 1},
    yellow = {1, 0.95, 0.2}
}
COLOR_ORDER = {"magenta", "cyan", "yellow"}
BACKGROUND = {0.98, 0.96, 0.92}

-- Player settings
PLAYER_RADIUS = 20
PLAYER_MAX_SPEED = 200
PLAYER_ACCEL = 1200
PLAYER_DECEL = 800
PLAYER_MAX_HP = 100
COLOR_SWITCH_COOLDOWN = 1.0

-- Projectile settings
PROJECTILE_SPEED = 400
PROJECTILE_RADIUS = 8
FIRE_RATE = 4  -- shots per second
PROJECTILE_DAMAGE = 25

-- Enemy settings
ENEMY_CONTACT_DAMAGE = 15
SPAWN_MARGIN = 50

-- XP settings
XP_MAGNET_RANGE = 80
XP_MAGNET_SPEED = 300
XP_PER_SHARD = 10
XP_SHARD_RADIUS = 6

-- ============================================================================
-- GAME STATE
-- ============================================================================

local gameState = "play"  -- play, paused, dead, levelup
local screenShake = {amount = 0, duration = 0}

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
local baseSpawnRate = 1.5  -- seconds between spawns

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

local function randomColor()
    return COLOR_ORDER[math.random(1, 3)]
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

-- ============================================================================
-- PAINT BLOB RENDERING
-- ============================================================================

local function generateBlobVertices(radius, segments, noiseAmount, seed)
    local vertices = {}
    math.randomseed(seed)
    for i = 1, segments do
        local angle = (i - 1) / segments * math.pi * 2
        local noise = 1 + (math.random() - 0.5) * noiseAmount
        local r = radius * noise
        table.insert(vertices, math.cos(angle) * r)
        table.insert(vertices, math.sin(angle) * r)
    end
    return vertices
end

local function drawPaintBlob(x, y, radius, color, time, seed)
    local c = COLORS[color] or color

    -- Pulsing animation
    local pulse = 1 + math.sin(time * 3 + seed) * 0.05
    local wobble = time * 0.5 + seed

    -- Glow layer (larger, transparent)
    love.graphics.setColor(c[1], c[2], c[3], 0.3)
    local glowVerts = generateBlobVertices(radius * 1.3 * pulse, 12, 0.3, seed + 1)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(wobble * 0.2)
    love.graphics.polygon("fill", glowVerts)
    love.graphics.pop()

    -- Main blob layer
    love.graphics.setColor(c[1], c[2], c[3], 1)
    local mainVerts = generateBlobVertices(radius * pulse, 10, 0.25, seed)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(-wobble * 0.15)
    love.graphics.polygon("fill", mainVerts)
    love.graphics.pop()

    -- Highlight blob (smaller, lighter)
    love.graphics.setColor(c[1] * 1.2, c[2] * 1.2, c[3] * 1.2, 0.5)
    local highlightVerts = generateBlobVertices(radius * 0.5 * pulse, 8, 0.2, seed + 2)
    love.graphics.push()
    love.graphics.translate(x - radius * 0.2, y - radius * 0.2)
    love.graphics.rotate(wobble * 0.1)
    love.graphics.polygon("fill", highlightVerts)
    love.graphics.pop()
end

local function drawSmallBlob(x, y, radius, color, time, seed)
    local c = COLORS[color] or color
    local pulse = 1 + math.sin(time * 4 + seed) * 0.08

    love.graphics.setColor(c[1], c[2], c[3], 0.4)
    love.graphics.circle("fill", x, y, radius * 1.2 * pulse)

    love.graphics.setColor(c[1], c[2], c[3], 1)
    local verts = generateBlobVertices(radius * pulse, 8, 0.2, seed)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.polygon("fill", verts)
    love.graphics.pop()
end

-- ============================================================================
-- PARTICLE SYSTEM
-- ============================================================================

local function spawnParticle(x, y, color, particleType)
    local p = {
        x = x,
        y = y,
        vx = (math.random() - 0.5) * 200,
        vy = (math.random() - 0.5) * 200,
        color = color,
        life = 0.5,
        maxLife = 0.5,
        radius = math.random(3, 8),
        type = particleType or "splatter",
        seed = math.random(1000)
    }
    table.insert(particles, p)
end

local function spawnDeathParticles(x, y, color, count)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 150)
        local p = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = color,
            life = 0.8,
            maxLife = 0.8,
            radius = math.random(4, 12),
            type = "splatter",
            seed = math.random(1000)
        }
        table.insert(particles, p)
    end
end

local function spawnFizzleParticle(x, y, color)
    local p = {
        x = x,
        y = y,
        vx = (math.random() - 0.5) * 100,
        vy = (math.random() - 0.5) * 100 - 50,
        color = color,
        life = 0.3,
        maxLife = 0.3,
        radius = 4,
        type = "fizzle",
        seed = math.random(1000)
    }
    table.insert(particles, p)
end

-- ============================================================================
-- PLAYER
-- ============================================================================

local function initPlayer()
    player = {
        x = 400,
        y = 300,
        vx = 0,
        vy = 0,
        color = "magenta",
        colorCooldown = 0,
        hp = PLAYER_MAX_HP + upgrades.maxHp,
        maxHp = PLAYER_MAX_HP + upgrades.maxHp,
        fireTimer = 0,
        xp = 0,
        level = 1,
        xpToLevel = 100,
        invincible = 0,
        seed = math.random(1000)
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
    -- Input
    local ix, iy = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then iy = -1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then iy = 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then ix = -1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then ix = 1 end

    -- Normalize diagonal movement
    if ix ~= 0 and iy ~= 0 then
        ix, iy = ix * 0.707, iy * 0.707
    end

    -- Apply acceleration/deceleration
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

    -- Clamp speed
    local speed = math.sqrt(player.vx * player.vx + player.vy * player.vy)
    if speed > maxSpeed then
        player.vx = player.vx / speed * maxSpeed
        player.vy = player.vy / speed * maxSpeed
    end

    -- Apply velocity
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Keep in bounds
    player.x = math.max(PLAYER_RADIUS, math.min(800 - PLAYER_RADIUS, player.x))
    player.y = math.max(PLAYER_RADIUS, math.min(600 - PLAYER_RADIUS, player.y))

    -- Color cooldown
    if player.colorCooldown > 0 then
        player.colorCooldown = player.colorCooldown - dt
    end

    -- Invincibility frames
    if player.invincible > 0 then
        player.invincible = player.invincible - dt
    end

    -- Firing
    player.fireTimer = player.fireTimer - dt
    if love.mouse.isDown(1) and player.fireTimer <= 0 then
        fireProjectile()
        player.fireTimer = 1 / (FIRE_RATE * upgrades.fireRate)
    end
end

local function drawPlayer(time)
    -- Flash when invincible
    if player.invincible > 0 and math.floor(player.invincible * 10) % 2 == 0 then
        return
    end

    drawPaintBlob(player.x, player.y, PLAYER_RADIUS, player.color, time, player.seed)

    -- Cooldown indicator ring
    if player.colorCooldown > 0 then
        local maxCooldown = COLOR_SWITCH_COOLDOWN * (1 - upgrades.cooldownReduction * 0.15)
        local progress = 1 - (player.colorCooldown / maxCooldown)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(3)
        love.graphics.arc("line", "open", player.x, player.y, PLAYER_RADIUS + 8,
            -math.pi/2, -math.pi/2 + progress * math.pi * 2)
    end
end

local function damagePlayer(amount)
    if player.invincible > 0 then return end

    player.hp = player.hp - amount
    player.invincible = 0.5
    shakeScreen(5, 0.15)

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
    local mx, my = love.mouse.getPosition()
    local dx, dy = mx - player.x, my - player.y
    dx, dy = normalize(dx, dy)

    local count = upgrades.projectileCount
    local spreadAngle = 0.15  -- radians between projectiles

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

        table.insert(projectiles, p)
    end
end

local function updateProjectiles(dt)
    for i = #projectiles, 1, -1 do
        local p = projectiles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        -- Remove if off screen
        if p.x < -50 or p.x > 850 or p.y < -50 or p.y > 650 then
            p.active = false
            table.remove(projectiles, i)
        end
    end
end

local function drawProjectiles(time)
    for _, p in ipairs(projectiles) do
        drawSmallBlob(p.x, p.y, PROJECTILE_RADIUS, p.color, time, p.seed)
    end
end

-- ============================================================================
-- ENEMIES
-- ============================================================================

local function spawnEnemy(enemyType)
    -- Spawn from screen edge
    local side = math.random(1, 4)
    local x, y
    if side == 1 then  -- Top
        x, y = math.random(0, 800), -SPAWN_MARGIN
    elseif side == 2 then  -- Right
        x, y = 800 + SPAWN_MARGIN, math.random(0, 600)
    elseif side == 3 then  -- Bottom
        x, y = math.random(0, 800), 600 + SPAWN_MARGIN
    else  -- Left
        x, y = -SPAWN_MARGIN, math.random(0, 600)
    end

    -- Balance color distribution
    local colorCounts = {magenta = 0, cyan = 0, yellow = 0}
    for _, e in ipairs(enemies) do
        colorCounts[e.color] = colorCounts[e.color] + 1
    end

    -- Pick least common color with some randomness
    local minCount = math.min(colorCounts.magenta, colorCounts.cyan, colorCounts.yellow)
    local candidates = {}
    for _, c in ipairs(COLOR_ORDER) do
        if colorCounts[c] <= minCount + 2 then
            table.insert(candidates, c)
        end
    end
    local color = candidates[math.random(#candidates)]

    local enemy = {
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        color = color,
        type = enemyType or "drifter",
        hp = 25,
        seed = math.random(1000),
        flashTimer = 0,
        -- Dasher specific
        dashCooldown = math.random() * 2 + 1,
        dashing = false,
        dashTimer = 0,
        telegraphTimer = 0,
        targetX = 0,
        targetY = 0
    }

    if enemyType == "dasher" then
        enemy.hp = 40
    end

    table.insert(enemies, enemy)
end

local function updateEnemies(dt)
    for i = #enemies, 1, -1 do
        local e = enemies[i]

        -- Flash timer
        if e.flashTimer > 0 then
            e.flashTimer = e.flashTimer - dt
        end

        if e.type == "drifter" then
            -- Simple drift toward player
            local dx, dy = player.x - e.x, player.y - e.y
            dx, dy = normalize(dx, dy)
            local speed = 60
            e.vx = dx * speed
            e.vy = dy * speed

        elseif e.type == "dasher" then
            if e.dashing then
                -- Currently dashing
                e.dashTimer = e.dashTimer - dt
                if e.dashTimer <= 0 then
                    e.dashing = false
                    e.dashCooldown = 2
                    e.vx, e.vy = 0, 0
                end
            elseif e.telegraphTimer > 0 then
                -- Telegraphing
                e.telegraphTimer = e.telegraphTimer - dt
                e.vx, e.vy = 0, 0
                if e.telegraphTimer <= 0 then
                    -- Start dash
                    e.dashing = true
                    e.dashTimer = 0.3
                    local dx, dy = e.targetX - e.x, e.targetY - e.y
                    dx, dy = normalize(dx, dy)
                    e.vx = dx * 500
                    e.vy = dy * 500
                end
            else
                e.dashCooldown = e.dashCooldown - dt
                if e.dashCooldown <= 0 then
                    -- Start telegraph
                    e.telegraphTimer = 0.5
                    e.targetX = player.x
                    e.targetY = player.y
                else
                    -- Slow drift
                    local dx, dy = player.x - e.x, player.y - e.y
                    dx, dy = normalize(dx, dy)
                    e.vx = dx * 30
                    e.vy = dy * 30
                end
            end
        end

        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt

        -- Contact damage
        local dist = distance(e.x, e.y, player.x, player.y)
        if dist < PLAYER_RADIUS + 15 and e.color == player.color then
            damagePlayer(ENEMY_CONTACT_DAMAGE)
        end
    end
end

local function drawEnemies(time)
    for _, e in ipairs(enemies) do
        local radius = 15
        if e.type == "dasher" then radius = 20 end

        -- Telegraph indicator for dashers
        if e.type == "dasher" and e.telegraphTimer > 0 then
            love.graphics.setColor(COLORS[e.color][1], COLORS[e.color][2], COLORS[e.color][3], 0.3)
            love.graphics.setLineWidth(2)
            love.graphics.line(e.x, e.y, e.targetX, e.targetY)
        end

        -- Flash white when hit
        if e.flashTimer > 0 then
            drawPaintBlob(e.x, e.y, radius, {1, 1, 1}, time, e.seed)
        else
            drawPaintBlob(e.x, e.y, radius, e.color, time, e.seed)
        end
    end
end

-- ============================================================================
-- XP SHARDS
-- ============================================================================

local function spawnShard(x, y)
    table.insert(shards, {
        x = x,
        y = y,
        vx = (math.random() - 0.5) * 100,
        vy = (math.random() - 0.5) * 100,
        seed = math.random(1000)
    })
end

local function updateShards(dt)
    for i = #shards, 1, -1 do
        local s = shards[i]

        -- Friction
        s.vx = s.vx * 0.95
        s.vy = s.vy * 0.95

        -- Magnetic pull to player
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

        -- Collect
        if dist < PLAYER_RADIUS + XP_SHARD_RADIUS then
            player.xp = player.xp + XP_PER_SHARD
            table.remove(shards, i)

            -- Level up check
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
        -- White/neutral color with shimmer
        local shimmer = 0.8 + math.sin(time * 5 + s.seed) * 0.2
        love.graphics.setColor(shimmer, shimmer, shimmer * 0.9, 1)
        love.graphics.circle("fill", s.x, s.y, XP_SHARD_RADIUS)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", s.x - 2, s.y - 2, XP_SHARD_RADIUS * 0.5)
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

    -- Pick 3 random upgrades
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
        player.hp = player.maxHp  -- Full heal
    end

    gameState = "play"
end

-- ============================================================================
-- COLLISION SYSTEM
-- ============================================================================

local function checkCollisions()
    -- Projectiles vs Enemies
    for i = #projectiles, 1, -1 do
        local p = projectiles[i]
        for j = #enemies, 1, -1 do
            local e = enemies[j]
            local dist = distance(p.x, p.y, e.x, e.y)
            local enemyRadius = e.type == "dasher" and 20 or 15

            if dist < PROJECTILE_RADIUS + enemyRadius then
                if p.color == e.color then
                    -- Matching color - deal damage
                    local dmg = PROJECTILE_DAMAGE * upgrades.damage
                    e.hp = e.hp - dmg
                    e.flashTimer = 0.1
                    spawnParticle(p.x, p.y, p.color, "hit")

                    if e.hp <= 0 then
                        spawnDeathParticles(e.x, e.y, e.color, 8)
                        spawnShard(e.x, e.y)
                        shakeScreen(3, 0.1)
                        table.remove(enemies, j)
                    end

                    p.active = false
                    table.remove(projectiles, i)
                    break
                else
                    -- Non-matching - fizzle effect
                    spawnFizzleParticle(p.x, p.y, p.color)
                end
            end
        end
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
        p.vy = p.vy + 200 * dt  -- Gravity

        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

local function drawParticles(time)
    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        local c = COLORS[p.color] or p.color
        love.graphics.setColor(c[1], c[2], c[3], alpha)
        love.graphics.circle("fill", p.x, p.y, p.radius * alpha)
    end
end

-- ============================================================================
-- SPAWNING SYSTEM
-- ============================================================================

local function updateSpawning(dt)
    waveTime = waveTime + dt
    spawnTimer = spawnTimer - dt

    -- Gradually increase spawn rate
    local spawnRate = baseSpawnRate - math.min(waveTime / 120, 1) * 0.8  -- Gets faster over 2 mins

    if spawnTimer <= 0 then
        spawnTimer = spawnRate

        -- Spawn enemies
        local enemyType = "drifter"
        if waveTime > 30 and math.random() < 0.3 then
            enemyType = "dasher"
        end

        spawnEnemy(enemyType)

        -- Spawn extra enemies as time goes on
        local extraEnemies = math.floor(waveTime / 45)
        for i = 1, extraEnemies do
            if math.random() < 0.5 then
                spawnEnemy("drifter")
            end
        end
    end
end

-- ============================================================================
-- UI DRAWING
-- ============================================================================

local function drawUI()
    -- Health bar
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 20, 20, 200, 20, 5, 5)

    local hpRatio = player.hp / player.maxHp
    local c = COLORS[player.color]
    love.graphics.setColor(c[1], c[2], c[3], 1)
    love.graphics.rectangle("fill", 20, 20, 200 * hpRatio, 20, 5, 5)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP: " .. player.hp .. "/" .. player.maxHp, 25, 22)

    -- XP bar
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 20, 45, 200, 10, 3, 3)

    love.graphics.setColor(0.8, 0.8, 0.4, 1)
    love.graphics.rectangle("fill", 20, 45, 200 * (player.xp / player.xpToLevel), 10, 3, 3)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Level " .. player.level, 25, 58)

    -- Color indicator
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 700, 20, 80, 30, 5, 5)

    love.graphics.setColor(c[1], c[2], c[3], 1)
    love.graphics.circle("fill", 720, 35, 12)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Q/E", 738, 27)

    -- Controls hint (first 10 seconds)
    if waveTime < 10 then
        love.graphics.setColor(0, 0, 0, 0.7 * (1 - waveTime / 10))
        love.graphics.print("WASD - Move | Mouse - Aim | LMB - Shoot | Q/E or 1/2/3 - Switch Color", 200, 570)
    end
end

local function drawLevelUpScreen()
    -- Darken background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("LEVEL UP!", 0, 100, 800, "center")
    love.graphics.printf("Choose an upgrade:", 0, 130, 800, "center")

    for i, choice in ipairs(levelUpChoices) do
        local y = 180 + (i - 1) * 80
        local mx, my = love.mouse.getPosition()
        local hover = mx > 250 and mx < 550 and my > y and my < y + 60

        if hover then
            love.graphics.setColor(0.4, 0.4, 0.6, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.4, 1)
        end
        love.graphics.rectangle("fill", 250, y, 300, 60, 10, 10)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(i .. ". " .. choice.name, 250, y + 10, 300, "center")
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.printf(choice.desc, 250, y + 32, 300, "center")
    end
end

local function drawDeathScreen()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.printf("GAME OVER", 0, 200, 800, "center")

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("You reached Level " .. player.level, 0, 280, 800, "center")
    love.graphics.printf("Survived for " .. math.floor(waveTime) .. " seconds", 0, 310, 800, "center")

    love.graphics.printf("Press R to Restart", 0, 400, 800, "center")
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
    love.graphics.setBackgroundColor(BACKGROUND)
    math.randomseed(os.time())
    initPlayer()
end

function love.update(dt)
    -- Clamp dt to prevent physics issues
    dt = math.min(dt, 1/30)

    -- Screen shake
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

    -- Apply screen shake
    love.graphics.push()
    if screenShake.amount > 0 then
        local dx = (math.random() - 0.5) * screenShake.amount * 2
        local dy = (math.random() - 0.5) * screenShake.amount * 2
        love.graphics.translate(dx, dy)
    end

    -- Draw game entities
    drawShards(time)
    drawProjectiles(time)
    drawEnemies(time)
    drawPlayer(time)
    drawParticles(time)

    love.graphics.pop()

    -- UI (not affected by shake)
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
        for i, choice in ipairs(levelUpChoices) do
            local cy = 180 + (i - 1) * 80
            if x > 250 and x < 550 and y > cy and y < cy + 60 then
                applyUpgrade(choice)
                break
            end
        end
    end
end

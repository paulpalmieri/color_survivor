--[[
    Entities System
    Player, enemies, projectiles, shards
]]

local Config = require("src.config")
local Game = require("src.game")
local Utils = require("src.utils")
local Particles = require("src.particles")
local Sound = require("src.sound")

local Entities = {}

-- Forward declarations
local fireProjectile

-- ============================================================================
-- PLAYER
-- ============================================================================

function Entities.initPlayer()
    local seed = math.random(1000)
    Game.colorWheelAnim.currentAngle = 0
    Game.colorWheelAnim.targetAngle = 0
    Game.colorWheelAnim.wobbleTime = 0

    Game.player = {
        x = Config.ARENA_WIDTH / 2,
        y = Config.ARENA_HEIGHT / 2,
        vx = 0, vy = 0,
        prevVx = 0, prevVy = 0,
        color = "red",
        colorCooldown = 0,
        hp = Config.PLAYER_MAX_HP + Game.upgrades.maxHp,
        maxHp = Config.PLAYER_MAX_HP + Game.upgrades.maxHp,
        fireTimer = 0,
        xp = 0,
        level = 1,
        xpToLevel = 100,
        invincible = 0,
        seed = seed,
        baseRadius = Config.PLAYER_RADIUS,
        stretchAngle = 0,
        stretchAmount = 1,
        squishAmount = 1,
        deformVel = 0,
        deformOffset = 0,
        wobbles = {
            {phase = math.random() * math.pi * 2, speed = 2.3, amount = 7.2},
            {phase = math.random() * math.pi * 2, speed = 3.7, amount = 4.8},
            {phase = math.random() * math.pi * 2, speed = 5.1, amount = 3.0},
        },
        membranePhase = 0,
        membraneSpeed = 4 + math.random() * 2,
        membraneAmp = 0.8,
        asymX = (math.random() - 0.5) * 0.3,
        asymY = (math.random() - 0.5) * 0.3,
        asymDriftX = 0,
        asymDriftY = 0,
        jitterX = 0,
        jitterY = 0,
        jitterTargetX = 0,
        jitterTargetY = 0,
        pulsePhase = math.random() * math.pi * 2,
        pulseSpeed = 1.5 + math.random() * 0.5,
        intensityNoise = 0,
        dashCharges = Config.DASH_MAX_CHARGES,
        dashRechargeTimer = 0,
        dashing = false,
        dashTimer = 0,
        dashDirX = 0,
        dashDirY = 0,
    }
end

local function getColorWheelAngle(colorIndex)
    return -(colorIndex - 1) * (math.pi * 2 / 3)
end

function Entities.switchColor(direction)
    local player = Game.player
    if player.colorCooldown > 0 then return end

    local currentIndex = Utils.getColorIndex(player.color)
    local newIndex = currentIndex + direction
    if newIndex < 1 then newIndex = 3 end
    if newIndex > 3 then newIndex = 1 end

    Game.colorWheelAnim.targetAngle = getColorWheelAngle(newIndex)

    player.color = Config.COLOR_ORDER[newIndex]
    player.colorCooldown = Config.COLOR_SWITCH_COOLDOWN * (1 - Game.upgrades.cooldownReduction * 0.15)
end

function Entities.setColorDirect(index)
    local player = Game.player
    if player.colorCooldown > 0 then return end
    if player.color == Config.COLOR_ORDER[index] then return end

    Game.colorWheelAnim.targetAngle = getColorWheelAngle(index)

    player.color = Config.COLOR_ORDER[index]
    player.colorCooldown = Config.COLOR_SWITCH_COOLDOWN * (1 - Game.upgrades.cooldownReduction * 0.15)
end

function Entities.triggerDash()
    local player = Game.player
    if player.dashCharges <= 0 then return end
    if player.dashing then return end

    local dx, dy = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then dy = -1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dy = 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then dx = -1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx = 1 end

    if dx == 0 and dy == 0 then
        local speed = math.sqrt(player.vx * player.vx + player.vy * player.vy)
        if speed > 5 then
            dx, dy = player.vx / speed, player.vy / speed
        else
            local mx, my = love.mouse.getPosition()
            mx, my = Game.screenToWorld(mx, my)
            dx, dy = mx - player.x, my - player.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                dx, dy = dx / dist, dy / dist
            else
                dx, dy = 1, 0
            end
        end
    end

    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        dx, dy = dx / len, dy / len
    end

    player.dashCharges = player.dashCharges - 1
    if player.dashRechargeTimer <= 0 then
        player.dashRechargeTimer = Config.DASH_CHARGE_COOLDOWN
    end

    player.dashing = true
    player.dashTimer = Config.DASH_DURATION
    player.dashDirX = dx
    player.dashDirY = dy
    player.invincible = math.max(player.invincible, Config.DASH_IFRAME_DURATION)
    player.deformVel = player.deformVel + 20
    Particles.spawnSplatter(player.x, player.y, player.color, 3)
end

function Entities.updatePlayer(dt)
    local player = Game.player

    player.prevVx = player.vx
    player.prevVy = player.vy

    if player.dashCharges < Config.DASH_MAX_CHARGES then
        player.dashRechargeTimer = player.dashRechargeTimer - dt
        if player.dashRechargeTimer <= 0 then
            player.dashCharges = player.dashCharges + 1
            if player.dashCharges < Config.DASH_MAX_CHARGES then
                player.dashRechargeTimer = Config.DASH_CHARGE_COOLDOWN
            else
                player.dashRechargeTimer = 0
            end
        end
    end

    local ix, iy = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then iy = -1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then iy = 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then ix = -1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then ix = 1 end

    if ix ~= 0 and iy ~= 0 then
        ix, iy = ix * 0.707, iy * 0.707
    end

    if player.dashing then
        player.dashTimer = player.dashTimer - dt
        if player.dashTimer <= 0 then
            player.dashing = false
            player.vx = player.dashDirX * Config.DASH_SPEED * 0.3
            player.vy = player.dashDirY * Config.DASH_SPEED * 0.3
        else
            player.vx = player.dashDirX * Config.DASH_SPEED
            player.vy = player.dashDirY * Config.DASH_SPEED
            if math.random() < dt * 60 then
                Particles.spawnSplatter(player.x, player.y, player.color, 1)
            end
        end

        player.x = player.x + player.vx * dt
        player.y = player.y + player.vy * dt
        player.x = math.max(Config.PLAYER_RADIUS, math.min(Config.ARENA_WIDTH - Config.PLAYER_RADIUS, player.x))
        player.y = math.max(Config.PLAYER_RADIUS, math.min(Config.ARENA_HEIGHT - Config.PLAYER_RADIUS, player.y))
    else
        local maxSpeed = Config.PLAYER_MAX_SPEED * (1 + (Game.upgrades.moveSpeed - 1) * 0.2)

        if ix ~= 0 then
            player.vx = player.vx + ix * Config.PLAYER_ACCEL * dt
        else
            if player.vx > 0 then
                player.vx = math.max(0, player.vx - Config.PLAYER_DECEL * dt)
            else
                player.vx = math.min(0, player.vx + Config.PLAYER_DECEL * dt)
            end
        end

        if iy ~= 0 then
            player.vy = player.vy + iy * Config.PLAYER_ACCEL * dt
        else
            if player.vy > 0 then
                player.vy = math.max(0, player.vy - Config.PLAYER_DECEL * dt)
            else
                player.vy = math.min(0, player.vy + Config.PLAYER_DECEL * dt)
            end
        end

        local speed = math.sqrt(player.vx * player.vx + player.vy * player.vy)
        if speed > maxSpeed then
            player.vx = player.vx / speed * maxSpeed
            player.vy = player.vy / speed * maxSpeed
        end

        player.x = player.x + player.vx * dt
        player.y = player.y + player.vy * dt
        player.x = math.max(Config.PLAYER_RADIUS, math.min(Config.ARENA_WIDTH - Config.PLAYER_RADIUS, player.x))
        player.y = math.max(Config.PLAYER_RADIUS, math.min(Config.ARENA_HEIGHT - Config.PLAYER_RADIUS, player.y))
    end

    if player.colorCooldown > 0 then
        player.colorCooldown = player.colorCooldown - dt
    end

    if player.invincible > 0 then
        player.invincible = player.invincible - dt
    end

    player.fireTimer = player.fireTimer - dt
    if love.mouse.isDown(1) and player.fireTimer <= 0 then
        fireProjectile()
        player.fireTimer = 1 / (Config.FIRE_RATE * Game.upgrades.fireRate)
    end

    -- Organic animation
    local totalWobble = 0
    for _, w in ipairs(player.wobbles) do
        w.phase = w.phase + w.speed * dt
        totalWobble = totalWobble + math.sin(w.phase) * w.amount
    end
    player.radiusWobble = totalWobble

    player.membranePhase = player.membranePhase + player.membraneSpeed * dt

    player.asymDriftX = player.asymDriftX + (math.random() - 0.5) * dt * 2
    player.asymDriftY = player.asymDriftY + (math.random() - 0.5) * dt * 2
    player.asymDriftX = player.asymDriftX * 0.98
    player.asymDriftY = player.asymDriftY * 0.98
    player.asymX = math.sin(Game.gameTime * 0.7) * 0.15 + player.asymDriftX
    player.asymY = math.cos(Game.gameTime * 0.9) * 0.15 + player.asymDriftY

    if math.random() < dt * 8 then
        player.jitterTargetX = (math.random() - 0.5) * 0.8
        player.jitterTargetY = (math.random() - 0.5) * 0.8
    end
    player.jitterX = Utils.lerp(player.jitterX, player.jitterTargetX, dt * 12)
    player.jitterY = Utils.lerp(player.jitterY, player.jitterTargetY, dt * 12)

    player.pulsePhase = player.pulsePhase + player.pulseSpeed * dt
    player.intensityNoise = Utils.lerp(player.intensityNoise, (math.random() - 0.5) * 0.15, dt * 6)

    local currentSpeed = math.sqrt(player.vx * player.vx + player.vy * player.vy)
    local prevSpeed = math.sqrt(player.prevVx * player.prevVx + player.prevVy * player.prevVy)

    local targetStretch = 1 + math.min(currentSpeed / 200, 0.3)
    local targetSquish = 1 / targetStretch

    local targetAngle = player.stretchAngle
    if currentSpeed > 5 then
        targetAngle = math.atan2(player.vy, player.vx)
    end

    if prevSpeed > 10 and currentSpeed > 10 then
        local dot = (player.vx * player.prevVx + player.vy * player.prevVy) / (currentSpeed * prevSpeed)
        if dot < 0.7 then
            local impulse = (1 - dot) * 0.3
            player.deformVel = player.deformVel + impulse * 15
        end
    end

    local stiffness = 180
    local damping = 12
    local springForce = -stiffness * player.deformOffset - damping * player.deformVel
    player.deformVel = player.deformVel + springForce * dt
    player.deformOffset = player.deformOffset + player.deformVel * dt
    player.deformOffset = math.max(-0.4, math.min(0.4, player.deformOffset))

    player.stretchAmount = Utils.lerp(player.stretchAmount, targetStretch, dt * 8)
    player.squishAmount = Utils.lerp(player.squishAmount, targetSquish, dt * 8)

    local angleDiff = targetAngle - player.stretchAngle
    while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
    while angleDiff < -math.pi do angleDiff = angleDiff + math.pi * 2 end
    player.stretchAngle = player.stretchAngle + angleDiff * dt * 10
end

function Entities.damagePlayer(amount)
    local player = Game.player
    if player.invincible > 0 then return end

    player.hp = player.hp - amount
    player.invincible = 0.5
    Game.shakeScreen(2, 0.15)

    if player.hp <= 0 then
        player.hp = 0
        Game.state = "dead"
    end
end

-- ============================================================================
-- PROJECTILES
-- ============================================================================

local function getPooledProjectile()
    for i, p in ipairs(Game.projectilePool) do
        if not p.active then
            return p
        end
    end
    local p = {active = false}
    table.insert(Game.projectilePool, p)
    return p
end

fireProjectile = function()
    local player = Game.player
    local sx, sy = love.mouse.getPosition()
    local mx, my = Game.screenToWorld(sx, sy)
    local dx, dy = mx - player.x, my - player.y
    dx, dy = Utils.normalize(dx, dy)

    local count = Game.upgrades.projectileCount
    local spreadAngle = 0.15

    Sound.play("fire", { color = player.color })

    for i = 1, count do
        local offset = (i - 1) - (count - 1) / 2
        local angle = math.atan2(dy, dx) + offset * spreadAngle

        local p = getPooledProjectile()
        p.active = true
        p.x = player.x
        p.y = player.y
        p.vx = math.cos(angle) * Config.PROJECTILE_SPEED
        p.vy = math.sin(angle) * Config.PROJECTILE_SPEED
        p.color = player.color
        p.seed = math.random(1000)
        p.baseRadius = Config.PROJECTILE_RADIUS
        p.radiusWobble = 0
        p.wobbleSpeed = 5 + math.random() * 3
        p.wobbleAmount = 3.0
        p.membranePhase = math.random() * math.pi * 2
        p.membraneSpeed = 6 + math.random() * 3  -- Faster than large blobs
        p.dying = false
        p.deathTimer = 0
        p.hasPierced = false

        table.insert(Game.projectiles, p)
    end
end

function Entities.updateProjectiles(dt)
    for i = #Game.projectiles, 1, -1 do
        local p = Game.projectiles[i]

        if p.dying then
            p.deathTimer = p.deathTimer - dt
            p.baseRadius = Config.PROJECTILE_RADIUS * (p.deathTimer / 0.1)
            if p.deathTimer <= 0 then
                p.active = false
                table.remove(Game.projectiles, i)
            end
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt

            if p.piercing and p.piercingEnemy then
                local e = p.piercingEnemy
                local dist = Utils.distance(p.x, p.y, e.x, e.y)
                local bulletRadius = p.baseRadius + (p.radiusWobble or 0)
                local enemyRadius = e.baseRadius + (e.radiusWobble or 0)

                -- On exit: change to mixed color
                if dist > bulletRadius + enemyRadius then
                    p.color = p.pendingColor
                    p.hasPierced = true
                    p.piercing = false
                    p.piercingEnemy = nil
                    p.pendingColor = nil
                    Particles.spawnSplatter(p.x, p.y, p.color, 3)
                end
            end

            p.radiusWobble = math.sin(Game.gameTime * p.wobbleSpeed) * p.wobbleAmount
            p.membranePhase = p.membranePhase + p.membraneSpeed * dt

            if p.x < -50 or p.x > Config.ARENA_WIDTH + 50 or p.y < -50 or p.y > Config.ARENA_HEIGHT + 50 then
                p.active = false
                table.remove(Game.projectiles, i)
            end
        end
    end
end

-- ============================================================================
-- ENEMIES
-- ============================================================================

function Entities.spawnEnemy(enemyType)
    local side = math.random(1, 4)
    local x, y

    local viewLeft = Game.camera.x
    local viewRight = Game.camera.x + Game.VIEWPORT_WIDTH
    local viewTop = Game.camera.y
    local viewBottom = Game.camera.y + Game.VIEWPORT_HEIGHT

    if side == 1 then
        x = viewLeft + math.random() * Game.VIEWPORT_WIDTH
        y = viewTop - Config.SPAWN_MARGIN
    elseif side == 2 then
        x = viewRight + Config.SPAWN_MARGIN
        y = viewTop + math.random() * Game.VIEWPORT_HEIGHT
    elseif side == 3 then
        x = viewLeft + math.random() * Game.VIEWPORT_WIDTH
        y = viewBottom + Config.SPAWN_MARGIN
    else
        x = viewLeft - Config.SPAWN_MARGIN
        y = viewTop + math.random() * Game.VIEWPORT_HEIGHT
    end

    x = math.max(0, math.min(Config.ARENA_WIDTH, x))
    y = math.max(0, math.min(Config.ARENA_HEIGHT, y))

    local availableColors = {"red", "yellow", "blue"}
    local useSecondary = Game.waveTime >= 15

    if useSecondary then
        table.insert(availableColors, "purple")
        table.insert(availableColors, "orange")
        table.insert(availableColors, "green")
    end

    local colorCounts = {}
    for _, c in ipairs(availableColors) do
        colorCounts[c] = 0
    end
    for _, e in ipairs(Game.enemies) do
        if colorCounts[e.color] then
            colorCounts[e.color] = colorCounts[e.color] + 1
        end
    end

    local minCount = math.huge
    for _, c in ipairs(availableColors) do
        if colorCounts[c] < minCount then
            minCount = colorCounts[c]
        end
    end

    local candidates = {}
    for _, c in ipairs(availableColors) do
        if colorCounts[c] <= minCount + 2 then
            table.insert(candidates, c)
        end
    end

    if useSecondary and math.random() < 0.4 then
        local secondaryCandidates = {}
        for _, c in ipairs(candidates) do
            if Utils.isSecondaryColor(c) then
                table.insert(secondaryCandidates, c)
            end
        end
        if #secondaryCandidates > 0 then
            candidates = secondaryCandidates
        end
    end

    local color = candidates[math.random(#candidates)]
    local seed = math.random(1000)
    local baseRadius = enemyType == "dasher" and Config.DASHER_RADIUS or Config.ENEMY_RADIUS

    local enemy = {
        x = x, y = y,
        vx = 0, vy = 0,
        color = color,
        type = enemyType or "drifter",
        hp = enemyType == "dasher" and 100 or 75,
        seed = seed,
        baseRadius = baseRadius,
        wobbles = {
            {phase = math.random() * math.pi * 2, speed = 2.0 + math.random() * 1.5, amount = 6.0},
            {phase = math.random() * math.pi * 2, speed = 3.5 + math.random() * 1.5, amount = 3.6},
            {phase = math.random() * math.pi * 2, speed = 5.0 + math.random() * 2, amount = 2.4},
        },
        radiusWobble = 0,
        membranePhase = math.random() * math.pi * 2,
        membraneSpeed = 3 + math.random() * 3,
        membraneAmp = 0.6 + math.random() * 0.4,
        pulseTimer = 0,
        pulseAmount = 12,
        radiusOffset = 0,
        radiusRecovery = 0,
        dashCooldown = math.random() * 2 + 1,
        dashing = false,
        dashTimer = 0,
        telegraphTimer = 0,
        targetX = 0, targetY = 0
    }

    table.insert(Game.enemies, enemy)
end

function Entities.updateEnemies(dt)
    local player = Game.player

    for i = #Game.enemies, 1, -1 do
        local e = Game.enemies[i]

        if e.pulseTimer > 0 then
            e.pulseTimer = e.pulseTimer - dt
        end

        if e.radiusRecovery > 0 then
            e.radiusRecovery = e.radiusRecovery - dt
            if e.radiusRecovery <= 0 then
                e.radiusOffset = 0
            else
                e.radiusOffset = -3 * Config.SCALE * (e.radiusRecovery / 0.1)
            end
        end

        if e.type == "drifter" then
            local dx, dy = player.x - e.x, player.y - e.y
            dx, dy = Utils.normalize(dx, dy)
            local speed = 144
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
                    dx, dy = Utils.normalize(dx, dy)
                    e.vx = dx * 1200
                    e.vy = dy * 1200
                end
            else
                e.dashCooldown = e.dashCooldown - dt
                if e.dashCooldown <= 0 then
                    e.telegraphTimer = 0.5
                    e.targetX = player.x
                    e.targetY = player.y
                else
                    local dx, dy = player.x - e.x, player.y - e.y
                    dx, dy = Utils.normalize(dx, dy)
                    e.vx = dx * 72
                    e.vy = dy * 72
                end
            end
        end

        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt

        local totalWobble = 0
        for _, w in ipairs(e.wobbles) do
            w.phase = w.phase + w.speed * dt
            totalWobble = totalWobble + math.sin(w.phase) * w.amount
        end
        e.radiusWobble = totalWobble
        e.membranePhase = e.membranePhase + e.membraneSpeed * dt

        local dist = Utils.distance(e.x, e.y, player.x, player.y)
        if dist < Config.PLAYER_RADIUS + e.baseRadius and e.color == player.color then
            Entities.damagePlayer(Config.ENEMY_CONTACT_DAMAGE)
        end
    end
end

-- ============================================================================
-- XP SHARDS
-- ============================================================================

function Entities.spawnShard(x, y)
    table.insert(Game.shards, {
        x = x, y = y,
        vx = (math.random() - 0.5) * 240,
        vy = (math.random() - 0.5) * 240,
        seed = math.random(1000)
    })
end

function Entities.updateShards(dt, triggerLevelUp)
    local player = Game.player

    for i = #Game.shards, 1, -1 do
        local s = Game.shards[i]

        s.vx = s.vx * 0.95
        s.vy = s.vy * 0.95

        local dist = Utils.distance(s.x, s.y, player.x, player.y)
        if dist < Config.XP_MAGNET_RANGE then
            local dx, dy = player.x - s.x, player.y - s.y
            dx, dy = Utils.normalize(dx, dy)
            local pull = (1 - dist / Config.XP_MAGNET_RANGE) * Config.XP_MAGNET_SPEED
            s.vx = s.vx + dx * pull * dt * 10
            s.vy = s.vy + dy * pull * dt * 10
        end

        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt

        if dist < Config.PLAYER_RADIUS + Config.XP_SHARD_RADIUS then
            player.xp = player.xp + Config.XP_PER_SHARD
            table.remove(Game.shards, i)

            if player.xp >= player.xpToLevel then
                player.xp = player.xp - player.xpToLevel
                player.level = player.level + 1
                player.xpToLevel = math.floor(player.xpToLevel * 1.5)
                triggerLevelUp()
            end
        end
    end
end

function Entities.drawShards(time)
    local effectiveZoom = Game.getEffectiveZoom()
    for _, s in ipairs(Game.shards) do
        local viewX, viewY = s.x - Game.camera.x, s.y - Game.camera.y
        local margin = 10 * Config.SCALE
        if viewX < -margin or viewX > Game.VIEWPORT_WIDTH + margin or viewY < -margin or viewY > Game.VIEWPORT_HEIGHT + margin then
            goto continue
        end
        local sx, sy = viewX * effectiveZoom, viewY * effectiveZoom
        local screenRadius = Config.XP_SHARD_RADIUS * effectiveZoom
        local shimmer = 0.8 + math.sin(time * 5 + s.seed) * 0.2
        love.graphics.setColor(shimmer, shimmer, shimmer * 0.9, 1)
        love.graphics.circle("fill", sx, sy, screenRadius)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", sx - 1 * effectiveZoom, sy - 1 * effectiveZoom, screenRadius * 0.5)
        ::continue::
    end
end

return Entities

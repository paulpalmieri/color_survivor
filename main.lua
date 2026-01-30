--[[
    Color Survivor
    A Vampire Survivors-style bullet hell with color-switching mechanics
    Soft-circle threshold blob rendering system
]]

-- Load modules
local Config = require("src.config")
local Game = require("src.game")
local Rendering = require("src.rendering")
local Entities = require("src.entities")
local Particles = require("src.particles")
local Collision = require("src.collision")
local Camera = require("src.camera")
local UI = require("src.ui")
local Drawing = require("src.drawing")
local Sound = require("src.sound")

-- ============================================================================
-- SPAWNING
-- ============================================================================

local function updateSpawning(dt)
    Game.waveTime = Game.waveTime + dt
    Game.spawnTimer = Game.spawnTimer - dt

    local spawnRate = Game.baseSpawnRate - math.min(Game.waveTime / 120, 1) * 0.8

    if Game.spawnTimer <= 0 then
        Game.spawnTimer = spawnRate

        local enemyType = "drifter"
        if math.random() < 0.3 then
            enemyType = "dasher"
        end

        Entities.spawnEnemy(enemyType)

        local extraEnemies = math.floor(Game.waveTime / 45)
        for i = 1, extraEnemies do
            if math.random() < 0.5 then
                Entities.spawnEnemy("drifter")
            end
        end
    end
end

-- ============================================================================
-- GAME RESET
-- ============================================================================

local function resetGame()
    Game.init()
    Entities.initPlayer()
    Camera.init()
end

-- ============================================================================
-- LOVE CALLBACKS
-- ============================================================================

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    love.graphics.setBackgroundColor(Config.BACKGROUND)
    math.randomseed(os.time())

    Rendering.init()
    UI.init()
    Sound.init()
    Entities.initPlayer()
    Camera.init()
end

function love.resize(w, h)
    Rendering.createColorBuffers()
    UI.updateScale()
    local uiScale = math.max(h / 1080, 0.5)
    Rendering.createColorWheelBuffers(uiScale)
end

function love.update(dt)
    dt = math.min(dt, 1/30)
    Game.gameTime = Game.gameTime + dt

    if Game.screenShake.duration > 0 then
        Game.screenShake.duration = Game.screenShake.duration - dt
        if Game.screenShake.duration <= 0 then
            Game.screenShake.amount = 0
        end
    end

    if Game.state == "play" then
        Entities.updatePlayer(dt)
        Camera.update()
        Entities.updateProjectiles(dt)
        Entities.updateEnemies(dt)
        Entities.updateShards(dt, UI.triggerLevelUp)
        Particles.update(dt)
        Particles.updateFX(dt)
        Collision.check(Entities.spawnShard)
        updateSpawning(dt)
    elseif Game.state == "levelup" then
        Particles.update(dt)
        Particles.updateFX(dt)
    end

    -- Update color wheel animation
    local angleDiff = Game.colorWheelAnim.targetAngle - Game.colorWheelAnim.currentAngle
    while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
    while angleDiff < -math.pi do angleDiff = angleDiff + math.pi * 2 end
    if math.abs(angleDiff) > 0.001 then
        Game.colorWheelAnim.currentAngle = Game.colorWheelAnim.currentAngle + angleDiff * dt * 12
    else
        Game.colorWheelAnim.currentAngle = Game.colorWheelAnim.targetAngle
    end
    Game.colorWheelAnim.wobbleTime = Game.colorWheelAnim.wobbleTime + dt
end

function love.draw()
    local time = love.timer.getTime()

    love.graphics.clear(Config.BACKGROUND)
    love.graphics.push()

    -- Apply screen shake
    if Game.screenShake.amount > 0 then
        local effectiveZoom = Game.getEffectiveZoom()
        local dx = (math.random() - 0.5) * Game.screenShake.amount * 2 * Config.SCALE * effectiveZoom
        local dy = (math.random() - 0.5) * Game.screenShake.amount * 2 * Config.SCALE * effectiveZoom
        love.graphics.translate(dx, dy)
    end

    Drawing.drawBackground()
    Entities.drawShards(time)
    Drawing.drawTelegraphLines()
    Drawing.drawBlobs()
    Particles.drawFX()

    love.graphics.pop()

    UI.draw()

    if Game.state == "levelup" then
        UI.drawLevelUpScreen()
    elseif Game.state == "dead" then
        UI.drawDeathScreen()
    end
end

function love.keypressed(key)
    if Game.state == "play" then
        if key == "space" then
            Entities.triggerDash()
        elseif key == "q" then
            Entities.switchColor(-1)
        elseif key == "e" then
            Entities.switchColor(1)
        elseif key == "1" then
            Entities.setColorDirect(1)
        elseif key == "2" then
            Entities.setColorDirect(2)
        elseif key == "3" then
            Entities.setColorDirect(3)
        elseif key == "c" then
            Game.showHitFX = not Game.showHitFX
        elseif key == "b" then
            local fs = love.window.getFullscreen()
            if fs then
                love.window.setMode(1280, 720, {borderless = false, resizable = true})
            else
                local _, _, flags = love.window.getMode()
                local dw, dh = love.window.getDesktopDimensions(flags.display)
                love.window.setMode(dw, dh, {borderless = true, resizable = true, fullscreentype = "desktop"})
                love.window.setFullscreen(true, "desktop")
            end
            -- Force recalculation after mode change
            local w, h = love.graphics.getDimensions()
            love.resize(w, h)
        elseif key == "escape" then
            love.event.quit()
        end
    elseif Game.state == "levelup" then
        if key == "1" and Game.levelUpChoices[1] then
            UI.applyUpgrade(Game.levelUpChoices[1])
        elseif key == "2" and Game.levelUpChoices[2] then
            UI.applyUpgrade(Game.levelUpChoices[2])
        elseif key == "3" and Game.levelUpChoices[3] then
            UI.applyUpgrade(Game.levelUpChoices[3])
        end
    elseif Game.state == "dead" then
        if key == "r" then
            resetGame()
        elseif key == "escape" then
            love.event.quit()
        end
    end
end

function love.mousepressed(x, y, button)
    if Game.state == "play" then
        if button == 2 then
            Entities.switchColor(1)
        end
    elseif Game.state == "levelup" and button == 1 then
        UI.handleLevelUpClick(x, y)
    end
end

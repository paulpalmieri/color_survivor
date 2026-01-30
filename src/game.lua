--[[
    Game State
    Central state object shared across all modules
]]

local Config = require("src.config")

local Game = {}

-- Initialize/reset all game state
function Game.init()
    -- Fixed viewport in world units (everyone sees same game area)
    Game.VIEWPORT_WIDTH = Config.BASE_WIDTH / Config.VIEW_ZOOM   -- 4800
    Game.VIEWPORT_HEIGHT = Config.BASE_HEIGHT / Config.VIEW_ZOOM  -- 2700

    -- Render dimensions (actual window size, updated on resize)
    Game.RENDER_WIDTH = Config.BASE_WIDTH
    Game.RENDER_HEIGHT = Config.BASE_HEIGHT
    Game.RENDER_SCALE = 1  -- Multiplier for drawing to current window

    -- Camera
    Game.camera = {x = 0, y = 0}

    -- Game state
    Game.state = "play"
    Game.screenShake = {amount = 0, duration = 0}
    Game.gameTime = 0
    Game.waveTime = 0
    Game.spawnTimer = 0
    Game.baseSpawnRate = 1.5

    -- Entity tables
    Game.player = {}
    Game.enemies = {}
    Game.projectiles = {}
    Game.shards = {}
    Game.particles = {}
    Game.fxParticles = {}

    -- Projectile pool
    Game.projectilePool = {}

    -- Level/upgrade system
    Game.levelUpChoices = {}
    Game.upgrades = {
        fireRate = 1,
        moveSpeed = 1,
        damage = 1,
        projectileCount = 1,
        cooldownReduction = 0,
        maxHp = 0
    }

    -- Color wheel animation state
    Game.colorWheelAnim = {
        currentAngle = 0,
        targetAngle = 0,
        wobbleTime = 0,
    }

    -- Settings
    Game.showHitFX = true
end

function Game.shakeScreen(amount, duration)
    Game.screenShake.amount = math.max(Game.screenShake.amount, amount)
    Game.screenShake.duration = math.max(Game.screenShake.duration, duration)
end

function Game.getEffectiveZoom()
    return Config.VIEW_ZOOM * Game.RENDER_SCALE
end

function Game.screenToWorld(sx, sy)
    local zoom = Game.getEffectiveZoom()
    return sx / zoom + Game.camera.x, sy / zoom + Game.camera.y
end

function Game.worldToScreen(wx, wy)
    local zoom = Game.getEffectiveZoom()
    return (wx - Game.camera.x) * zoom, (wy - Game.camera.y) * zoom
end

function Game.isOnScreen(wx, wy, margin)
    margin = margin or (50 * Config.SCALE)
    local sx, sy = Game.worldToScreen(wx, wy)
    return sx > -margin and sx < Game.RENDER_WIDTH + margin and
           sy > -margin and sy < Game.RENDER_HEIGHT + margin
end

-- Initialize on load
Game.init()

return Game

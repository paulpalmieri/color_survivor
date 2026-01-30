--[[
    Configuration & Constants
    All game settings, colors, and tuning values
]]

local Config = {}

-- High-resolution rendering (native resolution)
-- Reference resolution is 1920x1080, scales proportionally to window
Config.BASE_WIDTH = 1920
Config.BASE_HEIGHT = 1080
Config.SCALE = 6           -- Scale factor from old 320x180

-- View zoom: <1 = zoomed out (see more), >1 = zoomed in (see less)
Config.VIEW_ZOOM = 0.5

-- Arena dimensions (much larger play area)
Config.ARENA_WIDTH = 7680
Config.ARENA_HEIGHT = 4320

-- Color palette - RYB primaries + secondaries (paint mixing model)
Config.COLORS = {
    red = {0.95, 0.25, 0.3},
    yellow = {0.95, 0.85, 0.2},
    blue = {0.25, 0.35, 0.95},
    purple = {0.7, 0.25, 0.85},
    orange = {0.95, 0.55, 0.2},
    green = {0.25, 0.85, 0.3},
}
Config.PRIMARY_COLORS = {"red", "yellow", "blue"}
Config.SECONDARY_COLORS = {"purple", "orange", "green"}
Config.COLOR_ORDER = {"red", "yellow", "blue"}
Config.BACKGROUND = {0.95, 0.93, 0.88}

-- Paint mixing rules
Config.COLOR_MIX = {
    red = {blue = "purple", yellow = "orange"},
    yellow = {red = "orange", blue = "green"},
    blue = {red = "purple", yellow = "green"},
}

-- Parent colors (what primaries a secondary comes from)
Config.COLOR_PARENTS = {
    purple = {"red", "blue"},
    orange = {"red", "yellow"},
    green = {"yellow", "blue"},
}

-- Player settings
Config.PLAYER_RADIUS = 84
Config.PLAYER_MAX_SPEED = 480
Config.PLAYER_ACCEL = 2880
Config.PLAYER_DECEL = 1920
Config.PLAYER_MAX_HP = 100
Config.COLOR_SWITCH_COOLDOWN = 1.0

-- Dash settings
Config.DASH_SPEED = 1500
Config.DASH_DURATION = 0.15
Config.DASH_CHARGE_COOLDOWN = 2.0
Config.DASH_MAX_CHARGES = 2
Config.DASH_IFRAME_DURATION = 0.2

-- Projectile settings
Config.PROJECTILE_SPEED = 960
Config.PROJECTILE_RADIUS = 30
Config.FIRE_RATE = 4
Config.PROJECTILE_DAMAGE = 25

-- Enemy settings
Config.ENEMY_CONTACT_DAMAGE = 15
Config.ENEMY_RADIUS = 72
Config.DASHER_RADIUS = 84
Config.SPAWN_MARGIN = 120

-- XP settings
Config.XP_MAGNET_RANGE = 192
Config.XP_MAGNET_SPEED = 720
Config.XP_PER_SHARD = 10
Config.XP_SHARD_RADIUS = 12

-- Blob rendering
Config.SOFT_CIRCLE_SIZE = 256
Config.BLOB_THRESHOLD = 0.35
Config.BLOB_INTENSITY = 1.0

-- Paint splatter noise (organic edges for projectiles/particles)
Config.NOISE_SCALE = 0.015     -- Per-entity seed variation
Config.NOISE_AMOUNT = 0.18     -- Visible organic distortion
Config.NOISE_SPEED = 1.0       -- Animation speed

-- Mini-lobe system for small entities (projectiles)
Config.MINI_LOBE_THRESHOLD = 6 * Config.SCALE   -- Below this radius, use mini-lobes
Config.MINI_LOBE_COUNT = 2                       -- Number of lobes for small entities
Config.MINI_LOBE_ORBIT_DIST = 0.18               -- Orbit distance multiplier (tighter than 0.25)
Config.MINI_LOBE_RADIUS = 0.5                    -- Lobe radius multiplier
Config.MINI_LOBE_CORE_SCALE = 0.8                -- Core size multiplier

-- Particle sizes (world units, like other entity radii)
Config.PARTICLE_SPLATTER_RADIUS = {min = 8, max = 15}
Config.PARTICLE_DEATH_RADIUS = {min = 15, max = 30}
Config.PARTICLE_PAINTMIX_RADIUS = {min = 4, max = 8}
Config.PARTICLE_WOBBLE_AMOUNT = {min = 0.5, max = 1.0}  -- world units, NOT scaled

-- Color wheel UI geometry (base values at 1080p, scaled by uiScale)
Config.COLOR_WHEEL = {
    blobRadius = 38,      -- base blob size
    orbitRadius = 18,     -- base orbit distance
    canvasSize = 200,     -- base canvas size
}

return Config

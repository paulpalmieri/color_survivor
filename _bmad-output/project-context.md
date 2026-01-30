---
project_name: 'color_survivor'
user_name: 'Paul'
date: '2026-01-28'
sections_completed: ['technology_stack', 'architecture', 'rendering', 'entities', 'performance', 'conventions', 'critical_rules']
status: 'complete'
rule_count: 42
optimized_for_llm: true
---

# Project Context for AI Agents

_Critical rules and patterns for implementing game code in Color Survivor. Focus on unobvious details that agents might miss._

---

## Technology Stack

- **Framework:** LÖVE2D 11.x (Lua game framework)
- **Language:** Lua 5.1 (LuaJIT compatible)
- **Shaders:** GLSL (LÖVE shader format with `effect()` function)
- **Target:** PC/Mac (Steam), Web (LÖVE web export)
- **Resolution:** 1920x1080 reference, VIEW_ZOOM=0.4 for zoomed-out view

---

## Architecture Rules

### Module System

All game code lives in `src/` using Lua's module pattern:

```lua
-- Every module returns a table
local Module = {}
function Module.something() end
return Module

-- Require with dot notation
local Config = require("src.config")
```

### Core Modules

| Module | Purpose | Key Exports |
|--------|---------|-------------|
| `config` | Constants only, never mutate | `COLORS`, `PLAYER_*`, `ARENA_*` |
| `game` | ALL mutable state | `Game.player`, `Game.enemies`, `Game.state` |
| `utils` | Pure helper functions | `lerp`, `distance`, `normalize`, color checks |
| `entities` | Entity logic | `initPlayer`, `updatePlayer`, `spawnEnemy` |
| `rendering` | Low-level blob rendering | `renderColorBlobs`, shader refs |
| `drawing` | High-level draw calls | `drawBlobs`, `drawBackground` |
| `ui` | All UI systems | `draw`, `drawLevelUpScreen`, `triggerLevelUp` |
| `particles` | Particle systems | `spawn`, `spawnDeath`, `spawnSplatter` |
| `collision` | Projectile-enemy hits | `check(spawnShardCallback)` |
| `camera` | Camera follow | `update`, `init` |

### State Management - CRITICAL

**ALL mutable game state goes through the `Game` table in `src/game.lua`.**

```lua
-- CORRECT: Access state through Game
local Game = require("src.game")
Game.player.hp = Game.player.hp - damage
table.insert(Game.enemies, newEnemy)

-- WRONG: Local state that should be shared
local enemies = {}  -- NO! Use Game.enemies
```

---

## Coordinate Systems - CRITICAL

The game uses THREE coordinate spaces. Confusing them causes bugs.

### 1. World Coordinates
- Used for: Entity positions (`player.x`, `enemy.x`)
- Scale: 1 unit = 1 world pixel at SCALE=6
- Arena: 0 to `ARENA_WIDTH` (7680), 0 to `ARENA_HEIGHT` (4320)

### 2. Viewport Coordinates
- World coords relative to camera
- `viewX = entity.x - Game.camera.x`
- Used for: Culling checks before rendering

### 3. Screen Coordinates
- Final pixel position on screen
- `screenX = viewX * VIEW_ZOOM`
- Used for: All drawing operations

### Conversion Functions

```lua
-- World to screen (for drawing)
local screenX, screenY = Game.worldToScreen(entity.x, entity.y)

-- Screen to world (for mouse input)
local worldX, worldY = Game.screenToWorld(mouseX, mouseY)

-- Manual conversion
local viewX = entity.x - Game.camera.x
local screenX = viewX * Config.VIEW_ZOOM
```

### Common Mistake

```lua
-- WRONG: Drawing at world coordinates
love.graphics.circle("fill", entity.x, entity.y, radius)

-- CORRECT: Convert to screen coordinates first
local sx, sy = Game.worldToScreen(entity.x, entity.y)
local screenRadius = radius * Config.VIEW_ZOOM
love.graphics.circle("fill", sx, sy, screenRadius)
```

---

## Blob Rendering System

### How It Works

1. Each color has a canvas buffer (`colorBuffers[colorName]`)
2. Soft circles are drawn additively to buffer (grayscale intensity)
3. Threshold shader converts intensity → solid color with anti-aliased edge
4. Result composited to screen

### Adding New Blob Entities

Entities rendered as blobs need these fields:

```lua
{
    x = worldX,           -- World position
    y = worldY,
    baseRadius = 72,      -- Base size (world units)
    radiusWobble = 0,     -- Animated wobble offset
    vx = 0, vy = 0,       -- Velocity (for stretch calculation)
    -- Optional:
    membranePhase = 0,    -- For organic animation
    pulseTimer = 0,       -- Hit feedback
    isProjectile = true,  -- Skip multi-lobe rendering for small entities
}
```

### Shader Uniforms

```glsl
// threshold.glsl
extern float threshold;  -- 0.35 default, controls blob edge
extern vec3 blobColor;   -- RGB color to render
```

### Particle Sizing

Particles use the same world-unit system as other entities:

```lua
-- Particle radii are in world units (like projectiles/enemies)
Config.PARTICLE_SPLATTER_RADIUS = {min = 8, max = 15}   -- ~1/3 projectile size
Config.PARTICLE_DEATH_RADIUS = {min = 15, max = 30}     -- medium burst
Config.PARTICLE_PAINTMIX_RADIUS = {min = 4, max = 8}    -- tiny droplets

-- Wobble is also in world units, NOT pre-scaled
Config.PARTICLE_WOBBLE_AMOUNT = {min = 0.5, max = 1.0}
```

**Common Mistake:**
```lua
-- WRONG: Double-scaling particle radius
local radius = p.radius * Config.SCALE  -- NO! Already in world units

-- CORRECT: Use directly (scaling happens in renderColorBlobs)
local radius = p.radius + (p.radiusWobble or 0)
```

---

## Entity Animation Patterns

### Organic Wobble System

All major entities use multi-layer wobble for organic feel:

```lua
entity.wobbles = {
    {phase = random(), speed = 2.3, amount = 7.2},
    {phase = random(), speed = 3.7, amount = 4.8},
    {phase = random(), speed = 5.1, amount = 3.0},
}

-- In update:
local totalWobble = 0
for _, w in ipairs(entity.wobbles) do
    w.phase = w.phase + w.speed * dt
    totalWobble = totalWobble + math.sin(w.phase) * w.amount
end
entity.radiusWobble = totalWobble
```

### Velocity-Based Deformation

Entities stretch in movement direction:

```lua
local speed = math.sqrt(vx*vx + vy*vy)
local stretchFactor = 1 + math.min(speed / (PLAYER_MAX_SPEED * 2.5), 0.3)
local stretchX = stretchFactor
local stretchY = 1 / stretchFactor  -- Inverse to preserve volume
local angle = math.atan2(vy, vx)
```

---

## Color Mechanics

### RYB Color Model (Paint Mixing)

```
Primary:   Red, Yellow, Blue
Secondary: Purple (R+B), Orange (R+Y), Green (Y+B)
```

### Color Checks

```lua
local Utils = require("src.utils")

Utils.isPrimaryColor(color)      -- red/yellow/blue
Utils.isSecondaryColor(color)    -- purple/orange/green
Utils.getMixedColor(c1, c2)      -- returns secondary or nil
Utils.mixedBulletDamagesEnemy(bulletColor, enemyColor)  -- parent check
```

### Collision Color Rules

| Bullet | Enemy | Result |
|--------|-------|--------|
| Same color | Any | Full damage, pierce |
| Primary | Different primary | Pierce + mix color |
| Primary | Secondary | Pierce + become secondary |
| Secondary | Parent primary | 50% damage |
| Secondary | Non-parent | Absorbed (fizzle) |

---

## Performance Rules

### Target: 60 FPS

- Frame budget: 16.6ms
- Hot paths: `renderColorBlobs`, `updateEnemies`, `checkCollisions`

### Object Pooling

Projectiles use pooling to avoid GC:

```lua
-- Get from pool
local p = getPooledProjectile()
p.active = true
-- ... set properties ...
table.insert(Game.projectiles, p)

-- Return to pool (don't remove from projectilePool)
p.active = false
table.remove(Game.projectiles, i)
```

### Culling

Always check viewport bounds before expensive operations:

```lua
local viewX = entity.x - Game.camera.x
local viewY = entity.y - Game.camera.y
local margin = radius * 2
if viewX < -margin or viewX > Game.VIEWPORT_WIDTH + margin or
   viewY < -margin or viewY > Game.VIEWPORT_HEIGHT + margin then
    goto continue  -- Skip rendering/processing
end
```

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Modules | lowercase | `src/entities.lua` |
| Constants | UPPER_SNAKE | `PLAYER_MAX_SPEED` |
| Functions | camelCase | `updatePlayer`, `spawnEnemy` |
| Local vars | camelCase | `screenX`, `totalWobble` |
| Entity fields | camelCase | `baseRadius`, `colorCooldown` |

---

## Critical Don't-Miss Rules

### DO

- Access ALL mutable state through `Game` table
- Convert to screen coordinates before drawing
- Scale radii/distances by `VIEW_ZOOM` for screen space
- Use `Config.SCALE` for world-space sizes (multiply by 6)
- Return tables from modules (`return Module`)

### DON'T

- Create local entity tables outside `Game`
- Draw at world coordinates directly
- Forget `VIEW_ZOOM` when converting positions
- Mutate `Config` values at runtime
- Use `love.graphics.draw()` without coordinate conversion

### Common Gotchas

1. **Mouse position is screen coords** - must convert with `Game.screenToWorld()`
2. **Canvas operations reset blend mode** - always `setBlendMode("alpha")` after
3. **Entity removal during iteration** - iterate backwards: `for i = #list, 1, -1`
4. **Shader uniforms persist** - always set before draw, `setShader()` after

---

## File Quick Reference

```
main.lua              -- LÖVE callbacks, game loop orchestration
conf.lua              -- LÖVE window config only
src/
  config.lua          -- All constants (NEVER mutate)
  game.lua            -- All mutable state (Game table)
  utils.lua           -- Pure helpers (lerp, distance, color checks)
  camera.lua          -- Camera follow system
  entities.lua        -- Player, enemies, projectiles, shards
  particles.lua       -- Death/splatter/fizzle particles
  collision.lua       -- Projectile-enemy collision resolution
  rendering.lua       -- Blob rendering primitives
  drawing.lua         -- High-level draw (blobs, background, telegraph)
  ui.lua              -- HUD, level-up, death screen, color wheel
threshold.glsl        -- Blob threshold shader
threshold_stencil.glsl -- UI stencil shader
```

---

## Usage Guidelines

**For AI Agents:**
- Read this file before implementing any game code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Ask if a pattern isn't covered here

**For Humans:**
- Keep this file lean and focused on agent needs
- Update when architecture or patterns change
- Remove rules that become obvious over time

_Last Updated: 2026-01-28_

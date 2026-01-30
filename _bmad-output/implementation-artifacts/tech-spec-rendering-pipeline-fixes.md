# Tech-Spec: Rendering Pipeline Fixes

**Created:** 2026-01-28
**Status:** Implemented - Pending Verification
**Engine:** LOVE2D 11.x (Lua)

## Overview

### Feature/Mechanic Description

Fix rendering pipeline issues including particle sizing, wobble calculation bugs, and render pass organization. Ensure small paint splatter effects render correctly at appropriate sizes.

### Gameplay Impact

- Visual polish: splatter particles should look like small paint droplets, not enemy-sized blobs
- Consistent visual language: all blob-rendered entities should feel cohesive
- Performance: potential optimization by reducing render passes (secondary goal)

### Scope

**In Scope:**
- Fix particle radius double-scaling bug
- Fix wobble amount unit mismatch
- Tune splatter particle sizes for visual appeal
- Update project-context.md with corrected patterns

**Out of Scope:**
- Adding new particle types
- Changing the blob shader fundamentals
- UI/color wheel rendering changes

---

## Context for Development

### Engine Patterns

- All rendering goes through `Rendering.renderColorBlobs()` which draws soft circles to a canvas, then applies threshold shader
- Entities need: `x`, `y`, `baseRadius`, `radiusWobble`, optionally `vx`/`vy` for stretch, `isProjectile` flag for simple rendering
- `Config.SCALE = 6` is the multiplier from old 320x180 resolution to current world units
- Entity radii (player, enemy, projectile) are already in world units - NOT multiplied by SCALE

### Existing Systems Integration

| Module | Role | Changes Needed |
|--------|------|----------------|
| `src/particles.lua` | Particle creation and update | Fix radius and wobbleAmount units |
| `src/drawing.lua` | High-level draw calls | Remove incorrect SCALE multiplication |
| `src/rendering.lua` | Low-level blob rendering | No changes needed |
| `src/collision.lua` | Triggers splatter spawns | No changes needed |
| `src/config.lua` | Add particle size constants | New constants for particle sizes |

### Files to Reference

- `src/particles.lua:20-29` - particle spawn defaults
- `src/particles.lua:50-63` - spawnSplatter function
- `src/particles.lua:78-96` - spawnPaintMixFX function
- `src/drawing.lua:82-101` - particle rendering prep
- `src/config.lua:83-90` - blob rendering constants

### Technical Decisions

1. **Particle radii should be in world units** (like projectiles/enemies), not raw units that get scaled
2. **Wobble amounts should NOT be pre-scaled** - scaling happens once in drawing
3. **Splatter size target:** ~8-15 world units (vs projectile=30, enemy=72)
4. **Death particles size target:** ~15-30 world units
5. **PaintMixFX size target:** ~4-8 world units (tiny droplets)

---

## Implementation Plan

### Tasks

- [x] **Task 1: Add particle size constants to config.lua**
  - Add `PARTICLE_SPLATTER_RADIUS_MIN/MAX` (8-15)
  - Add `PARTICLE_DEATH_RADIUS_MIN/MAX` (15-30)
  - Add `PARTICLE_PAINTMIX_RADIUS_MIN/MAX` (4-8)
  - Add `PARTICLE_WOBBLE_AMOUNT` (0.5-1.0 world units, NOT scaled)

- [x] **Task 2: Fix particles.lua spawn functions**
  - `Particles.spawn()`: Use world-unit defaults for radius (~10-20), remove SCALE from wobbleAmount
  - `Particles.spawnSplatter()`: Use `PARTICLE_SPLATTER_RADIUS` range
  - `Particles.spawnDeath()`: Use `PARTICLE_DEATH_RADIUS` range
  - `Particles.spawnPaintMixFX()`: Use `PARTICLE_PAINTMIX_RADIUS` range
  - All wobbleAmount values: remove `* Config.SCALE`

- [x] **Task 3: Fix drawing.lua particle rendering**
  - Line 84: Remove `* Config.SCALE` from radius calculation
  - Particle radius is now in world units, wobble is in world units, no scaling needed
  - Result: `local radius = p.radius + (p.radiusWobble or 0)`
  - If shrinking: `radius = radius * alpha`

- [ ] **Task 4: Verify and test**
  - Test splatter on hit (should be small droplets)
  - Test death particles (medium burst)
  - Test paintmix FX (tiny droplets)
  - Test wobble animation (smooth, not jittery)
  - Verify no visual regressions with enemies/player/projectiles

- [x] **Task 5: Update project-context.md**
  - Document correct particle sizing pattern
  - Note that particle radius is in world units (like other entities)

### Performance Considerations

- No frame budget impact expected (same number of draw calls)
- Smaller particles = fewer pixels filled = slightly better fill rate
- Consider future optimization: merge enemy + projectile passes per color (not in this spec)

### Acceptance Criteria

- [ ] AC 1: Splatter particles on projectile hit are visibly smaller than projectiles (~1/3 to 1/2 size)
- [ ] AC 2: Death burst particles are medium-sized, creating satisfying explosion
- [ ] AC 3: PaintMixFX particles are tiny droplets, barely visible individually
- [ ] AC 4: Particle wobble animation is smooth, not jittery or oversized
- [ ] AC 5: No visual regression on player, enemies, or projectile rendering
- [ ] AC 6: Particles still fade out smoothly via alpha

---

## Additional Context

### Dependencies

- None - isolated rendering fix

### Testing Strategy

1. Manual visual testing in-game
2. Spawn enemies, shoot them, observe splatter size
3. Kill enemies, observe death particle size
4. Enable hit FX (`c` key), observe paintmix particles
5. Compare particle sizes to projectile/enemy as reference

### Code Changes Summary

**src/config.lua** - Add after line 90:
```lua
-- Particle sizes (world units, like other entity radii)
Config.PARTICLE_SPLATTER_RADIUS = {min = 8, max = 15}
Config.PARTICLE_DEATH_RADIUS = {min = 15, max = 30}
Config.PARTICLE_PAINTMIX_RADIUS = {min = 4, max = 8}
Config.PARTICLE_WOBBLE_AMOUNT = {min = 0.5, max = 1.0}  -- world units, NOT scaled
```

**src/particles.lua** - Key changes:
```lua
-- In Particles.spawn() defaults:
radius = config.radius or math.random(10, 20),  -- world units
wobbleAmount = config.wobbleAmount or (0.5 + math.random() * 0.5),  -- NO * Config.SCALE

-- In spawnSplatter():
radius = math.random(Config.PARTICLE_SPLATTER_RADIUS.min, Config.PARTICLE_SPLATTER_RADIUS.max),

-- In spawnDeath():
radius = math.random(Config.PARTICLE_DEATH_RADIUS.min, Config.PARTICLE_DEATH_RADIUS.max),

-- In spawnPaintMixFX():
radius = math.random(Config.PARTICLE_PAINTMIX_RADIUS.min, Config.PARTICLE_PAINTMIX_RADIUS.max),
```

**src/drawing.lua** - Line 84 change:
```lua
-- Before:
local radius = (p.radius + (p.radiusWobble or 0)) * Config.SCALE

-- After:
local radius = p.radius + (p.radiusWobble or 0)
```

### Notes

- The `fxParticles` system (rendered via `Particles.drawFX()` as simple circles) is a separate concern - not addressed in this spec
- Render pass optimization (merging enemy + projectile passes) deferred to future work
- Noise shader parameters unchanged - may need separate tuning pass after sizes are fixed

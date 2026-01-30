# Tech-Spec: Projectile Mini-Lobe Rendering

**Created:** 2026-01-28
**Status:** Completed
**Engine:** Love2D 11.x (Lua)

## Overview

### Feature/Mechanic Description

Enable a scaled-down version of the existing lobe system for projectiles. Instead of rendering as a single stretched ellipse, projectiles will use 2-3 small lobes orbiting a core - the same organic "amoeba" treatment that larger blobs get, but tuned for small entities.

### Gameplay Impact

- **Visual consistency:** Projectiles use the same organic language as player/enemies
- **Subtle improvement:** Small blob feel instead of ellipse, may be subtle at 5px
- **Minimal code change:** Reuses existing proven system

### Scope

**In Scope:**
- Enable lobe rendering for projectiles (currently excluded)
- Scale lobe count down for small entities (2-3 lobes vs 5)
- Adjust lobe distances and sizes for projectile scale
- Skip organelles for projectiles (too small to see)

**Out of Scope:**
- Changes to large entity lobe rendering
- New lobe animation patterns
- Particle system changes

## Context for Development

### Engine Patterns

- **Lobe system:** `src/rendering.lua:158-204` - draws core + orbiting lobes + organelles
- **Current exclusion:** Line 158 explicitly skips projectiles: `not entity.isProjectile`
- **Lobe parameters:** 5 lobes at 25% orbit distance, 55% lobe radius

### Existing Systems Integration

| System | File | Integration Point |
|--------|------|-------------------|
| Lobe rendering | `src/rendering.lua:158-204` | Modify condition & add small-entity branch |
| Projectile drawing | `src/drawing.lua:64-80` | Remove `isProjectile = true` flag |
| Config | `src/config.lua` | Add mini-lobe parameters |

### Files to Modify

1. `src/config.lua` - Add mini-lobe configuration constants
2. `src/rendering.lua:158-204` - Add small-entity lobe branch
3. `src/drawing.lua:70-79` - Remove `isProjectile` flag from projectiles

### Technical Decisions

1. **Lobe count:** 2-3 lobes for projectiles (vs 5 for large blobs)
2. **No organelles:** Skip the inner organelle layer - too small to see at 5px
3. **Tighter orbit:** Lobes closer to center (15-20% vs 25%) for cohesive shape
4. **Faster animation:** Membrane phase runs faster for snappy feel
5. **Size threshold:** Entities below `MINI_LOBE_THRESHOLD` use mini-lobe system

## Implementation Plan

### Tasks

- [x] Task 1: Add mini-lobe config constants to `src/config.lua`
  ```lua
  -- Mini-lobe system for small entities (projectiles)
  Config.MINI_LOBE_THRESHOLD = 6 * Config.SCALE  -- Below this radius, use mini-lobes
  Config.MINI_LOBE_COUNT = 2                      -- Number of lobes for small entities
  Config.MINI_LOBE_ORBIT_DIST = 0.18              -- Orbit distance multiplier (tighter than 0.25)
  Config.MINI_LOBE_RADIUS = 0.5                   -- Lobe radius multiplier
  Config.MINI_LOBE_CORE_SCALE = 0.8               -- Core size multiplier
  ```

- [x] Task 2: Remove `isProjectile` flag from projectile entities in `src/drawing.lua`
  - Line 78: Remove `isProjectile = true` from projectile entity table
  - This allows projectiles to enter the lobe rendering branch

- [x] Task 3: Modify lobe rendering in `src/rendering.lua:158-204`

  Replace the current condition:
  ```lua
  -- BEFORE:
  if worldRadius > (8 * Config.SCALE) and not entity.isProjectile then

  -- AFTER:
  if worldRadius > Config.MINI_LOBE_THRESHOLD then
      -- Existing large blob lobe code (5 lobes + 3 organelles)
      ...
  elseif worldRadius > (3 * Config.SCALE) then
      -- NEW: Mini-lobe rendering for small entities
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
      -- Very small: just draw core (existing fallback)
  ```

- [x] Task 4: Ensure projectiles have `membranePhase` for animation
  - In `src/entities.lua:355-372` (fireProjectile), add:
  ```lua
  p.membranePhase = math.random() * math.pi * 2
  p.membraneSpeed = 6 + math.random() * 3  -- Faster than large blobs
  ```
  - In `src/entities.lua:375-414` (updateProjectiles), add:
  ```lua
  p.membranePhase = p.membranePhase + p.membraneSpeed * dt
  ```

- [ ] Task 5: Visual tuning pass
  - Adjust `MINI_LOBE_COUNT` (try 2 vs 3)
  - Adjust `MINI_LOBE_ORBIT_DIST` for cohesive vs spread look
  - Test if effect is visible at projectile size
  - Compare against cluster approach visually

### Performance Considerations

- **Draw call increase:** 3x per projectile (core + 2 lobes)
- **At 20 projectiles:** 60 soft circles vs previous 20
- **Impact:** Negligible at 320x180 internal resolution
- **Computation:** Reuses existing lobe math, minimal overhead
- **Memory:** One new float per projectile (membranePhase)

### Acceptance Criteria

- [ ] AC 1: Given a projectile is fired, when it renders, then it appears as a small blob with 2-3 orbiting lobes (not a single ellipse)
- [ ] AC 2: Given the game is running, when observing projectiles, then their lobes animate subtly (membrane phase movement)
- [ ] AC 3: Given projectiles are moving fast, when observed, then the lobe pattern stretches along velocity (consistent with velocity deformation)
- [ ] AC 4: Given multiple projectiles exist, when comparing them, then each has slightly different lobe phases (visual variation)
- [ ] AC 5: Given 20+ projectiles on screen, when observing FPS, then performance remains at 60fps
- [ ] AC 6: Given the mini-lobe rendering, when playing, then projectiles feel more organic than plain ellipses

## Additional Context

### Dependencies

- No external dependencies
- Reuses existing lobe rendering math
- Works with existing threshold shader + noise

### Testing Strategy

- **Visual testing:** Compare before/after at actual game scale
- **Animation testing:** Verify lobes animate, not static
- **Scale testing:** Check if effect is actually visible at 5px (may be too subtle)
- **Performance testing:** Max projectiles, verify 60fps
- **Comparison:** Side-by-side with cluster approach to pick winner

### Notes

**Visual comparison to cluster approach:**

| Aspect | Mini-Lobes (B) | Cluster (A) |
|--------|----------------|-------------|
| Shape language | Amoeba/organic | Paint splatter |
| Code complexity | Simpler (reuses existing) | New helper function |
| Visual impact | Subtle at 5px | More visible |
| Animation | Built-in membrane phase | Static positions |
| Direction emphasis | Less (orbiting lobes) | More (trailing satellites) |

**Recommendation:** Implement both, compare in-game, pick the winner. Mini-lobes is ~30 min, cluster is ~1-2 hours. Could prototype mini-lobes first as quick test.

**Risk:** At 5 pixels, the lobe effect may be too subtle to notice. The cluster approach with trailing satellites may read better at this scale because it changes the *silhouette* more dramatically.

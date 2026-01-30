# Tech-Spec: Projectile Cluster Splatter Rendering

**Created:** 2026-01-28
**Status:** Ready for Development
**Engine:** Love2D 11.x (Lua)

## Overview

### Feature/Mechanic Description

Replace single-ellipse projectile rendering with a cluster-based splatter composition. Each projectile renders as 1 core circle + 2-3 trailing satellite circles, creating an organic "flung paint" look instead of a wobbly ellipse.

### Gameplay Impact

- **Visual feel:** Projectiles feel like flung paint blobs, not geometric shapes
- **Speed emphasis:** Trailing satellites create forward momentum perception
- **Satisfaction:** More "juice" when firing without changing mechanics

### Scope

**In Scope:**
- Cluster composition for player projectiles (core + 2-3 satellites)
- Satellites trail behind velocity vector (fast/snappy feel)
- Per-projectile random seed for variation
- Cluster rotation to match velocity direction
- Integration with existing threshold shader (noise still applies)

**Out of Scope:**
- Enemy projectiles (if any exist)
- Particle system changes (death particles, impact splatter)
- New shader work (reuses existing threshold + noise)
- Persistent paint trails

## Context for Development

### Engine Patterns

- **Rendering pipeline:** Entities → `renderColorBlobs()` → soft circle texture → threshold shader
- **Projectile data:** Created in `src/entities.lua:339-372`, has `x, y, vx, vy, seed, baseRadius`
- **Drawing:** Projectiles collected in `src/drawing.lua:64-80`, passed to `renderColorBlobs()`

### Existing Systems Integration

| System | File | Integration Point |
|--------|------|-------------------|
| Projectile creation | `src/entities.lua:339-372` | `fireProjectile()` - seed already exists |
| Projectile drawing | `src/drawing.lua:64-80` | Transform single entity → cluster entities |
| Blob rendering | `src/rendering.lua:104-220` | No changes needed - receives entity list |
| Config | `src/config.lua` | Add cluster parameters |

### Files to Modify

1. `src/config.lua` - Add cluster configuration constants
2. `src/drawing.lua:64-80` - Generate cluster entities instead of single entity

### Technical Decisions

1. **Cluster composition:** 1 core (100% radius) + 2-3 satellites (35-45% radius)
2. **Satellite positioning:** Trail behind velocity in local space, then rotate to world
3. **Offset pattern:** Core at origin, satellites at ~(-0.4 to -0.6, ±0.15 to ±0.25) in normalized local space
4. **Variation:** Use existing `p.seed` to randomize satellite count (2 or 3) and exact offsets
5. **Rotation:** `atan2(vy, vx)` determines cluster orientation
6. **Size scaling:** Satellite offsets scale with `baseRadius` to maintain proportions

## Implementation Plan

### Tasks

- [ ] Task 1: Add cluster config constants to `src/config.lua`
  ```lua
  Config.PROJECTILE_CLUSTER_CORE_SCALE = 0.7      -- Core is 70% of base radius
  Config.PROJECTILE_CLUSTER_SAT_SCALE = 0.4       -- Satellites are 40% of base radius
  Config.PROJECTILE_CLUSTER_SAT_DIST = 0.5        -- Satellite distance (multiplier of base radius)
  Config.PROJECTILE_CLUSTER_SAT_SPREAD = 0.25     -- Lateral spread (multiplier of base radius)
  ```

- [ ] Task 2: Create cluster generation helper function in `src/drawing.lua`
  ```lua
  -- Generate cluster entities for a single projectile
  local function generateProjectileCluster(p, angle, stretch)
      local entities = {}
      local cos_a, sin_a = math.cos(angle), math.sin(angle)

      -- Use seed for variation
      local rng = p.seed / 1000  -- 0-1 range
      local satCount = (rng > 0.5) and 3 or 2

      -- Core circle
      table.insert(entities, {
          x = p.x,
          y = p.y,
          baseRadius = p.baseRadius * Config.PROJECTILE_CLUSTER_CORE_SCALE,
          radiusWobble = p.radiusWobble * 0.7,
          -- ... deform params
      })

      -- Trailing satellites (in local space, rotated to world)
      for i = 1, satCount do
          local localX = -Config.PROJECTILE_CLUSTER_SAT_DIST * p.baseRadius
          local localY = (i - 1.5) * Config.PROJECTILE_CLUSTER_SAT_SPREAD * p.baseRadius * 2
          -- Add seed-based variation
          localX = localX + (rng - 0.5) * p.baseRadius * 0.2
          localY = localY + ((rng * i) % 1 - 0.5) * p.baseRadius * 0.15

          -- Rotate to world space
          local worldX = p.x + localX * cos_a - localY * sin_a
          local worldY = p.y + localX * sin_a + localY * cos_a

          table.insert(entities, {
              x = worldX,
              y = worldY,
              baseRadius = p.baseRadius * Config.PROJECTILE_CLUSTER_SAT_SCALE,
              radiusWobble = 0,
              -- ... deform params
          })
      end

      return entities
  end
  ```

- [ ] Task 3: Modify projectile collection loop in `src/drawing.lua:64-80`
  - Replace single entity insertion with cluster generation call
  - Pass velocity angle and stretch to cluster function
  - Insert all cluster entities into `splatterEntities`

- [ ] Task 4: Visual tuning pass
  - Adjust `CLUSTER_CORE_SCALE`, `CLUSTER_SAT_SCALE`, `CLUSTER_SAT_DIST`, `CLUSTER_SAT_SPREAD`
  - Test at various projectile counts (1, 5, 20 simultaneous)
  - Verify "fast and snappy" feel is achieved

### Performance Considerations

- **Draw call increase:** 3-4x per projectile (was 1, now 3-4 circles)
- **At 20 projectiles:** 60-80 soft circles vs previous 20
- **Impact:** Negligible at 320x180 internal resolution
- **Threshold shader:** Already optimized, handles additional circles fine
- **Memory:** No additional allocations (reusing entity table pattern)

### Acceptance Criteria

- [ ] AC 1: Given a projectile is fired, when it renders, then it appears as a cluster of 3-4 overlapping circles (not a single ellipse)
- [ ] AC 2: Given a projectile is moving, when observed, then the satellite circles trail BEHIND the velocity direction (creating forward momentum feel)
- [ ] AC 3: Given multiple projectiles are fired, when comparing them, then each has slightly different satellite arrangements (seed variation)
- [ ] AC 4: Given the projectile cluster, when the projectile changes direction, then the cluster rotates to match new velocity
- [ ] AC 5: Given 20+ projectiles on screen, when observing FPS, then performance remains at 60fps (no regression)
- [ ] AC 6: Given the new cluster rendering, when playing, then projectiles feel "fast and snappy" not "heavy and drippy"

## Additional Context

### Dependencies

- No external dependencies
- Uses existing rendering pipeline unchanged
- Threshold shader with noise still applies to each cluster circle

### Testing Strategy

- **Visual testing:** Side-by-side comparison (before/after screenshots)
- **Feel testing:** Fire projectiles, assess if they feel like "flung paint"
- **Direction testing:** Move mouse in circles while firing, verify cluster rotates smoothly
- **Performance testing:** Spawn max projectiles, verify 60fps maintained
- **Variation testing:** Fire many projectiles, verify visual variety from seeds

### Notes

**Cluster visual reference:**
```
Velocity direction: →

     ○         (satellite, trails behind)
   ●           (core, leads)
     ○         (satellite, trails behind)
```

**Future enhancements (out of scope):**
- Different cluster patterns for different projectile types
- Cluster "spread" animation on fire (satellites start tight, spread out)
- Impact cluster (splatter pattern on hit)

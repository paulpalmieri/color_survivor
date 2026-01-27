# Rendering System

Color Survivor uses a **soft-circle threshold** pipeline to create an organic, blobby, low-res pixel aesthetic. Entities look like paint, cells, or amoebas that visually merge when close together.

## Pipeline Overview

```
1. Game logic updates entity positions, wobble, deformation
2. For each color (red, cyan, yellow):
   a. Clear that color's buffer canvas
   b. Stamp soft gradient circles (additive blend) for every entity of that color
   c. Apply threshold shader → solid color where brightness exceeds cutoff
   d. Draw result onto the main game canvas
3. Scale the 320×180 game canvas up to the window with nearest-neighbor filtering
```

Everything renders at **320×180** then scales to the window. The `nearest` filter gives the chunky pixel look.

## Core Concept: Soft Circle + Threshold

Each entity is drawn as a **radial gradient circle** (bright white center fading to black at edges) onto a grayscale buffer using **additive blending**. When two entities are close, their gradients overlap and the brightness accumulates.

A **threshold shader** then reads this buffer: any pixel brighter than the threshold becomes solid color, everything else is transparent. This is what creates the merging blob effect — two nearby circles produce a combined brightness field that passes the threshold in the gap between them, forming a single connected shape.

### The Soft Circle Texture

Generated once at startup as a 64×64 image. Each pixel stores a brightness value based on distance from center:

```
value = max(0, 1 - distance_from_center)
value = smoothstep(value)   -- S-curve: value² × (3 - 2×value)
```

The smoothstep falloff is gentler than a simple quadratic. It keeps the center brighter for longer (so entities stay visible at their intended size) while still providing soft edges that merge nicely.

### The Threshold Shader (`threshold.glsl`)

```glsl
extern float threshold;
extern vec3 blobColor;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    float value = Texel(tex, tc).r;
    if (value > threshold) {
        float edge = smoothstep(threshold, threshold + 0.1, value);
        vec3 finalColor = blobColor * (0.8 + 0.2 * edge);
        return vec4(finalColor, 1.0);
    }
    return vec4(0.0);
}
```

- Pixels below threshold → fully transparent
- Pixels above threshold → solid `blobColor`
- The `smoothstep` edge factor darkens pixels near the threshold boundary (0.8× brightness) and lightens pixels well above it (1.0× brightness), giving subtle edge definition without outlines

## Customizable Constants

| Constant | Default | Effect |
|---|---|---|
| `SOFT_CIRCLE_SIZE` | `64` | Resolution of the gradient texture. Higher = smoother gradients but diminishing returns at low-res |
| `BLOB_THRESHOLD` | `0.35` | **Key tuning value.** Lower = blobs appear larger and merge more easily. Higher = blobs shrink and need to be closer to merge. Range: 0.1–0.8 |
| `BLOB_INTENSITY` | `1.0` | Brightness of each soft circle center. Higher = larger visible blob per entity. Also affects how far apart entities can be and still merge |
| `GAME_WIDTH/HEIGHT` | `320×180` | Internal render resolution. Smaller = chunkier pixels. Larger = smoother but less retro |

### How threshold and intensity interact

The visible radius of a single entity is determined by where `intensity × falloff(distance) > threshold`. With current values (intensity=1.0, threshold=0.35, smoothstep falloff), a single entity appears at roughly 70–80% of its defined radius. Two entities merge when the sum of their falloffs exceeds the threshold in the gap between them — at current values this happens when entities are about 1.5× their radius apart.

**Tuning guide:**
- Blobs too small → lower `BLOB_THRESHOLD` or raise `BLOB_INTENSITY`
- Blobs merging too aggressively → raise `BLOB_THRESHOLD`
- Blobs not merging enough → lower `BLOB_THRESHOLD` or raise `BLOB_INTENSITY`

## Color Buffers

One canvas per color (`colorBuffers["red"]`, `colorBuffers["cyan"]`, `colorBuffers["yellow"]`), all at game resolution. Reused every frame. Entities are grouped by color so that only same-color entities merge visually. The player renders as a separate pass on top.

## Organic Animation Layers

### Multi-Layer Wobble

Every entity (player, enemies, particles) has multiple sine wave oscillators at different frequencies. These sum together to produce an organic, non-repeating radius variation:

```lua
entity.wobbles = {
    {phase, speed = 2.3, amount = 1.2},  -- slow, large
    {phase, speed = 3.7, amount = 0.8},  -- medium
    {phase, speed = 5.1, amount = 0.5},  -- fast, subtle
}
```

Each wobble's `phase` advances by `speed × dt` each frame. The combined effect is a radius that breathes irregularly.

**Customizable per-wobble:** `speed` (frequency), `amount` (amplitude in pixels).

### Molecular Sub-Blobs (Organelles)

For entities larger than 8px radius (enemies and player, not projectiles), 4 additional soft circles are drawn orbiting inside the main blob. These create internal structure visible through the threshold — the blob looks like it contains organelles.

```
orbit angle = evenly spaced + membranePhase × (0.8 + i×0.1)
orbit distance = 35% of radius, oscillating ±15%
organelle size = 45% of parent radius, pulsing ±10%
organelle intensity = 70% of parent, varying ±15%
```

Because these sub-blobs are drawn additively on the same buffer, they merge with the main blob and with each other, creating shifting internal shapes.

**Customizable:** `numOrganelles` (count), orbit distance ratio, organelle size ratio, and the various oscillation multipliers in `renderColorBlobs`.

### Membrane Wobble Points (currently disabled)

6 small soft circles positioned around the perimeter of larger entities. They create bumps and pseudopod-like protrusions. Currently commented out — uncomment the `--[[` block in `renderColorBlobs` to re-enable.

**Customizable:** `numMembranePoints`, `mDist` ratio, `mRadius` ratio, `mIntensity` ratio.

### Player-Specific Organic Effects

The player has additional animation layers beyond what enemies get:

- **Asymmetric shape drift** — the blob is never perfectly round. `asymX`/`asymY` slowly drift using sine waves + random walk, making the shape morph over time
- **Brownian jitter** — tiny random position offsets that snap to new targets a few times per second and lerp smoothly, creating micro-movement
- **Internal pulse** — a slow sine-wave "heartbeat" that adds/subtracts from the radius
- **Intensity flicker** — subtle random brightness variation

All of these feed into the player entity data that gets passed to `renderColorBlobs`.

## Velocity Squash/Stretch

All entities stretch in their movement direction and squash perpendicular:

```lua
stretchFactor = 1 + min(speed / 200, 0.3)   -- cap at 30%
stretchX = stretchFactor
stretchY = 1 / stretchFactor
angle = atan2(vy, vx)
```

The soft circle texture is drawn with non-uniform scale and rotation to achieve this. The stretch is volume-preserving (`stretchX × stretchY ≈ 1`).

**Customizable:** the `200` divisor controls sensitivity (lower = stretches at lower speeds), the `0.3` cap limits maximum elongation.

### Player Direction-Change Deformation

The player has additional spring-physics deformation for direction changes:

1. **Smooth angle interpolation** — stretch angle lerps toward velocity direction instead of snapping. Rate: `angleDiff × dt × 10`
2. **Direction change detection** — dot product of current vs previous velocity detects turns. A dot product below 0.7 (>45° change) triggers a squish impulse
3. **Spring physics** — the impulse feeds a damped spring (`stiffness=180, damping=12`) that produces bouncy overshoot, making the blob compress on direction change and spring back

**Customizable:**
- Direction change sensitivity: the `0.7` dot product threshold
- Spring feel: `stiffness` (higher = snappier bounce), `damping` (higher = less oscillation)
- Impulse strength: the `0.3` and `15` multipliers on the impulse

## Particle Rendering

Particles go through the same soft-circle threshold pipeline grouped by color, so they merge with enemies/projectiles of the same color as they fly outward. Each particle has:

- **Organic wobble** — fast sine wave on radius
- **Tumble rotation** — random spin speed, giving tumbling stretched shapes
- **Velocity stretch** — stretched along movement with `customAngle` set to the tumble angle
- **Shrink over lifetime** — radius and intensity fade with `life/maxLife`

## Bullet Hit Effects

Both effect types work through the blob system:

**Wrong color (absorbed):** bullet enters `dying` state, its `baseRadius` shrinks to 0 over 0.1s. The enemy gains a `pulseTimer` that temporarily adds to its radius — visually the bullet shrinks into the enemy as it swells.

**Matching color (pierce):** bullet continues with 5% speed reduction. Enemy gets `radiusOffset = -3` (flinch inward) that recovers over 0.1s via `radiusRecovery`. 4 splatter particles spawn at the hit point.

## Render Order

1. Clear game canvas to cream background
2. Draw XP shards (simple circles, not part of blob system)
3. Draw dasher telegraph lines
4. Draw all blobs via `drawBlobs()`:
   - For each color: enemies + projectiles + particles → threshold → game canvas
   - Player → threshold → game canvas (on top)
5. Draw player cooldown arc indicator
6. Scale game canvas to window
7. Draw UI overlay (at window resolution)

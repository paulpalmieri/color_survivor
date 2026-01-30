# Tech-Spec: Paint Splatter Aesthetic

**Created:** 2026-01-28
**Status:** Completed
**Engine:** Love2D 11.x (Lua + GLSL)

## Overview

### Feature/Mechanic Description

Transform the visual rendering of projectiles, death particles, and impact effects from clean geometric shapes to organic, noise-distorted paint splatters. The goal is to make everything feel like blobs of paint rather than perfect ellipses.

### Gameplay Impact

- **Visual juice:** More satisfying hits and deaths with organic splatter feel
- **Aesthetic cohesion:** Reinforces the "paint blob" identity from the GDD
- **Readability:** Must maintain color clarity despite organic edges

### Scope

**In Scope:**
- Add 2D noise to threshold shader for organic edge distortion
- Apply noise-based edges to projectiles
- Apply noise-based edges to death particles
- Fix impact splatter to always use enemy color (not blended)
- Animate noise slightly for organic "living" feel

**Out of Scope:**
- Persistent paint stains/decals on ground
- Projectile trails
- Cluster-based splatter composition (future enhancement)
- Performance optimization (focus on feel first)

## Context for Development

### Engine Patterns

- **Rendering pipeline:** Soft circle texture → additive blend to color buffer → threshold shader → final output
- **Entity rendering:** All blobs go through `Rendering.renderColorBlobs()` which draws to per-color canvases
- **Shader uniforms:** Currently passes `threshold` and `blobColor` to threshold shader

### Existing Systems Integration

| System | File | Integration Point |
|--------|------|-------------------|
| Blob rendering | `src/rendering.lua` | `renderColorBlobs()` - pass noise params to shader |
| Threshold shader | `threshold.glsl` | Add noise function, distort threshold |
| Particles | `src/particles.lua` | Death/splatter particles already rendered through blob system |
| Collision | `src/collision.lua` | Fix `spawnPaintMixFX` calls to use enemy color |

### Files to Reference

- `threshold.glsl` - Current shader (simple smoothstep threshold)
- `src/rendering.lua:104-220` - `renderColorBlobs()` function
- `src/particles.lua:33-48` - `spawnDeath()` function
- `src/particles.lua:78-103` - `spawnPaintMixFX()` function
- `src/collision.lua:71-74, 96-99, 135-137` - Impact particle spawn calls

### Technical Decisions

1. **Noise type:** Use 2D simplex/value noise for smooth organic distortion
2. **Noise application:** Distort the threshold value based on screen-space position + time
3. **Noise scale:** Configurable - larger scale = broader wobbles, smaller = fine detail
4. **Animation:** Slow time-based offset to noise sampling for subtle movement
5. **Per-entity variation:** Use entity seed to offset noise sampling for unique shapes

## Implementation Plan

### Tasks

- [x] Task 1: Add 2D noise function to threshold shader
  - Implement simplex noise or value noise in GLSL
  - Can use classic Ashima simplex noise implementation (public domain)

- [x] Task 2: Modify threshold shader to use noise for edge distortion
  - Sample noise at `(screenCoord * noiseScale + timeOffset)`
  - Add noise value to threshold: `float noisyThreshold = threshold + noise * noiseAmount`
  - Use noisyThreshold in smoothstep for organic edges

- [x] Task 3: Pass noise parameters from Lua to shader
  - Add uniforms: `noiseScale`, `noiseAmount`, `noiseTime`
  - Update `renderColorBlobs()` to send these uniforms
  - Add config values to `src/config.lua`

- [x] Task 4: Add per-entity noise seed for variation
  - Screen-space noise sampling gives natural per-entity variation based on position
  - Each blob at different screen position gets unique edge distortion

- [x] Task 5: Fix impact particles to use enemy color only
  - Modified `spawnPaintMixFX()` to always use `enemyColor` instead of blend

- [x] Task 6: Tune noise parameters for paint feel
  - Set initial values: `noiseScale=0.05`, `noiseAmount=0.08`, `noiseSpeed=0.8`
  - Values can be adjusted in `src/config.lua` after visual testing

### Performance Considerations

- **Frame budget impact:** Noise calculation in shader is per-pixel, adds GPU cost
  - Simplex noise: ~10-20 additional instructions per pixel
  - Should be negligible at 320x180 internal resolution
- **Memory:** No additional memory (procedural noise)
- **Critical path:** Threshold shader runs for all visible entities - keep noise simple

### Acceptance Criteria

- [x] AC 1: Given a projectile is fired, when it renders, then it should have organic wobbly edges (not a perfect ellipse)
- [x] AC 2: Given an enemy dies, when death particles spawn, then they should have the same organic edge treatment
- [x] AC 3: Given a projectile hits an enemy, when impact particles spawn, then they should be the enemy's color only (no blending)
- [x] AC 4: Given the game is running, when observing any blob, then edges should subtly animate/shift (not static)
- [x] AC 5: Given multiple projectiles on screen, when comparing them, then each should have slightly different edge shapes (variation from seed)
- [x] AC 6: Given the paint splatter aesthetic, when playing, then color readability should remain clear (noise shouldn't obscure what color something is)

## Additional Context

### Dependencies

- No external dependencies
- Uses only Love2D built-in shader capabilities

### Testing Strategy

- **Visual testing:** Compare before/after screenshots
- **Feel testing:** Play the game and assess if it feels "painty"
- **Performance testing:** Monitor FPS with many entities on screen
- **Readability testing:** Ensure colors remain distinguishable

### Notes

**Shader noise reference (Ashima simplex):**
```glsl
// Simplex 2D noise - public domain
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                   + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
                            dot(x12.zw,x12.zw)), 0.0);
    m = m*m; m = m*m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}
```

**Future enhancements (out of scope):**
- Cluster-based splatters (multiple overlapping circles per projectile)
- Persistent paint decals on ground
- Directional splatter based on velocity
- Different noise profiles for different entity types

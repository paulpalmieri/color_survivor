# Tech-Spec: High-Resolution Rendering Migration

**Created:** 2026-01-28
**Status:** Completed
**Engine:** Love2D (Lua)

## Overview

### Feature/Mechanic Description

Remove the 320x180 low-resolution canvas constraint and render the game at native window/display resolution. The soft-circle blob rendering system remains unchanged - it simply operates at higher resolution, allowing the organic paint blob aesthetic to fully shine.

### Gameplay Impact

- **Visual clarity**: Blobs render with smooth edges instead of chunky pixels
- **Readability in chaos**: Easier to parse 100+ enemies during intense moments
- **Unique identity**: Moves away from saturated pixel-art survivors market toward distinctive "living paint" aesthetic

### Scope

**In Scope:**
- Remove 320x180 game canvas, render directly to window
- Scale all game constants (radii, speeds, distances) to new resolution
- Update camera system for native resolution
- Update coordinate conversion (screen-to-game, mouse input)
- Adjust soft-circle texture size for quality at higher res
- Update UI positioning for native resolution

**Out of Scope:**
- Shader modifications (threshold shader works at any resolution)
- Gameplay balance changes
- New visual effects
- Resolution options menu (future enhancement)

## Context for Development

### Engine Patterns

The game uses a multi-pass blob rendering pipeline:
1. Soft-circle textures drawn to per-color buffers with additive blending
2. Threshold shader applied to create solid blob shapes
3. Final composite to screen

This pipeline is resolution-agnostic - it will work identically at any resolution.

### Existing Systems Integration

| System | Impact |
|--------|--------|
| Blob rendering | Works as-is, just larger canvas |
| Camera | Needs updated bounds and follow logic |
| Input | Mouse coordinate conversion simplified |
| UI | Positions change from game-canvas to window coords |
| Collision | No change (world-space logic) |

### Files to Reference

- `main.lua` - All game code, constants, rendering pipeline
- `conf.lua` - Love2D window configuration
- `threshold.glsl` - Blob threshold shader (no changes needed)

### Technical Decisions

1. **Target resolution**: 1920x1080 as reference, scale proportionally to window size
2. **Scale factor**: ~6x from old 320x180 (1920/320 = 6)
3. **Maintain aspect ratio**: 16:9, letterbox if window differs
4. **Soft-circle texture**: Increase from 64px to 256px for quality

## Implementation Plan

### Tasks

- [x] **Task 1: Update constants and scale factors**
  - Define new base resolution (1920x1080) or use dynamic window size
  - Create SCALE_FACTOR constant (6x from original values)
  - Scale all radius constants: PLAYER_RADIUS, ENEMY_RADIUS, PROJECTILE_RADIUS, etc.
  - Scale all speed constants: PLAYER_MAX_SPEED, PROJECTILE_SPEED, etc.
  - Scale distance constants: XP_MAGNET_RANGE, SPAWN_MARGIN, etc.

- [x] **Task 2: Remove game canvas indirection**
  - Remove `gameCanvas` creation and usage
  - Remove the draw-to-canvas-then-scale pattern
  - Draw directly to the screen with native coordinates
  - Keep per-color buffers but at window resolution

- [x] **Task 3: Update camera system**
  - Scale ARENA_WIDTH/HEIGHT (or redefine as larger play area)
  - Update camera bounds and follow logic
  - Remove canvas-based coordinate offsets

- [x] **Task 4: Update input handling**
  - Simplify `screenToGame()` - may become identity or simple offset
  - Update mouse position handling for direct coordinates

- [x] **Task 5: Update soft-circle texture**
  - Increase SOFT_CIRCLE_SIZE from 64 to 256 (or dynamic based on resolution)
  - Regenerate soft-circle image data

- [x] **Task 6: Update UI drawing**
  - Reposition all UI elements for new resolution
  - Scale font sizes appropriately
  - Update HP bar, XP bar, dash indicators, timer positions

- [x] **Task 7: Update conf.lua**
  - Set new default window dimensions
  - Enable resizable window (optional)

### Performance Considerations

- **Frame budget impact**: Minimal - rendering same number of blobs, just larger buffers
- **Memory**: Color buffers will be larger (1920x1080 vs 320x180 = 36x more pixels per buffer)
- **GPU**: Modern GPUs handle this trivially; Love2D's batching remains efficient
- **Critical path**: Blob rendering is already GPU-bound; resolution change doesn't affect CPU logic

### Acceptance Criteria

- [x] AC1: Game renders at native window resolution without pixelation
- [x] AC2: All blob entities (player, enemies, projectiles, particles) render with smooth edges
- [x] AC3: Gameplay feel identical - same relative speeds, sizes, and distances
- [x] AC4: Camera follows player correctly within scaled arena bounds
- [x] AC5: Mouse aiming works correctly at new resolution
- [x] AC6: UI elements positioned correctly and readable
- [ ] AC7: Maintains 60fps with 100+ entities on screen (requires performance testing)
- [x] AC8: Window can be resized and game scales appropriately (letterboxed)

## Additional Context

### Dependencies

- None - this is a foundational change

### Testing Strategy

- Visual inspection: Blobs should look smooth and organic
- Gameplay feel test: Movement, shooting, collision should feel identical
- Performance test: Spawn 100+ enemies, verify 60fps maintained
- Resolution test: Try different window sizes, verify letterboxing works

### Notes

- This change enables the color wheel UI to render in the same visual language as the game
- Consider keeping the old 320x180 mode as a "retro mode" toggle (post-MVP)
- The cream canvas background and color palette remain unchanged - they define the aesthetic, not the resolution

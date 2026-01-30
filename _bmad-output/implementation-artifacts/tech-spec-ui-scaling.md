# Tech-Spec: UI Scaling & Color Wheel Improvements

**Created:** 2026-01-28
**Status:** Completed
**Engine:** LÖVE 2D (Lua)

## Overview

### Feature/Mechanic Description

Fix UI element sizing across all supported resolutions (1080p, 1440p, 4K) to ensure consistent game experience. Relocate color wheel to bottom-right with organic shadow border, and fix various UI sizing/positioning issues.

### Gameplay Impact

- Players can clearly see health, color state, and dash charges at a glance
- Reduced eye strain and improved peripheral readability
- New players can see control hints without clipping
- Level-up screen is readable without text overlap

### Scope

**In Scope:**
- Color wheel: relocate to bottom-right, add shadow border, scale with resolution
- Health bar: increase size
- Dash indicators: increase size
- Level Up screen: fix text overlap
- Tutorial text: fix bottom clipping
- All UI scales consistently across 1080p/1440p/4K

**Out of Scope:**
- Color wheel near-player floating indicator (future consideration)
- Animated pulse/glow effects on color switch (polish for later)
- UI sound effects

## Context for Development

### Engine Patterns

- LÖVE 2D with module-based architecture
- Soft-circle threshold blob rendering via shaders
- UI scaling uses `uiScale = winH / 1080` pattern
- Canvases for off-screen rendering (color buffers, color wheel masks)

### Existing Systems Integration

- `src/ui.lua` - All HUD drawing, level-up screen, death screen
- `src/config.lua` - `COLOR_WHEEL` constants, base dimensions
- `src/rendering.lua` - Color wheel canvas creation, blob rendering
- `main.lua` - `love.resize()` callback

### Files to Reference

| File | Purpose |
|------|---------|
| `src/ui.lua:197-301` | `UI.draw()` - main HUD rendering |
| `src/ui.lua:79-195` | `drawColorWheel()` - color wheel rendering |
| `src/ui.lua:303-343` | `UI.drawLevelUpScreen()` |
| `src/config.lua:87-92` | `COLOR_WHEEL` config values |
| `src/rendering.lua:64-71` | Color wheel canvas creation |

### Technical Decisions

1. **Color wheel scaling:** Recreate canvases on resize rather than fixed large canvas (proper scaling, no memory waste)
2. **Shadow border:** Use dark blob layer underneath RGB blobs (reuses existing threshold system)
3. **Position:** Bottom-right, grouped with dash indicators
4. **Base values:** Increase all UI element base sizes before scaling

## Implementation Plan

### Tasks

- [x] Task 1: Create `Rendering.createColorWheelBuffers(uiScale)` function
  - Extract color wheel canvas creation from `Rendering.init()`
  - Accept `uiScale` parameter to size canvases appropriately
  - Base canvas size: `300 * uiScale` (up from fixed 200)
  - Scale `blobRadius` and `orbitRadius` with uiScale

- [x] Task 2: Call color wheel buffer creation on resize
  - Add call to `Rendering.createColorWheelBuffers()` in `love.resize()`
  - Update `Rendering.init()` to call the new function

- [x] Task 3: Update `drawColorWheel()` for new position and shadow layer
  - Move position from top-right to bottom-right
  - Add shadow blob layer (draw dark blobs ~15% larger behind RGB blobs)
  - Update `uiScale` usage to match new canvas sizing

- [x] Task 4: Increase health bar dimensions
  - Height: `24 * uiScale` → `40 * uiScale`
  - Ensure font fits within bar

- [x] Task 5: Increase dash indicator dimensions
  - Height: `8 * uiScale` → `16 * uiScale`
  - Width: `40 * uiScale` → `50 * uiScale`

- [x] Task 6: Fix Level Up screen text overlap
  - Use `font:getHeight()` to calculate positions dynamically
  - Add proper spacing between "LEVEL UP!" and "Choose an upgrade:"

- [x] Task 7: Fix tutorial text clipping
  - Increase bottom margin: `winH - 60 * uiScale` → `winH - 80 * uiScale`
  - Verify visibility at minimum supported resolution

- [x] Task 8: Update `Config.COLOR_WHEEL` values
  - Remove fixed pixel values, use as base multipliers
  - `blobRadius`: 40 → 50 (base, scaled by uiScale)
  - `orbitRadius`: 16 → 24 (base, scaled by uiScale)
  - `canvasSize`: dynamic based on uiScale

### Performance Considerations

- **Frame budget impact:** Minimal - shadow blobs use same rendering path as existing blobs
- **Memory considerations:** Canvas recreation on resize is infrequent, acceptable cost
- **Critical path notes:** Color wheel rendering is already optimized; shadow layer adds ~3 additional soft circles per frame (negligible)

### Acceptance Criteria

- [x] AC 1: Given 1080p resolution, when viewing HUD, then health bar is clearly readable with HP text visible inside
- [x] AC 2: Given 1440p or 4K resolution, when viewing HUD, then all UI elements maintain same proportional size as 1080p
- [x] AC 3: Given any supported resolution, when viewing color wheel, then it appears in bottom-right with visible dark shadow border
- [x] AC 4: Given any supported resolution, when viewing dash indicators, then they are clearly visible below color wheel
- [x] AC 5: Given level up triggered, when viewing level up screen, then "LEVEL UP!" and "Choose an upgrade:" text do not overlap
- [x] AC 6: Given game start (first 12 seconds), when viewing tutorial text, then control hints are fully visible (not clipped)
- [x] AC 7: Given window resize, when resolution changes, then color wheel canvases recreate at appropriate size without visual artifacts

## Additional Context

### Dependencies

- No external dependencies
- Requires existing threshold shader system

### Testing Strategy

- Manual testing at 1280x720, 1920x1080, 2560x1440, 3840x2160
- Verify color wheel shadow blobs merge correctly via threshold shader
- Test window resize during gameplay
- Verify Level Up and Death screens at all resolutions

### Notes

- The color wheel shadow uses the same blob threshold system as gameplay entities - this maintains visual consistency
- Future polish: consider subtle pulse animation on color switch for the shadow layer
- Bottom-right placement keeps "ability status" grouped (color wheel + dash charges)

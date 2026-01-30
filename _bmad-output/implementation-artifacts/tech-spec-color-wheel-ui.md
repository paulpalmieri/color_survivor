# Tech-Spec: Rotating Blob Color Wheel UI

**Created:** 2026-01-28
**Status:** Completed
**Engine:** Love2D (Lua)
**Depends On:** tech-spec-high-res-rendering.md

## Overview

### Feature/Mechanic Description

A Venn diagram-style color wheel UI made of three overlapping paint blobs (Red, Yellow, Blue). The wheel rotates when the player switches colors, always positioning the current color at the top. The overlap zones naturally display secondary colors (Purple, Orange, Green), teaching the pierce+mix system through visual design.

### Gameplay Impact

- **Teaches mechanics visually**: Players see color mixing relationships without tutorials
- **Clear current state**: Current color always at top, instantly readable
- **Anticipation**: Shows next colors in the cycle, enabling strategic planning
- **Cohesive aesthetic**: UI matches game's organic blob style

### Scope

**In Scope:**
- Three overlapping blob circles arranged in triangular formation
- Rotation animation when color switches (current → top position)
- Organic wobble animation to feel alive
- Secondary color display in overlap zones
- Integration with existing color switch system
- Cooldown visualization (subtle desaturation or similar)

**Out of Scope:**
- Clickable/interactive elements (informational only)
- Secondary color selection by player
- Sound effects (separate task)
- Tutorial tooltips

## Context for Development

### Engine Patterns

The game uses soft-circle threshold rendering for blobs. However, per party mode discussion, the UI should render at **native resolution with styled circles** rather than through the threshold shader pipeline. This ensures:
- Crisp readability in peripheral vision during combat
- Consistent rendering regardless of game canvas state
- Separation of UI and game world rendering

### Existing Systems Integration

| System | Integration Point |
|--------|-------------------|
| Color switching | Read `player.color` and `player.colorCooldown` |
| Animation | Use existing `colorWheelAnim` state table |
| UI layer | Render in `drawUI()` function after game canvas |
| Color palette | Use existing `COLORS` and `COLOR_ORDER` tables |

### Files to Reference

- `main.lua:175-178` - Existing `colorWheelAnim` state
- `main.lua:576-608` - `switchColor()` and `setColorDirect()` functions
- `main.lua:1809-1908` - Current UI drawing code to replace
- `main.lua:24-52` - Color constants and mixing rules

### Technical Decisions

1. **Rendering approach**: Native Love2D circles with soft edges (not threshold shader)
2. **Rotation model**: Wheel rotates so current color is always at 12 o'clock
3. **Animation timing**: ~150-200ms rotation with eased interpolation
4. **Blob overlap**: ~30% overlap between adjacent circles to show secondaries
5. **Wobble**: Subtle sine-based radius variation (2-3% amplitude)
6. **Position**: Top-right corner, replacing current "Next" indicator

## Implementation Plan

### Tasks

- [x] **Task 1: Define color wheel geometry**
  - Calculate blob positions in triangular arrangement
  - Define overlap percentage (affects secondary visibility)
  - Set base radius for each blob
  - Position the widget in top-right corner
  ```lua
  -- Example geometry (adjust for actual resolution)
  COLOR_WHEEL = {
      centerX = screenWidth - 80,
      centerY = 80,
      blobRadius = 28,
      orbitRadius = 20,  -- distance from center to blob center
      overlapPercent = 0.3
  }
  ```

- [x] **Task 2: Implement rotation state tracking**
  - Track target rotation angle (0°, 120°, 240° for R/Y/B at top)
  - Track current animated rotation angle
  - Update `colorWheelAnim` to use rotation instead of offset
  ```lua
  colorWheelAnim = {
      currentAngle = 0,      -- current displayed rotation
      targetAngle = 0,       -- where we're rotating to
      angularVelocity = 0,   -- for spring physics (optional)
  }
  ```

- [x] **Task 3: Implement rotation animation**
  - On color switch, calculate new target angle
  - Animate current angle toward target using easing
  - Handle wrap-around (359° → 0°) smoothly
  - Target duration: 150-200ms
  ```lua
  -- In update:
  local angleDiff = targetAngle - currentAngle
  -- Normalize to shortest path
  if angleDiff > math.pi then angleDiff = angleDiff - math.pi * 2 end
  if angleDiff < -math.pi then angleDiff = angleDiff + math.pi * 2 end
  currentAngle = currentAngle + angleDiff * dt * 12  -- spring constant
  ```

- [x] **Task 4: Implement organic wobble**
  - Add per-blob wobble phase and speed
  - Subtle radius variation (2-3%)
  - Slight position jitter for "living" feel
  ```lua
  local wobble = math.sin(time * 3 + blobIndex) * (blobRadius * 0.03)
  ```

- [x] **Task 5: Draw primary color blobs**
  - Draw three circles at rotated positions
  - Current color (at top) slightly larger/brighter
  - Use soft-edge rendering (love.graphics circle with smooth edges)
  - Apply wobble to each blob

- [x] **Task 6: Draw secondary color overlaps**
  - Calculate overlap regions between adjacent blobs
  - Draw secondary colors in overlap zones
  - Colors: Purple (R+B), Orange (R+Y), Green (Y+B)
  - Use stencil or blend modes for clean overlap rendering

- [x] **Task 7: Implement cooldown visualization**
  - When `player.colorCooldown > 0`, show visual feedback
  - Option A: Desaturate non-current blobs
  - Option B: Subtle darkening overlay
  - Option C: Ring/arc progress indicator around current blob

- [x] **Task 8: Remove old "Next" color UI**
  - Delete the current sliding "Next" indicator code
  - Clean up unused animation state if any

- [x] **Task 9: Polish and tuning**
  - Adjust sizes for readability at different window sizes
  - Fine-tune wobble parameters
  - Fine-tune rotation animation feel
  - Test in combat scenarios for peripheral readability

### Performance Considerations

- **Frame budget impact**: Negligible - 3-6 circles per frame
- **Memory**: None significant
- **Critical path**: UI draws after game canvas, doesn't affect gameplay loop

### Acceptance Criteria

- [x] AC1: Three overlapping blobs visible in top-right corner
- [x] AC2: Current player color blob positioned at top (12 o'clock)
- [x] AC3: Wheel rotates smoothly when player switches color (R→Y→B cycle)
- [x] AC4: Secondary colors visible in overlap zones (Purple, Orange, Green)
- [x] AC5: Subtle organic wobble animation makes wheel feel alive
- [x] AC6: Rotation completes in ~150-200ms with eased motion
- [x] AC7: Cooldown state is visually communicated
- [x] AC8: Readable during intense gameplay (peripheral vision test)
- [x] AC9: Old "Next" indicator removed

## Additional Context

### Dependencies

- **High-res rendering migration** should be completed first (or simultaneously)
- Uses existing color constants and player state

### Testing Strategy

- Visual test: Verify rotation direction matches color cycle
- Animation test: Rotation feels snappy, not sluggish
- Readability test: Play a run, can you read current color peripherally?
- Edge case: Rapid color switching (spam right-click) - animation should handle gracefully

### Notes

- The overlap zones teach the pierce+mix mechanic passively - players will see Purple between Red and Blue and understand the relationship
- Consider adding subtle "pulse" when a pierce+mix happens in-game (future enhancement)
- The wheel could potentially show damage numbers or effects when mixing occurs (post-MVP)

### Visual Reference

```
        Static Layout:               After rotation (Y selected):

            ●R●                            ●Y●
           ╱   ╲                          ╱   ╲
         (P)   (O)                      (O)   (G)
           ╲   ╱                          ╲   ╱
          ●B● ●Y●                       ●R● ●B●
             (G)                           (P)

        ● = Primary blob (larger when selected)
        (X) = Secondary color in overlap zone
```

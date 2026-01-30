# Tech Spec: Sound System

**Status:** Ready for Testing
**Date:** 2026-01-28
**Author:** Paul (via quick-dev)

---

## Overview

Implement a sound system for Color Survivor using the existing sound assets. The system should handle sound playback for game events with proper pooling to avoid audio interruption on rapid-fire sounds.

---

## Context

### Available Sound Assets
```
assets/sounds/
  - player_fire_1.mp3
  - player_fire_2.mp3
  - player_fire_3.mp3
  - enemy_hit.mp3
  - enemy_death.mp3
```

### Game Events Requiring Sound
1. **Player fires** - `entities.lua:fireProjectile()` - needs variation (3 fire sounds)
2. **Enemy hit** - `collision.lua` - on damage application
3. **Enemy death** - `collision.lua` - when `e.hp <= 0`
4. **Color switch** - `entities.lua:switchColor/setColorDirect` - (no asset yet, skip for MVP)
5. **Level up** - `entities.lua:updateShards` - (no asset yet, skip for MVP)
6. **Dash** - `entities.lua:triggerDash` - (no asset yet, skip for MVP)
7. **Player hit/death** - `entities.lua:damagePlayer` - (no asset yet, skip for MVP)

---

## Tasks

- [x] **Task 1:** Create `src/sound.lua` module with LOVE2D audio integration
- [x] **Task 2:** Implement sound pooling for rapid-fire sounds (player shooting)
- [x] **Task 3:** Load all available sound assets on init
- [x] **Task 4:** Integrate firing sounds into `entities.lua:fireProjectile()`
- [x] **Task 5:** Integrate enemy hit sound into `collision.lua`
- [x] **Task 6:** Integrate enemy death sound into `collision.lua`
- [ ] **Task 7:** Test and verify all sounds play correctly

---

## Technical Approach

### Sound Module Structure (`src/sound.lua`)

```lua
local Sound = {}

-- Sound pools for rapid-fire sounds
Sound.pools = {}
Sound.sources = {}

function Sound.init()
    -- Load all sounds
    -- Create pools for frequently played sounds
end

function Sound.play(name, options)
    -- Play a sound by name
    -- options: { volume, pitch, pitchVariation }
end

function Sound.playPooled(name, options)
    -- Play from a pool (for rapid sounds like firing)
end

return Sound
```

### Sound Pooling Strategy

For player firing (can happen 5+ times per second):
- Create pool of 8 cloned sources per fire sound
- Cycle through pool on each play
- Prevents audio cutoff when firing rapidly

For enemy hit/death (less frequent):
- Single source per sound is sufficient
- Use `source:clone()` if needed for overlapping

### Integration Points

1. **main.lua** - Add `Sound.init()` in `love.load()`
2. **entities.lua** - Add `Sound.play("fire")` in `fireProjectile()`
3. **collision.lua** - Add `Sound.play("hit")` and `Sound.play("death")`

---

## Acceptance Criteria

- [ ] Sound module loads without errors
- [ ] Player firing plays varied sounds (cycles through fire_1, fire_2, fire_3)
- [ ] Rapid firing doesn't cut off or glitch sounds
- [ ] Enemy hits produce audible feedback
- [ ] Enemy deaths produce satisfying pop sound
- [ ] Game maintains 60fps with sound system active
- [ ] Volume levels are balanced (not too loud/quiet)

---

## Out of Scope

- Music system
- Sound for color switching (no asset)
- Sound for dash (no asset)
- Sound for level up (no asset)
- Sound for player hit/death (no asset)
- Audio settings/volume control UI

---

## Files to Modify

| File | Change |
|------|--------|
| `src/sound.lua` | **NEW** - Sound module |
| `main.lua` | Add Sound require and init |
| `src/entities.lua` | Add fire sound call |
| `src/collision.lua` | Add hit and death sound calls |

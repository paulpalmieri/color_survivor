# Color Survivor - Love2D Prototype Implementation Prompt

## Project Overview

Build a working prototype of a Vampire Survivors-style bullet hell game with a color-switching core mechanic using Love2D and Lua. The goal is to validate whether the color-switching loop feels like meaningful decisions or tedious chores.

**Priority: Get the core loop feeling good before adding progression systems.**

## Tech Stack

- Love2D (latest stable)
- Pure Lua, no external dependencies beyond Love2D
- Single-file or minimal file structure is fine for prototype speed

## Visual Style: Procedural Paint Blobs

Do NOT use placeholder circles or rectangles. Instead, create a distinctive "blobs of paint" aesthetic:

- Use metaballs/marching squares OR shader-based blob rendering for organic shapes
- Enemies and player should look like paint splotches, not geometric primitives
- Colors should be vibrant and distinct (recommend: Magenta/Cyan/Yellow or Red/Green/Blue with high saturation)
- When entities cluster, they should visually feel like paint pooling (even if just proximity-based glow)
- Screen background should be off-white or cream (like canvas/paper)
- Consider subtle "paint splatter" particles on enemy death

## Core Mechanics (Implement in This Order)

### Phase 1: Movement and Color Identity

**Player:**
- WASD or arrow key movement
- Smooth, responsive feel (experiment with slight acceleration/deceleration)
- Player is visually one of three colors at all times
- Color switch via Q/E (cycle) or 1/2/3 (direct select)
- **Color switch has a 1-second cooldown** - this is crucial, display it visually (cooldown ring, desaturation, etc.)
- Player has a health bar (start with 100 HP)

### Phase 2: Shooting and Damage

**Player Shooting:**
- Auto-fire toward nearest enemy OR mouse-aim (pick one, suggest mouse-aim for more control)
- Projectiles inherit player's current color
- Moderate fire rate (maybe 3-4 shots/second)
- Projectiles are small paint drops/splatters

**Damage Rules:**
- Enemies ONLY take damage from projectiles matching their color
- Non-matching projectiles pass through harmlessly (no collision)
- Visual feedback on hit (enemy flashes, screen shake subtle, splatter)
- Visual feedback on "immune" hit (subtle - maybe projectile fizzles with wrong-color particles)

### Phase 3: Enemies

**Basic Enemy Behavior:**
- Enemies drift toward player at varying speeds
- Three enemy types corresponding to three colors
- Enemies deal contact damage to player (10-20 HP)
- Enemies spawn from screen edges in waves

**Spawn Logic:**
- Start simple: random color, random edge position
- Gradually increase spawn rate over time
- Mix colors roughly evenly (don't let one color dominate)

**Enemy Variety (implement at least 2):**
1. **Drifter**: Slow, steady movement toward player. Low HP. Fodder.
2. **Dasher**: Pauses, telegraphs, then dashes toward player position. Medium HP.

### Phase 4: Validate the Feel

At this point, STOP and playtest. Ask:
- Does switching colors feel like a meaningful rotation or annoying busywork?
- Is the cooldown too long? Too short?
- Does positioning matter (kiting colored clusters)?
- Is it readable which enemies are which color in chaos?

**Only proceed to Phase 5 if the core loop feels promising.**

### Phase 5: XP and Basic Progression

**XP Shards:**
- Enemies drop XP shards on death (small paint drops in their color or neutral/white)
- Shards drift toward player when player is nearby (magnetic pickup)
- XP bar fills, level up triggers upgrade selection

**Level Up Screen:**
- Pause game, show 3 random upgrade cards
- Player picks one, game resumes
- Keep upgrades SIMPLE for prototype:
  - +20% fire rate
  - +20% move speed  
  - +20% projectile damage
  - +1 projectile per shot
  - -0.2s color switch cooldown
  - +20 max HP, heal to full

### Phase 6: Color-Specific Skills (If Time Permits)

**Aura Skill:**
- Passive damage aura around player
- Aura matches player's CURRENT color (changes when player switches)
- Low DPS but constant

**Orbital Skill:**
- Paint blobs orbit the player
- Each orbital is a FIXED color (doesn't change with player)
- Creates interesting routing: "my red orbital handles red enemies while I focus blue"

**Turret Skill:**
- Stationary turret placed on upgrade
- Fixed color when placed
- Player builds up territory over time

## Code Architecture Suggestions

```
main.lua          -- Entry point, game state management
entities/
  player.lua      -- Player state, movement, shooting, color
  enemy.lua       -- Enemy base behavior
  projectile.lua  -- Bullet logic
  shard.lua       -- XP pickup
systems/
  spawner.lua     -- Wave/spawn management
  collision.lua   -- Hit detection (color-aware)
  rendering.lua   -- Blob/metaball rendering
  upgrades.lua    -- Upgrade pool and application
```

Or just `main.lua` with clearly separated sections if that's faster.

## Key Implementation Notes

1. **Color Matching**: Use a simple enum or string ("red", "cyan", "yellow"). Don't overcomplicate.

2. **Cooldown Feedback**: The color-switch cooldown MUST be visually clear. The player should never be surprised they can't switch.

3. **Screen Shake**: Subtle (2-4 pixels, fast decay) on hits. Makes combat feel impactful.

4. **Spawn Balancing**: Track what colors are currently on screen. If one color is over 50% of enemies, bias spawns away from it.

5. **Performance**: Expect 100+ enemies on screen eventually. Use spatial partitioning for collision if it becomes a problem, but don't prematurely optimize.

6. **Death and Restart**: When HP hits 0, show simple death screen with "Press R to restart". Fast iteration loop.

## What NOT to Build (Prototype Scope)

- No main menu
- No save/load
- No sound (unless trivial to add)
- No boss enemies yet
- No complex card/upgrade synergies
- No meta-progression between runs
- No multiple weapon types

## Deliverable

A playable Love2D prototype where I can:
1. Move around and feel responsive
2. Shoot enemies and see them die (with color matching)
3. Switch colors with a cooldown that feels like a real decision
4. See the paint blob aesthetic (not placeholder shapes)
5. Pick upgrades on level up
6. Die and restart quickly

## Success Criteria

The prototype answers: **"Is frantically rotating through colors while managing positioning and cooldowns FUN?"**

If yes → expand the prototype
If no → we learned something, iterate on the mechanic or pivot
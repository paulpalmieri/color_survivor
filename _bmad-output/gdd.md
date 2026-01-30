---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
inputDocuments:
  - game-brief.md
  - brainstorming-session-2026-01-27.md
  - game.md
  - rendering.md
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 1
  projectDocs: 2
workflowType: 'gdd'
lastStep: 1
project_name: 'color_survivor'
user_name: 'Paul'
date: '2026-01-28'
game_type: 'roguelike'
game_name: 'Color Survivor'
---

# Color Survivor - Game Design Document

**Author:** Paul
**Game Type:** Roguelike (Survivors-like)
**Target Platform(s):** PC/Mac (Steam), Web (Demo)

---

## Executive Summary

### Game Name

Color Survivor

### Core Concept

Color Survivor is a roguelite bullet hell where enemies are your ammo. Players navigate an ever-growing swarm of color-coded paint blob enemies, shooting projectiles that must match an enemy's color to deal full damage. The core mechanic is the pierce-chain-mix system: non-matching bullets pierce through enemies and convert color using paint-mixing rules (Red + Blue = Purple, Red + Yellow = Orange, Yellow + Blue = Green), turning the horde itself into a tool for creating the bullets you need.

Runs escalate from focused survival into screen-filling chaos as players collect auto-cast skills and passive upgrades that combo together into emergent build archetypes. Color -- something everyone instinctively understands -- becomes a deep strategic language.

Cheerful procedural paint blob aesthetic with a chunky pixel look -- readable, distinctive, and unlike anything else in the survivors-like genre.

**Note:** This GDD describes the full design vision for Color Survivor. MVP scope is defined separately in the Game Brief. During development, reference the Game Brief for what to build now vs what to build later.

### Game Type

**Type:** Roguelike (survivors-like subgenre)
**Framework:** This GDD uses the roguelike template with type-specific sections for run structure, procedural generation, permadeath/progression, item/upgrade systems, character selection, and difficulty modifiers.

---

## Target Platform(s)

### Primary Platform

PC/Mac (Steam) -- keyboard/mouse

### Secondary Platform

Web browser (Love2D web export) -- playable demo for zero-budget marketing

### Future Platform

Console -- would require engine port, only if game proves successful

### Control Scheme

| Input | Action |
|---|---|
| WASD / Arrow Keys | Movement |
| Mouse aim | Aim direction |
| Left click | Shoot (or auto-fire toward cursor) |
| Right click | Cycle color |
| 1 / 2 / 3 | Direct color select (Red / Yellow / Blue) |
| Space | Dash |

**Design notes:**
- Right click color cycling keeps left hand free for movement at all times
- Direct select (1/2/3) available for advanced players who want precision
- Controller mapping feasible for future console port (bumpers for color cycle, triggers for shoot/dash)

---

## Target Audience

### Demographics

Core gaming enthusiasts, ages 25-35. PC/Mac players.

### Gaming Experience

Core to experienced -- familiar with roguelites and survivors-likes (Vampire Survivors, Brotato, Halls of Torment, Death Must Die).

### Genre Familiarity

Primary audience knows the genre well. Secondary audience (newcomers) is served by the intuitive color system -- "red hurts red" needs no tutorial.

### Session Length

15-20 minute runs. Long sessions through multiple runs if the loop keeps players engaged.

### Player Motivations

- The crescendo from survival to domination
- Discovering build combos that feel personal
- Visual spectacle of god-runs with paint effects
- Simple mechanics that reveal hidden depth
- "One more run" pull

---

## Goals and Context

### Project Goals

1. **Validate the core mechanic** -- prove the pierce-chain-mix color system is fun through prototyping and playtesting multiple variants
2. **Ship a playable game** -- first project, learn by shipping. Get Color Survivor on Steam.
3. **Make a game I'd play** -- built by a survivors fan, for survivors fans. Personal enjoyment is the primary success metric.

### Background and Rationale

Color Survivor was born from a love of survivors-likes and a question: what if color wasn't just cosmetic, but the entire damage system? The paint blob aesthetic emerged organically from Love2D's shader capabilities and became the game's visual identity -- something no other survivors-like looks like.

AI-assisted solo development makes a project of this scope feasible as a first game. The survivors-like genre is proven and hungry for fresh takes. Most entries are number-driven (DPS, stats, scaling); Color Survivor is system-driven (color physics, positional chains, enemies-as-resources). That's a genuine gap.

---

## Unique Selling Points (USPs)

1. **Enemies Are Your Ammo** -- The pierce-chain-mix system turns enemies from obstacles into resources. Positioning isn't just about dodging -- it's about lining up color chains through the horde.

2. **Color As Universal Language** -- Mechanic and aesthetic are unified. Color isn't cosmetic -- it IS the game system. Instantly readable; depth emerges through play.

3. **Procedural Paint Blob Aesthetic** -- Soft-circle threshold rendering with chunky pixel look. Cheerful, organic, and technically unique. The game looks like nothing else in the genre.

### Competitive Positioning

Survivors-likes are dominated by number-driven progression and dark pixel art aesthetics. Color Survivor offers a system-driven alternative with a cheerful paint identity. The short-form hook: "Survivors-like where you shoot THROUGH enemies to mix colors."

---

## Core Gameplay

### Game Pillars

1. **Controlled Chaos** -- The screen is exploding with paint and enemies but the player always feels in control. Simple assets ensure readability. Responsive, properly paced, never unfair.
   - *Gut-check:* A new player survives their first 2 minutes without feeling lost. A veteran dies at minute 15 from a positioning mistake, not randomness.

2. **Strategy** -- Positioning matters, color choices matter, build decisions matter. Thinking under pressure, not just reflexes.
   - *Gut-check:* Players discuss optimal color-switch timing and pierce angles online.

3. **Depth** -- Simple surface, layers underneath. Color system, pierce chains, build combos. Easy to learn, long mastery curve.
   - *Gut-check:* Players discover new build combos after 50 hours.

**Pillar Prioritization:** When pillars conflict, prioritize:
Controlled Chaos > Strategy > Depth. If it doesn't feel good and readable in the moment, nothing else matters.

### Core Gameplay Loop

**Action Loop (constant -- the heartbeat):**
Move through the horde → shoot color-matched projectiles → switch colors to target different enemies → pierce non-matching enemies to chain-mix bullets → dash to reposition

**Build Loop (periodic -- the breathing room):**
Collect XP from kills → level up → choose auto-cast skill or passive upgrade → return to action with new power

**Exploration Loop (macro -- the journey):**
Navigate the infinite map → discover POIs → engage with objectives → push toward the boss encounter

**Loop Diagram:**

```
[MOVE/DODGE] → [SHOOT/SWITCH COLOR] → [PIERCE/CHAIN] → [ENEMIES DIE]
      ↑                                                        ↓
      ↑                                                   [DROP XP]
      ↑                                                        ↓
[NEW POWER] ← [CHOOSE UPGRADE] ← [LEVEL UP] ← [COLLECT XP]
```

**Loop Timing:**
- Action loop: continuous, moment-to-moment (seconds)
- Build loop: every 30-90 seconds (level-up frequency)
- Exploration loop: over the full 15-minute run
- Full run: ~15 minutes, ending with boss encounter

**Loop Variation:** Each run feels different through:
- Random skill/upgrade offerings at level-up
- Different enemy color compositions forcing different pierce strategies
- Map exploration revealing different POIs and challenges
- Build identity emerging from the specific skills collected

### Win/Loss Conditions

#### Victory Conditions

- **Boss Kill:** At ~15 minutes, a final boss spawns. Defeat the boss to complete the run.
- The boss encounter is the climax of the run -- the ultimate test of your build, positioning, and color mastery.

#### Failure Conditions

- **HP reaches 0:** Permadeath. Run is over immediately.
- Can die during the run OR during the boss fight -- both are valid failure states.

#### Failure Recovery

- **Instant restart:** Death screen → press R → new run. Fast iteration loop.
- Death should feel like YOUR mistake -- a positioning error, a bad color switch, a greedy play.
- Death screen should communicate how far you got and what build you had -- fuel for "one more run."
- Meta progression (post-MVP) provides slight persistent boosts to soften the restart.

---

## Game Mechanics

### Primary Mechanics

#### 1. Movement (Pillar: Controlled Chaos)
- **Feel:** Fast, responsive, with subtle blob-like inertia and deformation. The player should feel snappy to control but look organic -- paint sliding across the canvas.
- **When:** Constant -- the primary survival tool.
- **Skill tested:** Positioning, spatial awareness, pathing through enemy formations.
- **Progression:** Base move speed upgradeable via passives.

#### 2. Dash (Pillar: Controlled Chaos)
- **Feel:** Quick burst of repositioning. Needs to feel good -- snappy, impactful.
- **When:** Situational -- escape tight spots, reposition for pierce angles.
- **Invincibility frames:** Yes -- brief iframes during dash.
- **Cooldown:** TBD through playtesting. Short enough to feel available, long enough to require timing.
- **Skill tested:** Timing, situational awareness.
- **Progression:** Dash cooldown and distance upgradeable.

#### 3. Color Switching (Pillar: Strategy)
- **Feel:** Deliberate, strategic. The cooldown forces commitment to a color choice.
- **When:** Constant decision-making -- "which color do I need right now?"
- **Cycle:** Forced full cycle (Red → Yellow → Blue → Red). No skipping. Right click to advance.
- **Cooldown:** TBD -- needs experimentation. Currently 1 second in prototype, may change.
- **Visual feedback:** Cooldown must be crystal clear (cooldown ring, desaturation, etc.).
- **Skill tested:** Planning, anticipation, decision-making under pressure.
- **Progression:** Cooldown reduction as a powerful upgrade.

#### 4. Shooting (Pillar: Controlled Chaos, Strategy)
- **Feel:** Satisfying paint splatter. Projectiles are small paint drops.
- **When:** Constant -- hold left click to auto-fire toward cursor.
- **Fire rate:** Start slow (~2 shots/second). Frantic fire rates are the RESULT of upgrades, not the baseline. Early game should feel deliberate.
- **Skill tested:** Aim, target prioritization, lining up pierce angles.
- **Progression:** Fire rate, projectile count, projectile speed all upgradeable.

#### 5. Pierce + Mix (Pillar: Strategy, Depth)
- **Feel:** Visually clear -- bullet enters enemy, brief pause/flash, exits the other side as a new color.
- **When:** Happens naturally when bullets hit non-matching enemies. Becomes intentional as players learn the system.
- **Rules:**
  - Bullet hits non-matching primary enemy → pierces through, chip damage, bullet becomes mixed color (paint mixing: R+B=Purple, R+Y=Orange, Y+B=Green)
  - **Max 1 pierce per bullet** (baseline). Multiple pierces as a potential upgrade.
  - Bullet exits from the opposite side of the enemy relative to entry angle.
  - Mixed bullet can then hit matching secondary enemy for full damage, or parent-color enemy for reduced damage, or non-parent enemy for decomposition into two primary bullets.
- **Skill tested:** Positioning, formation reading, intentional pierce setups.
- **Progression:** Pierce count, pierce damage, mixed bullet bonuses.

#### 6. Collect (Pillar: Depth)
- **When:** Passive -- XP shards drop from kills, magnetic pickup when player is nearby.
- **Progression:** Pickup radius upgradeable.

### Mechanic Interactions

| Mechanic | Interacts With | How |
|---|---|---|
| Movement | Pierce + Mix | Positioning determines which enemies you can line up for pierces |
| Color Switch | Shooting | Bullets inherit current color -- switching changes your damage target |
| Color Switch | Pierce + Mix | Your current color determines which enemies you pierce vs match-kill |
| Dash | Movement | Emergency repositioning to set up or escape bad color situations |
| Shooting | Pierce + Mix | Every non-matching shot is a potential pierce -- aim matters |

### Mechanic Progression

Mechanics start simple and deliberate. Upgrades increase speed, volume, and complexity:
- **Early run:** Slow fire rate, one pierce, full cycle cooldown. Every shot and switch is a decision.
- **Mid run:** Faster fire rate, maybe extra projectiles. Decisions become faster-paced.
- **Late run:** Frantic fire rate, multiple projectiles, reduced cooldown. The build is online -- controlled chaos.

---

## Controls and Input

### Control Scheme (PC/Mac)

| Input | Action | Frequency |
|---|---|---|
| WASD / Arrow Keys | Movement | Constant |
| Mouse | Aim direction | Constant |
| Left Click (hold) | Auto-fire | Constant |
| Right Click | Cycle color (forced full cycle) | Frequent |
| 1 / 2 / 3 | Direct color select (advanced shortcut) | Optional |
| Space | Dash | Situational |

### Input Feel

- **Movement:** Responsive with subtle inertia -- fast direction changes with slight blob deformation. Snappy but organic.
- **Shooting:** Hold to auto-fire, satisfying rhythm. Paint splatter feedback on hits.
- **Color switch:** Tactile click feel. Cooldown feedback must be immediately visible -- never surprise the player with "can't switch yet."
- **Dash:** Instant burst, brief screen effect, iframes feel protective.

### Accessibility Controls

- Rebindable keys (post-MVP)
- Color accessibility (post-MVP -- shapes or patterns as color alternatives)

---

## Roguelike Specific Design

### Run Structure

- **Run length:** ~15 minutes, ending with boss spawn
- **Starting conditions:** Same every run -- one blob, base stats, Red starting color. No variation for MVP.
- **Difficulty scaling:** Simple ramp -- enemy health increases, enemy quantity increases, secondary color enemies introduced mid-run (~5 min mark)
- **Victory:** Kill the boss to complete the run

### Procedural Generation

- **Enemy spawning:** Random from screen edges, balanced color distribution (no single color dominating >50%)
- **Map:** Large bounded arena for MVP (multiple screens of traversable space). Infinite map with POIs is post-MVP.
- **Seed system:** Not for MVP.

### Permadeath and Progression

- **Permadeath:** HP hits 0 = run over. Full reset.
- **Meta-progression:** None for MVP. Post-MVP: pigment currency for slight passive boosts and unlocks.
- **Between runs:** Nothing persists. Death screen → restart.

### Item and Upgrade System

- **Level-up screen:** Pause game, show 3 random choices, pick one, resume.
- **Upgrade types:**
  - Passive stat boosts (fire rate, move speed, projectile damage, pickup radius, max HP, cooldown reduction)
  - Auto-cast skills (auras, orbital projectiles, paint trails -- small pool for MVP, 2-3 skills)
- **Rarity:** Not for MVP. Flat pool.
- **Synergies:** Emergent from skill + passive combinations. No hard-coded synergies for MVP.
- **Build variety:** Emerges organically from random offerings and player choice.

### Character Selection

Not for MVP. Single playable blob. Post-MVP: potential for characters with different starting colors, stats, or passive abilities.

### Difficulty Modifiers

Not for MVP. Post-MVP: challenge modifiers, difficulty tiers, mutators.

---

## Progression and Balance

### Player Progression

**Within-run progression:**
- **Skill progression:** Player learns to read enemy formations, set up pierce angles, time color switches. Mastery curve.
- **Power progression:** XP → level up → choose upgrade. Each upgrade makes you stronger.

**Between-run progression:**
- **MVP:** None. Each run starts fresh.
- **Post-MVP:** Meta-progression via pigment currency for slight persistent boosts and unlocks.

### Difficulty Curve

**Pattern:** Escalating ramp within each 15-minute run.

| Time | Challenge |
|---|---|
| 0-3 min | Tutorial pace. Primary colors only. Few enemies. Learn color matching. |
| 3-7 min | Ramp up. More enemies, faster spawns. Pierce naturally happens. |
| 7-12 min | Secondary color enemies introduced. Must engage with pierce + mix. |
| 12-15 min | Full chaos. High density, all colors. Build should be coming online. |
| 15 min | Boss spawn. Ultimate test. |

**Difficulty options:** None for MVP. Single difficulty tuned for the core audience.

### Economy and Resources

**MVP economy:**
- **XP shards:** Drop from kills, magnetic pickup, fill XP bar, trigger level-up.
- **No currency.** No shops. No trading.

**Post-MVP economy:**
- **Pigment:** Persists between runs, spent on meta-progression unlocks.
- **Prismatic Pigment:** Rare drop from secondary enemies, premium unlocks.

---

## Level Design Framework

### Level Types

**MVP: Large Arena**
- One bounded play space with no transitions or loading screens
- Player spawns at center, enemies spawn from screen edges
- Arena size: large enough to allow meaningful traversal and repositioning (multiple screens worth of space)
- Player can kite, retreat, and use space strategically -- not a cramped box
- No environmental hazards for MVP

**Post-MVP: Infinite Map**
- Seamless scrolling world with procedurally placed POIs
- Color wells, ability shrines, XP caches, challenge zones
- Macro-level exploration layered on top of micro-level combat

### Level Progression

**No discrete levels** -- progression is time-based within a single 15-minute run.

The "level" IS the run:
- **0-3 min:** Natural onboarding. Few enemies, primary colors only. Player learns color matching organically.
- **3-7 min:** Density increases. Pierce opportunities arise naturally.
- **7-12 min:** Secondary color enemies introduced. Pierce + mix becomes necessary.
- **12-15 min:** Peak chaos. All colors, high density. Build should be online.
- **15 min:** Boss spawns. Final test.

**Environment:** Large static arena for MVP -- big enough for strategic movement and kiting. No terrain changes, no phase transitions. Complexity comes from enemy composition, not level geometry.

---

## Art and Audio Direction

### Art Style

**Procedural Paint Blob Aesthetic**

- **Rendering:** Soft-circle threshold rendering at low internal resolution (320x180), scaled with nearest-neighbor filtering for chunky pixelated look
- **Background:** Cream/off-white canvas -- the "paper" that paint lives on
- **Colors:** Vibrant, high-saturation RYB primaries (Red, Yellow, Blue) and secondaries (Purple, Orange, Green)
- **Entity rendering:** All entities are paint blobs with organic animation (wobble, squash/stretch, organelles)
- **Health display:** Enemies shrink as they take damage -- no HP bars needed
- **Effects:** Paint splatter on hits, color mixing visuals on pierce, satisfying death bursts

**Visual Priorities:**
1. Readability -- player must always know what color everything is
2. Distinctiveness -- look like nothing else in the genre
3. Cheerfulness -- bright, playful, inviting

**Alternative exploration:** May experiment with higher-res smooth rendering vs current pixelated style.

### Audio and Music

**Direction:** Chill, simple. TBD through experimentation.

**MVP Audio:**
- Hit sounds (satisfying paint splat)
- Kill sounds (burst/pop)
- Color switch feedback (click/whoosh)
- Level-up chime
- Dash sound
- Death sound
- Boss spawn warning

**Music:** Post-MVP. Placeholder or silence for initial testing.

**Production:** Solo, AI-assisted. Start minimal, iterate based on feel.

---

## Technical Specifications

### Performance Requirements

- **Target framerate:** 60fps constant
- **Entity count:** Must handle 100+ enemies with shader-based rendering (already proven in prototype)
- **Resolution:** 320x180 internal, scaled to display resolution
- **Memory:** Minimal -- procedural assets, no large textures
- **Load times:** Instant (no loading screens within gameplay)

### Platform-Specific Details

**PC/Mac (Primary):**
- Engine: Love2D (Lua)
- Distribution: Steam
- Input: Keyboard/mouse required, controller support post-MVP
- Min specs: TBD through testing, but Love2D is lightweight

**Web (Secondary):**
- Love2D web export for playable demo
- Browser compatibility: Modern browsers (Chrome, Firefox, Safari, Edge)
- Used for zero-budget marketing -- "try before you download"

**Console (Future):**
- Would require engine port (Love2D doesn't support console)
- Only pursued if Steam release proves successful

### Asset Requirements

**Art Assets:**
- None required -- all visuals are procedural (soft-circle threshold rendering)
- Shader code for blob rendering (already built)
- Particle effects (procedural)

**Audio Assets (MVP):**
- 6-8 sound effects (hits, kills, color switch, level-up, dash, death, boss warning)
- No music for MVP

**Data Assets:**
- Upgrade/skill definitions (Lua tables)
- Enemy type definitions (Lua tables)
- Balance tuning values (Lua config)

---

## Development Epics

### Epic Structure

**Epic 0: Current State (Done)**
- Player movement, color switching with cooldown
- Shooting with color matching
- Basic enemies (drifters, dashers) in 3 primary colors
- XP / level-up with simple upgrades
- Death + restart
- Paint blob rendering pipeline

**Epic 1: Core Mechanic Validation**
- Implement pierce + mix system
- Test multiple variants of pierce behavior
- Add visual feedback for pierce (entry flash, color change, exit)
- Playtest and iterate until fun

**Epic 2: Dash + Secondary Colors**
- Implement dash with iframes
- Add secondary color enemies (Purple, Orange, Green)
- Implement mixed bullet → secondary enemy damage
- Implement decomposition (mixed bullet → non-parent → split)

**Epic 3: Auto-Cast Skills**
- Implement 2-3 auto-cast skills (aura, orbital, trail)
- Add skills to level-up pool
- Test build variety and emergent combos

**Epic 4: Boss + Win Condition**
- Design and implement boss encounter
- Add 15-minute timer and boss spawn
- Victory screen on boss kill
- Death screen improvements (show build, time survived)

**Epic 5: Polish + Playtest**
- Sound effects
- Visual polish (effects, juice)
- Balance tuning
- External playtesting

**Post-MVP Epics:**
- Infinite map + POIs
- Full skill pool expansion
- Meta-progression system
- Additional bosses
- Music
- Steam integration

---

## Success Metrics

### Technical Metrics

- **Performance:** 60fps with 100+ entities on target hardware
- **Stability:** No crashes during 15-minute runs
- **Load time:** <1 second to start a new run
- **Web build:** Playable in browser without significant performance loss

### Gameplay Metrics

**Core Mechanic Validation:**
- Pierce + mix feels intentional, not accidental
- Players actively position for pierce opportunities (observed in playtesting)
- Color switching feels strategic, not annoying

**Retention Signals:**
- Playtesters want to play again after dying
- "One more run" behavior observed
- Players express desire to try different approaches

**Build Variety:**
- Different skill combinations produce noticeably different experiences
- No single dominant strategy emerges

**Difficulty Feel:**
- New players survive first 2-3 minutes
- Deaths feel fair ("my mistake") not random
- Boss is challenging but beatable with good builds

**Personal Metric:**
- Do I want to keep playing? (Primary success criterion)

---

## Out of Scope

**Explicitly NOT in MVP:**

- Infinite map / POIs (large bounded arena for MVP, no POIs)
- Meta-progression / persistent unlocks
- Multiple characters / character selection
- Difficulty modifiers / mutators
- Seed system / run sharing
- Leaderboards / online features
- Controller support
- Rebindable keys
- Color accessibility modes
- Full skill pool (MVP has 2-3 skills)
- Music
- Bosses beyond the final boss
- Rainbow/white/black enemies
- Splitting blobs
- Player color drift mechanics
- Color zones
- Narrative / story elements

**These are NOT cut -- they're post-MVP backlog.** Validate core mechanic first, then expand.

---

## Assumptions and Dependencies

### Assumptions

- Love2D performance is sufficient for 100+ entities (proven in prototype)
- Procedural art pipeline eliminates need for external art assets
- Solo dev with AI assistance can complete MVP scope
- The pierce + mix mechanic will be fun once properly implemented (needs validation)
- 15-minute runs are the right length for the genre (can adjust)

### Dependencies

- **Love2D framework:** Game depends on Love2D staying maintained and functional
- **Steam:** Distribution depends on Steam approval and integration
- **Web export:** Marketing strategy depends on Love2D web export working reliably

### Open Questions (To Resolve Through Prototyping)

- Exact color switch cooldown duration
- Exact dash cooldown and distance
- Exact fire rate progression curve
- White vs black for "super color" (post-MVP)
- How secondary enemies visually signal their color requirements
- Exact boss design and mechanics

---

*This GDD describes the full design vision for Color Survivor. For what to build NOW, reference the MVP definition in the Game Brief. Validate core mechanics before expanding scope.*

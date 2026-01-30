---
title: 'Game Brainstorming Session'
date: '2026-01-27'
author: 'Paul'
version: '1.0'
stepsCompleted: [1, 2, 3, 4]
status: 'completed'
---

# Game Brainstorming Session

## Session Info

- **Date:** 2026-01-27
- **Facilitator:** Game Designer Agent (Samus Shepard)
- **Participant:** Paul
- **Mode:** Guided with Party Mode (Cloud Dragonborn, Indie, Samus Shepard)

---

## Brainstorming Approach

**Selected Mode:** Guided
**Techniques Used:** Core Loop Brainstorming, Player Fantasy Mining, Emergence Engineering, Genre Mashup
**Focus:** Evolving an existing Love2D prototype into a full roguelite vision

---

## Starting Context

Paul has a working Love2D prototype of a Vampire Survivors-style bullet hell with:
- Color-switching mechanic (3 colors, cooldown-gated)
- Soft-circle threshold rendering pipeline (paint blob aesthetic)
- Organic animation layers (wobble, organelles, squash/stretch)
- Basic enemies (Drifters, Dashers), auto-spawning waves
- XP/level-up system with simple upgrades

**Key insight from Paul:** Loves the pathing/avoidance feel, the paint blob aesthetic, high intensity with simple mechanics. Wants an approachable but intense roguelite. Color as the universal theme.

---

## Core Vision

**Identity Statement:** Color Survivor is a roguelite where enemies are your palette. Match colors for damage, pierce for mixing, and chain through the horde to paint your way to victory.

**Pillars:**
- Approachable but intense roguelite (15-20 min runs)
- Pathing/avoidance as core skill
- Color as the universal language (mechanic + aesthetic + progression)
- Cheerful paint aesthetic, chaotic gameplay
- Easy to prototype and iterate

---

## Key Ideas

### 1. Color Pierce / Chain System (CORE MECHANIC EVOLUTION)

**The breakthrough:** Enemies are not just targets -- they are AMMO. Non-matching bullets pierce through enemies, converting color via paint mixing rules (subtractive/RYB model).

**Paint Mixing Rules:**
- Red + Blue = Purple
- Red + Yellow = Orange
- Yellow + Blue = Green

**Damage Tiers:**
| Interaction | Result |
|---|---|
| Matching color bullet → enemy | Full damage |
| Non-matching primary → enemy | Pierces, chip damage, bullet converts to mixed color |
| Mixed bullet → parent color enemy | Reduced damage |
| Mixed bullet → non-parent enemy | Decomposes into two primary bullets |

**Design implications:**
- Positioning is about lining up color chains, not just dodging
- Enemy formations become puzzles
- Difficulty lever = color scarcity (wrong mix of enemies on screen)

### 2. Secondary Color Enemies

**Direction 2 + 4 hybrid:**
- Mid-run: secondary enemies (Purple, Orange, Green) begin spawning
- They require mixed bullets to kill efficiently -- forces engagement with pierce system
- Late-run upgrades allow mixed bullets to also damage both parent colors (Direction 4)

**Companion Spawning:** Secondary enemies spawn with primary-color companions nearby, giving the player the "tools" to create the needed mixed bullets.

**Color Shedding:** Secondary enemies periodically shed small primary-color minions (e.g., Purple pulses out tiny Red and Blue blobs). Visually fits paint blob aesthetic perfectly.

### 3. Super Color (White or Black)

**Undecided -- both strong options:**
- **White (Canvas Energy):** Fits cheerful aesthetic, the canvas itself becomes a weapon, visually striking against colorful blobs. Erases/damages all.
- **Black (All Colors Combined):** Paint logic, heavy/powerful, ultimate mastery fantasy.

**Leaning:** White fits the cheerful paint-on-canvas identity better.

**Must be earned** -- endgame payoff, not a freebie.

### 4. Infinite Map with POIs

- No arena boundaries -- infinite scrolling map
- Points of Interest drive exploration: color wells, ability shrines, XP caches, challenge arenas
- Two layers of spatial decision: micro (dodge clusters) and macro (navigate toward POIs)
- Discovery as a progression driver alongside combat

### 5. Health Display via Blob Size

- No HP bars -- enemies shrink as they take damage
- Lower HP = smaller blob, more wobble, less saturation
- Rendering system already supports this (radius tied to HP%)
- Game reads itself with zero UI overhead

### 6. Build System: 4 Active Skills + Passive Upgrades

- **4 major skill slots** filled during the run (drops or level-up choices)
- Skills can be comboed together for emergent build identity
- Passive upgrades on top (fire rate, move speed, etc.)
- **No class selection** -- builds emerge organically from what you find
- Prototype-friendly: just need a pool of skills and an upgrade screen

### 7. Emergent Build Archetypes

Not designed as classes -- emerge from skill/upgrade combinations:

- **The Splash Zone:** Paint aura, close-range, aggressive pathing
- **The Sharpshooter:** Fewer strong projectiles, pierce focus, positional play
- **The Painter:** Turrets, trails, zones -- territorial map control
- **The Mixer:** Pierce chain bonuses, combo-focused, high skill ceiling

### 8. Color-Aware Upgrade Ideas (Favorites)

**Offensive:**
- Prismatic Burst -- kills trigger explosion in enemy's color
- Color Seeker -- projectiles curve toward same-color enemies
- Chain Lightning -- kill arcs to nearby same-color enemies
- Splatter Shot -- projectiles split into all 3 primaries on hit
- Pierce Master -- pierced bullets keep full speed + gain damage
- Decomposition Blast -- mixed bullet splits are explosive
- Paint Trail -- leave trail of current color, damages matching enemies

**Defensive/Utility:**
- Color Shield -- absorb one hit from matching color
- Chromatic Dash -- dash leaves color burst
- Palette Swap -- instant no-cooldown switch on a timer

**Summon/Territory:**
- Paint Turret -- fixed-color stationary turret
- Color Clone -- decoy blob draws same-color enemies
- Minion Painter -- friendly blobs that seek and pierce
- Color Well -- zone that converts enemies passing through

### 9. Meta Progression (Between Runs)

**Currency:** "Pigment" from kills, "Prismatic Pigment" (rare) from secondary kills

**Unlocks (variety, not power):**
- New upgrade cards added to pool
- New POI types
- New enemy types / modifiers
- Alternate pierce/mix behaviors as mutators

**Slight passive boosts (capped):**
- Base move speed, starting upgrades, cooldown reduction, XP radius

---

## Parked Ideas (Revisit Later)

- Player color shifting / drift (enemies or environment force-change your color)
- Color zones (map regions that buff/debuff based on player's current color)
- Player color slowly drifting over time requiring management
- Boss design
- Wave/pacing structure
- Sound/music direction

---

## Next Steps

1. **Game Brief** -- formalize this vision into a structured brief
2. **GDD** -- detailed design document with full mechanic specs
3. **Prototype iteration** -- implement pierce/chain system in existing Love2D prototype

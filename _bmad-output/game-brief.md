---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - brainstorming-session-2026-01-27.md
documentCounts:
  brainstorming: 1
  research: 0
  notes: 0
workflowType: 'game-brief'
lastStep: 0
project_name: 'color_survivor'
user_name: 'Paul'
date: '2026-01-27'
game_name: 'Color Survivor'
---

# Game Brief: {{game_name}}

**Date:** {{date}}
**Author:** {{user_name}}
**Status:** Draft for GDD Development

---

## Executive Summary

Color Survivor is a roguelite bullet hell where enemies are your ammo -- pierce, mix, and combo your way through a colorful swarm.

**Target Audience:** Core gaming enthusiasts (25-35) who enjoy survivors-likes and want strategic depth without added complexity.

**Core Pillars:** Controlled Chaos > Strategy > Depth

**Key Differentiators:** Enemies as ammo (pierce-chain-mix system), color as universal language (mechanic + aesthetic unified), procedural paint blob aesthetic.

**Platform:** PC/Mac (Steam), web demo for marketing.

**Success Vision:** The pierce-chain mechanic feels fun, playtesters ask to play again, and there's a clear path to a Steam release.

---

## Game Vision

### Core Concept

A roguelite bullet hell where enemies are your ammo -- pierce, mix, and combo your way through a colorful swarm.

### Elevator Pitch

Color Survivor is a roguelite where enemies aren't just threats -- they're your palette. Pierce them to mix colors, chain kills through the horde, and build an arsenal of auto-cast abilities in an infinite hand-painted world. Easy to pick up. Impossible to put down.

### Vision Statement

Color is the simplest language in the world -- everyone knows red, blue, yellow. Color Survivor turns that instinct into a deep strategic system. Pierce enemies to mix new colors, line up formations for chain kills, and discover builds no one else has found. Beneath the cheerful paint blobs is a game that rewards the players who push further. Built by a survivors fan, for survivors fans -- responsive, expressive, and endlessly replayable.

---

## Target Market

### Primary Audience

Core gaming enthusiasts in their late 20s-30s who enjoy roguelites and survivors-likes. PC/Mac players (keyboard/mouse) who appreciate polished game feel, satisfying combos, and "one more run" hooks. They've played Vampire Survivors, Brotato, or similar titles and are looking for something with more strategic depth without more complexity.

**Demographics:**
- Age: 25-35
- Platform: PC/Mac primary, console potential
- Input: Keyboard/mouse, adaptable to controller

**Gaming Preferences:**
- Roguelites, survivors-likes, action games with build variety
- Value polish, game feel, and visual spectacle
- Enjoy discovering combos and synergies organically
- Willing to invest in long sessions if the gameplay loop is engaging

**Motivations:**
- The rush of a god-run with screen-filling chaos
- Discovering build combos that feel personal
- Simple mechanics that reveal hidden depth over time
- Visual payoff -- effects, explosions, satisfying chain reactions

### Secondary Audience

Players newer to roguelites who are drawn in by the approachable color-based mechanics and cheerful aesthetic. The color system is universally intuitive -- "red hurts red" needs no tutorial. This lowers the barrier to entry compared to stat-heavy roguelites, making Color Survivor a potential gateway game for the genre. These players may not seek deep build optimization but enjoy the spectacle and progression of getting further each run.

### Market Context

The survivors-like genre exploded after Vampire Survivors (2022) and remains popular with titles like Brotato, Halls of Torment, and Soulstone Survivors. The audience is proven and hungry for fresh takes.

**Similar Successful Games:**
- Vampire Survivors -- proved the auto-battler roguelite market
- Brotato -- showed build variety keeps the genre fresh
- Halls of Torment -- demonstrated the audience wants more depth and polish

**Market Opportunity:**
Most survivors-likes are number-driven -- DPS stats, scaling multipliers, raw damage output. Color Survivor is system-driven -- color physics, positional chain reactions, and enemies-as-resources. This is a genuine gap in the genre. The approachable paint aesthetic also differentiates visually in a space dominated by pixel art and dark fantasy themes.

---

## Game Fundamentals

### Core Gameplay Pillars

1. **Controlled Chaos** -- The screen is exploding with paint and enemies but the player always feels in control. Simple assets ensure readability. Responsive, properly paced, never unfair.
   - *Gut-check:* A new player can survive their first 2 minutes without feeling lost. A veteran can still die at minute 15 from a positioning mistake, not randomness.

2. **Strategy** -- Positioning matters, color choices matter, build decisions matter. This is thinking under pressure, not just reflexes.
   - *Gut-check:* Players are discussing optimal color-switch timing and pierce angles online.

3. **Depth** -- Simple surface, layers underneath. The color system, pierce chains, build combos. Easy to learn, long mastery curve discovered over time.
   - *Gut-check:* Players are still discovering new build combos after 50 hours.

**Pillar Priority:** When pillars conflict, prioritize:
Controlled Chaos > Strategy > Depth. If it doesn't feel good and readable in the moment, nothing else matters.

### Primary Mechanics

**Action Loop (constant -- the heartbeat):**
- **Move/Dash** -- Navigate through the horde, dodge threats, reposition with quick dashes
- **Shoot** -- Fire color-matched projectiles at enemies
- **Switch Color** -- Cycle active color on a cooldown, gating your damage options
- **Pierce/Chain** -- Line up shots through non-matching enemies to mix colors and create chain reactions

**Build Loop (periodic -- the breathing room):**
- **Collect** -- Gather XP, pick up auto-cast skills, and passive upgrades
- **Plan** -- At level-up moments, evaluate your build and choose the skill/upgrade that best combos with your current loadout

**Exploration Loop (macro -- the journey):**
- **Explore** -- Navigate the infinite map toward POIs, shrines, and objectives

**Core Loop:** The action loop runs constantly -- move, shoot, switch, chain. Periodically the build loop interrupts -- collect XP, level up, plan your next upgrade. Over the course of the run, the exploration loop pulls you across the infinite map toward new objectives and challenges. Each loop feeds the others: better builds amplify the action, exploration surfaces new challenges that test your build.

### Player Experience Goals

- **Mastery/Growth** -- Getting better at chains, discovering combos, reading enemy formations
- **Tension/Relief** -- Surviving close calls, clutch color switches, clearing a dense swarm
- **Discovery** -- Finding new skill combos, reaching new POIs, "what happens if I..."
- **Spectacle** -- Watching your build go off, paint explosions filling the screen, god-run moments
- **Motivated Death** -- Every death feels like YOUR mistake, not the game's. The death screen shows how close you were to something greater. This is where "one more run" either happens or doesn't.

**Emotional Journey:** Early run feels focused and manageable. Mid-run ramps into controlled chaos as skills and enemies escalate. Late-run is full spectacle -- the build is online and the screen is a paint war. Death hits and you see what almost was -- pride from how far you pushed, hunger to go again. End of session: satisfaction from the combos pulled off and the itch to beat your best.

---

## Scope and Constraints

### Target Platforms

**Primary:** PC/Mac (Steam) -- keyboard/mouse
**Secondary:** Web browser (Love2D web export) -- zero-budget marketing tool, let players try before downloading
**Future:** Console (would require engine port, only if game proves successful)

### Budget Considerations

Zero budget, self-funded. Time is the primary investment. No outsourcing planned -- all work done solo with AI assistance across design, code, art, and audio.

### Team Resources

**Team size:** Solo developer, AI-assisted at all steps
**Availability:** Full-time currently -- but this may change. Scope must survive on nights/weekends if circumstances shift.
**Skills covered:** Design, programming, procedural art, audio (learning)
**Skill gaps:** Audio is the least experienced area -- will experiment and iterate
**First project:** Scope decisions should favor simplicity and iteration speed

### Technical Constraints

**Engine:** Love2D (Lua) -- chosen for fast iteration, good performance, AI-friendly codebase
**Art pipeline:** Procedural -- soft-circle threshold rendering, blob system already built. No external art assets needed.
**Performance:** Must handle 100+ entities with shader-based rendering at 60fps (already proven)
**Online features:** None for MVP -- no leaderboards, no cloud saves, purely offline
**Console:** Not feasible on Love2D -- would require a future engine port if warranted by success

### Scope Realities

- **First project + solo dev = scope is the #1 risk.** The brainstorming session generated a rich feature set (pierce chains, 6 color types, skill slots, infinite map, POIs, meta progression). NOT all of this ships in v1. An explicit MVP must be defined that validates the core mechanic with the smallest possible feature set.
- Ruthless prioritization is non-negotiable. If a feature doesn't serve the core pillars, it waits.
- Full-time availability is a current advantage but not guaranteed -- scope should be resilient to reduced hours.
- Zero budget means marketing relies on the game's visual distinctiveness, a playable web demo, and community word-of-mouth.
- Love2D locks out console for now but removes engine complexity as a risk.

---

## Reference Framework

### Inspiration Games

**Vampire Survivors**
- Taking: Auto-escalation (game gets crazier over time), "one more run" loop, simplicity of pickup-and-play
- Not Taking: The passive/idle feel -- Color Survivor should always demand active decision-making through color switching and positioning

**Halls of Torment**
- Taking: More active, skill-based combat feel, higher intensity and stakes
- Not Taking: ARPG complexity -- keep systems approachable

**Soulstone Survivors**
- Taking: Visual spectacle of abilities going off, build variety and combo potential
- Not Taking: Overwhelming UI and stat complexity

**Death Must Die**
- Taking: The god-run feeling when a build comes together, overall polish and game feel
- Not Taking: N/A -- primarily an inspiration for quality bar

**The Common Thread:** The crescendo from survival to domination. You start weak, make choices, and suddenly the screen is full of YOUR effects wiping everything. That power fantasy escalation is the emotional core Color Survivor must deliver.

### Competitive Analysis

**Direct Competitors:** Vampire Survivors, Brotato, Halls of Torment, Soulstone Survivors, Death Must Die, and the growing wave of survivors-likes on Steam.

**Competitor Strengths:** Proven audience, deep build variety, satisfying power scaling, strong "one more run" loops. The genre works.

**Competitor Weaknesses:** Many entries in the genre lean passive -- especially at lower skill levels. Mechanics are often generic (shoot, AOE, orbit) with different skins. Visually the space clusters around pixel art or dark fantasy. Even the more active entries (Halls of Torment, Death Must Die) rely on numerical damage systems rather than systemic mechanics.

### Key Differentiators

1. **Enemies Are Your Ammo** -- The pierce-chain-mix system turns enemies from obstacles into resources. No other survivors-like makes the horde itself part of your weapon system. Positioning isn't just about dodging -- it's about lining up color chains.

2. **Color As Universal Language** -- Mechanic and aesthetic are unified. Color isn't cosmetic -- it IS the game system. Damage, mixing, strategy, and visual identity all flow from the same source. Color matching is instantly readable; pierce-chain mechanics are learned naturally through play.

3. **Procedural Paint Blob Aesthetic** -- Visually distinctive in a genre dominated by pixel art and dark fantasy. Cheerful, organic, and technically unique (soft-circle threshold rendering). The game looks like nothing else in the genre.

**Short-Form Hook:** "Survivors-like where you shoot THROUGH enemies to mix colors."

**Unique Value Proposition:** Color Survivor is the first survivors-like where enemies are your palette -- pierce, mix, and chain your way through a colorful swarm using a damage system built entirely on color physics.

---

## Content Framework

### World and Setting

Abstract paint world -- no concrete setting or lore. The game is a canvas that generates terrain and enemies from color. World-building is purely mechanical and visual, not narrative.

### Narrative Approach

**Minimal.** No story, no cutscenes, no dialogue. Pure gameplay. Narrative elements may be explored later if the game warrants it.

**Story Delivery:** N/A

### Content Volume

To be defined by MVP scope. Core content: 3 primary colors, 3 secondary colors, enemy types per color, auto-cast skill pool, passive upgrade pool, infinite map with POIs. Exact volume depends on what playtesting reveals is needed for satisfying run length.

---

## Art and Audio Direction

### Visual Style

Procedural paint blob aesthetic using soft-circle threshold rendering at low internal resolution (320x180), scaled up with nearest-neighbor filtering for a chunky pixelated look. Cream/off-white canvas background. Vibrant, high-saturation colors (RYB primaries + secondaries).

Currently pixelated -- may experiment with higher-res smooth rendering as an alternative. The low-res blob style is distinctive and worth keeping as default.

**References:** No direct visual references -- the aesthetic is technically unique to this game's rendering pipeline.

### Audio Style

Chill, simple. Direction TBD -- will experiment. No voice acting. Sound effects and music handled solo.

### Production Approach

- **Art:** Fully procedural -- no external art assets needed. Rendering pipeline already built.
- **Audio:** Solo, experimental. Start with minimal SFX for key interactions (hits, kills, level-up, color switch). Music later.
- **AI-assisted:** All production steps supported by AI tooling.

---

## Risk Assessment

### Key Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Scope creep | High | High | Define tight MVP first. Only add features that serve core pillars. Brainstorming backlog is NOT a todo list. |
| Pierce mechanic legibility | Medium | High | Playtest early. If chains aren't readable in 100+ enemy chaos, simplify visual language or reduce density. |
| Core mechanic uncertainty | Medium | High | The pierce-chain-mix system is the leading design but not finalized. Prototype and test multiple variants before committing. |
| Solo burnout | Medium | Medium | Take breaks. Ship small milestones. Celebrate progress. AI assistance reduces grunt work. |
| Genre saturation / discoverability | Medium | Medium | Lean on visual distinctiveness, playable web demo, and the unique color-physics hook for organic discovery. |

### Technical Challenges

- **Core mechanic validation:** Multiple versions of the core color mechanic should be prototyped and playtested before committing. Possible variants: different mixing rules, different pierce behaviors, different relationships between color and damage. Kill darlings early.
- **Enemy scaling with skills:** As players acquire auto-cast skills, screen chaos increases. Enemy count, spawn logic, and visual clarity must scale together. Needs iterative tuning.
- **Pierce chain readability:** The core mechanic must remain visually clear even in late-game chaos. May need visual indicators (trails, flash effects) to communicate what's happening.
- **Performance at scale:** 100+ enemies with shader-based blob rendering, particles, and skill effects. Already proven for base case but may need optimization as features layer on.

### Market Risks

Genre is crowded but the audience is proven and hungry for fresh takes. The color-physics system and procedural paint aesthetic are genuine differentiators that are hard to copy. Discoverability is the main market risk -- mitigated by the web demo strategy and visual distinctiveness.

### Mitigation Strategies

1. **Mechanic prototyping** -- build and test multiple versions of the core color interaction before committing to one. Kill darlings early.
2. **MVP-first development** -- validate the core mechanic before building progression, meta, or content depth
3. **Continuous playtesting** -- test readability and fun at every milestone, not just at the end
4. **Web demo for marketing** -- let players try before buying, zero-cost visibility
5. **Backlog discipline** -- brainstormed ideas (rainbow enemies, splitting blobs, bosses, etc.) stay in backlog until MVP is validated

---

## Success Criteria

### MVP Definition

**Already Built:**
- Player movement, color switching with cooldown
- Shooting with color matching
- Basic enemies (drifters, dashers) in 3 colors
- XP / level-up with simple upgrades
- Death + restart
- Paint blob rendering pipeline

**MVP Additions:**
- Pierce mechanic (core differentiator -- test multiple variants)
- Dash
- Secondary colors (purple, orange, green) + mixed bullet system
- Secondary color enemies
- 2-3 auto-cast skills to test build feel

**Post-MVP Backlog:**
- Infinite map + POIs
- Full skill pool
- Meta progression (pigment currency, unlocks)
- Bosses, rainbow enemies, splitting blobs
- Audio / music
- Color accessibility

### Success Metrics

- **Core mechanic validation:** The pierce-chain mechanic feels fun and creates meaningful decisions under pressure
- **Retention signal:** Playtesters (including yourself) want to keep playing and try different approaches
- **Build variety signal:** Different skill combinations produce noticeably different run experiences
- **Path to release:** After MVP validation, a clear roadmap to a Steam-worthy product is visible

### Launch Goals

TBD -- validate MVP first. Launch goals will be defined after core mechanic is proven fun.

---

## Next Steps

### Immediate Actions

1. **Prototype multiple versions of the core color mechanic** -- test pierce/chain variants, different mixing rules, different damage relationships
2. **Playtest the winner** -- does it feel fun under pressure? Is it readable?
3. **Add dash + secondary colors** -- build out the MVP feature set
4. **Create GDD** -- formalize the full design once core mechanics are validated

### Research Needs

- Experiment with pierce mechanic variants before committing
- Test readability of color chains at high enemy density
- Explore low-res pixelated vs smooth blob rendering

### Open Questions

- White vs black for the "super color"?
- Exact auto-cast skill designs and combo interactions
- How do secondary enemies signal what colors they need?
- Infinite map structure and POI design (post-MVP)
- Audio direction

---

_This Game Brief serves as the foundational input for Game Design Document (GDD) creation._

_Next Steps: Use the GDD workflow to create detailed game design documentation once core mechanics are validated._

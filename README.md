# Kid Kiyotaka's White Room

A Civilization V: Brave New World mod adding **The Fourth Generation White
Room**, led by **Kid Kiyotaka Ayanokoji**.

The White Room is a single-capital civilization built around controlled
adaptation. It does not expand through settlers. Instead, it studies repeated
patterns, battlefield pressure, city collapse, and economic connections, then
turns them into permanent scaling advantages.

## Civilization

**Civilization:** The Fourth Generation White Room  
**Leader:** Kid Kiyotaka Ayanokoji  
**Trait:** Masterpiece of the White Room  
**Starting City:** White Room

The White Room begins normally, but cannot found additional cities after its
capital. Conquered cities can still be annexed, puppeted, or razed. Its strength
comes from turning a narrow start into long-term compounding power.

## UA / UU / UB Overview

UA means **Unique Ability**, UU means **Unique Unit**, and UB means **Unique
Building**.

| Type | Name | Summary |
| --- | --- | --- |
| UA | Masterpiece of the White Room | One founded capital; learns from worked improvement patterns, city damage, ranged strikes, trade connections, foreign city losses, and Kiyotaka's combat. |
| UU | Kiyotaka Ayanokoji | Robotics super-unit with permanent Perfect Adaptation; maximum 1 active copy. |
| UU | 4th Generation Operative | Plastics elite infantry with double XP, friendly-territory and wounded-target bonuses; maximum 3 active copies. |
| UB | None | The civilization has two unique units instead of a unique building. Hidden adaptation buildings implement its bonuses and cannot be constructed. |

Both UUs are additional White Room-exclusive unit classes, not replacements for
standard units.

## Unique Ability (UA): Masterpiece of the White Room

The White Room learns from repetition and failure.

- Cannot found new cities after the starting capital.
- May annex, puppet, or raze conquered cities.
- Each additional currently worked, unpillaged improvement of the same type
  gives its city +0.5% to the linked yield. This bonus follows the current worked
  pattern rather than accumulating permanently each turn.
- Each detected increase in a city's damage adds a permanent +0.25% city-defense
  stack for that city.
- A city's ranged strike adds a permanent +0.25% ranged-strike stack, counted at
  most once per game turn and protected against reload duplication.
- Each newly deployed trade-route connection involving the White Room adds
  permanent +0.125% Gold output to its cities.
- When another civilization or City-State loses a city, the White Room improves
  permanent empire-wide attack strength against cities by +0.5% and city defense
  by +0.25%. White Room's own city losses do not count.
- Kiyotaka permanently adapts through combat.

Most scaling is intentionally uncapped. The civilization is designed to feel
quiet early, then increasingly difficult to answer if opponents fail to end the
game before the White Room has learned enough.

## Unique Unit (UU): Kiyotaka Ayanokoji

**Unlocks:** Robotics  
**Limit:** 1 active copy  
**Role:** Singular late-game super-unit

**Base Stats:** 130 Combat Strength, 3 Movement, 1200 Production, +8 additional maintenance.

Kiyotaka is extremely expensive and cannot be purchased. He starts with a suite
of elite promotions, including March, Blitz, Drill I, Shock I, Cover I, Medic I,
Survivalism I, Ignore Terrain Cost, and White Room Training.

### Perfect Adaptation

Kiyotaka permanently improves whenever he experiences combat.

- When personally landing a killing blow: gains combat strength, bonus damage
  against that unit class, and immediate XP. Nearby allied kills do not count.
- On dealing damage: gains combat strength, attack strength, and progress
  toward moving after combat.
- On taking damage: gains damage resistance, healing scaling, and extra combat
  strength while wounded.
- On surviving below 25 HP: gains a larger combat and resistance boost, then
  receives a small heal at the start of the next White Room turn.

The worst mistake an enemy can make is failing to finish him.

### Contextual Presentation

Kiyotaka reacts to the battle instead of repeating one generic line. Attacking
an already-wounded target, taking no return damage, counterattacking, falling
below half health, surviving critical damage, recovering, and eliminating a
unit all draw from separate original dialogue pools. Routine combat remarks are
deliberately intermittent, with a cooldown and no immediate repeats.

Deployment, critical survival, Flow State, adaptation-tier breakthroughs,
decoded enemy combat classes, and death also create White Room assessment
banners. Every adaptation event is preserved in telemetry with its associated
Subject Note, even when no floating combat line is shown.

## Unique Unit (UU): 4th Generation Operative

**Unlocks:** Plastics  
**Limit:** 3 active copies  
**Role:** Elite infantry strike team

**Base Stats:** 85 Combat Strength, 2 Movement, 650 Production, +4 additional maintenance.

4th Generation Operatives are costly, capped elite units. They cannot be
purchased and are meant to operate as a small, specialized force rather than a
mass army.

They begin with March, Drill I, Shock I, Cover I, Ignore Terrain Cost, White
Room Training, a friendly-territory bonus, and a bonus against wounded units.
They also cannot be gifted to City-States when the Community Patch event hook is
available.

White Room Training grants +100% experience, Controlled Environment grants +15%
Combat Strength in friendly territory, and Exploit Weakness grants +33% when
attacking wounded units. Each deployment has a persistent `OPERATIVE-##` callsign
and a service record that remains archived after its loss.

Production costs above are base values before game-speed and other modifiers.

## Unique Buildings (UBs): None

There is no player-buildable unique building or replacement building. The mod's
invisible dummy buildings apply worked-improvement yields, city-defense
adaptation, ranged-strike adaptation, trade learning, and captured-city learning.
They are implementation details of the UA, not additional UBs.

## Gameplay Style

The White Room favors a controlled, compact empire.

- Build a strong capital.
- Work repeated improvements to scale city yields.
- Use trade routes to build permanent gold output.
- Let cities endure pressure and return fire to increase their defensive value.
- Conquer selectively, then annex useful cities.
- Keep Kiyotaka alive and active so Perfect Adaptation can compound.

The civ is strongest in longer games where its many small adaptations have time
to stack. Current balance uses very slow fractional scaling for most adaptation
systems, so several triggers may be needed before a whole-percent bonus appears
in Civ V's normal UI.

## In-Game Status Panel

The mod includes a small **White Room** button in-game. It opens a status panel
for tracking adaptation progress during play and testing.

The panel is split into focused tabs:

- **Empire**: trade-route learning, captured-city learning, applied global bonuses, and ready/pending status.
- **Cities**: per-city damage defense, ranged-strike stacks, duplicate yields, worked improvements, and most-adapted city.
- **Kiyotaka**: deployment details, Perfect Adaptation counters, Flow State progress, and class adaptations.
- **Units**: Kiyotaka and Operative caps, persistent `OPERATIVE-##` callsigns, active and archived service records, combat statistics, technology, trainability, and deployment status.
- **Telemetry**: a persistent, turn-stamped feed of the newest 32 adaptation and operational events from Kiyotaka, Operatives, city pressure, worked-improvement patterns, trade routes, and observed foreign city losses.

Each tab includes a compact summary strip above the detailed readout so the
most important status can be checked quickly.

## Requirements

- Civilization V: Brave New World
- Community Patch version 151 or newer is required.

The Community Patch dependency is declared in the mod package so its event
options and gameplay callbacks load before White Room.

## Current Art

Custom art is included for:

- Leader icon
- Civilization icon and alpha icon
- Dawn of Man image
- Setup map image
- Kiyotaka unit icon
- 4th Generation Operative unit icon

The animated diplomacy leader scene and 3D unit models still use safe existing
Civilization V assets.

## Development Notes

Implementation status, internal IDs, Lua log expectations, and test notes are in
[`IMPLEMENTATION_NOTES.md`](IMPLEMENTATION_NOTES.md).

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

## Trait: Masterpiece of the White Room

The White Room permanently learns from repetition and failure.

- Cannot found new cities after the starting capital.
- May annex, puppet, or raze conquered cities.
- Worked duplicate improvements improve city yields.
- Cities become stronger after taking damage.
- Cities improve their ranged strikes after firing.
- Trade route connections improve empire gold output.
- When another civilization or City-State loses a city, the White Room improves
  its anti-city doctrine and city defense.
- Kiyotaka permanently adapts through combat.

Most scaling is intentionally uncapped. The civilization is designed to feel
quiet early, then increasingly difficult to answer if opponents fail to end the
game before the White Room has learned enough.

## Unique Unit: Kiyotaka Ayanokoji

**Unlocks:** Robotics  
**Limit:** 1 active copy  
**Role:** Singular late-game super-unit

Kiyotaka is extremely expensive and cannot be purchased. He starts with a suite
of elite promotions, including March, Blitz, Drill I, Shock I, Cover I, Medic I,
Survivalism I, Ignore Terrain Cost, and White Room Training.

### Perfect Adaptation

Kiyotaka permanently improves whenever he experiences combat.

- On kill: gains combat strength, bonus damage against that unit class, and
  immediate XP.
- On dealing damage: gains combat strength, attack strength, and progress
  toward moving after combat.
- On taking damage: gains damage resistance, healing scaling, and extra combat
  strength while wounded.
- On surviving below 25 HP: gains a larger combat and resistance boost, then
  receives a small heal at the start of the next White Room turn.

The worst mistake an enemy can make is failing to finish him.

## Unique Unit: 4th Generation Operative

**Unlocks:** Plastics  
**Limit:** 3 active copies  
**Role:** Elite infantry strike team

4th Generation Operatives are costly, capped elite units. They cannot be
purchased and are meant to operate as a small, specialized force rather than a
mass army.

They begin with March, Drill I, Shock I, Cover I, Ignore Terrain Cost, White
Room Training, a friendly-territory bonus, and a bonus against wounded units.
They also cannot be gifted to City-States when the Community Patch event hook is
available.

## Gameplay Style

The White Room favors a controlled, compact empire.

- Build a strong capital.
- Work repeated improvements to scale city yields.
- Use trade routes to build permanent gold output.
- Let cities endure pressure and return fire to increase their defensive value.
- Conquer selectively, then annex useful cities.
- Keep Kiyotaka alive and active so Perfect Adaptation can compound.

The civ is strongest in longer games where its many small adaptations have time
to stack.

## In-Game Status Panel

The mod includes a small **White Room** button in-game. It opens a status panel
for tracking adaptation progress during play and testing.

The panel currently shows:

- Empire-wide trade-route learning and captured-city learning.
- Per-city damage defense stacks and ranged-strike stacks.
- Per-city worked-improvement counts and duplicate yield bonuses.
- Kiyotaka deployment status and Perfect Adaptation counters.
- Active 4th Generation Operative count.

## Requirements

- Civilization V: Brave New World
- Community Patch is recommended and used for some advanced combat/event hooks.

The mod includes guards where possible so missing hooks do not crash the game,
but the intended experience is with Community Patch active.

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

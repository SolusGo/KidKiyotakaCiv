# Kid Kiyotaka White Room Civ V Mod

Work-in-progress Civilization V BNW ModBuddy project for **The Fourth
Generation White Room**, led by **Kid Kiyotaka Ayanokoji**.

## Current Status

The mod currently builds as a playable civilization with all planned core
mechanics implemented and tested. Leader/civilization icons and Dawn of Man
art now use the supplied Kid Kiyotaka image; the animated diplomacy leader
scene still uses safe existing Civilization V art.

## Logging Policy

- Keep visible startup logs so `Lua.log` can confirm each feature file loaded
  and initialized.
- Keep loader include/error logs visible because they are the fastest way to
  confirm the mod's Lua activation path.
- Gate noisy gameplay-event logs behind per-feature debug flags, including
  combat adaptation triggers, city damage/ranged triggers, trade-route learning
  triggers, settler removal, unit-cap enforcement, and duplicate-improvement
  per-city recalculation logs.
- To debug a specific feature, set that file's `WR_*_DEBUG` flag to `true`.

## Done

- ModBuddy project setup:
  - `KidKiyotakaWhiteRoom.civ5proj`
  - Civ V build/deploy paths
  - `SafeName` fixed so the mod deploys to the correct folder
- Playable civ shell:
  - `CIVILIZATION_WHITE_ROOM_KID`
  - `LEADER_WR_KID_KIYOTAKA`
  - `TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM`
  - White Room city names
  - White Room spy names
  - polished gameplay, Civilopedia, and Dawn of Man text
  - supplied Kid Kiyotaka image wired as leader portrait, civ icon, alpha icon, and Dawn of Man image
  - existing Washington art still used for the animated diplomacy leader scene
- Unique units:
  - `UNIT_WR_KIYOTAKA`
  - `UNIT_WR_FOURTH_GEN_OPERATIVE`
- Kiyotaka adaptation dummy promotions:
  - combat adaptation tiers I-VIII
  - resistance adaptation tiers I-VIII
- Duplicate-improvement dummy buildings:
  - food, production, gold, science, culture, faith
  - 1%, 5%, 10%, 25%, 50% denominations
- Duplicate worked-improvement scaling:
  - file: `Lua/WhiteRoomDuplicateImprovements.lua`
  - SQL: `SQL/WhiteRoomDuplicateDummyBuildings.sql`
  - counts only worked, owned, unpillaged improvements
  - each duplicate worked improvement gives +0.5% to the matching city yield
  - because Civ V building yield modifiers are integer percentages, fractional duplicate bonuses only become visible once they reach a whole percent
  - applies current dummy building counts idempotently to avoid unnecessary city updates
  - recalculates every player turn and after `BuildFinished` when available
  - logs only when a city's worked-improvement state changes, unless forced through the manual helper
  - manual test helper: `WR_RecalculateDuplicateImprovementBonusesForActivePlayer()`
- Lua loading fixed:
  - one `WhiteRoomLuaLoader.lua` InGameUIAddin
  - separate feature Lua files loaded through `include(...)`
- Cannot settle, can annex:
  - file: `Lua/WhiteRoomCannotSettle.lua`
  - auto-founds the starting capital from the first Settler if White Room has no cities
  - blocks Settler training through `PlayerCanTrain` when available
  - removes later White Room Settlers that are granted, captured, or otherwise created
  - does not touch captured cities, so annex/puppet/raze flow should remain normal
- Kiyotaka and operative unit caps:
  - file: `Lua/WhiteRoomUnitCaps.lua`
  - Kiyotaka active cap: 1
  - 4th Generation Operative active cap: 3
  - blocks training through `PlayerCanTrain` when available
  - removes extra capped units if they are granted, captured, or otherwise created
  - keeps the highest-level/highest-XP copies when removing extras
- Static unique unit polish:
  - file: `SQL/WhiteRoomPlayableCiv.sql`
  - Kiyotaka: 130 combat, 3 moves, 1200 production, +8 extra maintenance
  - Kiyotaka starts with March, Blitz, Drill I, Shock I, Cover I, Medic I, Survivalism I, Ignore Terrain Cost, and White Room Training
  - 4th Generation Operative: 85 combat, 2 moves, 650 production, +4 extra maintenance
  - 4th Generation Operative starts with March, Drill I, Shock I, Cover I, Ignore Terrain Cost, White Room Training, Controlled Environment, and Exploit Weakness
  - both units use `HurryCostModifier = -1` and faith purchase disabled so they should not be purchasable
  - custom promotions added: `PROMOTION_WR_DOUBLE_XP`, `PROMOTION_WR_FRIENDLY_TERRITORY`, `PROMOTION_WR_WOUNDED_TARGETS`
- 4th Generation Operative behavior:
  - file: `Lua/WhiteRoomFourthGenOperative.lua`
  - blocks gifting 4th Generation Operatives to City-States through Community Patch `GameEvents.PlayerCanGiftUnit` when available
- Perfect Adaptation for Kiyotaka:
  - files: `Lua/WhiteRoomKiyotakaScaling.lua`, `SQL/WhiteRoomAdaptationDummyPromotions.sql`
  - Kiyotaka gets the base `PROMOTION_WR_PERFECT_ADAPTATION`
  - on credited kill: +0.25% combat counter, +0.25% counter against the killed unit's combat class, +1 XP
  - on Kiyotaka-attributed damage dealt to a unit: +0.13% combat counter, +0.13% attack counter, +0.07% move-after-combat chance counter
  - on damage taken: +0.19% resistance counter, +0.13% healing counter, +0.13% below-50-HP combat counter
  - on surviving a drop below 25 HP: +0.75% combat counter, +0.75% resistance counter, and a 3 HP heal queued for the next White Room turn
  - class-specific adaptation uses generated `PROMOTION_WR_KIYOTAKA_VS_<UNITCOMBAT>_<TIER>` promotions
  - movement-after-combat becomes the `Flow State` promotion once the stored chance reaches 100%
  - exact counters are saved with `Modding.OpenSaveData()` and converted into visible tier promotions
  - damage-dealt credit uses `Events.EndCombatSim` when available and only fires when Kiyotaka is the attacker or defender and the opposing combat target's damage increases
  - tested in-game with Community Patch active: kill credit, non-kill damage credit, damage taken, below-25-HP survival, and next-turn heal all confirmed in `Lua.log`
- City HP-loss adaptation:
  - files: `Lua/WhiteRoomCityHpAdaptation.lua`, `SQL/WhiteRoomCityHpAdaptationDummyBuildings.sql`
  - tracks each White Room city's damage between player turns
  - when city damage increases, adds +1 city defense adaptation stack for that city
  - applies invisible dummy buildings in 1/5/10/25/50 denominations
  - each stack is worth +0.25% city defense/HP scaling; visible dummy buildings apply only whole-percent amounts
  - logs `WR City HP Adaptation: <city> took damage (...)`
  - tested in-game and confirmed working
- City ranged strike adaptation:
  - files: `Lua/WhiteRoomCityRangedStrikeAdaptation.lua`, `SQL/WhiteRoomCityRangedStrikeDummyBuildings.sql`
  - safely probes `city:HasPerformedRangedStrikeThisTurn()` with `pcall`
  - polls White Room cities on turn and city-info dirty events
  - confirmed CP exposes the ranged-strike flag in `Lua.log`
  - when a White Room city flips to "has performed a ranged strike this turn", adds +1 ranged adaptation stack for that city
  - applies invisible dummy buildings in 1/5/10/25/50 denominations
  - dummy building writes are idempotent to avoid city-info dirty event loops/freezes
  - each stack is worth +0.25% city `RangedStrikeModifier`; visible dummy buildings apply only whole-percent amounts
  - logs `WR City Ranged Adaptation: <city> fired a ranged strike (...)`
  - tested in-game and confirmed working
- Trade route learning:
  - files: `Lua/WhiteRoomTradeRouteLearning.lua`, `SQL/WhiteRoomTradeRouteLearningDummyBuildings.sql`
  - uses Community Patch `GameEvents.PlayerTradeRouteCompleted` when available
  - also polls active routes with `player:GetTradeRoutes()` each White Room turn, because the CP completed event may not fire for already-active routes
  - when a White Room trade route connection completes, adds +0.125% permanent gold learning
  - because Civ V building yield modifiers are integer percentages, every 8 learned connections applies +1% Gold
  - applies the current whole-percent gold modifier to all White Room cities through invisible dummy buildings
  - logs `WR Trade Route Learning: trade connection learned by White Room (...)`
  - tested in-game and confirmed working
- Captured city learning:
  - files: `Lua/WhiteRoomCapturedCityLearning.lua`, `SQL/WhiteRoomCapturedCityLearningDummyBuildings.sql`
  - listens for `Events.SerialEventCityCaptured`
  - triggers when any non-White-Room major civ or City-State loses a city
  - each city-loss event gives White Room +0.5% attack vs cities and +0.25% city defense learning
  - city defense uses repeatable invisible dummy buildings in 1/5/10/25/50 denominations
  - attack vs cities uses hidden city-attack promotions applied to White Room combat units
  - the original eleven promotion rows are retained in their original order for old-save compatibility; their values form a 1-1024 binary ladder for exact bonuses up to +2047%
  - reapplies existing bonuses to current cities/units each White Room turn
  - debug logs `WR Captured City Learning: <old owner> lost city id <id> to <new owner> (...)` when `WR_CITY_LOSS_DEBUG` is enabled
  - tested in-game with IGE and confirmed working

- CP research tooltip compatibility:
  - repairs malformed `AURONTRAIT` building references from Arendelle's United Republic of Nations across yield and happiness tooltip tables
  - removes remaining orphaned `BuildingType` rows from CP building-class yield and happiness tooltip tables
  - removes orphaned `Unit_FreePromotions` links that would abort CP's research-panel refresh and leave stale technology text
  - normalizes custom unit classes with `NULL DefaultUnit` values while preserving their original civilization-only availability
- Phase 4 in-game status UI:
  - files: `UI/WhiteRoomStatusPanel.xml`, `UI/WhiteRoomStatusPanel.lua`
  - separate `White Room Status Panel` InGameUIAddin
  - adds a small in-game `White Room` button
  - hides and closes the status UI while a leader-diplomacy screen is active
  - opens a tabbed status panel with Empire, Cities, Kiyotaka, and Units views
  - Empire tab shows trade-route learning, captured-city learning, stored/applied global bonuses, and ready/pending labels
  - Cities tab shows per-city damage defense stacks, ranged-strike stacks, stored/applied city bonuses, duplicate yield bonuses, worked improvements, and the currently most-adapted city
  - Kiyotaka tab shows deployment details, Perfect Adaptation counters, Flow State progress, and class adaptations
  - Units tab shows unique unit active counts, caps, tech status, trainability, and deployment status
  - Phase 3 polish adds section dividers, compact dossier-style rows, and clearer stored-vs-applied bonus wording
  - Phase 4 polish adds an at-a-glance summary strip above the detailed readout and clearer active-tab labels
  - Phase 5 polish adds color-coded status badges, stronger readout hierarchy, and sorted city cards
  - Phase 6 polish adds richer tooltips, a compact/expanded toggle, White Room-themed labels, and a stronger Kiyotaka dossier profile
  - reads existing saved counters through `Modding.OpenSaveData()` and recalculates worked-improvement display live from city plots

## Hardest To Easiest Remaining Work

1. In-game status panel verification after rebuild
2. In-game art verification after rebuild

## Recommended Implementation Order

1. Rebuild and verify the White Room status panel appears in-game
2. Verify leader/civ icons and Dawn of Man image in-game

## Important IDs

```lua
GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
GameInfoTypes.LEADER_WR_KID_KIYOTAKA
GameInfoTypes.TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM
GameInfoTypes.UNIT_WR_KIYOTAKA
GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE
```

## Test Checklist

- Rebuild in ModBuddy.
- Start Civ V fresh.
- Enable `Kid Kiyotaka White Room`.
- Confirm the civ appears on the setup screen.
- Start a game as the White Room.
- Check `Database.log` for White Room SQL errors.
- Check `Lua.log` for:

```text
WhiteRoomLuaLoader.lua loaded
WhiteRoomLuaLoader included WhiteRoomDuplicateImprovements.lua
WhiteRoomDuplicateImprovements.lua loaded
WR Duplicate Improvements: initialized
WhiteRoomLuaLoader included WhiteRoomCityHpAdaptation.lua
WhiteRoomCityHpAdaptation.lua loaded
WR City HP Adaptation: initialized
WhiteRoomLuaLoader included WhiteRoomCityRangedStrikeAdaptation.lua
WhiteRoomCityRangedStrikeAdaptation.lua loaded
WR City Ranged Adaptation: initialized
WhiteRoomLuaLoader included WhiteRoomTradeRouteLearning.lua
WhiteRoomTradeRouteLearning.lua loaded
WR Trade Route Learning: PlayerTradeRouteCompleted hook available
WR Trade Route Learning: player:GetTradeRoutes() polling available
WR Trade Route Learning: initialized
WhiteRoomLuaLoader included WhiteRoomCapturedCityLearning.lua
WhiteRoomCapturedCityLearning.lua loaded
WR Captured City Learning: SerialEventCityCaptured hook available
WR Captured City Learning: initialized
WhiteRoomLuaLoader included WhiteRoomCannotSettle.lua
WhiteRoomCannotSettle.lua loaded
WR Cannot Settle: initialized
WhiteRoomLuaLoader included WhiteRoomKiyotakaScaling.lua
WhiteRoomKiyotakaScaling.lua loaded
WR Perfect Adaptation: initialized
WhiteRoomLuaLoader included WhiteRoomUnitCaps.lua
WhiteRoomUnitCaps.lua loaded
WR Unit Caps: initialized; Kiyotaka cap 1, 4th Generation Operative cap 3
WhiteRoomLuaLoader included WhiteRoomFourthGenOperative.lua
WhiteRoomFourthGenOperative.lua loaded
WR 4th Generation Operative: initialized
WhiteRoomStatusPanel.lua loaded
WR Status Panel: initialized
```

## Notes

- White Room's starting Settler is converted into the capital by Lua. Later
  Settlers should be blocked or removed; captured cities should still work.
- Current unique-unit tech unlocks are `TECH_ROBOTICS` for Kiyotaka and
  `TECH_PLASTIC` for the 4th Generation Operative.
- Static unique unit SQL was validated against a temporary copy of the local
  Civ V debug database.
- Perfect Adaptation SQL was validated against a temporary copy of the local
  Civ V debug database. Unit damage dealt requires Community Patch
  `Events.EndCombatSim`.
- Leader/civ icons and Dawn of Man art use the supplied Kid Kiyotaka image. The animated diplomacy leader scene intentionally still uses existing Civ V art to avoid crashes.
- Community Patch may expose useful city/combat hooks, but those still need
  explicit probing before exact damage or city ranged-strike mechanics are
  attempted.

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
  - persists an irreversible initial-capital-consumed flag and vetoes later founding through Community Patch `PlayerCanFoundCity`
  - blocks Settler training through `PlayerCanTrain` when available
  - removes later White Room Settlers that are granted, captured, or otherwise created
  - does not touch captured cities, so annex/puppet/raze flow should remain normal
- Kiyotaka and operative unit caps:
  - file: `Lua/WhiteRoomUnitCaps.lua`
  - Kiyotaka active cap: 1
  - 4th Generation Operative active cap: 3
  - counts both active units and city production queues through `PlayerCanTrain`/`CityCanTrain`
  - `CityCanTrain` cannot distinguish revalidating a current order from appending another copy behind it, so the current head is allowed and any same-city excess is safely pruned on the next player turn
  - queue pruning reserves current production before later queue entries, avoiding cancellation of a legal in-progress unit
  - prunes excess legacy queues and enforces the active cap immediately through Community Patch `UnitCreated`
  - removes extra capped units if they are granted, captured, or otherwise created
  - explicitly rejects Kiyotaka and the 4th Generation Operative as training or upgrade targets for every non-White Room civilization, preventing foreign unique-unit lineages from resolving into White Room units
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
  - assigns each deployment a persistent, non-reused callsign (`OPERATIVE-01`, `OPERATIVE-02`, and so on)
  - maps callsigns to live Civ V unit IDs and clears the mapping on loss so recycled unit IDs receive new identities
  - tracks per-operative and lifetime combats, kills, damage dealt/taken, wounded-target engagements, controlled-environment engagements, deployment turn, and loss turn
  - archives final level, combat totals, and kills when an Operative is lost
  - records Operative registration, engagements, kills, special-condition engagements, and losses in adaptation telemetry
- Perfect Adaptation for Kiyotaka:
  - files: `Lua/WhiteRoomKiyotakaScaling.lua`, `Lua/WhiteRoomKiyotakaFlavor.lua`, `SQL/WhiteRoomAdaptationDummyPromotions.sql`
  - Kiyotaka gets the base `PROMOTION_WR_PERFECT_ADAPTATION`
  - on a verified direct Kiyotaka kill: +0.25% combat counter, +0.25% counter against the killed unit's combat class, +1 XP
  - on Kiyotaka-attributed damage dealt to a unit: +0.13% combat counter, +0.13% attack counter, +0.07% move-after-combat chance counter
  - on damage taken: +0.19% resistance counter, +0.13% healing counter, +0.13% below-50-HP combat counter
  - on surviving a drop below 25 HP: +0.75% combat counter, +0.75% resistance counter, and a 3 HP heal queued for the next White Room turn
  - class-specific adaptation uses generated `PROMOTION_WR_KIYOTAKA_VS_<UNITCOMBAT>_<TIER>` promotions
  - movement-after-combat becomes the `Flow State` promotion once the stored chance reaches 100%
  - exact counters are saved with `Modding.OpenSaveData()` and converted into visible tier promotions
  - death clears only transient pending-heal, last-damage, and combat-target state; permanent adaptation counters remain
  - damage-dealt and damage-taken credit use shared Community Patch `BattleStarted` / `BattleJoined` / `BattleFinished` snapshots, independent of Quick Combat, visibility, or animation
  - kill credit is awarded directly from Civ V's authoritative `UnitPrekill` event while the defeated unit type and Kiyotaka's combat state are still available
  - gameplay battle participants record exact opposing units; `UnitPrekill` retains terminal damage before removal, and city conquest retains terminal city damage before owner/HP replacement
  - kill credit requires the exact attacker/defender pairing; nearby allied kills and collateral/bystander victims grant no Kiyotaka kill adaptation or XP
  - per-victim deduplication protects against delayed-death callbacks firing more than once, while the `UnitPrekill` unit type preserves class-specific adaptation for direct kills and counterattack kills
  - contextual flavor separates ordinary attacks, clean exchanges, counterattacks, wounded targets, kills, wounded kills, damage, below-half-health pressure, critical survival, recovery, deployment, Flow State, tier breakthroughs, class-doctrine milestones, and death
  - routine combat barks use a 35% chance, a one-turn cooldown, and per-event no-repeat selection; forced milestone/survival lines bypass the chance and cooldown
  - floating combat text is only shown for the active White Room player, while every trigger still records its original Subject Note in persistent telemetry
  - major assessments are saved to an eight-record banner queue so consecutive milestones display in order; banners pause behind the status panel, city screen, diplomacy, and blocking overview popups
  - flavor can be disabled or tuned before initialization with `WR_KIYOTAKA_FLAVOR_ENABLED`, `WR_KIYOTAKA_BARK_CHANCE_PERCENT`, and `WR_KIYOTAKA_BARK_COOLDOWN_TURNS`
  - tested in-game with Community Patch active: kill credit, non-kill damage credit, damage taken, below-25-HP survival, and next-turn heal all confirmed in `Lua.log`
- City HP-loss adaptation:
  - files: `Lua/WhiteRoomCityHpAdaptation.lua`, `SQL/WhiteRoomCityHpAdaptationDummyBuildings.sql`
  - tracks each White Room city's damage between player turns
  - keys persistent/runtime state by owner, city ID, coordinates, and founding turn; legacy owner/city-ID saves migrate once
  - when city damage increases, adds +1 city defense adaptation stack for that city
  - applies invisible dummy buildings in 1/5/10/25/50 denominations
  - each stack is worth +0.25% city defense; dummy buildings apply whole percentages through CP `BuildingDefenseModifier`, not flat strength or extra HP
  - logs `WR City HP Adaptation: <city> took damage (...)`
  - tested in-game and confirmed working
- City ranged strike adaptation:
  - files: `Lua/WhiteRoomCityRangedStrikeAdaptation.lua`, `SQL/WhiteRoomCityRangedStrikeDummyBuildings.sql`
  - safely probes `city:HasPerformedRangedStrikeThisTurn()` with `pcall`
  - shares the same strong city identity and one-time legacy migration used by HP adaptation and the status UI
  - polls White Room cities on turn/city-info dirty events and gameplay city battle completion
  - confirmed CP exposes the ranged-strike flag in `Lua.log`
  - a true performed-strike flag awards once per game turn, guarded by persistent `LAST_RANGED_STRIKE_COUNTED_TURN` under the strong city identity
  - existing saves without the new guard retain all stacks; an already-true flag at initial load is conservatively primed without re-awarding
  - applies invisible dummy buildings in 1/5/10/25/50 denominations
  - dummy building writes are idempotent to avoid city-info dirty event loops/freezes
  - each stack is worth +0.25% city `RangedStrikeModifier`; visible dummy buildings apply only whole-percent amounts
  - logs `WR City Ranged Adaptation: <city> fired a ranged strike (...)`
  - tested in-game and confirmed working
- Trade route learning:
  - files: `Lua/WhiteRoomTradeRouteLearning.lua`, `SQL/WhiteRoomTradeRouteLearningDummyBuildings.sql`
  - polls every player's outgoing routes so both inbound and outbound White Room connections are observed
  - persists active counts per route fingerprint; polling opens route instances and Community Patch `PlayerTradeRouteCompleted` closes them
  - event/poll ordering is deduplicated, save/reload does not re-award active routes, and a later route between the same endpoints earns independently
  - each newly deployed White Room trade route instance adds +0.125% permanent gold learning
  - because Civ V building yield modifiers are integer percentages, every 8 learned connections applies +1% Gold
  - applies the current whole-percent gold modifier to all White Room cities through invisible dummy buildings
  - logs `WR Trade Route Learning: trade connection learned by White Room (...)`
  - tested in-game and confirmed working

- Package integrity:
  - the ModBuddy project declares `(1) Community Patch` `d1b6328c-ff44-4b0d-aad7-c657f83610cd` version 151+ as its sole hard dependency
  - `tools/sync_modinfo.py` rebuilds the `.modinfo` file list, hashes, VFS flags, database actions, and entry points from the ModBuddy project
  - dependency and reference metadata are generated from the project alongside files, actions, and entry points
  - `tools/validate_mod.py` verifies package parity, the exact Community Patch dependency, static runtime contracts, and deterministic regression models
- Captured city learning:
  - files: `Lua/WhiteRoomCapturedCityLearning.lua`, `SQL/WhiteRoomCapturedCityLearningDummyBuildings.sql`
  - listens for authoritative `GameEvents.CityCaptureComplete`; coordinates/founding turn identify the captured city, and capture deduplication is persisted
  - excludes White Room own losses even if the capture eliminates its last city
  - triggers when any non-White-Room major civ or City-State loses a city
  - each city-loss event gives White Room +0.5% attack vs cities and +0.25% city defense learning
  - city defense uses repeatable invisible dummy buildings in 1/5/10/25/50 denominations
  - attack vs cities uses hidden city-attack promotions applied to White Room combat units
  - the original eleven promotion rows are retained in their original order for old-save compatibility; their values form a 1-1024 binary ladder for exact bonuses up to +2047%
  - reapplies existing bonuses to current cities/units each White Room turn
  - debug logs `WR Captured City Learning: <old owner> lost city id <id> to <new owner> (...)` when `WR_CITY_LOSS_DEBUG` is enabled
  - tested in-game with IGE and confirmed working

- CP research tooltip compatibility:
  - compatibility SQL is scoped to White Room-owned text, dummy buildings, and unit classes
  - unrelated mod rows and orphaned foreign references are deliberately left untouched
  - normalizes only White Room's two custom unit classes when their `DefaultUnit` is `NULL`, preserving civilization-only availability without rewriting unrelated custom civilizations' classes
- Phase 4 in-game status UI:
  - files: `UI/WhiteRoomStatusPanel.xml`, `UI/WhiteRoomStatusPanel.lua`
  - separate `White Room Status Panel` InGameUIAddin
  - adds a small in-game `White Room` button
  - shows the status button, dossier data, telemetry feed, and Kiyotaka assessment banners only when the local active player controls the White Room civilization; AI White Room records are not exposed to players using another civilization
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
  - adaptation telemetry adds a fifth tab backed by a persistent 32-record rotating buffer
  - telemetry records actual Kiyotaka combat/survival/recovery, Operative service activity, city damage and ranged strikes, worked-improvement pattern changes, trade-route learning, and observed foreign city losses
  - the telemetry feed is newest-first, turn-stamped, category-coded, save-persistent, compact-mode aware, and live-refreshes while open
  - a dossier-style live-assessment banner consumes Kiyotaka's persistent major-event queue without dropping events during other full-screen UI
  - reads existing saved counters through `Modding.OpenSaveData()` and recalculates worked-improvement display live from city plots
- Unique-unit unlock dossiers:
  - separate `WhiteRoomUnitUnlock` UI add-in; it does not replace CP or base-game research and notification contexts
  - shows a one-time portrait dossier when Plastics unlocks the Fourth Generation Operative and Robotics unlocks Kiyotaka
  - portrait presentation uses grid frames rather than a stretched `256x256Frame.dds`, avoiding the offset opaque block visible behind Kiyotaka's circular icon
  - assessment, doctrine, and acknowledgement controls use explicit interior rows and spacing so text and buttons do not overlap panel borders
  - also leaves a standard generic notification after the dossier is acknowledged
  - old saves silently record technologies already researched, preventing historical unlock spam
  - writes the seen flag before opening UI and falls back to next-turn polling if the research event is unavailable

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
WhiteRoomLuaLoader included WhiteRoomTelemetry.lua
WhiteRoomTelemetry.lua loaded
WR Adaptation Telemetry: initialized; retaining newest 32 records
WhiteRoomLuaLoader included WhiteRoomKiyotakaFlavor.lua
WhiteRoomKiyotakaFlavor.lua loaded
WR Kiyotaka Flavor: initialized with contextual barks, telemetry notes, and banner queue
WR Battle Tracking: initialized with Community Patch gameplay events
WhiteRoomLuaLoader included WhiteRoomBattleTracking.lua
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
WR Captured City Learning: initialized with CityCaptureComplete
WhiteRoomLuaLoader included WhiteRoomCannotSettle.lua
WhiteRoomCannotSettle.lua loaded
WR Cannot Settle: initialized
WhiteRoomLuaLoader included WhiteRoomKiyotakaScaling.lua
WhiteRoomKiyotakaScaling.lua loaded
WR Perfect Adaptation: initialized with gameplay battle tracking
WhiteRoomLuaLoader included WhiteRoomUnitCaps.lua
WhiteRoomUnitCaps.lua loaded
WR Unit Caps: initialized; Kiyotaka cap 1, 4th Generation Operative cap 3
WhiteRoomLuaLoader included WhiteRoomFourthGenOperative.lua
WhiteRoomFourthGenOperative.lua loaded
WR 4th Generation Operative: initialized with persistent service records
WhiteRoomStatusPanel.lua loaded
WR Status Panel: initialized
```

- Verify Kiyotaka receives kill XP, combat adaptation, class adaptation,
  `TARGET NEUTRALIZED` telemetry, and a forced kill bark when his own attack or
  counterattack destroys a unit.
- Verify a different White Room unit destroying an enemy adjacent to Kiyotaka
  grants him no XP, kill telemetry, or class adaptation.

## Notes

- White Room's starting Settler is converted into the capital by Lua. Later
  Settlers should be blocked or removed; captured cities should still work.
- Current unique-unit tech unlocks are `TECH_ROBOTICS` for Kiyotaka and
  `TECH_PLASTIC` for the 4th Generation Operative.
- Static unique unit SQL was validated against a temporary copy of the local
  Civ V debug database.
- Perfect Adaptation uses Community Patch gameplay battle hooks
  (`EVENTS_BATTLES = 1`); animation events are not authoritative.
- Leader/civ icons and Dawn of Man art use the supplied Kid Kiyotaka image. The animated diplomacy leader scene intentionally still uses existing Civ V art to avoid crashes.
- Community Patch event signatures and the percentage defense field were
  checked against the installed CP declarations and upstream combat source.

## Gameplay-hook follow-up verification (2026-10-05)

Install development dependencies with `python -m pip install -r requirements-dev.txt`.
Packaged text uses LF line endings via `.gitattributes` so Git checkout does not
silently invalidate the manifest's byte-level MD5 hashes.
Run `python tools/sync_modinfo.py` after changing packaged assets, then
`python tools/validate_mod.py`. The validator requires Lua 5.1 via Lupa and checks:

- All Lua source syntax, project/manifest parity, MD5 hashes, CP dependency/options,
  and tracker-before-consumer load order.
- Actual Kiyotaka/Operative gameplay handlers without animation events: non-lethal
  damage, defending, siege kills, immediate XP, bystander rejection, lethal damage,
  final archived records, recycled callsigns, nested battles, AI ownership,
  city ranged attacks, captured-city damage, flavor banners, and persisted telemetry.
- Actual ranged-strike modules across reloads, next-turn strikes and legacy saves,
  plus deterministic behavior models and persistent capture deduplication.
- Changed SQL against a minimal CP schema: percentage denominations, no unintended
  flat defense/HP effects, retained unit exclusivity, and unchanged foreign rows.
- Expected initialization messages in the mocked runtime.

The status panel keeps its layout. Only visible banner timing runs every frame;
idle queue reads are throttled to 0.5 seconds. Telemetry checks run at 0.5 seconds
only on visible Units/Telemetry tabs. DiploList visibility has no reliable CP/EUI
event, so a cached-control-only poll remains at 0.25 seconds; city screens,
diplomacy, popups and turn transitions retain their existing event handlers.

All configured balance values and permanent progression keys are preserved.
The new percentage field requires the already-declared Community Patch 151+
dependency. Old city dummy instances automatically use the corrected definition.
No live Civ V test was performed for this follow-up: earlier in-game confirmations
above refer to the prior implementation. Test Quick Combat on/off, attacker/defender
kills and non-kills, ranged city strikes, capture and same-turn reload in-game.

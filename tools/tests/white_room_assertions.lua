local kiyotaka = newUnit(0, 1, 11)
local enemy = newUnit(1, 2, 13)
-- Quick/non-visible combat: only gameplay hooks; attacker gains once.
startBattle(0, 1, 1, 2)
kiyotaka.damage = 20
enemy.damage = 30
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_0_COMBAT, 13, "damage dealt combat")
expect(SAVE.WR_KIYOTAKA_0_ATTACK, 13, "damage dealt attack")
expect(SAVE.WR_KIYOTAKA_0_MOVE_CHANCE, 7, "damage dealt flow")
expect(SAVE.WR_KIYOTAKA_0_RESISTANCE, 19, "damage taken resistance")
expect(SAVE.WR_KIYOTAKA_0_HEALING, 13, "damage taken healing")
expect(SAVE.WR_KIYOTAKA_0_DESPERATION, 13, "damage taken desperation")
Events.EndCombatSim() -- presentation callback must not double-count
Events.SerialEventUnitSetDamage(0, 1, 20)
GameEvents.BattleFinished() -- duplicate finish is harmless
WR_KiyotakaScaling_DoTurn(0)
expect(SAVE.WR_KIYOTAKA_0_COMBAT, 13, "no animation/turn duplicate")
expect(SAVE.WR_KIYOTAKA_0_RESISTANCE, 19, "no damage-event duplicate")

-- Defender counterattack and critical survival, then immediate siege kill.
startBattle(1, 2, 0, 1)
kiyotaka.damage = 80
enemy.damage = 40
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_0_COMBAT, 101, "defender and low HP combat")
expect(SAVE.WR_KIYOTAKA_0_RESISTANCE, 113, "critical survival resistance")
expect(SAVE.WR_KIYOTAKA_0_PENDING_HEAL, 3, "critical survival heal")
startBattle(0, 1, 1, 2)
killUnit(1, 2, 0)
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_0_CLASS_SIEGE, 25, "siege kill stack once")
expect(SAVE.WR_KIYOTAKA_0_COMBAT, 139, "kill plus dealt damage")
expect(kiyotaka.xp, 1, "immediate kill XP once")

-- Another unit's kill with Kiyotaka nearby must not award him credit.
local operative = newUnit(0, 3, 12)
enemy = newUnit(1, 2, 13, 40)
startBattle(0, 3, 1, 2)
operative.damage = 20
killUnit(1, 2, 0)
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_0_CLASS_SIEGE, 25, "no bystander credit")
expect(SAVE.WR_OPERATIVE_0_RECORD_1_COMBATS, 1, "operative combats")
expect(SAVE.WR_OPERATIVE_0_RECORD_1_KILLS, 1, "operative kills")
expect(SAVE.WR_OPERATIVE_0_RECORD_1_DAMAGE_DEALT, 60, "terminal damage snapshot")
expect(SAVE.WR_OPERATIVE_0_RECORD_1_WOUNDED_ENGAGEMENTS, 1, "wounded engagement")
expect(SAVE.WR_OPERATIVE_0_RECORD_1_FRIENDLY_ENGAGEMENTS, 1, "friendly engagement")

-- Final engagement updates the archived serial without creating a new callsign.
enemy = newUnit(1, 2, 13)
startBattle(1, 2, 0, 3)
enemy.damage = 25
killUnit(0, 3, 1)
GameEvents.BattleFinished()
expect(SAVE.WR_OPERATIVE_0_RECORD_1_COMBATS, 2, "archived final combat")
expect(SAVE.WR_OPERATIVE_0_RECORD_1_DAMAGE_TAKEN, 100, "archived terminal damage")
expect(SAVE.WR_OPERATIVE_0_RECORD_1_ACTIVE, 0, "archive stays inactive")
expect(SAVE.WR_OPERATIVE_0_TOTAL_LOSSES, 1, "loss once across prekill phases")
expect(SAVE.WR_OPERATIVE_0_NEXT_SERIAL, 1, "no phantom redeployment")

-- Reused IDs get a new callsign, and defenders record counterattack kills.
operative = newUnit(0, 3, 12)
enemy = newUnit(1, 2, 13, 10)
startBattle(1, 2, 0, 3)
operative.damage = 10
killUnit(1, 2, 0)
GameEvents.BattleFinished()
expect(SAVE.WR_OPERATIVE_0_NEXT_SERIAL, 2, "reused unit gets new callsign")
expect(SAVE.WR_OPERATIVE_0_RECORD_2_KILLS, 1, "operative counterattack kill")
expect(SAVE.WR_OPERATIVE_0_RECORD_2_DAMAGE_DEALT, 90, "counterattack terminal damage")
expect(SAVE.WR_OPERATIVE_0_RECORD_2_WOUNDED_ENGAGEMENTS or 0, 0, "defending is not wounded attack")
expect(SAVE.WR_OPERATIVE_0_RECORD_1_ACTIVE, 0, "old archive not reactivated")

-- AI/off-screen unit, same event surface, plus ranged city as an opponent.
Players[2].civ = 1
local aiKiyotaka = newUnit(2, 8, 11)
local city = newCity(1, 4, 9, 9, 0)
startBattle(2, 8, 1, 4, false, true)
city.damage = 50
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_2_ATTACK, 13, "AI/offscreen city damage")
startBattle(1, 4, 2, 8, true, false)
aiKiyotaka.damage = 15
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_2_RESISTANCE, 19, "ranged city incoming damage")
expect(SAVE.WR_KIYOTAKA_2_ATTACK, 13, "ranged defender no fictitious counterattack")

-- Lethal damage earns adaptation but not survival recovery; permanent keys stay.
enemy = newUnit(1, 2, 13)
startBattle(1, 2, 2, 8)
enemy.damage = 40
killUnit(2, 8, 1)
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_2_COMBAT, 26, "final counterattack progress preserved")
expect(SAVE.WR_KIYOTAKA_2_RESISTANCE, 38, "final resistance preserved")
expect(SAVE.WR_KIYOTAKA_2_PENDING_HEAL, 0, "no recovery from lethal damage")
expect(SAVE.WR_KIYOTAKA_FLAVOR_2_ACTIVE, 0, "death flavor does not redeploy")
expect(SAVE.WR_KIYOTAKA_BANNER_2_SEQUENCE, nil, "AI banners stay private")

-- Ranged reload idempotence exercises the actual module and persisted keys.
local ranged = newCity(0, 9, 4, 5, 2)
reloadRanged()
local prefix = "WR_CITY_RANGED_0:9:4:5:2_"
ranged.strike = true
Events.SpecificCityInfoDirty(0, 9)
expect(SAVE[prefix .. "ATTACK_STACKS"], 1, "first ranged strike")
reloadRanged() -- fresh local Lua state, same persisted save
Events.SerialEventCityInfoDirty()
expect(SAVE[prefix .. "ATTACK_STACKS"], 1, "no ranged reload exploit")
TURN = TURN + 1
ranged.strike = false
GameEvents.PlayerDoTurn(0)
ranged.strike = true
Events.SpecificCityInfoDirty(0, 9)
expect(SAVE[prefix .. "ATTACK_STACKS"], 2, "next turn ranged strike")
-- Existing save: preserve history and conservatively prime an already-true flag.
local legacy = newCity(0, 10, 5, 5, 1)
legacy.strike = true
SAVE["WR_CITY_RANGED_0:10:5:5:1_ATTACK_STACKS"] = 20
reloadRanged()
expect(SAVE["WR_CITY_RANGED_0:10:5:5:1_ATTACK_STACKS"], 20, "legacy stacks intact")

-- Foreign city-state/civilization loss, persistent duplicate guard, own loss excluded.
enemy = newUnit(1, 2, 13)
GameEvents.CityCaptureComplete(1, false, 9, 9, 0, 3, true)
expect(SAVE.WR_CAPTURED_CITY_LEARNING_0_CITY_LOSS_STACKS, 1, "foreign city capture")
reloadCapture()
GameEvents.CityCaptureComplete(1, false, 9, 9, 0, 3, true)
expect(SAVE.WR_CAPTURED_CITY_LEARNING_0_CITY_LOSS_STACKS, 1, "persistent capture dedup")
Events.SerialEventCityCaptured({}, 1, 4, 0)
expect(SAVE.WR_CAPTURED_CITY_LEARNING_0_CITY_LOSS_STACKS, 1, "no UI capture award")
Players[0].alive = false
GameEvents.CityCaptureComplete(0, false, 4, 5, 1, 2, true)
expect(SAVE.WR_CAPTURED_CITY_LEARNING_2_CITY_LOSS_STACKS, 1, "dead White Room own loss excluded")
Players[0].alive = true

-- Capturing a city preserves damage credit even after owner/HP replacement.
city = newCity(1, 5, 8, 8, 1)
city.damage = 180
local priorAttack = SAVE.WR_KIYOTAKA_0_ATTACK
startBattle(0, 1, 1, 5, false, true)
Players[1].cities[5] = nil
local captured = newCity(0, 6, 8, 8, 1)
captured.damage = 50
GameEvents.CityCaptureComplete(1, false, 8, 8, 0, 3, true)
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_0_ATTACK, priorAttack + 13, "captured city damage credit")

-- Nested battle callbacks use separate snapshots and exclude bystanders.
local outerTarget = newUnit(1, 20, 13)
local innerTarget = newUnit(1, 21, 13)
priorAttack = SAVE.WR_KIYOTAKA_0_ATTACK
startBattle(0, 1, 1, 20)
GameEvents.BattleJoined(0, 3, 2, false)
startBattle(0, 3, 1, 21)
innerTarget.damage = 20
GameEvents.BattleFinished()
outerTarget.damage = 20
GameEvents.BattleFinished()
expect(SAVE.WR_KIYOTAKA_0_ATTACK, priorAttack + 13, "nested Kiyotaka battle counted once")
expect(SAVE.WR_OPERATIVE_0_RECORD_2_COMBATS, 2, "bystander does not count as operative combat")

assert(#FLAVOR > 0, "combat flavor still emits")
assert(#TELEMETRY > 0, "telemetry still emits")
assert(SAVE.WR_TELEMETRY_0_SEQUENCE > 0, "telemetry persists")
assert(SAVE.WR_KIYOTAKA_BANNER_0_SEQUENCE > 0, "human flavor banners queue")
expect(#WR_BattleTracking.battles, 0, "battle stack drained")

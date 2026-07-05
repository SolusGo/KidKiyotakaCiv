-- White Room Kid Kiyotaka - Perfect Adaptation

print("WhiteRoomKiyotakaScaling.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local UNIT_WR_KIYOTAKA = GameInfoTypes.UNIT_WR_KIYOTAKA
local PROMOTION_WR_KIYOTAKA_FLOW_STATE = GameInfoTypes.PROMOTION_WR_KIYOTAKA_FLOW_STATE

local WR_SAVE = Modding.OpenSaveData()
local WR_KIYOTAKA_DEBUG = false
local WR_TIERS = {100, 500, 1000, 2000, 3500, 5000, 7500, 10000}
local WR_ROMAN = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII"}

local function WR_Debug(message)
    if WR_KIYOTAKA_DEBUG then
        print(message)
    end
end

local WR_COMBAT_PROMOTIONS = {
    "PROMOTION_WR_KIYOTAKA_COMBAT_ADAPTATION_I",
    "PROMOTION_WR_KIYOTAKA_COMBAT_ADAPTATION_II",
    "PROMOTION_WR_KIYOTAKA_COMBAT_ADAPTATION_III",
    "PROMOTION_WR_KIYOTAKA_COMBAT_ADAPTATION_IV",
    "PROMOTION_WR_KIYOTAKA_COMBAT_ADAPTATION_V",
    "PROMOTION_WR_KIYOTAKA_COMBAT_ADAPTATION_VI",
    "PROMOTION_WR_KIYOTAKA_COMBAT_ADAPTATION_VII",
    "PROMOTION_WR_KIYOTAKA_COMBAT_ADAPTATION_VIII"
}

local WR_ATTACK_PROMOTIONS = {
    "PROMOTION_WR_KIYOTAKA_ATTACK_ADAPTATION_I",
    "PROMOTION_WR_KIYOTAKA_ATTACK_ADAPTATION_II",
    "PROMOTION_WR_KIYOTAKA_ATTACK_ADAPTATION_III",
    "PROMOTION_WR_KIYOTAKA_ATTACK_ADAPTATION_IV",
    "PROMOTION_WR_KIYOTAKA_ATTACK_ADAPTATION_V",
    "PROMOTION_WR_KIYOTAKA_ATTACK_ADAPTATION_VI",
    "PROMOTION_WR_KIYOTAKA_ATTACK_ADAPTATION_VII",
    "PROMOTION_WR_KIYOTAKA_ATTACK_ADAPTATION_VIII"
}

local WR_RESISTANCE_PROMOTIONS = {
    "PROMOTION_WR_KIYOTAKA_RESISTANCE_ADAPTATION_I",
    "PROMOTION_WR_KIYOTAKA_RESISTANCE_ADAPTATION_II",
    "PROMOTION_WR_KIYOTAKA_RESISTANCE_ADAPTATION_III",
    "PROMOTION_WR_KIYOTAKA_RESISTANCE_ADAPTATION_IV",
    "PROMOTION_WR_KIYOTAKA_RESISTANCE_ADAPTATION_V",
    "PROMOTION_WR_KIYOTAKA_RESISTANCE_ADAPTATION_VI",
    "PROMOTION_WR_KIYOTAKA_RESISTANCE_ADAPTATION_VII",
    "PROMOTION_WR_KIYOTAKA_RESISTANCE_ADAPTATION_VIII"
}

local WR_DESPERATION_PROMOTIONS = {
    "PROMOTION_WR_KIYOTAKA_DESPERATION_ADAPTATION_I",
    "PROMOTION_WR_KIYOTAKA_DESPERATION_ADAPTATION_II",
    "PROMOTION_WR_KIYOTAKA_DESPERATION_ADAPTATION_III",
    "PROMOTION_WR_KIYOTAKA_DESPERATION_ADAPTATION_IV",
    "PROMOTION_WR_KIYOTAKA_DESPERATION_ADAPTATION_V",
    "PROMOTION_WR_KIYOTAKA_DESPERATION_ADAPTATION_VI",
    "PROMOTION_WR_KIYOTAKA_DESPERATION_ADAPTATION_VII",
    "PROMOTION_WR_KIYOTAKA_DESPERATION_ADAPTATION_VIII"
}

local WR_DAMAGE_CACHE = {}

local function WR_SaveKey(playerID, key)
    return "WR_KIYOTAKA_" .. tostring(playerID) .. "_" .. key
end

local function WR_GetSavedNumber(playerID, key)
    local value = WR_SAVE.GetValue(WR_SaveKey(playerID, key))
    return tonumber(value) or 0
end

local function WR_SetSavedNumber(playerID, key, value)
    WR_SAVE.SetValue(WR_SaveKey(playerID, key), value or 0)
end

local function WR_ChangeSavedNumber(playerID, key, delta)
    local value = WR_GetSavedNumber(playerID, key) + delta
    WR_SetSavedNumber(playerID, key, value)
    return value
end

local function WR_IsWhiteRoomPlayer(player)
    return player
        and player:IsAlive()
        and CIV_WHITE_ROOM_KID ~= nil
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_FindKiyotaka(player)
    if player == nil or UNIT_WR_KIYOTAKA == nil then
        return nil
    end

    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_WR_KIYOTAKA then
            return unit
        end
    end

    return nil
end

local function WR_UnitDamageKey(playerID, unitID)
    return tostring(playerID) .. ":" .. tostring(unitID)
end

local function WR_GetTierIndex(hundredths)
    for i = #WR_TIERS, 1, -1 do
        if hundredths >= WR_TIERS[i] then
            return i
        end
    end

    return 0
end

local function WR_SetPromotion(unit, promotionType, enabled)
    local promotionID = GameInfoTypes[promotionType]
    if promotionID == nil then
        return
    end

    if unit:IsHasPromotion(promotionID) ~= enabled then
        unit:SetHasPromotion(promotionID, enabled)
    end
end

local function WR_ApplyTierPromotion(unit, promotionTypes, tierIndex, allowWhenInactive)
    for i, promotionType in ipairs(promotionTypes) do
        WR_SetPromotion(unit, promotionType, i == tierIndex and allowWhenInactive ~= false)
    end
end

local function WR_ClassSuffix(unitCombatType)
    if unitCombatType == nil then
        return nil
    end

    return string.gsub(unitCombatType, "UNITCOMBAT_", "")
end

local function WR_ApplyClassAdaptation(playerID, unit)
    for unitCombatInfo in GameInfo.UnitCombatInfos() do
        local suffix = WR_ClassSuffix(unitCombatInfo.Type)
        if suffix ~= nil then
            local tierIndex = WR_GetTierIndex(WR_GetSavedNumber(playerID, "CLASS_" .. suffix))
            for i, roman in ipairs(WR_ROMAN) do
                WR_SetPromotion(
                    unit,
                    "PROMOTION_WR_KIYOTAKA_VS_" .. suffix .. "_" .. roman,
                    i == tierIndex
                )
            end
        end
    end
end

local function WR_ApplyPerfectAdaptation(playerID, unit)
    if unit == nil then
        return
    end

    WR_ApplyTierPromotion(unit, WR_COMBAT_PROMOTIONS, WR_GetTierIndex(WR_GetSavedNumber(playerID, "COMBAT")))
    WR_ApplyTierPromotion(unit, WR_ATTACK_PROMOTIONS, WR_GetTierIndex(WR_GetSavedNumber(playerID, "ATTACK")))
    WR_ApplyTierPromotion(unit, WR_RESISTANCE_PROMOTIONS, WR_GetTierIndex(WR_GetSavedNumber(playerID, "RESISTANCE")))

    local isBelowHalf = unit:GetDamage() >= 50
    WR_ApplyTierPromotion(
        unit,
        WR_DESPERATION_PROMOTIONS,
        WR_GetTierIndex(WR_GetSavedNumber(playerID, "DESPERATION")),
        isBelowHalf
    )

    if PROMOTION_WR_KIYOTAKA_FLOW_STATE ~= nil then
        unit:SetHasPromotion(
            PROMOTION_WR_KIYOTAKA_FLOW_STATE,
            WR_GetSavedNumber(playerID, "MOVE_CHANCE") >= 10000
        )
    end

    WR_ApplyClassAdaptation(playerID, unit)
end

local function WR_LogCounters(playerID, reason)
    WR_Debug(string.format(
        "WR Perfect Adaptation: %s -> combat %.2f%%, attack %.2f%%, resistance %.2f%%, healing %.2f%%, lowHP %.2f%%, move-after-combat %.2f%%",
        reason,
        WR_GetSavedNumber(playerID, "COMBAT") / 100,
        WR_GetSavedNumber(playerID, "ATTACK") / 100,
        WR_GetSavedNumber(playerID, "RESISTANCE") / 100,
        WR_GetSavedNumber(playerID, "HEALING") / 100,
        WR_GetSavedNumber(playerID, "DESPERATION") / 100,
        WR_GetSavedNumber(playerID, "MOVE_CHANCE") / 100
    ))
end

local function WR_ChangeExperience(unit, amount)
    if unit == nil or amount == 0 then
        return
    end

    pcall(function()
        unit:ChangeExperience(amount)
    end)
end

local function WR_HealUnit(unit, amount, playerID)
    if unit == nil or amount <= 0 then
        return
    end

    local newDamage = math.max(0, unit:GetDamage() - amount)
    pcall(function()
        unit:SetDamage(newDamage, playerID)
    end)
end

local function WR_RecordLowHpSurvival(playerID, unit, reason)
    local turn = Game.GetGameTurn()
    if WR_GetSavedNumber(playerID, "LOW_HP_TURN") == turn then
        return
    end

    WR_SetSavedNumber(playerID, "LOW_HP_TURN", turn)
    WR_ChangeSavedNumber(playerID, "COMBAT", 75)
    WR_ChangeSavedNumber(playerID, "RESISTANCE", 75)
    WR_ChangeSavedNumber(playerID, "PENDING_HEAL", 3)
    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_LogCounters(playerID, "survived below 25 HP (" .. reason .. ")")
end

local function WR_RecordDamageTaken(playerID, unit, oldDamage, newDamage)
    if newDamage <= oldDamage then
        return
    end

    WR_ChangeSavedNumber(playerID, "RESISTANCE", 19)
    WR_ChangeSavedNumber(playerID, "HEALING", 13)
    WR_ChangeSavedNumber(playerID, "DESPERATION", 13)

    if oldDamage < 75 and newDamage >= 75 then
        WR_RecordLowHpSurvival(playerID, unit, "damage taken")
    end

    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_LogCounters(playerID, "took damage")
end

local function WR_RecordDamageDealt(playerID, unit, targetLabel)
    WR_ChangeSavedNumber(playerID, "COMBAT", 13)
    WR_ChangeSavedNumber(playerID, "ATTACK", 13)
    WR_ChangeSavedNumber(playerID, "MOVE_CHANCE", 7)
    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_LogCounters(playerID, "dealt damage to " .. targetLabel)
end

local function WR_RecordKill(playerID, unit, killedUnitType)
    local killedUnitInfo = GameInfo.Units[killedUnitType]
    local killedClass = killedUnitInfo and killedUnitInfo.CombatClass or nil

    WR_ChangeSavedNumber(playerID, "COMBAT", 25)
    WR_ChangeExperience(unit, 1)

    if killedClass ~= nil then
        local suffix = WR_ClassSuffix(killedClass)
        if suffix ~= nil then
            WR_ChangeSavedNumber(playerID, "CLASS_" .. suffix, 25)
        end
    end

    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_LogCounters(playerID, "kill")
end

local function WR_IsKiyotakaNearPlot(unit, x, y)
    if unit == nil or x == nil or y == nil or x < 0 or y < 0 then
        return false
    end

    local plot = unit:GetPlot()
    if plot == nil then
        return false
    end

    return Map.PlotDistance(plot:GetX(), plot:GetY(), x, y) <= 1
end

local function WR_PrimeDamageCache()
    for playerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
        local player = Players[playerID]
        if player ~= nil and player:IsAlive() then
            for unit in player:Units() do
                WR_DAMAGE_CACHE[WR_UnitDamageKey(playerID, unit:GetID())] = unit:GetDamage()
            end
        end
    end
end

local function WR_ApplyPendingHeal(playerID, unit)
    local pendingHeal = WR_GetSavedNumber(playerID, "PENDING_HEAL")
    if pendingHeal <= 0 then
        return
    end

    local healingBonus = math.floor(WR_GetSavedNumber(playerID, "HEALING") / 100)
    local totalHeal = pendingHeal + healingBonus
    WR_SetSavedNumber(playerID, "PENDING_HEAL", 0)
    WR_HealUnit(unit, totalHeal, playerID)
    WR_Debug(string.format(
        "WR Perfect Adaptation: healed Kiyotaka for %d HP at start of turn",
        totalHeal
    ))
end

function WR_KiyotakaScaling_DoTurn(playerID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    local unit = WR_FindKiyotaka(player)
    if unit == nil then
        return
    end

    WR_ApplyPendingHeal(playerID, unit)

    local lastDamage = WR_GetSavedNumber(playerID, "LAST_DAMAGE")
    local currentDamage = unit:GetDamage()
    if lastDamage > 0 and currentDamage > lastDamage then
        WR_RecordDamageTaken(playerID, unit, lastDamage, currentDamage)
    end

    WR_SetSavedNumber(playerID, "LAST_DAMAGE", currentDamage)
    WR_DAMAGE_CACHE[WR_UnitDamageKey(playerID, unit:GetID())] = currentDamage
    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_PrimeDamageCache()
end

GameEvents.PlayerDoTurn.Add(WR_KiyotakaScaling_DoTurn)

if GameEvents.UnitPrekill ~= nil then
    GameEvents.UnitPrekill.Add(function(killedPlayerID, killedUnitID, killedUnitType, x, y, delay, killerPlayerID)
        if killerPlayerID == nil or killerPlayerID < 0 then
            return
        end

        local killerPlayer = Players[killerPlayerID]
        if not WR_IsWhiteRoomPlayer(killerPlayer) then
            return
        end

        local unit = WR_FindKiyotaka(killerPlayer)
        if not WR_IsKiyotakaNearPlot(unit, x, y) then
            return
        end

        WR_RecordKill(killerPlayerID, unit, killedUnitType)
    end)
end

if Events.SerialEventUnitSetDamage ~= nil then
    Events.SerialEventUnitSetDamage.Add(function(playerID, unitID, damage)
        local player = Players[playerID]
        if player == nil then
            return
        end

        local unit = player:GetUnitByID(unitID)
        if unit == nil then
            return
        end

        local key = WR_UnitDamageKey(playerID, unitID)
        local oldDamage = WR_DAMAGE_CACHE[key]
        local newDamage = unit:GetDamage()
        if type(damage) == "number" then
            newDamage = damage
        end

        WR_DAMAGE_CACHE[key] = newDamage
        if oldDamage == nil or newDamage <= oldDamage then
            return
        end

        if unit:GetUnitType() == UNIT_WR_KIYOTAKA and WR_IsWhiteRoomPlayer(player) then
            WR_RecordDamageTaken(playerID, unit, oldDamage, newDamage)
            WR_SetSavedNumber(playerID, "LAST_DAMAGE", newDamage)
            return
        end
    end)
end

if Events.EndCombatSim ~= nil then
    Events.EndCombatSim.Add(function(
        attackerPlayerID,
        attackerUnitID,
        attackerUnitDamage,
        attackerFinalUnitDamage,
        attackerMaxHitPoints,
        defenderPlayerID,
        defenderUnitID,
        defenderUnitDamage,
        defenderFinalUnitDamage,
        defenderMaxHitPoints,
        attackerX,
        attackerY,
        defenderX,
        defenderY
    )
        local attackerPlayer = Players[attackerPlayerID]
        if WR_IsWhiteRoomPlayer(attackerPlayer) then
            local attackerUnit = attackerPlayer:GetUnitByID(attackerUnitID)
            if attackerUnit ~= nil
                and attackerUnit:GetUnitType() == UNIT_WR_KIYOTAKA
                and defenderFinalUnitDamage ~= nil
                and defenderUnitDamage ~= nil
                and defenderFinalUnitDamage > defenderUnitDamage then
                WR_RecordDamageDealt(attackerPlayerID, attackerUnit, "combat target")
            end
        end

        local defenderPlayer = Players[defenderPlayerID]
        if WR_IsWhiteRoomPlayer(defenderPlayer) then
            local defenderUnit = defenderPlayer:GetUnitByID(defenderUnitID)
            if defenderUnit ~= nil
                and defenderUnit:GetUnitType() == UNIT_WR_KIYOTAKA
                and attackerFinalUnitDamage ~= nil
                and attackerUnitDamage ~= nil
                and attackerFinalUnitDamage > attackerUnitDamage then
                WR_RecordDamageDealt(defenderPlayerID, defenderUnit, "counterattack target")
            end
        end
    end)
end

WR_PrimeDamageCache()

print("WR Perfect Adaptation: initialized")

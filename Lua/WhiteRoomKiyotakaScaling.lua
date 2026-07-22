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
local WR_UNIT_TYPE_CACHE = {}
local WR_PENDING_COMBAT_DEATHS = {}

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

local function WR_GetFlavorMetrics(playerID)
    return {
        COMBAT = WR_GetSavedNumber(playerID, "COMBAT"),
        ATTACK = WR_GetSavedNumber(playerID, "ATTACK"),
        RESISTANCE = WR_GetSavedNumber(playerID, "RESISTANCE"),
        HEALING = WR_GetSavedNumber(playerID, "HEALING"),
        DESPERATION = WR_GetSavedNumber(playerID, "DESPERATION"),
        MOVE_CHANCE = WR_GetSavedNumber(playerID, "MOVE_CHANCE")
    }
end

local function WR_RegisterFlavorDeployment(playerID, unit)
    if WR_KiyotakaFlavorRegisterDeployment ~= nil then
        WR_KiyotakaFlavorRegisterDeployment(playerID, unit, WR_GetFlavorMetrics(playerID))
    end
end

local function WR_CheckFlavorMilestones(playerID, unit)
    if WR_KiyotakaFlavorCheckMilestones ~= nil then
        WR_KiyotakaFlavorCheckMilestones(playerID, unit, WR_GetFlavorMetrics(playerID))
    end
end

local function WR_UnitDamageKey(playerID, unitID)
    return tostring(playerID) .. ":" .. tostring(unitID)
end

local function WR_CacheUnitType(playerID, unitID)
    if playerID == nil or unitID == nil or unitID < 0 then
        return nil
    end

    local key = WR_UnitDamageKey(playerID, unitID)
    local player = Players[playerID]
    local unit = player ~= nil and player:GetUnitByID(unitID) or nil
    if unit ~= nil then
        WR_UNIT_TYPE_CACHE[key] = unit:GetUnitType()
    end

    return WR_UNIT_TYPE_CACHE[key]
end

local function WR_RememberCombatDeath(killedPlayerID, killedUnitID, killedUnitType, killerPlayerID)
    if killedPlayerID == nil
        or killedUnitID == nil
        or killedUnitID < 0
        or killerPlayerID == nil
        or killerPlayerID < 0 then
        return
    end

    WR_PENDING_COMBAT_DEATHS[WR_UnitDamageKey(killedPlayerID, killedUnitID)] = {
        turn = Game.GetGameTurn(),
        killerPlayerID = killerPlayerID,
        killedUnitType = killedUnitType
    }
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

    WR_RegisterFlavorDeployment(playerID, unit)
    WR_SetSavedNumber(playerID, "LOW_HP_TURN", turn)
    WR_ChangeSavedNumber(playerID, "COMBAT", 75)
    WR_ChangeSavedNumber(playerID, "RESISTANCE", 75)
    WR_ChangeSavedNumber(playerID, "PENDING_HEAL", 3)
    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_LogCounters(playerID, "survived below 25 HP (" .. reason .. ")")

    if WR_KiyotakaFlavorEvent ~= nil then
        WR_KiyotakaFlavorEvent(
            playerID,
            unit,
            "LOW_HP",
            "CRITICAL SURVIVAL // SUBJECT 004",
            "Below 25 HP // Combat +0.75% // Resistance +0.75% // Recovery queued +3 HP",
            {
                forceBark = true,
                bannerTitle = "SUBJECT 004 // CRITICAL SURVIVAL",
                bannerSubtitle = "Failure conditions rejected // Adaptation accelerated"
            }
        )
    end

    WR_CheckFlavorMilestones(playerID, unit)
end

local function WR_RecordDamageTaken(playerID, unit, oldDamage, newDamage)
    if newDamage <= oldDamage then
        return
    end

    WR_RegisterFlavorDeployment(playerID, unit)
    WR_ChangeSavedNumber(playerID, "RESISTANCE", 19)
    WR_ChangeSavedNumber(playerID, "HEALING", 13)
    WR_ChangeSavedNumber(playerID, "DESPERATION", 13)

    if oldDamage < 75 and newDamage >= 75 then
        WR_RecordLowHpSurvival(playerID, unit, "damage taken")
    end

    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_LogCounters(playerID, "took damage")

    if WR_KiyotakaFlavorEvent ~= nil then
        local eventType = "DAMAGE_TAKEN"
        if oldDamage < 50 and newDamage >= 50 then
            eventType = "BELOW_HALF"
        end

        WR_KiyotakaFlavorEvent(
            playerID,
            unit,
            eventType,
            "DAMAGE ASSIMILATED // SUBJECT 004",
            string.format(
                "HP %d -> %d // Resistance +0.19%% // Healing +0.13%% // Low-HP power +0.13%%",
                100 - oldDamage,
                100 - newDamage
            ),
            {forceBark = false}
        )
    end


    WR_CheckFlavorMilestones(playerID, unit)
end

local function WR_RecordDamageDealt(playerID, unit, targetLabel, flavorEventType)
    WR_RegisterFlavorDeployment(playerID, unit)
    local oldMoveChance = WR_GetSavedNumber(playerID, "MOVE_CHANCE")
    WR_ChangeSavedNumber(playerID, "COMBAT", 13)
    WR_ChangeSavedNumber(playerID, "ATTACK", 13)
    WR_ChangeSavedNumber(playerID, "MOVE_CHANCE", 7)
    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_LogCounters(playerID, "dealt damage to " .. targetLabel)

    if WR_KiyotakaFlavorEvent ~= nil then
        WR_KiyotakaFlavorEvent(
            playerID,
            unit,
            flavorEventType or "DAMAGE_DEALT",
            "COMBAT PATTERN ACQUIRED // SUBJECT 004",
            "Target " .. tostring(targetLabel) .. " // Combat +0.13% // Attack +0.13% // Flow +0.07%",
            {forceBark = false}
        )
    end


    local newMoveChance = WR_GetSavedNumber(playerID, "MOVE_CHANCE")
    if oldMoveChance < 10000 and newMoveChance >= 10000 and WR_KiyotakaFlavorEvent ~= nil then
        WR_KiyotakaFlavorEvent(
            playerID,
            unit,
            "FLOW_STATE",
            "FLOW STATE ACHIEVED // SUBJECT 004",
            "Movement-after-combat threshold reached // Stored chance 100.00%",
            {
                forceBark = true,
                bannerTitle = "SUBJECT 004 // FLOW STATE",
                bannerSubtitle = "The pattern is complete // Movement is no longer interrupted"
            }
        )
    end

    WR_CheckFlavorMilestones(playerID, unit)
end

local function WR_RecordKill(playerID, unit, killedUnitType, flavorEventType)
    local killedUnitInfo = GameInfo.Units[killedUnitType]
    local killedClass = killedUnitInfo and killedUnitInfo.CombatClass or nil
    WR_RegisterFlavorDeployment(playerID, unit)

    WR_ChangeSavedNumber(playerID, "COMBAT", 25)
    WR_ChangeExperience(unit, 1)

    local classValue = 0
    if killedClass ~= nil then
        local suffix = WR_ClassSuffix(killedClass)
        if suffix ~= nil then
            classValue = WR_ChangeSavedNumber(playerID, "CLASS_" .. suffix, 25)
        end
    end

    WR_ApplyPerfectAdaptation(playerID, unit)
    WR_LogCounters(playerID, "kill")

    if WR_KiyotakaFlavorEvent ~= nil then
        local killedUnitLabel = killedUnitInfo and killedUnitInfo.Description or "UNKNOWN TARGET"
        if killedUnitInfo ~= nil and killedUnitInfo.Description ~= nil then
            killedUnitLabel = Locale.ConvertTextKey(killedUnitInfo.Description)
        end

        local classLabel = killedClass or "UNKNOWN CLASS"
        classLabel = string.gsub(classLabel, "UNITCOMBAT_", "")
        classLabel = string.gsub(classLabel, "_", " ")

        WR_KiyotakaFlavorEvent(
            playerID,
            unit,
            flavorEventType or "KILL",
            "TARGET NEUTRALIZED // SUBJECT 004",
            tostring(killedUnitLabel) .. " // " .. classLabel .. " // Combat +0.25% // Class adaptation +0.25% // XP +1",
            {forceBark = true}
        )

        if killedClass ~= nil and classValue > 0 and WR_KiyotakaFlavorCheckClassMilestone ~= nil then
            WR_KiyotakaFlavorCheckClassMilestone(playerID, unit, classLabel, classValue)
        end
    end


    WR_CheckFlavorMilestones(playerID, unit)
end

local function WR_PrimeDamageCache()
    for playerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
        local player = Players[playerID]
        if player ~= nil and player:IsAlive() then
            for unit in player:Units() do
                local key = WR_UnitDamageKey(playerID, unit:GetID())
                WR_DAMAGE_CACHE[key] = unit:GetDamage()
                WR_UNIT_TYPE_CACHE[key] = unit:GetUnitType()
            end
        end
    end
end

local function WR_WasDestroyed(finalDamage, maxHitPoints)
    return type(finalDamage) == "number"
        and type(maxHitPoints) == "number"
        and maxHitPoints > 0
        and finalDamage >= maxHitPoints
end

local function WR_GetVerifiedDirectKillType(
    killerPlayerID,
    killedPlayerID,
    killedUnitID,
    finalDamage,
    maxHitPoints
)
    if killedPlayerID == nil or killedUnitID == nil or killedUnitID < 0 then
        return nil
    end

    local key = WR_UnitDamageKey(killedPlayerID, killedUnitID)
    local pendingDeath = WR_PENDING_COMBAT_DEATHS[key]
    if pendingDeath ~= nil
        and pendingDeath.turn == Game.GetGameTurn()
        and pendingDeath.killerPlayerID == killerPlayerID then
        WR_PENDING_COMBAT_DEATHS[key] = nil
        return pendingDeath.killedUnitType or WR_CacheUnitType(killedPlayerID, killedUnitID)
    end

    local killedPlayer = Players[killedPlayerID]
    local killedUnit = killedPlayer ~= nil and killedPlayer:GetUnitByID(killedUnitID) or nil
    if WR_WasDestroyed(finalDamage, maxHitPoints) or killedUnit == nil then
        WR_PENDING_COMBAT_DEATHS[key] = nil
        return WR_CacheUnitType(killedPlayerID, killedUnitID)
    end

    return nil
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

    if WR_KiyotakaFlavorEvent ~= nil then
        WR_KiyotakaFlavorEvent(
            playerID,
            unit,
            "RECOVERY",
            "RECOVERY PROTOCOL COMPLETE // SUBJECT 004",
            "Queued critical-survival recovery restored " .. tostring(totalHeal) .. " HP",
            {forceBark = true}
        )
    end
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

    WR_RegisterFlavorDeployment(playerID, unit)
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
        local killedPlayer = Players[killedPlayerID]
        local killedUnit = killedPlayer ~= nil and killedPlayer:GetUnitByID(killedUnitID) or nil

        WR_RememberCombatDeath(killedPlayerID, killedUnitID, killedUnitType, killerPlayerID)

        if killedUnitType == UNIT_WR_KIYOTAKA then
            if WR_IsWhiteRoomPlayer(killedPlayer) and WR_KiyotakaFlavorRecordDeath ~= nil then
                WR_KiyotakaFlavorRecordDeath(killedPlayerID, killedUnit)
            end
        end
    end)
end

if Events.SerialEventUnitCreated ~= nil then
    Events.SerialEventUnitCreated.Add(function(playerID, unitID)
        WR_PENDING_COMBAT_DEATHS[WR_UnitDamageKey(playerID, unitID)] = nil
        WR_CacheUnitType(playerID, unitID)
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

if Events.RunCombatSim ~= nil then
    Events.RunCombatSim.Add(function(
        attackerPlayerID,
        attackerUnitID,
        attackerUnitDamage,
        attackerFinalUnitDamage,
        attackerMaxHitPoints,
        defenderPlayerID,
        defenderUnitID
    )
        WR_CacheUnitType(attackerPlayerID, attackerUnitID)
        WR_CacheUnitType(defenderPlayerID, defenderUnitID)
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
                local flavorEventType = "DAMAGE_DEALT"
                if type(defenderUnitDamage) == "number" and defenderUnitDamage > 0 then
                    flavorEventType = "WOUNDED_TARGET"
                elseif type(attackerFinalUnitDamage) == "number"
                    and type(attackerUnitDamage) == "number"
                    and attackerFinalUnitDamage <= attackerUnitDamage then
                    flavorEventType = "NO_DAMAGE"
                end

                WR_RecordDamageDealt(attackerPlayerID, attackerUnit, "combat target", flavorEventType)

                local killedUnitType = WR_GetVerifiedDirectKillType(
                    attackerPlayerID,
                    defenderPlayerID,
                    defenderUnitID,
                    defenderFinalUnitDamage,
                    defenderMaxHitPoints
                )
                if killedUnitType ~= nil then
                    local killFlavorEventType = defenderUnitDamage > 0 and "WOUNDED_KILL" or "KILL"
                    WR_RecordKill(attackerPlayerID, attackerUnit, killedUnitType, killFlavorEventType)
                end
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
                WR_RecordDamageDealt(defenderPlayerID, defenderUnit, "counterattack target", "COUNTERATTACK")

                local killedUnitType = WR_GetVerifiedDirectKillType(
                    defenderPlayerID,
                    attackerPlayerID,
                    attackerUnitID,
                    attackerFinalUnitDamage,
                    attackerMaxHitPoints
                )
                if killedUnitType ~= nil then
                    local killFlavorEventType = attackerUnitDamage > 0 and "WOUNDED_KILL" or "KILL"
                    WR_RecordKill(defenderPlayerID, defenderUnit, killedUnitType, killFlavorEventType)
                end
            end
        end
    end)
end

WR_PrimeDamageCache()

print("WR Perfect Adaptation: initialized")

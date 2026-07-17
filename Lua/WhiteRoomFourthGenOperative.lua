-- White Room Kid Kiyotaka - 4th Generation Operative

print("WhiteRoomFourthGenOperative.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local UNIT_WR_FOURTH_GEN_OPERATIVE = GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE
local WR_OPERATIVE_SAVE = Modding.OpenSaveData()

local function WR_IsWhiteRoomPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_IsOperativeUnit(unit)
    return unit ~= nil and unit:GetUnitType() == UNIT_WR_FOURTH_GEN_OPERATIVE
end

local function WR_IsFourthGenOperative(playerID, unitID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return false
    end

    return WR_IsOperativeUnit(player:GetUnitByID(unitID))
end

local function WR_OperativeGlobalKey(playerID, suffix)
    return "WR_OPERATIVE_" .. tostring(playerID) .. "_" .. suffix
end

local function WR_OperativeUnitKey(playerID, unitID)
    return WR_OperativeGlobalKey(playerID, "UNIT_" .. tostring(unitID) .. "_SERIAL")
end

local function WR_OperativeRecordKey(playerID, serial, suffix)
    return WR_OperativeGlobalKey(playerID, "RECORD_" .. tostring(serial) .. "_" .. suffix)
end

local function WR_GetNumber(key)
    return tonumber(WR_OPERATIVE_SAVE.GetValue(key)) or 0
end

local function WR_SetNumber(key, value)
    WR_OPERATIVE_SAVE.SetValue(key, value or 0)
end

local function WR_ChangeNumber(key, delta)
    local value = WR_GetNumber(key) + (delta or 0)
    WR_SetNumber(key, value)
    return value
end

local function WR_GetRecordNumber(playerID, serial, suffix)
    return WR_GetNumber(WR_OperativeRecordKey(playerID, serial, suffix))
end

local function WR_SetRecordNumber(playerID, serial, suffix, value)
    WR_SetNumber(WR_OperativeRecordKey(playerID, serial, suffix), value)
end

local function WR_ChangeRecordNumber(playerID, serial, suffix, delta)
    return WR_ChangeNumber(WR_OperativeRecordKey(playerID, serial, suffix), delta)
end

local function WR_ChangeGlobalNumber(playerID, suffix, delta)
    return WR_ChangeNumber(WR_OperativeGlobalKey(playerID, suffix), delta)
end

local function WR_OperativeCallsign(serial)
    return string.format("OPERATIVE-%02d", serial)
end

local function WR_GetOperativeSerial(playerID, unitID)
    return WR_GetNumber(WR_OperativeUnitKey(playerID, unitID))
end

local function WR_EnsureOperativeIdentity(playerID, unit)
    if not WR_IsOperativeUnit(unit) then
        return 0
    end

    local unitID = unit:GetID()
    local serial = WR_GetOperativeSerial(playerID, unitID)
    if serial > 0 then
        WR_SetRecordNumber(playerID, serial, "ACTIVE", 1)
        WR_SetRecordNumber(playerID, serial, "UNIT_ID", unitID)
        return serial
    end

    serial = WR_ChangeGlobalNumber(playerID, "NEXT_SERIAL", 1)
    WR_SetNumber(WR_OperativeUnitKey(playerID, unitID), serial)
    WR_SetRecordNumber(playerID, serial, "ACTIVE", 1)
    WR_SetRecordNumber(playerID, serial, "UNIT_ID", unitID)
    WR_SetRecordNumber(playerID, serial, "DEPLOY_TURN", Game.GetGameTurn())
    WR_SetRecordNumber(playerID, serial, "LOSS_TURN", -1)

    if WR_RecordTelemetry ~= nil then
        WR_RecordTelemetry(
            playerID,
            "OPERATIVE",
            WR_OperativeCallsign(serial) .. " REGISTERED",
            string.format(
                "Roster link established // Level %d // XP %d // Active capacity tracked",
                unit:GetLevel(),
                unit:GetExperience()
            )
        )
    end

    return serial
end

local function WR_IsFriendlyTerritory(playerID, unit)
    local plot = unit ~= nil and unit:GetPlot() or nil
    return plot ~= nil and plot:GetOwner() == playerID
end

local function WR_DamageDelta(beforeDamage, afterDamage)
    if type(beforeDamage) ~= "number" or type(afterDamage) ~= "number" then
        return 0
    end

    return math.max(0, afterDamage - beforeDamage)
end

local function WR_WasDestroyed(finalDamage, maxHitPoints)
    return type(finalDamage) == "number"
        and type(maxHitPoints) == "number"
        and maxHitPoints > 0
        and finalDamage >= maxHitPoints
end

local function WR_RecordOperativeEngagement(playerID, unit, damageDealt, damageTaken, attackedWounded, friendlyTerritory, killedTarget)
    local serial = WR_EnsureOperativeIdentity(playerID, unit)
    if serial <= 0 then
        return
    end

    local combats = WR_ChangeRecordNumber(playerID, serial, "COMBATS", 1)
    local totalDealt = WR_ChangeRecordNumber(playerID, serial, "DAMAGE_DEALT", damageDealt)
    local totalTaken = WR_ChangeRecordNumber(playerID, serial, "DAMAGE_TAKEN", damageTaken)
    WR_ChangeGlobalNumber(playerID, "TOTAL_COMBATS", 1)
    WR_ChangeGlobalNumber(playerID, "TOTAL_DAMAGE_DEALT", damageDealt)
    WR_ChangeGlobalNumber(playerID, "TOTAL_DAMAGE_TAKEN", damageTaken)

    if attackedWounded then
        WR_ChangeRecordNumber(playerID, serial, "WOUNDED_ENGAGEMENTS", 1)
        WR_ChangeGlobalNumber(playerID, "TOTAL_WOUNDED_ENGAGEMENTS", 1)
    end

    if friendlyTerritory then
        WR_ChangeRecordNumber(playerID, serial, "FRIENDLY_ENGAGEMENTS", 1)
        WR_ChangeGlobalNumber(playerID, "TOTAL_FRIENDLY_ENGAGEMENTS", 1)
    end

    if killedTarget then
        WR_ChangeRecordNumber(playerID, serial, "KILLS", 1)
        WR_ChangeGlobalNumber(playerID, "TOTAL_KILLS", 1)
    end

    if WR_RecordTelemetry ~= nil then
        local flags = {}
        if killedTarget then
            table.insert(flags, "TARGET NEUTRALIZED")
        end
        if attackedWounded then
            table.insert(flags, "WOUNDED TARGET")
        end
        if friendlyTerritory then
            table.insert(flags, "CONTROLLED ENVIRONMENT")
        end
        if #flags == 0 then
            table.insert(flags, "STANDARD ENGAGEMENT")
        end

        WR_RecordTelemetry(
            playerID,
            "OPERATIVE",
            WR_OperativeCallsign(serial) .. (killedTarget and " // TARGET ELIMINATED" or " // ENGAGEMENT RECORDED"),
            string.format(
                "Damage %d dealt / %d taken // Combat %d // Career damage %d / %d // %s",
                damageDealt,
                damageTaken,
                combats,
                totalDealt,
                totalTaken,
                table.concat(flags, " // ")
            )
        )
    end
end

local function WR_RegisterActiveOperatives(playerID, player)
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    for unit in player:Units() do
        if WR_IsOperativeUnit(unit) then
            WR_EnsureOperativeIdentity(playerID, unit)
        end
    end
end

function WR_FourthGenOperative_DoTurn(playerID)
    WR_RegisterActiveOperatives(playerID, Players[playerID])
end

GameEvents.PlayerDoTurn.Add(WR_FourthGenOperative_DoTurn)

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
        defenderMaxHitPoints
    )
        local attackerPlayer = Players[attackerPlayerID]
        if WR_IsWhiteRoomPlayer(attackerPlayer) then
            local attackerUnit = attackerPlayer:GetUnitByID(attackerUnitID)
            if WR_IsOperativeUnit(attackerUnit) then
                WR_RecordOperativeEngagement(
                    attackerPlayerID,
                    attackerUnit,
                    WR_DamageDelta(defenderUnitDamage, defenderFinalUnitDamage),
                    WR_DamageDelta(attackerUnitDamage, attackerFinalUnitDamage),
                    defenderUnitID ~= nil and defenderUnitID >= 0 and type(defenderUnitDamage) == "number" and defenderUnitDamage > 0,
                    WR_IsFriendlyTerritory(attackerPlayerID, attackerUnit),
                    defenderUnitID ~= nil and defenderUnitID >= 0 and WR_WasDestroyed(defenderFinalUnitDamage, defenderMaxHitPoints)
                )
            end
        end

        local defenderPlayer = Players[defenderPlayerID]
        if WR_IsWhiteRoomPlayer(defenderPlayer) then
            local defenderUnit = defenderPlayer:GetUnitByID(defenderUnitID)
            if WR_IsOperativeUnit(defenderUnit) then
                WR_RecordOperativeEngagement(
                    defenderPlayerID,
                    defenderUnit,
                    WR_DamageDelta(attackerUnitDamage, attackerFinalUnitDamage),
                    WR_DamageDelta(defenderUnitDamage, defenderFinalUnitDamage),
                    false,
                    WR_IsFriendlyTerritory(defenderPlayerID, defenderUnit),
                    attackerUnitID ~= nil and attackerUnitID >= 0 and WR_WasDestroyed(attackerFinalUnitDamage, attackerMaxHitPoints)
                )
            end
        end
    end)
end

if GameEvents.UnitPrekill ~= nil then
    GameEvents.UnitPrekill.Add(function(killedPlayerID, killedUnitID, killedUnitType, x, y, delay, killerPlayerID)
        if killedUnitType ~= UNIT_WR_FOURTH_GEN_OPERATIVE then
            return
        end

        local player = Players[killedPlayerID]
        if not WR_IsWhiteRoomPlayer(player) then
            return
        end

        local unit = player:GetUnitByID(killedUnitID)
        local serial = WR_GetOperativeSerial(killedPlayerID, killedUnitID)
        if serial <= 0 and unit ~= nil then
            serial = WR_EnsureOperativeIdentity(killedPlayerID, unit)
        end
        if serial <= 0 then
            return
        end

        WR_SetRecordNumber(killedPlayerID, serial, "ACTIVE", 0)
        WR_SetRecordNumber(killedPlayerID, serial, "LOSS_TURN", Game.GetGameTurn())
        if unit ~= nil then
            WR_SetRecordNumber(killedPlayerID, serial, "FINAL_LEVEL", unit:GetLevel())
            WR_SetRecordNumber(killedPlayerID, serial, "FINAL_XP", unit:GetExperience())
        end
        WR_SetNumber(WR_OperativeUnitKey(killedPlayerID, killedUnitID), 0)
        WR_ChangeGlobalNumber(killedPlayerID, "TOTAL_LOSSES", 1)

        if WR_RecordTelemetry ~= nil then
            local cause = "operational loss"
            local killer = killerPlayerID ~= nil and killerPlayerID >= 0 and Players[killerPlayerID] or nil
            if killer ~= nil then
                cause = "lost to " .. tostring(killer:GetName() or killerPlayerID)
            end

            WR_RecordTelemetry(
                killedPlayerID,
                "OPERATIVE",
                WR_OperativeCallsign(serial) .. " // OPERATIVE LOST",
                string.format(
                    "%s // Final record: Level %d // %d combats // %d kills",
                    cause,
                    WR_GetRecordNumber(killedPlayerID, serial, "FINAL_LEVEL"),
                    WR_GetRecordNumber(killedPlayerID, serial, "COMBATS"),
                    WR_GetRecordNumber(killedPlayerID, serial, "KILLS")
                )
            )
        end
    end)
end

if GameEvents.PlayerCanGiftUnit ~= nil then
    GameEvents.PlayerCanGiftUnit.Add(function(playerID, cityStateID, unitID)
        if WR_IsFourthGenOperative(playerID, unitID) then
            return false
        end

        return true
    end)
end

for playerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
    WR_RegisterActiveOperatives(playerID, Players[playerID])
end

print("WR 4th Generation Operative: initialized with persistent service records")

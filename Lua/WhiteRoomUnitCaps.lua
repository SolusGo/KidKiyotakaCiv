-- White Room Kid Kiyotaka - Unique Unit Caps

print("WhiteRoomUnitCaps.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local UNIT_WR_KIYOTAKA = GameInfoTypes.UNIT_WR_KIYOTAKA
local UNIT_WR_FOURTH_GEN_OPERATIVE = GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE
local WR_UNIT_CAPS_DEBUG = false

local function WR_Debug(message)
    if WR_UNIT_CAPS_DEBUG then
        print(message)
    end
end

local WR_UNIT_CAPS = {}
WR_UNIT_CAPS[UNIT_WR_KIYOTAKA] = 1
WR_UNIT_CAPS[UNIT_WR_FOURTH_GEN_OPERATIVE] = 3

local function WR_IsRestrictedWhiteRoomUnit(unitType)
    return (UNIT_WR_KIYOTAKA ~= nil and unitType == UNIT_WR_KIYOTAKA)
        or (UNIT_WR_FOURTH_GEN_OPERATIVE ~= nil and unitType == UNIT_WR_FOURTH_GEN_OPERATIVE)
end

local function WR_IsWhiteRoomPlayer(player)
    return player
        and player:IsAlive()
        and CIV_WHITE_ROOM_KID ~= nil
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_GetUnitName(unitType)
    local unitInfo = GameInfo.Units[unitType]
    return unitInfo and unitInfo.Type or tostring(unitType)
end

local function WR_GetUnitScore(unit)
    local level = unit.GetLevel and unit:GetLevel() or 0
    local xp = unit.GetExperience and unit:GetExperience() or 0
    return (level * 100000) + (xp * 1000) + unit:GetID()
end

local function WR_GetCappedUnits(player, unitType)
    local units = {}

    for unit in player:Units() do
        if unit:GetUnitType() == unitType then
            units[#units + 1] = unit
        end
    end

    table.sort(units, function(a, b)
        return WR_GetUnitScore(a) > WR_GetUnitScore(b)
    end)

    return units
end

local function WR_CountUnits(player, unitType)
    local count = 0

    for unit in player:Units() do
        if unit:GetUnitType() == unitType then
            count = count + 1
        end
    end

    return count
end

local function WR_CountOtherQueuedUnits(player, unitType, excludedCityID)
    local count = 0

    for city in player:Cities() do
        local queueLength = city:GetOrderQueueLength()
        for index = 0, queueLength - 1 do
            local orderType, queuedUnitType = city:GetOrderFromQueue(index)
            if orderType == OrderTypes.ORDER_TRAIN
                and queuedUnitType == unitType
                and not (city:GetID() == excludedCityID and index == 0) then
                count = count + 1
            end
        end
    end

    return count
end

local function WR_PruneExcessQueuedUnits(player, unitType, cap)
    local remainingSlots = math.max(0, cap - WR_CountUnits(player, unitType))

    for city in player:Cities() do
        local removals = {}
        local queueLength = city:GetOrderQueueLength()

        for index = 0, queueLength - 1 do
            local orderType, queuedUnitType = city:GetOrderFromQueue(index)
            if orderType == OrderTypes.ORDER_TRAIN and queuedUnitType == unitType then
                if remainingSlots > 0 then
                    remainingSlots = remainingSlots - 1
                else
                    removals[#removals + 1] = index
                end
            end
        end

        for removalIndex = #removals, 1, -1 do
            city:PopOrder(removals[removalIndex], false, true)
            WR_Debug(string.format(
                "WR Unit Caps: removed excess queued %s from %s; cap is %d",
                WR_GetUnitName(unitType),
                city:GetName(),
                cap
            ))
        end
    end
end

local function WR_EnforceUnitCap(player, unitType, cap)
    if unitType == nil or cap == nil then
        return
    end

    local units = WR_GetCappedUnits(player, unitType)
    if #units <= cap then
        return
    end

    for i = cap + 1, #units do
        local unit = units[i]
        local plot = unit:GetPlot()
        local x = plot and plot:GetX() or -1
        local y = plot and plot:GetY() or -1

        unit:Kill(false, -1)
        WR_Debug(string.format(
            "WR Unit Caps: removed extra %s for %s at (%d,%d); cap is %d",
            WR_GetUnitName(unitType),
            player:GetName(),
            x,
            y,
            cap
        ))
    end
end

function WR_UnitCaps_DoTurn(playerID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    for unitType, cap in pairs(WR_UNIT_CAPS) do
        WR_EnforceUnitCap(player, unitType, cap)
        WR_PruneExcessQueuedUnits(player, unitType, cap)
    end
end

GameEvents.PlayerDoTurn.Add(WR_UnitCaps_DoTurn)

if GameEvents.PlayerCanTrain ~= nil then
    GameEvents.PlayerCanTrain.Add(function(playerID, unitType)
        local player = Players[playerID]
        if not WR_IsWhiteRoomPlayer(player) then
            return not WR_IsRestrictedWhiteRoomUnit(unitType)
        end

        local cap = WR_UNIT_CAPS[unitType]
        if cap == nil then
            return true
        end

        if WR_CountUnits(player, unitType) >= cap then
            WR_Debug(string.format(
                "WR Unit Caps: blocked %s training for %s; cap is %d",
                WR_GetUnitName(unitType),
                player:GetName(),
                cap
            ))
            return false
        end

        return true
    end)
end

if GameEvents.CityCanTrain ~= nil then
    GameEvents.CityCanTrain.Add(function(playerID, cityID, unitType)
        local player = Players[playerID]
        if not WR_IsWhiteRoomPlayer(player) then
            return not WR_IsRestrictedWhiteRoomUnit(unitType)
        end

        local cap = WR_UNIT_CAPS[unitType]
        if cap == nil then
            return true
        end

        return WR_CountUnits(player, unitType)
            + WR_CountOtherQueuedUnits(player, unitType, cityID) < cap
    end)
end

if GameEvents.UnitCreated ~= nil then
    GameEvents.UnitCreated.Add(function(playerID, unitID, unitType, plotX, plotY)
        local player = Players[playerID]
        if not WR_IsWhiteRoomPlayer(player) then
            return
        end

        local cap = WR_UNIT_CAPS[unitType]
        if cap ~= nil then
            WR_EnforceUnitCap(player, unitType, cap)
        end
    end)
end

if GameEvents.CanHaveUpgrade ~= nil then
    GameEvents.CanHaveUpgrade.Add(function(playerID, unitID, unitClassType, unitType)
        local player = Players[playerID]
        if not WR_IsWhiteRoomPlayer(player) and WR_IsRestrictedWhiteRoomUnit(unitType) then
            return false
        end

        return true
    end)
end

print("WR Unit Caps: initialized; Kiyotaka cap 1, 4th Generation Operative cap 3")

-- White Room Kid Kiyotaka - City Ranged Strike Adaptation

print("WhiteRoomCityRangedStrikeAdaptation.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID

local WR_CITY_RANGED_SAVE = Modding.OpenSaveData()
local WR_CITY_RANGED_STATE = {}
local WR_HAS_PERFORMED_SUPPORT = nil
local WR_CITY_RANGED_DEBUG = false
local WR_CITY_RANGED_PERCENT_PER_STACK = 0.25

local function WR_Debug(message)
    if WR_CITY_RANGED_DEBUG then
        print(message)
    end
end

local WR_CITY_RANGED_DUMMY_BUILDINGS = {
    { percent = 50, type = "BUILDING_WR_CITY_RANGE_ADAPT_50", id = GameInfoTypes.BUILDING_WR_CITY_RANGE_ADAPT_50 },
    { percent = 25, type = "BUILDING_WR_CITY_RANGE_ADAPT_25", id = GameInfoTypes.BUILDING_WR_CITY_RANGE_ADAPT_25 },
    { percent = 10, type = "BUILDING_WR_CITY_RANGE_ADAPT_10", id = GameInfoTypes.BUILDING_WR_CITY_RANGE_ADAPT_10 },
    { percent = 5, type = "BUILDING_WR_CITY_RANGE_ADAPT_5", id = GameInfoTypes.BUILDING_WR_CITY_RANGE_ADAPT_5 },
    { percent = 1, type = "BUILDING_WR_CITY_RANGE_ADAPT_1", id = GameInfoTypes.BUILDING_WR_CITY_RANGE_ADAPT_1 }
}

local function WR_IsWhiteRoomPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_CityKey(playerID, city)
    return tostring(playerID) .. ":" .. tostring(city:GetID())
end

local function WR_SaveKey(playerID, city, suffix)
    return "WR_CITY_RANGED_" .. WR_CityKey(playerID, city) .. "_" .. suffix
end

local function WR_GetSavedNumber(playerID, city, suffix)
    local value = WR_CITY_RANGED_SAVE.GetValue(WR_SaveKey(playerID, city, suffix))
    if type(value) ~= "number" then
        return 0
    end

    return value
end

local function WR_SetSavedNumber(playerID, city, suffix, value)
    WR_CITY_RANGED_SAVE.SetValue(WR_SaveKey(playerID, city, suffix), value)
end

local function WR_ApplyRangedStacks(city, stacks)
    local remaining = math.floor(math.max(0, stacks) * WR_CITY_RANGED_PERCENT_PER_STACK)
    local desiredCounts = {}

    for _, entry in ipairs(WR_CITY_RANGED_DUMMY_BUILDINGS) do
        desiredCounts[entry.type] = 0
        if entry.id ~= nil and remaining >= entry.percent then
            local count = math.floor(remaining / entry.percent)
            desiredCounts[entry.type] = count
            remaining = remaining - (count * entry.percent)
        end
    end

    for _, entry in ipairs(WR_CITY_RANGED_DUMMY_BUILDINGS) do
        if entry.id ~= nil then
            local desired = desiredCounts[entry.type] or 0
            if city:GetNumRealBuilding(entry.id) ~= desired then
                city:SetNumRealBuilding(entry.id, desired)
            end
        end
    end
end

local function WR_RecordRangedStrike(playerID, city, reason)
    local stacks = WR_GetSavedNumber(playerID, city, "ATTACK_STACKS") + 1
    WR_SetSavedNumber(playerID, city, "ATTACK_STACKS", stacks)
    WR_ApplyRangedStacks(city, stacks)

    WR_Debug(string.format(
        "WR City Ranged Adaptation: %s fired a ranged strike (%s); ranged stacks now %d (+%.2f%%, applied +%d%%)",
        city:GetName(),
        reason,
        stacks,
        stacks * WR_CITY_RANGED_PERCENT_PER_STACK,
        math.floor(stacks * WR_CITY_RANGED_PERCENT_PER_STACK)
    ))

    if WR_RecordTelemetry ~= nil then
        WR_RecordTelemetry(
            playerID,
            "CITY",
            "RANGED DOCTRINE UPDATED // " .. city:GetName(),
            string.format(
                "Strike confirmed // Stack %d // Stored +%.2f%% // Applied +%d%%",
                stacks,
                stacks * WR_CITY_RANGED_PERCENT_PER_STACK,
                math.floor(stacks * WR_CITY_RANGED_PERCENT_PER_STACK)
            )
        )
    end
end

local function WR_GetHasPerformedRangedStrike(city)
    if city == nil then
        return false, false
    end

    local ok, hasPerformed = pcall(function()
        return city:HasPerformedRangedStrikeThisTurn()
    end)

    if WR_HAS_PERFORMED_SUPPORT == nil then
        WR_HAS_PERFORMED_SUPPORT = ok
        if ok then
            WR_Debug("WR City Ranged Probe: city:HasPerformedRangedStrikeThisTurn() is available")
        else
            WR_Debug("WR City Ranged Probe: city:HasPerformedRangedStrikeThisTurn() is not available")
        end
    end

    if not ok then
        return false, false
    end

    return true, hasPerformed == true
end

local function WR_PollCity(playerID, city, reason)
    local supported, hasPerformed = WR_GetHasPerformedRangedStrike(city)
    if not supported then
        return
    end

    local key = WR_CityKey(playerID, city)
    local previous = WR_CITY_RANGED_STATE[key]
    WR_CITY_RANGED_STATE[key] = hasPerformed

    if hasPerformed and previous ~= true then
        WR_Debug(string.format(
            "WR City Ranged Probe: %s has performed a ranged strike this turn (%s)",
            city:GetName(),
            reason
        ))
        WR_RecordRangedStrike(playerID, city, reason)
    end
end

local function WR_ApplySavedRangedStacksForCity(playerID, city)
    WR_ApplyRangedStacks(city, WR_GetSavedNumber(playerID, city, "ATTACK_STACKS"))
end

local function WR_PollPlayerCities(playerID, reason)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    for city in player:Cities() do
        if reason == "PlayerDoTurn" or reason == "initial" then
            WR_ApplySavedRangedStacksForCity(playerID, city)
        end
        WR_PollCity(playerID, city, reason)
    end
end

local function WR_PollAllWhiteRoomCities(reason)
    for playerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
        WR_PollPlayerCities(playerID, reason)
    end
end

GameEvents.PlayerDoTurn.Add(function(playerID)
    WR_PollPlayerCities(playerID, "PlayerDoTurn")
end)

if Events.ActivePlayerTurnStart ~= nil then
    Events.ActivePlayerTurnStart.Add(function()
        WR_PollAllWhiteRoomCities("ActivePlayerTurnStart")
    end)
end

if Events.ActivePlayerTurnEnd ~= nil then
    Events.ActivePlayerTurnEnd.Add(function()
        WR_PollAllWhiteRoomCities("ActivePlayerTurnEnd")
    end)
end

if Events.SerialEventCityInfoDirty ~= nil then
    Events.SerialEventCityInfoDirty.Add(function()
        WR_PollAllWhiteRoomCities("SerialEventCityInfoDirty")
    end)
end

if Events.SpecificCityInfoDirty ~= nil then
    Events.SpecificCityInfoDirty.Add(function(playerID, cityID)
        local player = Players[playerID]
        if WR_IsWhiteRoomPlayer(player) then
            local city = player:GetCityByID(cityID)
            if city ~= nil then
                WR_PollCity(playerID, city, "SpecificCityInfoDirty")
            end
        end
    end)
end

WR_PollAllWhiteRoomCities("initial")

print("WR City Ranged Adaptation: initialized")

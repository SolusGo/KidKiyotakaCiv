-- White Room Kid Kiyotaka - City HP-loss Adaptation

print("WhiteRoomCityHpAdaptation.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID

local WR_CITY_HP_SAVE = Modding.OpenSaveData()
local WR_CITY_DAMAGE_CACHE = {}
local WR_CITY_DEF_PERCENT_PER_STACK = 0.5

local WR_CITY_DEF_DUMMY_BUILDINGS = {
    { percent = 50, type = "BUILDING_WR_CITY_DEF_ADAPT_50", id = GameInfoTypes.BUILDING_WR_CITY_DEF_ADAPT_50 },
    { percent = 25, type = "BUILDING_WR_CITY_DEF_ADAPT_25", id = GameInfoTypes.BUILDING_WR_CITY_DEF_ADAPT_25 },
    { percent = 10, type = "BUILDING_WR_CITY_DEF_ADAPT_10", id = GameInfoTypes.BUILDING_WR_CITY_DEF_ADAPT_10 },
    { percent = 5, type = "BUILDING_WR_CITY_DEF_ADAPT_5", id = GameInfoTypes.BUILDING_WR_CITY_DEF_ADAPT_5 },
    { percent = 1, type = "BUILDING_WR_CITY_DEF_ADAPT_1", id = GameInfoTypes.BUILDING_WR_CITY_DEF_ADAPT_1 }
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
    return "WR_CITY_HP_" .. WR_CityKey(playerID, city) .. "_" .. suffix
end

local function WR_GetSavedNumber(playerID, city, suffix)
    local value = WR_CITY_HP_SAVE.GetValue(WR_SaveKey(playerID, city, suffix))
    if type(value) ~= "number" then
        return 0
    end

    return value
end

local function WR_SetSavedNumber(playerID, city, suffix, value)
    WR_CITY_HP_SAVE.SetValue(WR_SaveKey(playerID, city, suffix), value)
end

local function WR_GetCityDamage(city)
    local ok, damage = pcall(function()
        return city:GetDamage()
    end)

    if ok and type(damage) == "number" then
        return damage
    end

    return 0
end

local function WR_ClearCityDefenseDummies(city)
    for _, entry in ipairs(WR_CITY_DEF_DUMMY_BUILDINGS) do
        if entry.id ~= nil and city:GetNumRealBuilding(entry.id) ~= 0 then
            city:SetNumRealBuilding(entry.id, 0)
        end
    end
end

local function WR_ApplyCityDefenseStacks(city, stacks)
    WR_ClearCityDefenseDummies(city)

    local remaining = math.floor(math.max(0, stacks) * WR_CITY_DEF_PERCENT_PER_STACK)
    for _, entry in ipairs(WR_CITY_DEF_DUMMY_BUILDINGS) do
        if entry.id ~= nil and remaining >= entry.percent then
            local count = math.floor(remaining / entry.percent)
            city:SetNumRealBuilding(entry.id, count)
            remaining = remaining - (count * entry.percent)
        end
    end
end

local function WR_RecordCityHpLoss(playerID, city, oldDamage, newDamage)
    local stacks = WR_GetSavedNumber(playerID, city, "DEF_STACKS") + 1
    WR_SetSavedNumber(playerID, city, "DEF_STACKS", stacks)
    WR_ApplyCityDefenseStacks(city, stacks)

    print(string.format(
        "WR City HP Adaptation: %s took damage (%d -> %d); defense stacks now %d (+%.1f%%, applied +%d%%)",
        city:GetName(),
        oldDamage,
        newDamage,
        stacks,
        stacks * WR_CITY_DEF_PERCENT_PER_STACK,
        math.floor(stacks * WR_CITY_DEF_PERCENT_PER_STACK)
    ))
end

local function WR_PrimeCityDamageCacheForPlayer(playerID, player)
    for city in player:Cities() do
        WR_CITY_DAMAGE_CACHE[WR_CityKey(playerID, city)] = WR_GetCityDamage(city)
        WR_ApplyCityDefenseStacks(city, WR_GetSavedNumber(playerID, city, "DEF_STACKS"))
    end
end

function WR_CityHpAdaptation_DoTurn(playerID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    for city in player:Cities() do
        local key = WR_CityKey(playerID, city)
        local oldDamage = WR_CITY_DAMAGE_CACHE[key]
        local newDamage = WR_GetCityDamage(city)

        if oldDamage ~= nil and newDamage > oldDamage then
            WR_RecordCityHpLoss(playerID, city, oldDamage, newDamage)
        else
            WR_ApplyCityDefenseStacks(city, WR_GetSavedNumber(playerID, city, "DEF_STACKS"))
        end

        WR_CITY_DAMAGE_CACHE[key] = newDamage
        WR_SetSavedNumber(playerID, city, "LAST_DAMAGE", newDamage)
    end
end

GameEvents.PlayerDoTurn.Add(WR_CityHpAdaptation_DoTurn)

for playerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
    local player = Players[playerID]
    if WR_IsWhiteRoomPlayer(player) then
        WR_PrimeCityDamageCacheForPlayer(playerID, player)
    end
end

print("WR City HP Adaptation: initialized")

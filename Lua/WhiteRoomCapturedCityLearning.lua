-- White Room Kid Kiyotaka - Captured City Learning

print("WhiteRoomCapturedCityLearning.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID

local WR_CITY_LOSS_SAVE = Modding.OpenSaveData()
local WR_CITY_LOSS_RECENT_EVENTS = {}

local WR_CITY_LOSS_DEF_DUMMY_BUILDINGS = {
    { percent = 50, type = "BUILDING_WR_CITY_LOSS_DEF_50", id = GameInfoTypes.BUILDING_WR_CITY_LOSS_DEF_50 },
    { percent = 25, type = "BUILDING_WR_CITY_LOSS_DEF_25", id = GameInfoTypes.BUILDING_WR_CITY_LOSS_DEF_25 },
    { percent = 10, type = "BUILDING_WR_CITY_LOSS_DEF_10", id = GameInfoTypes.BUILDING_WR_CITY_LOSS_DEF_10 },
    { percent = 5, type = "BUILDING_WR_CITY_LOSS_DEF_5", id = GameInfoTypes.BUILDING_WR_CITY_LOSS_DEF_5 },
    { percent = 1, type = "BUILDING_WR_CITY_LOSS_DEF_1", id = GameInfoTypes.BUILDING_WR_CITY_LOSS_DEF_1 }
}

local WR_CITY_LOSS_ATTACK_PROMOTIONS = {
    { percent = 5000, type = "PROMOTION_WR_CITY_LOSS_ATTACK_5000", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_5000 },
    { percent = 2000, type = "PROMOTION_WR_CITY_LOSS_ATTACK_2000", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_2000 },
    { percent = 1000, type = "PROMOTION_WR_CITY_LOSS_ATTACK_1000", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_1000 },
    { percent = 500, type = "PROMOTION_WR_CITY_LOSS_ATTACK_500", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_500 },
    { percent = 200, type = "PROMOTION_WR_CITY_LOSS_ATTACK_200", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_200 },
    { percent = 100, type = "PROMOTION_WR_CITY_LOSS_ATTACK_100", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_100 },
    { percent = 50, type = "PROMOTION_WR_CITY_LOSS_ATTACK_50", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_50 },
    { percent = 20, type = "PROMOTION_WR_CITY_LOSS_ATTACK_20", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_20 },
    { percent = 10, type = "PROMOTION_WR_CITY_LOSS_ATTACK_10", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_10 },
    { percent = 2, type = "PROMOTION_WR_CITY_LOSS_ATTACK_2", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_2 }
}

local function WR_IsWhiteRoomPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_SaveKey(playerID, suffix)
    return "WR_CAPTURED_CITY_LEARNING_" .. tostring(playerID) .. "_" .. suffix
end

local function WR_GetSavedNumber(playerID, suffix)
    local value = WR_CITY_LOSS_SAVE.GetValue(WR_SaveKey(playerID, suffix))
    if type(value) ~= "number" then
        return 0
    end

    return value
end

local function WR_SetSavedNumber(playerID, suffix, value)
    WR_CITY_LOSS_SAVE.SetValue(WR_SaveKey(playerID, suffix), value)
end

local function WR_ClearCityLossDefenseDummies(city)
    for _, entry in ipairs(WR_CITY_LOSS_DEF_DUMMY_BUILDINGS) do
        if entry.id ~= nil and city:GetNumRealBuilding(entry.id) ~= 0 then
            city:SetNumRealBuilding(entry.id, 0)
        end
    end
end

local function WR_ApplyCityLossDefenseToCity(city, stacks)
    WR_ClearCityLossDefenseDummies(city)

    local remaining = math.max(0, stacks)
    for _, entry in ipairs(WR_CITY_LOSS_DEF_DUMMY_BUILDINGS) do
        if entry.id ~= nil and remaining >= entry.percent then
            local count = math.floor(remaining / entry.percent)
            city:SetNumRealBuilding(entry.id, count)
            remaining = remaining - (count * entry.percent)
        end
    end
end

local function WR_ApplyCityLossAttackToUnit(unit, cityAttackPercent)
    local remaining = math.max(0, cityAttackPercent)

    for _, entry in ipairs(WR_CITY_LOSS_ATTACK_PROMOTIONS) do
        if entry.id ~= nil then
            if remaining >= entry.percent then
                unit:SetHasPromotion(entry.id, true)
                remaining = remaining - entry.percent
            else
                unit:SetHasPromotion(entry.id, false)
            end
        end
    end
end

local function WR_ShouldApplyToUnit(unit)
    if unit == nil or unit:IsDead() then
        return false
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    if unitInfo == nil then
        return false
    end

    return (unitInfo.Combat or 0) > 0 or (unitInfo.RangedCombat or 0) > 0
end

local function WR_ApplyCapturedCityLearningForPlayer(playerID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    local cityLossStacks = WR_GetSavedNumber(playerID, "CITY_LOSS_STACKS")
    local cityAttackPercent = cityLossStacks * 2

    for city in player:Cities() do
        WR_ApplyCityLossDefenseToCity(city, cityLossStacks)
    end

    for unit in player:Units() do
        if WR_ShouldApplyToUnit(unit) then
            WR_ApplyCityLossAttackToUnit(unit, cityAttackPercent)
        end
    end
end

local function WR_PlayerName(playerID)
    local player = Players[playerID]
    if player == nil then
        return tostring(playerID)
    end

    local name = player:GetName()
    if name == nil or name == "" then
        return tostring(playerID)
    end

    return name
end

local function WR_RecordCityLossForWhiteRoom(playerID, oldOwnerID, cityID, newOwnerID)
    local eventKey = table.concat({
        tostring(Game.GetGameTurn()),
        tostring(playerID),
        tostring(oldOwnerID),
        tostring(cityID),
        tostring(newOwnerID)
    }, ":")

    if WR_CITY_LOSS_RECENT_EVENTS[eventKey] then
        return
    end
    WR_CITY_LOSS_RECENT_EVENTS[eventKey] = true

    local cityLossStacks = WR_GetSavedNumber(playerID, "CITY_LOSS_STACKS") + 1
    WR_SetSavedNumber(playerID, "CITY_LOSS_STACKS", cityLossStacks)
    WR_ApplyCapturedCityLearningForPlayer(playerID)

    print(string.format(
        "WR Captured City Learning: %s lost city id %s to %s; White Room learned from collapse -> vs cities +%d%%, city defense +%d%%",
        WR_PlayerName(oldOwnerID),
        tostring(cityID),
        WR_PlayerName(newOwnerID),
        cityLossStacks * 2,
        cityLossStacks
    ))
end

local function WR_RecordOtherPlayerCityLoss(oldOwnerID, cityID, newOwnerID)
    local oldOwner = Players[oldOwnerID]
    if oldOwner == nil or WR_IsWhiteRoomPlayer(oldOwner) then
        return
    end

    for playerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
        local player = Players[playerID]
        if WR_IsWhiteRoomPlayer(player) then
            WR_RecordCityLossForWhiteRoom(playerID, oldOwnerID, cityID, newOwnerID)
        end
    end
end

function WR_CapturedCityLearning_DoTurn(playerID)
    WR_ApplyCapturedCityLearningForPlayer(playerID)
end

GameEvents.PlayerDoTurn.Add(WR_CapturedCityLearning_DoTurn)

if Events.SerialEventCityCaptured ~= nil then
    Events.SerialEventCityCaptured.Add(function(hexPos, oldOwnerID, cityID, newOwnerID)
        WR_RecordOtherPlayerCityLoss(oldOwnerID, cityID, newOwnerID)
    end)
    print("WR Captured City Learning: SerialEventCityCaptured hook available")
else
    print("WR Captured City Learning: SerialEventCityCaptured hook unavailable")
end

print("WR Captured City Learning: initialized")

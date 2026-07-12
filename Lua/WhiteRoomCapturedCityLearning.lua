-- White Room Kid Kiyotaka - Captured City Learning

print("WhiteRoomCapturedCityLearning.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID

local WR_CITY_LOSS_SAVE = Modding.OpenSaveData()
local WR_CITY_LOSS_RECENT_EVENTS = {}
local WR_CITY_LOSS_DEBUG = true
local WR_CITY_LOSS_LAST_APPLY_LOG = {}
local WR_PlayerName
local WR_CITY_LOSS_DEF_PERCENT_PER_STACK = 0.25
local WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK = 0.5

local function WR_Debug(message)
    if WR_CITY_LOSS_DEBUG then
        print(message)
    end
end

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
    { percent = 2, type = "PROMOTION_WR_CITY_LOSS_ATTACK_2", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_2 },
    { percent = 1, type = "PROMOTION_WR_CITY_LOSS_ATTACK_1", id = GameInfoTypes.PROMOTION_WR_CITY_LOSS_ATTACK_1 }
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

    local remaining = math.floor(math.max(0, stacks) * WR_CITY_LOSS_DEF_PERCENT_PER_STACK)
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
    local applied = 0
    local activePromotions = {}

    for _, entry in ipairs(WR_CITY_LOSS_ATTACK_PROMOTIONS) do
        if entry.id ~= nil then
            if remaining >= entry.percent then
                unit:SetHasPromotion(entry.id, true)
                remaining = remaining - entry.percent
                applied = applied + entry.percent
                table.insert(activePromotions, "+" .. tostring(entry.percent))
            else
                unit:SetHasPromotion(entry.id, false)
            end
        elseif remaining >= entry.percent then
            WR_Debug("WR Captured City Learning: missing promotion " .. tostring(entry.type) .. " while trying to apply +" .. tostring(entry.percent) .. "% vs cities")
        end
    end

    return applied, remaining, activePromotions
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
    local cityDefenseStored = cityLossStacks * WR_CITY_LOSS_DEF_PERCENT_PER_STACK
    local cityDefenseApplied = math.floor(cityDefenseStored)
    local cityAttackStored = cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK
    local cityAttackPercent = math.floor(cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK)
    local cityCount = 0
    local eligibleUnitCount = 0
    local representedAttackPercent = 0
    local attackRemainder = cityAttackPercent
    local activePromotions = {}

    for city in player:Cities() do
        cityCount = cityCount + 1
        WR_ApplyCityLossDefenseToCity(city, cityLossStacks)
    end

    for unit in player:Units() do
        if WR_ShouldApplyToUnit(unit) then
            eligibleUnitCount = eligibleUnitCount + 1
            local applied, remaining, promotions = WR_ApplyCityLossAttackToUnit(unit, cityAttackPercent)
            representedAttackPercent = applied
            attackRemainder = remaining
            activePromotions = promotions
        end
    end

    local applyLogKey = table.concat({
        tostring(cityLossStacks),
        tostring(cityAttackPercent),
        tostring(representedAttackPercent),
        tostring(attackRemainder),
        tostring(cityDefenseApplied),
        tostring(cityCount),
        tostring(eligibleUnitCount)
    }, ":")

    if WR_CITY_LOSS_LAST_APPLY_LOG[playerID] ~= applyLogKey then
        WR_CITY_LOSS_LAST_APPLY_LOG[playerID] = applyLogKey

        local promotionText = table.concat(activePromotions, ", ")
        if promotionText == "" then
            promotionText = "none"
        end

        WR_Debug(string.format(
            "WR Captured City Learning: applying to %s; stacks=%d, cities=%d, eligible units=%d, vs cities stored +%.2f%%, whole +%d%%, represented +%d%% [%s], unrepresented +%d%%, city defense stored +%.2f%%, applied +%d%%",
            WR_PlayerName(playerID),
            cityLossStacks,
            cityCount,
            eligibleUnitCount,
            cityAttackStored,
            cityAttackPercent,
            representedAttackPercent,
            promotionText,
            attackRemainder,
            cityDefenseStored,
            cityDefenseApplied
        ))

        if attackRemainder > 0 then
            WR_Debug(string.format(
                "WR Captured City Learning: warning - +%d%% vs cities could not be represented by available promotions for %s",
                attackRemainder,
                WR_PlayerName(playerID)
            ))
        end
    end
end

function WR_PlayerName(playerID)
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

    WR_Debug(string.format(
        "WR Captured City Learning: %s lost city id %s to %s; White Room learned from collapse -> vs cities +%d%%, city defense +%.2f%%",
        WR_PlayerName(oldOwnerID),
        tostring(cityID),
        WR_PlayerName(newOwnerID),
        math.floor(cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK),
        cityLossStacks * WR_CITY_LOSS_DEF_PERCENT_PER_STACK
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
    WR_Debug("WR Captured City Learning: SerialEventCityCaptured hook available")
else
    WR_Debug("WR Captured City Learning: SerialEventCityCaptured hook unavailable")
end

print("WR Captured City Learning: initialized")

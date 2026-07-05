-- ============================================================================
-- White Room Kid Kiyotaka - Duplicate Worked-Improvement Scaling
-- ============================================================================
--
-- Mechanic:
--   Each White Room city counts its currently worked, unpillaged improvements.
--   For each duplicate of the same improvement, the city gets +1% to the
--   matching city yield through invisible dummy buildings.
--
-- Examples:
--   1 worked Farm  = +0% Food
--   3 worked Farms = +2% Food
--   5 worked Mines = +4% Production
--
-- This recalculates from current city state, clears old dummy buildings first,
-- and then reapplies the current correct values. It should not permanently
-- stack over time.
-- ============================================================================

print("WhiteRoomDuplicateImprovements.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local WR_DUP_DEBUG = false
local WR_DUP_LOG_EVERY_TURN = false
local WR_DUP_PERCENT_PER_DUPLICATE = 1

local PERCENT_DENOMS = {50, 25, 10, 5, 1}
local YIELD_ORDER = {"FOOD", "PRODUCTION", "GOLD", "SCIENCE", "CULTURE", "FAITH"}

local YieldDummyBuildings = {
    FOOD = {},
    PRODUCTION = {},
    GOLD = {},
    SCIENCE = {},
    CULTURE = {},
    FAITH = {}
}

local ImprovementYieldType = {}
local ImprovementNames = {}
local LastCitySignatures = {}

local function WR_Log(message)
    print("WR Duplicate Improvements: " .. message)
end

local function WR_Debug(message)
    if WR_DUP_DEBUG then
        WR_Log(message)
    end
end

local function RegisterDummyBuilding(yieldName, percent, buildingType)
    local buildingID = GameInfoTypes[buildingType]

    if buildingID == nil then
        WR_Log("missing dummy building " .. buildingType)
        return
    end

    YieldDummyBuildings[yieldName][percent] = buildingID
end

local function RegisterImprovement(improvementType, yieldName)
    local improvementID = GameInfoTypes[improvementType]

    if improvementID == nil then
        WR_Log("missing improvement " .. improvementType)
        return
    end

    ImprovementYieldType[improvementID] = yieldName
    ImprovementNames[improvementID] = improvementType
end

local function InitializeDuplicateImprovementTables()
    RegisterDummyBuilding("FOOD", 1, "BUILDING_WR_DUP_FOOD_1")
    RegisterDummyBuilding("FOOD", 5, "BUILDING_WR_DUP_FOOD_5")
    RegisterDummyBuilding("FOOD", 10, "BUILDING_WR_DUP_FOOD_10")
    RegisterDummyBuilding("FOOD", 25, "BUILDING_WR_DUP_FOOD_25")
    RegisterDummyBuilding("FOOD", 50, "BUILDING_WR_DUP_FOOD_50")

    RegisterDummyBuilding("PRODUCTION", 1, "BUILDING_WR_DUP_PROD_1")
    RegisterDummyBuilding("PRODUCTION", 5, "BUILDING_WR_DUP_PROD_5")
    RegisterDummyBuilding("PRODUCTION", 10, "BUILDING_WR_DUP_PROD_10")
    RegisterDummyBuilding("PRODUCTION", 25, "BUILDING_WR_DUP_PROD_25")
    RegisterDummyBuilding("PRODUCTION", 50, "BUILDING_WR_DUP_PROD_50")

    RegisterDummyBuilding("GOLD", 1, "BUILDING_WR_DUP_GOLD_1")
    RegisterDummyBuilding("GOLD", 5, "BUILDING_WR_DUP_GOLD_5")
    RegisterDummyBuilding("GOLD", 10, "BUILDING_WR_DUP_GOLD_10")
    RegisterDummyBuilding("GOLD", 25, "BUILDING_WR_DUP_GOLD_25")
    RegisterDummyBuilding("GOLD", 50, "BUILDING_WR_DUP_GOLD_50")

    RegisterDummyBuilding("SCIENCE", 1, "BUILDING_WR_DUP_SCIENCE_1")
    RegisterDummyBuilding("SCIENCE", 5, "BUILDING_WR_DUP_SCIENCE_5")
    RegisterDummyBuilding("SCIENCE", 10, "BUILDING_WR_DUP_SCIENCE_10")
    RegisterDummyBuilding("SCIENCE", 25, "BUILDING_WR_DUP_SCIENCE_25")
    RegisterDummyBuilding("SCIENCE", 50, "BUILDING_WR_DUP_SCIENCE_50")

    RegisterDummyBuilding("CULTURE", 1, "BUILDING_WR_DUP_CULTURE_1")
    RegisterDummyBuilding("CULTURE", 5, "BUILDING_WR_DUP_CULTURE_5")
    RegisterDummyBuilding("CULTURE", 10, "BUILDING_WR_DUP_CULTURE_10")
    RegisterDummyBuilding("CULTURE", 25, "BUILDING_WR_DUP_CULTURE_25")
    RegisterDummyBuilding("CULTURE", 50, "BUILDING_WR_DUP_CULTURE_50")

    RegisterDummyBuilding("FAITH", 1, "BUILDING_WR_DUP_FAITH_1")
    RegisterDummyBuilding("FAITH", 5, "BUILDING_WR_DUP_FAITH_5")
    RegisterDummyBuilding("FAITH", 10, "BUILDING_WR_DUP_FAITH_10")
    RegisterDummyBuilding("FAITH", 25, "BUILDING_WR_DUP_FAITH_25")
    RegisterDummyBuilding("FAITH", 50, "BUILDING_WR_DUP_FAITH_50")

    RegisterImprovement("IMPROVEMENT_FARM", "FOOD")

    RegisterImprovement("IMPROVEMENT_MINE", "PRODUCTION")
    RegisterImprovement("IMPROVEMENT_LUMBERMILL", "PRODUCTION")
    RegisterImprovement("IMPROVEMENT_QUARRY", "PRODUCTION")
    RegisterImprovement("IMPROVEMENT_MANUFACTORY", "PRODUCTION")

    RegisterImprovement("IMPROVEMENT_TRADING_POST", "GOLD")
    RegisterImprovement("IMPROVEMENT_CUSTOMS_HOUSE", "GOLD")
    RegisterImprovement("IMPROVEMENT_PLANTATION", "GOLD")
    RegisterImprovement("IMPROVEMENT_CAMP", "GOLD")

    RegisterImprovement("IMPROVEMENT_ACADEMY", "SCIENCE")
    RegisterImprovement("IMPROVEMENT_LANDMARK", "CULTURE")
    RegisterImprovement("IMPROVEMENT_HOLY_SITE", "FAITH")
end

local function IsWhiteRoomPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and CIV_WHITE_ROOM_KID ~= nil
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function GetCityKey(playerID, city)
    return tostring(playerID) .. ":" .. tostring(city:GetID())
end

local function IsPlotWorkedByCity(city, plot)
    local ok, result = pcall(function()
        return city:IsWorkingPlot(plot)
    end)

    if ok then
        return result
    end

    return plot:GetWorkingCity() == city
end

local function ApplyPercentToCity(city, yieldName, percent)
    local buildingMap = YieldDummyBuildings[yieldName]
    if buildingMap == nil then
        return
    end

    local remaining = math.max(0, percent)
    local desiredCounts = {}

    for _, denom in ipairs(PERCENT_DENOMS) do
        local buildingID = buildingMap[denom]
        desiredCounts[denom] = 0

        if buildingID ~= nil and remaining >= denom then
            local count = math.floor(remaining / denom)
            desiredCounts[denom] = count
            remaining = remaining - (count * denom)
        end
    end

    for _, denom in ipairs(PERCENT_DENOMS) do
        local buildingID = buildingMap[denom]

        if buildingID ~= nil then
            local desired = desiredCounts[denom] or 0
            if city:GetNumRealBuilding(buildingID) ~= desired then
                city:SetNumRealBuilding(buildingID, desired)
            end
        end
    end
end

local function CountWorkedImprovements(playerID, city)
    local improvementCounts = {}

    for i = 0, city:GetNumCityPlots() - 1 do
        local plot = city:GetCityIndexPlot(i)

        if plot ~= nil and plot:GetOwner() == playerID and IsPlotWorkedByCity(city, plot) then
            local improvementID = plot:GetImprovementType()

            if improvementID ~= nil
                and improvementID ~= -1
                and not plot:IsImprovementPillaged()
                and ImprovementYieldType[improvementID] ~= nil then
                improvementCounts[improvementID] = (improvementCounts[improvementID] or 0) + 1
            end
        end
    end

    return improvementCounts
end

local function BuildZeroYieldPercents()
    return {
        FOOD = 0,
        PRODUCTION = 0,
        GOLD = 0,
        SCIENCE = 0,
        CULTURE = 0,
        FAITH = 0
    }
end

local function CalculateYieldPercents(improvementCounts)
    local yieldPercents = BuildZeroYieldPercents()

    for improvementID, count in pairs(improvementCounts) do
        local duplicates = math.max(0, count - 1)
        local yieldName = ImprovementYieldType[improvementID]

        if yieldName ~= nil and duplicates > 0 then
            yieldPercents[yieldName] = yieldPercents[yieldName] + (duplicates * WR_DUP_PERCENT_PER_DUPLICATE)
        end
    end

    return yieldPercents
end

local function BuildImprovementSignature(improvementCounts)
    local parts = {}

    for improvementID, count in pairs(improvementCounts) do
        table.insert(parts, tostring(ImprovementNames[improvementID] or improvementID) .. "=" .. tostring(count))
    end

    table.sort(parts)

    if #parts == 0 then
        return "none"
    end

    return table.concat(parts, ",")
end

local function BuildYieldSignature(yieldPercents)
    local parts = {}

    for _, yieldName in ipairs(YIELD_ORDER) do
        table.insert(parts, yieldName .. "=" .. tostring(yieldPercents[yieldName] or 0))
    end

    return table.concat(parts, ";")
end

local function LogCityResult(playerID, city, improvementCounts, yieldPercents, forceLog)
    local cityKey = GetCityKey(playerID, city)
    local signature = BuildImprovementSignature(improvementCounts) .. "|" .. BuildYieldSignature(yieldPercents)

    if not WR_DUP_LOG_EVERY_TURN and not forceLog and LastCitySignatures[cityKey] == signature then
        return
    end

    LastCitySignatures[cityKey] = signature

    WR_Log(string.format(
        "Turn %d, %s -> Worked Improvements [%s], Food +%d%%, Prod +%d%%, Gold +%d%%, Science +%d%%, Culture +%d%%, Faith +%d%%",
        Game.GetGameTurn(),
        city:GetName(),
        BuildImprovementSignature(improvementCounts),
        yieldPercents.FOOD,
        yieldPercents.PRODUCTION,
        yieldPercents.GOLD,
        yieldPercents.SCIENCE,
        yieldPercents.CULTURE,
        yieldPercents.FAITH
    ))
end

function WR_RecalculateCityDuplicateImprovementBonuses(playerID, city, forceLog)
    if city == nil then
        return
    end

    local improvementCounts = CountWorkedImprovements(playerID, city)
    local yieldPercents = CalculateYieldPercents(improvementCounts)

    for _, yieldName in ipairs(YIELD_ORDER) do
        ApplyPercentToCity(city, yieldName, yieldPercents[yieldName] or 0)
    end

    LogCityResult(playerID, city, improvementCounts, yieldPercents, forceLog)
end

function WR_RecalculateDuplicateImprovementBonuses(playerID, forceLog)
    local player = Players[playerID]

    if not IsWhiteRoomPlayer(player) then
        return
    end

    for city in player:Cities() do
        WR_RecalculateCityDuplicateImprovementBonuses(playerID, city, forceLog)
    end
end

function WR_RecalculateDuplicateImprovementBonusesForActivePlayer()
    local playerID = Game.GetActivePlayer()
    WR_RecalculateDuplicateImprovementBonuses(playerID, true)
end

function WR_OnDuplicateImprovementBuildFinished(playerID, x, y, improvementID)
    local player = Players[playerID]

    if not IsWhiteRoomPlayer(player) then
        return
    end

    local plot = Map.GetPlot(x, y)
    if plot == nil then
        return
    end

    local city = plot:GetWorkingCity()

    if city ~= nil and city:GetOwner() == playerID then
        WR_RecalculateCityDuplicateImprovementBonuses(playerID, city, true)
        WR_Debug("recalculated after improvement build near " .. city:GetName())
    end
end

InitializeDuplicateImprovementTables()

if CIV_WHITE_ROOM_KID == nil then
    WR_Log("CIVILIZATION_WHITE_ROOM_KID is missing; duplicate scaling will stay inactive")
else
    WR_Log("initialized")
end

GameEvents.PlayerDoTurn.Add(WR_RecalculateDuplicateImprovementBonuses)

if GameEvents.BuildFinished then
    GameEvents.BuildFinished.Add(WR_OnDuplicateImprovementBuildFinished)
end

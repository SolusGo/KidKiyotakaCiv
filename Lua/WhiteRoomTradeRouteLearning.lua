-- White Room Kid Kiyotaka - Trade Route Learning

print("WhiteRoomTradeRouteLearning.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID

local WR_TRADE_SAVE = Modding.OpenSaveData()
local WR_TRADE_RECENT_EVENTS = {}
local WR_TRADE_POLL_SUPPORT = nil
local WR_TRADE_HALF_STACKS_PER_CONNECTION = 0.25

local WR_TRADE_GOLD_DUMMY_BUILDINGS = {
    { percent = 50, type = "BUILDING_WR_TRADE_GOLD_50", id = GameInfoTypes.BUILDING_WR_TRADE_GOLD_50 },
    { percent = 25, type = "BUILDING_WR_TRADE_GOLD_25", id = GameInfoTypes.BUILDING_WR_TRADE_GOLD_25 },
    { percent = 10, type = "BUILDING_WR_TRADE_GOLD_10", id = GameInfoTypes.BUILDING_WR_TRADE_GOLD_10 },
    { percent = 5, type = "BUILDING_WR_TRADE_GOLD_5", id = GameInfoTypes.BUILDING_WR_TRADE_GOLD_5 },
    { percent = 1, type = "BUILDING_WR_TRADE_GOLD_1", id = GameInfoTypes.BUILDING_WR_TRADE_GOLD_1 }
}

local function WR_IsWhiteRoomPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_SaveKey(playerID, suffix)
    return "WR_TRADE_ROUTE_LEARNING_" .. tostring(playerID) .. "_" .. suffix
end

local function WR_GetSavedNumber(playerID, suffix)
    local value = WR_TRADE_SAVE.GetValue(WR_SaveKey(playerID, suffix))
    if type(value) ~= "number" then
        return 0
    end

    return value
end

local function WR_SetSavedNumber(playerID, suffix, value)
    WR_TRADE_SAVE.SetValue(WR_SaveKey(playerID, suffix), value)
end

local function WR_GetSavedFlag(key)
    return WR_TRADE_SAVE.GetValue(key) == 1
end

local function WR_SetSavedFlag(key)
    WR_TRADE_SAVE.SetValue(key, 1)
end

local function WR_ClearTradeGoldDummies(city)
    for _, entry in ipairs(WR_TRADE_GOLD_DUMMY_BUILDINGS) do
        if entry.id ~= nil and city:GetNumRealBuilding(entry.id) ~= 0 then
            city:SetNumRealBuilding(entry.id, 0)
        end
    end
end

local function WR_ApplyTradeGoldPercentToCity(city, percent)
    WR_ClearTradeGoldDummies(city)

    local remaining = math.max(0, percent)
    for _, entry in ipairs(WR_TRADE_GOLD_DUMMY_BUILDINGS) do
        if entry.id ~= nil and remaining >= entry.percent then
            local count = math.floor(remaining / entry.percent)
            city:SetNumRealBuilding(entry.id, count)
            remaining = remaining - (count * entry.percent)
        end
    end
end

local function WR_ApplyTradeGoldForPlayer(playerID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    local halfStacks = WR_GetSavedNumber(playerID, "HALF_GOLD_STACKS")
    local wholePercent = math.floor(halfStacks / 2)

    for city in player:Cities() do
        WR_ApplyTradeGoldPercentToCity(city, wholePercent)
    end
end

local function WR_CityName(playerID, cityID)
    local player = Players[playerID]
    if player == nil then
        return tostring(cityID)
    end

    local city = player:GetCityByID(cityID)
    if city == nil then
        return tostring(cityID)
    end

    return city:GetName()
end

local function WR_RecordTradeRouteLearning(playerID, otherPlayerID, fromCityID, toCityID, domain, connectionType)
    local turn = Game.GetGameTurn()
    local eventKey = table.concat({
        tostring(turn),
        tostring(playerID),
        tostring(otherPlayerID),
        tostring(fromCityID),
        tostring(toCityID),
        tostring(domain),
        tostring(connectionType)
    }, ":")

    if WR_TRADE_RECENT_EVENTS[eventKey] then
        return
    end
    WR_TRADE_RECENT_EVENTS[eventKey] = true

    local halfStacks = WR_GetSavedNumber(playerID, "HALF_GOLD_STACKS") + WR_TRADE_HALF_STACKS_PER_CONNECTION
    WR_SetSavedNumber(playerID, "HALF_GOLD_STACKS", halfStacks)
    WR_ApplyTradeGoldForPlayer(playerID)

    local wholePercent = math.floor(halfStacks / 2)
    local learnedPercent = halfStacks * 0.5

    print(string.format(
        "WR Trade Route Learning: trade connection learned by White Room (%s -> %s); gold learning now +%.2f%%, applied gold modifier +%d%%",
        WR_CityName(playerID, fromCityID),
        WR_CityName(otherPlayerID, toCityID),
        learnedPercent,
        wholePercent
    ))
end

local function WR_GetRouteField(route, names)
    for _, name in ipairs(names) do
        local value = route[name]
        if value ~= nil then
            return value
        end
    end

    return nil
end

local function WR_GetRouteCityID(route, cityFieldNames, idFieldNames)
    local city = WR_GetRouteField(route, cityFieldNames)
    if city ~= nil and type(city) == "table" and city.GetID ~= nil then
        return city:GetID()
    end

    return WR_GetRouteField(route, idFieldNames)
end

local function WR_BuildPolledRoute(route)
    local fromPlayerID = WR_GetRouteField(route, { "FromID", "FromPlayer", "FromPlayerID", "FromCiv", "FromCivilization" })
    local toPlayerID = WR_GetRouteField(route, { "ToID", "ToPlayer", "ToPlayerID", "ToCiv", "ToCivilization" })
    local fromCityID = WR_GetRouteCityID(route, { "FromCity", "fromCity" }, { "FromCityID", "FromCityId", "FromCityIndex" })
    local toCityID = WR_GetRouteCityID(route, { "ToCity", "toCity" }, { "ToCityID", "ToCityId", "ToCityIndex" })
    local domain = WR_GetRouteField(route, { "Domain", "DomainType", "RouteDomain" }) or -1
    local connectionType = WR_GetRouteField(route, { "ConnectionType", "TradeConnectionType", "RouteType" }) or -1

    return fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType
end

local function WR_RecordPolledRoute(playerID, fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
    if fromPlayerID == nil or toPlayerID == nil or fromCityID == nil or toCityID == nil then
        return
    end

    local learnedRouteKey = table.concat({
        "WR_TRADE_ROUTE_LEARNED",
        tostring(playerID),
        tostring(fromPlayerID),
        tostring(fromCityID),
        tostring(toPlayerID),
        tostring(toCityID),
        tostring(domain),
        tostring(connectionType)
    }, "_")

    if WR_GetSavedFlag(learnedRouteKey) then
        return
    end

    WR_SetSavedFlag(learnedRouteKey)

    if playerID == fromPlayerID then
        WR_RecordTradeRouteLearning(playerID, toPlayerID, fromCityID, toCityID, domain, connectionType)
    else
        WR_RecordTradeRouteLearning(playerID, fromPlayerID, toCityID, fromCityID, domain, connectionType)
    end
end

local function WR_PollActiveTradeRoutes(playerID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    if player.GetTradeRoutes == nil then
        if WR_TRADE_POLL_SUPPORT == nil then
            WR_TRADE_POLL_SUPPORT = false
            print("WR Trade Route Learning: player:GetTradeRoutes() unavailable")
        end
        return
    end

    local ok, routes = pcall(function()
        return player:GetTradeRoutes()
    end)

    if WR_TRADE_POLL_SUPPORT == nil then
        WR_TRADE_POLL_SUPPORT = ok
        if ok then
            print("WR Trade Route Learning: player:GetTradeRoutes() polling available")
        else
            print("WR Trade Route Learning: player:GetTradeRoutes() polling unavailable")
        end
    end

    if not ok or routes == nil then
        return
    end

    for _, route in pairs(routes) do
        local fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType = WR_BuildPolledRoute(route)
        if fromPlayerID == playerID or toPlayerID == playerID then
            WR_RecordPolledRoute(playerID, fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
        end
    end
end

function WR_TradeRouteLearning_DoTurn(playerID)
    WR_ApplyTradeGoldForPlayer(playerID)
    WR_PollActiveTradeRoutes(playerID)
end

GameEvents.PlayerDoTurn.Add(WR_TradeRouteLearning_DoTurn)

if GameEvents.PlayerTradeRouteCompleted ~= nil then
    GameEvents.PlayerTradeRouteCompleted.Add(function(fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
        local fromPlayer = Players[fromPlayerID]
        local toPlayer = Players[toPlayerID]

        if WR_IsWhiteRoomPlayer(fromPlayer) then
            WR_RecordTradeRouteLearning(fromPlayerID, toPlayerID, fromCityID, toCityID, domain, connectionType)
        end

        if toPlayerID ~= fromPlayerID and WR_IsWhiteRoomPlayer(toPlayer) then
            WR_RecordTradeRouteLearning(toPlayerID, fromPlayerID, toCityID, fromCityID, domain, connectionType)
        end
    end)

    print("WR Trade Route Learning: PlayerTradeRouteCompleted hook available")
else
    print("WR Trade Route Learning: PlayerTradeRouteCompleted hook unavailable")
end

print("WR Trade Route Learning: initialized")

-- White Room Kid Kiyotaka - Trade Route Learning

print("WhiteRoomTradeRouteLearning.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID

local WR_TRADE_SAVE = Modding.OpenSaveData()
local WR_TRADE_RECENT_DEPARTURES = {}
local WR_TRADE_POLL_SUPPORT = nil
local WR_TRADE_DEBUG = false
local WR_TRADE_HALF_STACKS_PER_CONNECTION = 0.25
local WR_TRADE_STATE_VERSION = 2

local function WR_Debug(message)
    if WR_TRADE_DEBUG then
        print(message)
    end
end

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
    return tonumber(value) or 0
end

local function WR_SetSavedNumber(playerID, suffix, value)
    WR_TRADE_SAVE.SetValue(WR_SaveKey(playerID, suffix), value)
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
    return city ~= nil and city:GetName() or tostring(cityID)
end

local function WR_RecordTradeRouteLearning(playerID, otherPlayerID, ownCityID, otherCityID, domain, connectionType)
    local halfStacks = WR_GetSavedNumber(playerID, "HALF_GOLD_STACKS") + WR_TRADE_HALF_STACKS_PER_CONNECTION
    WR_SetSavedNumber(playerID, "HALF_GOLD_STACKS", halfStacks)
    WR_ApplyTradeGoldForPlayer(playerID)

    local wholePercent = math.floor(halfStacks / 2)
    local learnedPercent = halfStacks * 0.5
    local ownCityName = WR_CityName(playerID, ownCityID)
    local otherCityName = WR_CityName(otherPlayerID, otherCityID)

    WR_Debug(string.format(
        "WR Trade Route Learning: route instance learned by White Room (%s <-> %s); gold learning now +%.2f%%, applied gold modifier +%d%%",
        ownCityName,
        otherCityName,
        learnedPercent,
        wholePercent
    ))

    if WR_RecordTelemetry ~= nil then
        WR_RecordTelemetry(
            playerID,
            "EMPIRE",
            "TRADE CONNECTION ANALYZED",
            string.format(
                "%s <-> %s // Gold stored +%.2f%% // Applied +%d%%",
                ownCityName,
                otherCityName,
                learnedPercent,
                wholePercent
            )
        )
    end
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
    if type(city) == "number" then
        return city
    end

    if city ~= nil then
        local ok, cityID = pcall(function()
            return city:GetID()
        end)
        if ok then
            return cityID
        end
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

local function WR_RouteFingerprint(fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
    return table.concat({
        tostring(fromPlayerID),
        tostring(fromCityID),
        tostring(toPlayerID),
        tostring(toCityID),
        tostring(domain),
        tostring(connectionType)
    }, ":")
end

local function WR_RegisterFingerprint(playerID, fingerprint)
    local knownSuffix = "ROUTE_V2_KNOWN_" .. fingerprint
    if WR_GetSavedNumber(playerID, knownSuffix) == 1 then
        return
    end

    local count = WR_GetSavedNumber(playerID, "ROUTE_V2_REGISTRY_COUNT") + 1
    WR_SetSavedNumber(playerID, "ROUTE_V2_REGISTRY_COUNT", count)
    WR_TRADE_SAVE.SetValue(WR_SaveKey(playerID, "ROUTE_V2_REGISTRY_" .. tostring(count)), fingerprint)
    WR_SetSavedNumber(playerID, knownSuffix, 1)
end

local function WR_AwardRouteInstances(playerID, route, count)
    for _ = 1, count do
        if playerID == route.fromPlayerID then
            WR_RecordTradeRouteLearning(playerID, route.toPlayerID, route.fromCityID, route.toCityID, route.domain, route.connectionType)
        else
            WR_RecordTradeRouteLearning(playerID, route.fromPlayerID, route.toCityID, route.fromCityID, route.domain, route.connectionType)
        end
    end
end

local function WR_DepartureKey(playerID, fingerprint)
    return tostring(playerID) .. "|" .. fingerprint
end

local function WR_RecordRecentDeparture(playerID, fingerprint, count)
    if count <= 0 then
        return
    end

    local key = WR_DepartureKey(playerID, fingerprint)
    local departure = WR_TRADE_RECENT_DEPARTURES[key]
    local turn = Game.GetGameTurn()

    if departure == nil or departure.turn ~= turn then
        departure = { turn = turn, count = 0 }
        WR_TRADE_RECENT_DEPARTURES[key] = departure
    end

    departure.count = departure.count + count
end

local function WR_ConsumeRecentDeparture(playerID, fingerprint)
    local key = WR_DepartureKey(playerID, fingerprint)
    local departure = WR_TRADE_RECENT_DEPARTURES[key]
    if departure == nil or Game.GetGameTurn() - departure.turn > 1 or departure.count <= 0 then
        WR_TRADE_RECENT_DEPARTURES[key] = nil
        return false
    end

    departure.count = departure.count - 1
    if departure.count <= 0 then
        WR_TRADE_RECENT_DEPARTURES[key] = nil
    end

    return true
end

local function WR_GetAllActiveRouteCounts(playerID)
    local routeCounts = {}
    local pollWorked = false

    for routeOwnerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
        local routeOwner = Players[routeOwnerID]
        if routeOwner ~= nil and routeOwner:IsAlive() and routeOwner.GetTradeRoutes ~= nil then
            local ok, routes = pcall(function()
                return routeOwner:GetTradeRoutes()
            end)

            if ok and routes ~= nil then
                pollWorked = true
                for _, rawRoute in pairs(routes) do
                    local fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType = WR_BuildPolledRoute(rawRoute)
                    if (fromPlayerID == playerID or toPlayerID == playerID)
                        and fromPlayerID ~= nil
                        and fromCityID ~= nil
                        and toPlayerID ~= nil
                        and toCityID ~= nil then
                        local fingerprint = WR_RouteFingerprint(fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
                        local route = routeCounts[fingerprint]
                        if route == nil then
                            route = {
                                count = 0,
                                fromPlayerID = fromPlayerID,
                                fromCityID = fromCityID,
                                toPlayerID = toPlayerID,
                                toCityID = toCityID,
                                domain = domain,
                                connectionType = connectionType
                            }
                            routeCounts[fingerprint] = route
                        end
                        route.count = route.count + 1
                    end
                end
            end
        end
    end

    if WR_TRADE_POLL_SUPPORT == nil then
        WR_TRADE_POLL_SUPPORT = pollWorked
        WR_Debug("WR Trade Route Learning: global route polling " .. (pollWorked and "available" or "unavailable"))
    end

    return pollWorked, routeCounts
end

local function WR_ReconcileActiveRoutes(playerID, awardNewRoutes)
    local pollWorked, routeCounts = WR_GetAllActiveRouteCounts(playerID)
    if not pollWorked then
        return false
    end

    for fingerprint, route in pairs(routeCounts) do
        WR_RegisterFingerprint(playerID, fingerprint)
        local activeSuffix = "ROUTE_V2_ACTIVE_" .. fingerprint
        local oldCount = WR_GetSavedNumber(playerID, activeSuffix)

        if awardNewRoutes and route.count > oldCount then
            WR_AwardRouteInstances(playerID, route, route.count - oldCount)
        elseif route.count < oldCount then
            WR_RecordRecentDeparture(playerID, fingerprint, oldCount - route.count)
        end

        WR_SetSavedNumber(playerID, activeSuffix, route.count)
    end

    local registryCount = WR_GetSavedNumber(playerID, "ROUTE_V2_REGISTRY_COUNT")
    for index = 1, registryCount do
        local fingerprint = WR_TRADE_SAVE.GetValue(WR_SaveKey(playerID, "ROUTE_V2_REGISTRY_" .. tostring(index)))
        if type(fingerprint) == "string" and routeCounts[fingerprint] == nil then
            local activeSuffix = "ROUTE_V2_ACTIVE_" .. fingerprint
            local oldCount = WR_GetSavedNumber(playerID, activeSuffix)
            if oldCount > 0 then
                WR_RecordRecentDeparture(playerID, fingerprint, oldCount)
                WR_SetSavedNumber(playerID, activeSuffix, 0)
            end
        end
    end

    return true
end

local function WR_EnsureRouteState(playerID)
    if WR_GetSavedNumber(playerID, "ROUTE_STATE_VERSION") >= WR_TRADE_STATE_VERSION then
        return true
    end

    if WR_ReconcileActiveRoutes(playerID, false) then
        WR_SetSavedNumber(playerID, "ROUTE_STATE_VERSION", WR_TRADE_STATE_VERSION)
        WR_Debug("WR Trade Route Learning: migrated active routes without granting duplicate credit")
        return true
    end

    return false
end

local function WR_ProcessCompletedRoute(playerID, fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
    local route = {
        fromPlayerID = fromPlayerID,
        fromCityID = fromCityID,
        toPlayerID = toPlayerID,
        toCityID = toCityID,
        domain = domain,
        connectionType = connectionType
    }
    local fingerprint = WR_RouteFingerprint(fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
    WR_RegisterFingerprint(playerID, fingerprint)

    local activeSuffix = "ROUTE_V2_ACTIVE_" .. fingerprint
    local activeCount = WR_GetSavedNumber(playerID, activeSuffix)
    if activeCount > 0 then
        WR_SetSavedNumber(playerID, activeSuffix, activeCount - 1)
        return
    end

    if WR_ConsumeRecentDeparture(playerID, fingerprint) then
        return
    end

    WR_AwardRouteInstances(playerID, route, 1)
end

function WR_TradeRouteLearning_DoTurn(playerID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    WR_ApplyTradeGoldForPlayer(playerID)
    if WR_EnsureRouteState(playerID) then
        WR_ReconcileActiveRoutes(playerID, true)
    end
end

GameEvents.PlayerDoTurn.Add(WR_TradeRouteLearning_DoTurn)

if GameEvents.PlayerTradeRouteCompleted ~= nil then
    GameEvents.PlayerTradeRouteCompleted.Add(function(fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
        local fromPlayer = Players[fromPlayerID]
        local toPlayer = Players[toPlayerID]

        if WR_IsWhiteRoomPlayer(fromPlayer) and WR_EnsureRouteState(fromPlayerID) then
            WR_ProcessCompletedRoute(fromPlayerID, fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
        end

        if toPlayerID ~= fromPlayerID and WR_IsWhiteRoomPlayer(toPlayer) and WR_EnsureRouteState(toPlayerID) then
            WR_ProcessCompletedRoute(toPlayerID, fromPlayerID, fromCityID, toPlayerID, toCityID, domain, connectionType)
        end
    end)

    WR_Debug("WR Trade Route Learning: PlayerTradeRouteCompleted hook available")
else
    WR_Debug("WR Trade Route Learning: PlayerTradeRouteCompleted hook unavailable")
end

print("WR Trade Route Learning: initialized")

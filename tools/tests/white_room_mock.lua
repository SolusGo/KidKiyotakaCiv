-- Minimal gameplay surface. No animation events are fired by these tests.
SAVE = {}
TURN = 10
LOG = {}
TELEMETRY = {}
FLAVOR = {}
local realPrint = print
print = function(message) LOG[#LOG + 1] = tostring(message) end
function eventBus()
    return setmetatable({}, { __index = function(bus, name)
        local callbacks = {}
        local event = { Add = function(callback) callbacks[#callbacks + 1] = callback end }
        setmetatable(event, { __call = function(_, ...)
            for _, callback in ipairs(callbacks) do callback(...) end
        end })
        rawset(bus, name, event)
        return event
    end })
end
GameEvents = eventBus()
Events = eventBus()
GameDefines = { MAX_CIV_PLAYERS = 4, MAX_HIT_POINTS = 100 }
Game = { GetGameTurn = function() return TURN end, GetActivePlayer = function() return 0 end,
    Rand = function() return 0 end }
Modding = { OpenSaveData = function() return {
    GetValue = function(key) return SAVE[key] end,
    SetValue = function(key, value) SAVE[key] = value end
} end }
Locale = { ConvertTextKey = function(key) return key end }
GameInfoTypes = { CIVILIZATION_WHITE_ROOM_KID = 1, UNIT_WR_KIYOTAKA = 11, UNIT_WR_FOURTH_GEN_OPERATIVE = 12 }
GameInfo = {
    Units = { [11] = { Combat = 20 }, [12] = { Combat = 20 },
        [13] = { Combat = 20, CombatClass = "UNITCOMBAT_SIEGE", Description = "Rocket Artillery" } },
    UnitCombatInfos = function() return function() return nil end end
}
function WR_RecordTelemetry(playerID, category, title, detail)
    TELEMETRY[#TELEMETRY + 1] = { playerID, category, title, detail }
end
function WR_KiyotakaFlavorEvent(playerID, unit, kind)
    FLAVOR[#FLAVOR + 1] = kind
end
function WR_KiyotakaFlavorRecordDeath() FLAVOR[#FLAVOR + 1] = "DEATH" end
function iterator(items)
    local keys = {}
    for key in pairs(items) do keys[#keys + 1] = key end
    table.sort(keys)
    local i = 0
    return function() i = i + 1; return items[keys[i]] end
end
function newPlot(owner, x, y)
    return { GetOwner = function() return owner end, GetX = function() return x end,
        GetY = function() return y end, GetPlotCity = function(self) return self.city end }
end
function newUnit(playerID, id, unitType, damage)
    local unit = { id = id, unitType = unitType, damage = damage or 0, xp = 0,
        plot = newPlot(playerID, id, 0), promotions = {} }
    function unit:GetID() return self.id end
    function unit:GetUnitType() return self.unitType end
    function unit:GetDamage() return self.damage end
    function unit:GetMaxHitPoints() return 100 end
    function unit:GetPlot() return self.plot end
    function unit:IsDead() return self.damage >= 100 end
    function unit:GetLevel() return 1 end
    function unit:GetExperience() return self.xp end
    function unit:ChangeExperience(amount) self.xp = self.xp + amount end
    function unit:IsHasPromotion(id) return self.promotions[id] or false end
    function unit:SetHasPromotion(id, value) self.promotions[id] = value end
    function unit:SetDamage(value) self.damage = value end
    Players[playerID].units[id] = unit
    GameEvents.UnitCreated(playerID, id)
    return unit
end
function newCity(playerID, id, x, y, founded)
    local city = { id = id, x = x, y = y, founded = founded, damage = 0,
        strike = false, buildings = {}, plot = newPlot(playerID, x, y) }
    function city:GetID() return self.id end
    function city:GetX() return self.x end
    function city:GetY() return self.y end
    function city:GetGameTurnFounded() return self.founded end
    function city:GetDamage() return self.damage end
    function city:GetMaxHitPoints() return 200 end
    function city:GetPlot() return self.plot end
    function city:GetName() return "Test City" end
    function city:HasPerformedRangedStrikeThisTurn() return self.strike end
    function city:GetNumRealBuilding(id) return self.buildings[id] or 0 end
    function city:SetNumRealBuilding(id, count) self.buildings[id] = count end
    city.plot.city = city
    Players[playerID].cities[id] = city
    PLOTS[x .. ":" .. y] = city.plot
    return city
end
Players = {}
for id = 0, 3 do
    local player = { id = id, civ = id == 0 and 1 or 2, alive = true, units = {}, cities = {} }
    function player:IsAlive() return self.alive end
    function player:GetCivilizationType() return self.civ end
    function player:GetUnitByID(id) return self.units[id] end
    function player:GetCityByID(id) return self.cities[id] end
    function player:Units() return iterator(self.units) end
    function player:Cities() return iterator(self.cities) end
    function player:GetName() return "Player " .. self.id end
    Players[id] = player
end
PLOTS = {}
Map = { GetPlot = function(x, y) return PLOTS[x .. ":" .. y] end }
function startBattle(attackerPlayer, attackerID, defenderPlayer, defenderID, attackerCity, defenderCity)
    GameEvents.BattleStarted(0, 0, 0)
    GameEvents.BattleJoined(attackerPlayer, attackerID, 0, attackerCity or false)
    GameEvents.BattleJoined(defenderPlayer, defenderID, 1, defenderCity or false)
end
function killUnit(playerID, unitID, killerID)
    local unit = Players[playerID]:GetUnitByID(unitID)
    unit.damage = 100
    GameEvents.UnitPrekill(playerID, unitID, unit.unitType, 0, 0, true, killerID)
    GameEvents.UnitPrekill(playerID, unitID, unit.unitType, 0, 0, false, killerID)
    Players[playerID].units[unitID] = nil
end
function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

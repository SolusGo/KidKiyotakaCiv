-- White Room Kid Kiyotaka - Cannot Settle

print("WhiteRoomCannotSettle.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local UNITCLASS_SETTLER = GameInfoTypes.UNITCLASS_SETTLER
local WR_CANNOT_SETTLE_DEBUG = false

local function WR_Debug(message)
    if WR_CANNOT_SETTLE_DEBUG then
        print(message)
    end
end

local function WR_IsWhiteRoomPlayer(player)
    return player
        and player:IsAlive()
        and CIV_WHITE_ROOM_KID ~= nil
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_IsSettler(unit)
    if unit == nil or UNITCLASS_SETTLER == nil then
        return false
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    return unitInfo ~= nil and unitInfo.Class == "UNITCLASS_SETTLER"
end

local function WR_GetFirstSettler(player)
    for unit in player:Units() do
        if WR_IsSettler(unit) then
            return unit
        end
    end

    return nil
end

local function WR_KillAllSettlers(player, reason)
    local settlers = {}

    for unit in player:Units() do
        if WR_IsSettler(unit) then
            settlers[#settlers + 1] = unit
        end
    end

    for _, unit in ipairs(settlers) do
        local plot = unit:GetPlot()
        local x = plot and plot:GetX() or -1
        local y = plot and plot:GetY() or -1

        unit:Kill(false, -1)
        WR_Debug(string.format(
            "WR Cannot Settle: removed Settler for %s at (%d,%d) [%s]",
            player:GetName(),
            x,
            y,
            reason or "no-settle rule"
        ))
    end
end

local function WR_AutoFoundStartingCapital(player)
    if player:GetNumCities() > 0 then
        return false
    end

    local settler = WR_GetFirstSettler(player)
    if settler == nil then
        return false
    end

    local plot = settler:GetPlot()
    if plot == nil then
        return false
    end

    local x = plot:GetX()
    local y = plot:GetY()

    player:InitCity(x, y)
    WR_KillAllSettlers(player, "starting capital founded")

    WR_Debug(string.format(
        "WR Cannot Settle: auto-founded starting capital for %s at (%d,%d)",
        player:GetName(),
        x,
        y
    ))

    return true
end

function WR_CannotSettle_DoTurn(playerID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return
    end

    if WR_AutoFoundStartingCapital(player) then
        return
    end

    WR_KillAllSettlers(player, "White Room cannot settle new cities")
end

GameEvents.PlayerDoTurn.Add(WR_CannotSettle_DoTurn)

if GameEvents.PlayerCanTrain ~= nil then
    GameEvents.PlayerCanTrain.Add(function(playerID, unitType)
        local player = Players[playerID]
        if not WR_IsWhiteRoomPlayer(player) then
            return true
        end

        local unitInfo = GameInfo.Units[unitType]
        if unitInfo ~= nil and unitInfo.Class == "UNITCLASS_SETTLER" then
            WR_Debug(string.format(
                "WR Cannot Settle: blocked Settler training for %s",
                player:GetName()
            ))
            return false
        end

        return true
    end)
end

print("WR Cannot Settle: initialized")

-- White Room Kid Kiyotaka - 4th Generation Operative

print("WhiteRoomFourthGenOperative.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local UNIT_WR_FOURTH_GEN_OPERATIVE = GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE

local function WR_IsWhiteRoomPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_IsFourthGenOperative(playerID, unitID)
    local player = Players[playerID]
    if not WR_IsWhiteRoomPlayer(player) then
        return false
    end

    local unit = player:GetUnitByID(unitID)
    return unit ~= nil and unit:GetUnitType() == UNIT_WR_FOURTH_GEN_OPERATIVE
end

if GameEvents.PlayerCanGiftUnit ~= nil then
    GameEvents.PlayerCanGiftUnit.Add(function(playerID, cityStateID, unitID)
        if WR_IsFourthGenOperative(playerID, unitID) then
            return false
        end

        return true
    end)
end

print("WR 4th Generation Operative: initialized")

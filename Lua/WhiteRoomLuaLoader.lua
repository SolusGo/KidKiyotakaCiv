-- White Room Kid Kiyotaka - Lua Loader

print("WhiteRoomLuaLoader.lua loaded")

local function WR_Include(fileName)
    local ok, err = pcall(function()
        include(fileName)
    end)

    if ok then
        print("WhiteRoomLuaLoader included " .. fileName)
    else
        print("WhiteRoomLuaLoader failed to include " .. fileName .. ": " .. tostring(err))
    end
end

WR_Include("WhiteRoomTelemetry.lua")
WR_Include("WhiteRoomKiyotakaFlavor.lua")
WR_Include("WhiteRoomCannotSettle.lua")
WR_Include("WhiteRoomDuplicateImprovements.lua")
WR_Include("WhiteRoomCityHpAdaptation.lua")
WR_Include("WhiteRoomCityRangedStrikeAdaptation.lua")
WR_Include("WhiteRoomTradeRouteLearning.lua")
WR_Include("WhiteRoomCapturedCityLearning.lua")
WR_Include("WhiteRoomKiyotakaScaling.lua")
WR_Include("WhiteRoomUnitCaps.lua")
WR_Include("WhiteRoomFourthGenOperative.lua")

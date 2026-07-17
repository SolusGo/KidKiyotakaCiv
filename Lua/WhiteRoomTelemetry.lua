-- White Room Kid Kiyotaka - Persistent Adaptation Telemetry

print("WhiteRoomTelemetry.lua loaded")

local WR_TELEMETRY_SAVE = Modding.OpenSaveData()
local WR_TELEMETRY_MAX_EVENTS = 32

local function WR_TelemetryPrefix(playerID)
    return "WR_TELEMETRY_" .. tostring(playerID) .. "_"
end

local function WR_TelemetrySlotKey(playerID, slot, suffix)
    return WR_TelemetryPrefix(playerID) .. "SLOT_" .. tostring(slot) .. "_" .. suffix
end

local function WR_TelemetrySafeText(value, fallback)
    if value == nil then
        return fallback or ""
    end

    local text = tostring(value)
    if text == "" then
        return fallback or ""
    end

    return text
end

function WR_RecordTelemetry(playerID, category, headline, detail)
    if playerID == nil or playerID < 0 then
        return
    end

    local prefix = WR_TelemetryPrefix(playerID)
    local sequence = tonumber(WR_TELEMETRY_SAVE.GetValue(prefix .. "SEQUENCE")) or 0
    sequence = sequence + 1

    local slot = ((sequence - 1) % WR_TELEMETRY_MAX_EVENTS) + 1
    local turn = 0
    if Game ~= nil and Game.GetGameTurn ~= nil then
        turn = Game.GetGameTurn()
    end

    WR_TELEMETRY_SAVE.SetValue(prefix .. "SEQUENCE", sequence)
    WR_TELEMETRY_SAVE.SetValue(WR_TelemetrySlotKey(playerID, slot, "SEQUENCE"), sequence)
    WR_TELEMETRY_SAVE.SetValue(WR_TelemetrySlotKey(playerID, slot, "TURN"), turn)
    WR_TELEMETRY_SAVE.SetValue(WR_TelemetrySlotKey(playerID, slot, "CATEGORY"), WR_TelemetrySafeText(category, "SYSTEM"))
    WR_TELEMETRY_SAVE.SetValue(WR_TelemetrySlotKey(playerID, slot, "HEADLINE"), WR_TelemetrySafeText(headline, "ADAPTATION RECORDED"))
    WR_TELEMETRY_SAVE.SetValue(WR_TelemetrySlotKey(playerID, slot, "DETAIL"), WR_TelemetrySafeText(detail, "No additional data."))
end

print("WR Adaptation Telemetry: initialized; retaining newest " .. tostring(WR_TELEMETRY_MAX_EVENTS) .. " records")

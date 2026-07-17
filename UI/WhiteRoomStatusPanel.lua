-- White Room Kid Kiyotaka - In-game Status Panel

print("WhiteRoomStatusPanel.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local UNIT_WR_KIYOTAKA = GameInfoTypes.UNIT_WR_KIYOTAKA
local UNIT_WR_FOURTH_GEN_OPERATIVE = GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE
local WR_CIV_ICON_ATLAS = "WR_WHITE_ROOM_ICON_ATLAS"

local WR_STATUS_SAVE = Modding.OpenSaveData()
local WR_PERCENT_PER_DUPLICATE = 0.5
local WR_CITY_DEF_PERCENT_PER_STACK = 0.25
local WR_CITY_RANGED_PERCENT_PER_STACK = 0.25
local WR_CITY_LOSS_DEF_PERCENT_PER_STACK = 0.25
local WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK = 0.5
local WR_TELEMETRY_MAX_EVENTS = 32
local WR_ACTIVE_TAB = "EMPIRE"
local WR_CITY_SCREEN_OPEN = false
local WR_DIPLOMACY_OPEN = false
local WR_OPEN_BLOCKING_POPUPS = {}
local WR_COMPACT_MODE = false
local WR_DIPLO_LIST_CONTEXT = nil
local WR_DIPLO_LIST_WAS_OPEN = false
local WR_DIPLO_LIST_POLL_ELAPSED = 0
local WR_TELEMETRY_POLL_ELAPSED = 0
local WR_LAST_TELEMETRY_SEQUENCE = -1

local WR_BLOCKING_POPUP_TYPES = {}

local WR_TAB_PRESENTATION = {
    EMPIRE = {state = "LIVE // E-01", stream = "STREAM // EMPIRE"},
    CITIES = {state = "LIVE // C-02", stream = "STREAM // CITY NETWORK"},
    KIYOTAKA = {state = "LIVE // S-04", stream = "STREAM // SUBJECT 004"},
    UNITS = {state = "LIVE // U-04", stream = "STREAM // GEN-4 OPERATIVES"},
    TELEMETRY = {state = "REC // T-05", stream = "STREAM // ADAPTATION FEED"}
}

local function WR_RegisterBlockingPopup(popupType)
    if popupType ~= nil then
        WR_BLOCKING_POPUP_TYPES[popupType] = true
    end
end

if ButtonPopupTypes ~= nil then
    WR_RegisterBlockingPopup(ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY)
    WR_RegisterBlockingPopup(ButtonPopupTypes.BUTTONPOPUP_DIPLOMATIC_OVERVIEW)
    WR_RegisterBlockingPopup(ButtonPopupTypes.BUTTONPOPUP_CULTURE_OVERVIEW)
end

local WR_YIELD_ORDER = {"FOOD", "PRODUCTION", "GOLD", "SCIENCE", "CULTURE", "FAITH"}

local WR_IMPROVEMENT_YIELDS = {
    IMPROVEMENT_FARM = "FOOD",
    IMPROVEMENT_MINE = "PRODUCTION",
    IMPROVEMENT_LUMBERMILL = "PRODUCTION",
    IMPROVEMENT_QUARRY = "PRODUCTION",
    IMPROVEMENT_MANUFACTORY = "PRODUCTION",
    IMPROVEMENT_TRADING_POST = "GOLD",
    IMPROVEMENT_CUSTOMS_HOUSE = "GOLD",
    IMPROVEMENT_PLANTATION = "GOLD",
    IMPROVEMENT_CAMP = "GOLD",
    IMPROVEMENT_ACADEMY = "SCIENCE",
    IMPROVEMENT_LANDMARK = "CULTURE",
    IMPROVEMENT_HOLY_SITE = "FAITH"
}

local ImprovementYieldByID = {}
local ImprovementLabelByID = {}

local function WR_RegisterImprovement(improvementType, yieldName)
    local improvementID = GameInfoTypes[improvementType]
    if improvementID == nil then
        return
    end

    ImprovementYieldByID[improvementID] = yieldName
    ImprovementLabelByID[improvementID] = string.gsub(string.gsub(improvementType, "IMPROVEMENT_", ""), "_", " ")
end

for improvementType, yieldName in pairs(WR_IMPROVEMENT_YIELDS) do
    WR_RegisterImprovement(improvementType, yieldName)
end

local function WR_IsWhiteRoomPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and CIV_WHITE_ROOM_KID ~= nil
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_GetActiveWhiteRoomPlayer()
    local activePlayerID = Game.GetActivePlayer()
    local activePlayer = Players[activePlayerID]
    if WR_IsWhiteRoomPlayer(activePlayer) then
        return activePlayerID, activePlayer
    end

    for playerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
        local player = Players[playerID]
        if WR_IsWhiteRoomPlayer(player) then
            return playerID, player
        end
    end

    return nil, nil
end

local function WR_SaveValue(key)
    return WR_STATUS_SAVE.GetValue(key)
end

local function WR_GetSavedNumber(key)
    local value = WR_SaveValue(key)
    if type(value) == "number" then
        return value
    end

    return tonumber(value) or 0
end

local function WR_CitySaveKey(prefix, playerID, city, suffix)
    return prefix .. tostring(playerID) .. ":" .. tostring(city:GetID()) .. "_" .. suffix
end

local function WR_PlayerSaveKey(prefix, playerID, suffix)
    return prefix .. tostring(playerID) .. "_" .. suffix
end

local function WR_TelemetryPrefix(playerID)
    return "WR_TELEMETRY_" .. tostring(playerID) .. "_"
end

local function WR_TelemetrySlotKey(playerID, slot, suffix)
    return WR_TelemetryPrefix(playerID) .. "SLOT_" .. tostring(slot) .. "_" .. suffix
end

local function WR_GetTelemetrySequence(playerID)
    return WR_GetSavedNumber(WR_TelemetryPrefix(playerID) .. "SEQUENCE")
end

local function WR_GetTelemetryEvents(playerID)
    local events = {}
    local sequence = WR_GetTelemetrySequence(playerID)
    local retained = math.min(sequence, WR_TELEMETRY_MAX_EVENTS)

    for offset = 0, retained - 1 do
        local eventSequence = sequence - offset
        local slot = ((eventSequence - 1) % WR_TELEMETRY_MAX_EVENTS) + 1
        local storedSequence = WR_GetSavedNumber(WR_TelemetrySlotKey(playerID, slot, "SEQUENCE"))

        if storedSequence == eventSequence then
            table.insert(events, {
                sequence = eventSequence,
                turn = WR_GetSavedNumber(WR_TelemetrySlotKey(playerID, slot, "TURN")),
                category = tostring(WR_SaveValue(WR_TelemetrySlotKey(playerID, slot, "CATEGORY")) or "SYSTEM"),
                headline = tostring(WR_SaveValue(WR_TelemetrySlotKey(playerID, slot, "HEADLINE")) or "ADAPTATION RECORDED"),
                detail = tostring(WR_SaveValue(WR_TelemetrySlotKey(playerID, slot, "DETAIL")) or "No additional data.")
            })
        end
    end

    return events, sequence
end

local function WR_GetTelemetrySummary(playerID)
    local events, sequence = WR_GetTelemetryEvents(playerID)
    local summary = {
        events = events,
        sequence = sequence,
        retained = #events,
        latestTurn = nil,
        subject = 0,
        operative = 0,
        city = 0,
        empire = 0,
        surveillance = 0
    }

    if #events > 0 then
        summary.latestTurn = events[1].turn
    end

    for _, event in ipairs(events) do
        if event.category == "SUBJECT" then
            summary.subject = summary.subject + 1
        elseif event.category == "OPERATIVE" then
            summary.operative = summary.operative + 1
        elseif event.category == "CITY" then
            summary.city = summary.city + 1
        elseif event.category == "SURVEILLANCE" then
            summary.surveillance = summary.surveillance + 1
        else
            summary.empire = summary.empire + 1
        end
    end

    return summary
end

local function WR_IsPlotWorkedByCity(city, plot)
    local ok, result = pcall(function()
        return city:IsWorkingPlot(plot)
    end)

    if ok then
        return result == true
    end

    return plot:GetWorkingCity() == city
end

local function WR_CountWorkedImprovements(playerID, city)
    local improvementCounts = {}
    local yieldPercents = {}

    for _, yieldName in ipairs(WR_YIELD_ORDER) do
        yieldPercents[yieldName] = 0
    end

    for i = 0, city:GetNumCityPlots() - 1 do
        local plot = city:GetCityIndexPlot(i)

        if plot ~= nil and plot:GetOwner() == playerID and WR_IsPlotWorkedByCity(city, plot) then
            local improvementID = plot:GetImprovementType()
            local yieldName = ImprovementYieldByID[improvementID]

            if improvementID ~= nil
                and improvementID ~= -1
                and yieldName ~= nil
                and not plot:IsImprovementPillaged() then
                improvementCounts[improvementID] = (improvementCounts[improvementID] or 0) + 1
            end
        end
    end

    for improvementID, count in pairs(improvementCounts) do
        local yieldName = ImprovementYieldByID[improvementID]
        local duplicates = math.max(0, count - 1)
        if yieldName ~= nil then
            yieldPercents[yieldName] = (yieldPercents[yieldName] or 0) + (duplicates * WR_PERCENT_PER_DUPLICATE)
        end
    end

    return improvementCounts, yieldPercents
end

local function WR_FormatPercentFromHundredths(value)
    return string.format("%.2f%%", (value or 0) / 100)
end

local function WR_FormatHalfPercentStacks(halfStacks)
    return string.format("%.2f%%", (halfStacks or 0) * 0.5)
end

local function WR_Divider()
    return "------------------------------------------------------------"
end

local function WR_Color(text, colorTag)
    return colorTag .. tostring(text or "") .. "[ENDCOLOR]"
end

local function WR_Positive(text)
    return WR_Color(text, "[COLOR_POSITIVE_TEXT]")
end

local function WR_Warning(text)
    return WR_Color(text, "[COLOR_WARNING_TEXT]")
end

local function WR_Negative(text)
    return WR_Color(text, "[COLOR_NEGATIVE_TEXT]")
end

local function WR_Header(text)
    return WR_Color(text, "[COLOR_YIELD_FOOD]")
end

local function WR_StatusBadge(label, tone)
    if tone == "GOOD" then
        return WR_Positive("[" .. label .. "]")
    elseif tone == "BAD" then
        return WR_Negative("[" .. label .. "]")
    elseif tone == "WARN" then
        return WR_Warning("[" .. label .. "]")
    end

    return "[" .. label .. "]"
end

local function WR_StatusTag(isReady)
    if isReady then
        return WR_StatusBadge("READY", "GOOD")
    end

    return WR_StatusBadge("PENDING", "WARN")
end

local function WR_StoredAppliedTag(storedPercent, appliedPercent)
    if (appliedPercent or 0) > 0 then
        return WR_StatusBadge("APPLIED", "GOOD")
    elseif (storedPercent or 0) > 0 then
        return WR_StatusBadge("STORED", "WARN")
    end

    return WR_StatusBadge("WAITING", "BAD")
end

local function WR_FormatStoredApplied(storedPercent, appliedPercent)
    return string.format("+%.2f%% stored, +%d%% applied", storedPercent or 0, appliedPercent or 0)
end

local function WR_FormatYieldPercent(percent)
    return string.format("%.2f", percent or 0)
end

local function WR_AppendYieldLine(lines, label, yieldPercents)
    local parts = {}
    for _, yieldName in ipairs(WR_YIELD_ORDER) do
        local percent = yieldPercents[yieldName] or 0
        if percent > 0 then
            table.insert(parts, WR_Positive(yieldName .. " +" .. WR_FormatYieldPercent(percent) .. "%"))
        end
    end

    if #parts == 0 then
        table.insert(lines, label .. ": " .. WR_StatusBadge("WAITING", "BAD") .. " no duplicate worked-improvement yield bonuses")
    else
        table.insert(lines, label .. ": " .. table.concat(parts, ", "))
    end
end

local function WR_AppendWorkedImprovements(lines, improvementCounts)
    local parts = {}

    for improvementID, count in pairs(improvementCounts) do
        table.insert(parts, string.format("%s x%d", ImprovementLabelByID[improvementID] or tostring(improvementID), count))
    end

    table.sort(parts)

    if #parts == 0 then
        table.insert(lines, "  Worked improvements: " .. WR_StatusBadge("NONE", "WARN") .. " none tracked")
    else
        table.insert(lines, "  Worked improvements: " .. table.concat(parts, ", "))
    end
end

local function WR_FindKiyotaka(player)
    if player == nil or UNIT_WR_KIYOTAKA == nil then
        return nil
    end

    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_WR_KIYOTAKA then
            return unit
        end
    end

    return nil
end

local function WR_CountUnitsOfType(player, unitType)
    local count = 0

    if player == nil or unitType == nil then
        return 0
    end

    for unit in player:Units() do
        if unit:GetUnitType() == unitType then
            count = count + 1
        end
    end

    return count
end

local function WR_CountOperatives(player)
    return WR_CountUnitsOfType(player, UNIT_WR_FOURTH_GEN_OPERATIVE)
end

local function WR_OperativeGlobalKey(playerID, suffix)
    return "WR_OPERATIVE_" .. tostring(playerID) .. "_" .. suffix
end

local function WR_OperativeRecordKey(playerID, serial, suffix)
    return WR_OperativeGlobalKey(playerID, "RECORD_" .. tostring(serial) .. "_" .. suffix)
end

local function WR_OperativeUnitKey(playerID, unitID)
    return WR_OperativeGlobalKey(playerID, "UNIT_" .. tostring(unitID) .. "_SERIAL")
end

local function WR_OperativeCallsign(serial)
    if serial == nil or serial <= 0 then
        return "OPERATIVE-??"
    end

    return string.format("OPERATIVE-%02d", serial)
end

local function WR_GetOperativeRecordNumber(playerID, serial, suffix)
    return WR_GetSavedNumber(WR_OperativeRecordKey(playerID, serial, suffix))
end

local function WR_GetOperativeLifetimeSummary(playerID)
    return {
        deployed = WR_GetSavedNumber(WR_OperativeGlobalKey(playerID, "NEXT_SERIAL")),
        losses = WR_GetSavedNumber(WR_OperativeGlobalKey(playerID, "TOTAL_LOSSES")),
        combats = WR_GetSavedNumber(WR_OperativeGlobalKey(playerID, "TOTAL_COMBATS")),
        kills = WR_GetSavedNumber(WR_OperativeGlobalKey(playerID, "TOTAL_KILLS")),
        damageDealt = WR_GetSavedNumber(WR_OperativeGlobalKey(playerID, "TOTAL_DAMAGE_DEALT")),
        damageTaken = WR_GetSavedNumber(WR_OperativeGlobalKey(playerID, "TOTAL_DAMAGE_TAKEN")),
        woundedEngagements = WR_GetSavedNumber(WR_OperativeGlobalKey(playerID, "TOTAL_WOUNDED_ENGAGEMENTS")),
        friendlyEngagements = WR_GetSavedNumber(WR_OperativeGlobalKey(playerID, "TOTAL_FRIENDLY_ENGAGEMENTS"))
    }
end

local function WR_GetActiveOperativeRecords(playerID, player)
    local records = {}

    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_WR_FOURTH_GEN_OPERATIVE then
            local serial = WR_GetSavedNumber(WR_OperativeUnitKey(playerID, unit:GetID()))
            local plot = unit:GetPlot()
            local location = "unknown"
            if plot ~= nil then
                location = string.format("(%d, %d)", plot:GetX(), plot:GetY())
            end

            table.insert(records, {
                serial = serial,
                callsign = WR_OperativeCallsign(serial),
                unit = unit,
                location = location,
                deployTurn = serial > 0 and WR_GetOperativeRecordNumber(playerID, serial, "DEPLOY_TURN") or Game.GetGameTurn(),
                combats = serial > 0 and WR_GetOperativeRecordNumber(playerID, serial, "COMBATS") or 0,
                kills = serial > 0 and WR_GetOperativeRecordNumber(playerID, serial, "KILLS") or 0,
                damageDealt = serial > 0 and WR_GetOperativeRecordNumber(playerID, serial, "DAMAGE_DEALT") or 0,
                damageTaken = serial > 0 and WR_GetOperativeRecordNumber(playerID, serial, "DAMAGE_TAKEN") or 0,
                woundedEngagements = serial > 0 and WR_GetOperativeRecordNumber(playerID, serial, "WOUNDED_ENGAGEMENTS") or 0,
                friendlyEngagements = serial > 0 and WR_GetOperativeRecordNumber(playerID, serial, "FRIENDLY_ENGAGEMENTS") or 0
            })
        end
    end

    table.sort(records, function(a, b)
        if a.serial == b.serial then
            return a.unit:GetID() < b.unit:GetID()
        end

        if a.serial <= 0 then
            return false
        elseif b.serial <= 0 then
            return true
        end

        return a.serial < b.serial
    end)

    return records
end

local function WR_TechStatus(player, unitType)
    local unitInfo = unitType ~= nil and GameInfo.Units[unitType] or nil
    if player == nil or unitInfo == nil or unitInfo.PrereqTech == nil then
        return "No tech requirement found"
    end

    local techID = GameInfoTypes[unitInfo.PrereqTech]
    local techInfo = techID ~= nil and GameInfo.Technologies[techID] or nil
    local techName = techInfo ~= nil and Locale.ConvertTextKey(techInfo.Description) or unitInfo.PrereqTech
    local team = Teams[player:GetTeam()]

    if team ~= nil and techID ~= nil and team:IsHasTech(techID) then
        return "Unlocked by " .. techName
    end

    return "Requires " .. techName
end

local function WR_CanTrainStatus(player, unitType)
    if player == nil or unitType == nil then
        return "Unavailable"
    end

    local ok, result = pcall(function()
        return player:CanTrain(unitType)
    end)

    if ok and result == true then
        return "Can train"
    end

    return "Cannot train right now"
end

local function WR_ClassLabel(unitCombatInfo)
    if unitCombatInfo == nil then
        return "Unknown"
    end

    return string.gsub(string.gsub(unitCombatInfo.Type, "UNITCOMBAT_", ""), "_", " ")
end

local function WR_GetKiyotakaProfile(playerID)
    local keyPrefix = "WR_KIYOTAKA_" .. tostring(playerID) .. "_"
    local profile = {
        combat = WR_GetSavedNumber(keyPrefix .. "COMBAT"),
        attack = WR_GetSavedNumber(keyPrefix .. "ATTACK"),
        resistance = WR_GetSavedNumber(keyPrefix .. "RESISTANCE"),
        healing = WR_GetSavedNumber(keyPrefix .. "HEALING"),
        desperation = WR_GetSavedNumber(keyPrefix .. "DESPERATION"),
        moveChance = WR_GetSavedNumber(keyPrefix .. "MOVE_CHANCE"),
        pendingHeal = WR_GetSavedNumber(keyPrefix .. "PENDING_HEAL"),
        bestClassLabel = "None",
        bestClassValue = 0,
        classParts = {}
    }

    profile.totalScore = profile.combat
        + profile.attack
        + profile.resistance
        + profile.healing
        + profile.desperation
        + profile.moveChance

    for unitCombatInfo in GameInfo.UnitCombatInfos() do
        local suffix = string.gsub(unitCombatInfo.Type, "UNITCOMBAT_", "")
        local value = WR_GetSavedNumber(keyPrefix .. "CLASS_" .. suffix)
        if value > 0 then
            profile.totalScore = profile.totalScore + value
            local label = WR_ClassLabel(unitCombatInfo)
            table.insert(profile.classParts, string.format("%s +%s", label, WR_FormatPercentFromHundredths(value)))

            if value > profile.bestClassValue then
                profile.bestClassValue = value
                profile.bestClassLabel = label
            end
        end
    end

    table.sort(profile.classParts)
    profile.flowRemaining = math.max(0, 10000 - profile.moveChance)

    return profile
end

local function WR_AppendPanelHeader(lines, title, player)
    table.insert(lines, WR_Header(title))
    table.insert(lines, WR_Divider())
    table.insert(lines, "Player: " .. (player:GetName() or "White Room") .. "    Turn: " .. tostring(Game.GetGameTurn()))
    table.insert(lines, "")
end

local function WR_TelemetryBadge(category)
    if category == "SUBJECT" then
        return WR_StatusBadge("SUBJECT", "GOOD")
    elseif category == "OPERATIVE" then
        return WR_StatusBadge("OPERATIVE", "GOOD")
    elseif category == "CITY" then
        return WR_StatusBadge("CITY", "WARN")
    elseif category == "SURVEILLANCE" then
        return WR_StatusBadge("SURVEILLANCE", "BAD")
    elseif category == "EMPIRE" then
        return WR_StatusBadge("EMPIRE", "GOOD")
    end

    return WR_StatusBadge("SYSTEM", "WARN")
end

local function WR_AppendTelemetry(lines, playerID)
    local summary = WR_GetTelemetrySummary(playerID)

    table.insert(lines, WR_Header("Live Adaptation Telemetry"))
    table.insert(lines, WR_Divider())
    table.insert(lines, string.format(
        "  %s Newest %d of %d retained records // %d lifetime events",
        WR_StatusBadge("RECORDING", "GOOD"),
        summary.retained,
        WR_TELEMETRY_MAX_EVENTS,
        summary.sequence
    ))
    table.insert(lines, "  Subject " .. tostring(summary.subject)
        .. "    Operative " .. tostring(summary.operative)
        .. "    City " .. tostring(summary.city)
        .. "    Empire " .. tostring(summary.empire)
        .. "    Surveillance " .. tostring(summary.surveillance))
    table.insert(lines, "")

    if summary.retained == 0 then
        table.insert(lines, "  " .. WR_StatusBadge("AWAITING DATA", "WARN") .. " No adaptation events have been recorded yet.")
        table.insert(lines, "  Combat, city pressure, trade analysis, and observed city losses will appear here.")
        return
    end

    local displayCount = summary.retained
    if WR_COMPACT_MODE then
        displayCount = math.min(displayCount, 12)
    end

    for index = 1, displayCount do
        local event = summary.events[index]
        table.insert(lines, string.format(
            "  %s  TURN %d // %s",
            WR_TelemetryBadge(event.category),
            event.turn,
            event.headline
        ))

        if WR_COMPACT_MODE then
            table.insert(lines, "     " .. event.detail)
        else
            table.insert(lines, "     " .. WR_Positive("DATA") .. " // " .. event.detail)
            table.insert(lines, "     RECORD " .. string.format("%04d", event.sequence))
        end

        table.insert(lines, "")
    end

    if WR_COMPACT_MODE and summary.retained > displayCount then
        table.insert(lines, "  " .. tostring(summary.retained - displayCount) .. " older retained records hidden in compact mode.")
    end
end

local function WR_AppendKiyotaka(lines, playerID, player)
    local profile = WR_GetKiyotakaProfile(playerID)

    table.insert(lines, WR_Header("Subject Dossier"))
    table.insert(lines, WR_Divider())

    local unit = WR_FindKiyotaka(player)
    if unit == nil then
        table.insert(lines, "  " .. WR_StatusBadge("MISSING", "BAD") .. " Not currently deployed.")
    else
        local plot = unit:GetPlot()
        local location = "unknown location"
        if plot ~= nil then
            location = string.format("(%d, %d)", plot:GetX(), plot:GetY())
        end

        table.insert(lines, string.format(
            "  %s Level %d    XP %d    HP %d/100    Location %s",
            WR_StatusBadge("ACTIVE", "GOOD"),
            unit:GetLevel(),
            unit:GetExperience(),
            100 - unit:GetDamage(),
            location
        ))
    end

    table.insert(lines, "")
    table.insert(lines, WR_Header("Adaptation Profile"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  Total adaptation score +" .. WR_FormatPercentFromHundredths(profile.totalScore))
    table.insert(lines, "  Strongest matchup      " .. (profile.bestClassValue > 0 and WR_Positive(profile.bestClassLabel .. " +" .. WR_FormatPercentFromHundredths(profile.bestClassValue)) or WR_StatusBadge("NONE", "WARN")))
    table.insert(lines, "  Flow State             " .. WR_StatusTag(profile.moveChance >= 10000) .. " " .. WR_FormatPercentFromHundredths(profile.moveChance))
    table.insert(lines, "  Next Flow threshold    " .. (profile.flowRemaining > 0 and ("needs +" .. WR_FormatPercentFromHundredths(profile.flowRemaining)) or WR_Positive("ready")))
    table.insert(lines, "  Pending low-HP heal    " .. (profile.pendingHeal > 0 and WR_Positive("+" .. tostring(profile.pendingHeal) .. " HP next turn") or WR_StatusBadge("NONE", "WARN")))

    if WR_COMPACT_MODE then
        return
    end

    table.insert(lines, "")
    table.insert(lines, WR_Header("Perfect Adaptation Details"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  Combat       +" .. WR_FormatPercentFromHundredths(profile.combat))
    table.insert(lines, "  Attack       +" .. WR_FormatPercentFromHundredths(profile.attack))
    table.insert(lines, "  Resistance   +" .. WR_FormatPercentFromHundredths(profile.resistance))
    table.insert(lines, "  Healing      +" .. WR_FormatPercentFromHundredths(profile.healing))
    table.insert(lines, "  Low-HP power +" .. WR_FormatPercentFromHundredths(profile.desperation))
    table.insert(lines, "  Move chance  +" .. WR_FormatPercentFromHundredths(profile.moveChance))

    if #profile.classParts > 0 then
        table.insert(lines, "")
        table.insert(lines, WR_Header("Class Adaptations"))
        table.insert(lines, WR_Divider())
        for _, classLine in ipairs(profile.classParts) do
            table.insert(lines, "  " .. classLine)
        end
    else
        table.insert(lines, "")
        table.insert(lines, WR_Header("Class Adaptations"))
        table.insert(lines, WR_Divider())
        table.insert(lines, "  " .. WR_StatusBadge("NONE", "WARN") .. " No class-specific kill data yet")
    end
end

local function WR_AppendEmpire(lines, playerID)
    local tradeHalfStacks = WR_GetSavedNumber(WR_PlayerSaveKey("WR_TRADE_ROUTE_LEARNING_", playerID, "HALF_GOLD_STACKS"))
    local cityLossStacks = WR_GetSavedNumber(WR_PlayerSaveKey("WR_CAPTURED_CITY_LEARNING_", playerID, "CITY_LOSS_STACKS"))
    local tradeStored = tradeHalfStacks * 0.5
    local tradeApplied = math.floor(tradeHalfStacks / 2)
    local cityAttackStored = cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK
    local cityAttackApplied = math.floor(cityAttackStored)
    local cityDefenseStored = cityLossStacks * WR_CITY_LOSS_DEF_PERCENT_PER_STACK
    local cityDefenseApplied = math.floor(cityDefenseStored)

    table.insert(lines, WR_Header("Priority Readout"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  Trade gold       " .. WR_StoredAppliedTag(tradeStored, tradeApplied) .. " " .. WR_FormatStoredApplied(tradeStored, tradeApplied))
    table.insert(lines, "  Attack vs cities " .. WR_StoredAppliedTag(cityAttackStored, cityAttackApplied) .. " " .. WR_FormatStoredApplied(cityAttackStored, cityAttackApplied))
    table.insert(lines, "  City defense     " .. WR_StoredAppliedTag(cityDefenseStored, cityDefenseApplied) .. " " .. WR_FormatStoredApplied(cityDefenseStored, cityDefenseApplied))

    if WR_COMPACT_MODE then
        return
    end

    table.insert(lines, "")
    table.insert(lines, WR_Header("Learning Counters"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  Trade-route progress: " .. string.format("%.2f / 2.00 half-stacks toward next +1%% Gold", tradeHalfStacks % 2))
    table.insert(lines, "  Observed city losses: " .. tostring(cityLossStacks))
end

local function WR_AppendCities(lines, playerID, player)
    local hasCities = false
    local bestCityName = nil
    local bestCityScore = -1
    local cityCards = {}
    local totalDuplicatePercent = 0
    local totalDefenseStacks = 0
    local totalRangedStacks = 0

    for city in player:Cities() do
        hasCities = true
        local hpStacks = WR_GetSavedNumber(WR_CitySaveKey("WR_CITY_HP_", playerID, city, "DEF_STACKS"))
        local rangedStacks = WR_GetSavedNumber(WR_CitySaveKey("WR_CITY_RANGED_", playerID, city, "ATTACK_STACKS"))
        local improvementCounts, yieldPercents = WR_CountWorkedImprovements(playerID, city)
        local cityScore = hpStacks + rangedStacks

        for _, yieldName in ipairs(WR_YIELD_ORDER) do
            local percent = yieldPercents[yieldName] or 0
            cityScore = cityScore + (percent * 4)
            totalDuplicatePercent = totalDuplicatePercent + percent
        end

        totalDefenseStacks = totalDefenseStacks + hpStacks
        totalRangedStacks = totalRangedStacks + rangedStacks

        if cityScore > bestCityScore then
            bestCityScore = cityScore
            bestCityName = city:GetName()
        end

        local hpStored = hpStacks * WR_CITY_DEF_PERCENT_PER_STACK
        local hpApplied = math.floor(hpStored)
        local rangedStored = rangedStacks * WR_CITY_RANGED_PERCENT_PER_STACK
        local rangedApplied = math.floor(rangedStored)

        table.insert(cityCards, {
            name = city:GetName(),
            score = cityScore,
            hpStacks = hpStacks,
            hpStored = hpStored,
            hpApplied = hpApplied,
            rangedStacks = rangedStacks,
            rangedStored = rangedStored,
            rangedApplied = rangedApplied,
            improvementCounts = improvementCounts,
            yieldPercents = yieldPercents
        })
    end

    if not hasCities then
        table.insert(lines, "  No White Room cities found.")
        return
    end

    table.insert(lines, WR_Header("City Network"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  Cities monitored: " .. tostring(#cityCards))
    table.insert(lines, "  Most adapted: " .. WR_Positive(bestCityName or "None"))
    table.insert(lines, "  Defense stacks: " .. tostring(totalDefenseStacks) .. "    Ranged stacks: " .. tostring(totalRangedStacks))
    table.insert(lines, "  Duplicate yield total: +" .. string.format("%.2f%%", totalDuplicatePercent))
    table.insert(lines, "")

    table.sort(cityCards, function(a, b)
        if a.score == b.score then
            return a.name < b.name
        end

        return a.score > b.score
    end)

    table.insert(lines, WR_Header("City Cards"))
    table.insert(lines, WR_Divider())

    for _, card in ipairs(cityCards) do
        table.insert(lines, WR_Header(card.name))
        table.insert(lines, WR_Divider())
        table.insert(lines, string.format(
            "  Defense   %s stacks %3d  %s",
            WR_StoredAppliedTag(card.hpStored, card.hpApplied),
            card.hpStacks,
            WR_FormatStoredApplied(card.hpStored, card.hpApplied)
        ))
        table.insert(lines, string.format(
            "  Ranged    %s stacks %3d  %s",
            WR_StoredAppliedTag(card.rangedStored, card.rangedApplied),
            card.rangedStacks,
            WR_FormatStoredApplied(card.rangedStored, card.rangedApplied)
        ))
        if WR_COMPACT_MODE then
            WR_AppendYieldLine(lines, "  Duplicate yields", card.yieldPercents)
        else
            WR_AppendYieldLine(lines, "  Duplicate yields", card.yieldPercents)
            WR_AppendWorkedImprovements(lines, card.improvementCounts)
        end
        table.insert(lines, "")
    end
end

local function WR_AppendUnits(lines, playerID, player)
    local kiyotakaCount = WR_CountUnitsOfType(player, UNIT_WR_KIYOTAKA)
    local operativeCount = WR_CountUnitsOfType(player, UNIT_WR_FOURTH_GEN_OPERATIVE)
    local lifetime = WR_GetOperativeLifetimeSummary(playerID)
    local activeRecords = WR_GetActiveOperativeRecords(playerID, player)

    table.insert(lines, WR_Header("Kiyotaka Ayanokoji"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  " .. WR_StatusTag(kiyotakaCount > 0) .. " Active: " .. tostring(kiyotakaCount) .. " / 1")
    table.insert(lines, "  Tech: " .. WR_TechStatus(player, UNIT_WR_KIYOTAKA))
    if not WR_COMPACT_MODE then
        table.insert(lines, "  Training: " .. WR_CanTrainStatus(player, UNIT_WR_KIYOTAKA))
        table.insert(lines, "  Cannot be purchased; extras are removed by the cap script.")
    end
    table.insert(lines, "")
    table.insert(lines, WR_Header("4th Generation Operatives"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  " .. WR_StatusTag(operativeCount > 0) .. " Active: " .. tostring(operativeCount) .. " / 3")
    table.insert(lines, "  Tech: " .. WR_TechStatus(player, UNIT_WR_FOURTH_GEN_OPERATIVE))
    table.insert(lines, string.format(
        "  Lifetime: %d deployed // %d lost // %d combats // %d kills",
        lifetime.deployed,
        lifetime.losses,
        lifetime.combats,
        lifetime.kills
    ))
    table.insert(lines, string.format(
        "  Combat data: %d damage dealt // %d taken // %d wounded-target // %d controlled-environment engagements",
        lifetime.damageDealt,
        lifetime.damageTaken,
        lifetime.woundedEngagements,
        lifetime.friendlyEngagements
    ))
    if not WR_COMPACT_MODE then
        table.insert(lines, "  Training: " .. WR_CanTrainStatus(player, UNIT_WR_FOURTH_GEN_OPERATIVE))
        table.insert(lines, "  Cannot be purchased or gifted to City-States.")
    end

    table.insert(lines, "")
    table.insert(lines, WR_Header("Active Service Records"))
    table.insert(lines, WR_Divider())

    if #activeRecords == 0 then
        table.insert(lines, "  " .. WR_StatusBadge("NO ACTIVE OPERATIVES", "WARN") .. " Awaiting deployment.")
    else
        for _, record in ipairs(activeRecords) do
            local unit = record.unit
            table.insert(lines, string.format(
                "  %s %s  Level %d // XP %d // HP %d/100",
                WR_StatusBadge("ACTIVE", "GOOD"),
                WR_Header(record.callsign),
                unit:GetLevel(),
                unit:GetExperience(),
                100 - unit:GetDamage()
            ))
            table.insert(lines, string.format(
                "     Deployed turn %d // Location %s // %d combats // %d kills",
                record.deployTurn,
                record.location,
                record.combats,
                record.kills
            ))

            if not WR_COMPACT_MODE then
                table.insert(lines, string.format(
                    "     Damage %d dealt / %d taken // Wounded targets %d // Controlled environment %d",
                    record.damageDealt,
                    record.damageTaken,
                    record.woundedEngagements,
                    record.friendlyEngagements
                ))
            end

            table.insert(lines, "")
        end
    end

    if not WR_COMPACT_MODE and lifetime.losses > 0 then
        table.insert(lines, WR_Header("Archived Service Records"))
        table.insert(lines, WR_Divider())

        local firstSerial = math.max(1, lifetime.deployed - 7)
        local archivedShown = 0
        for serial = lifetime.deployed, firstSerial, -1 do
            if WR_GetOperativeRecordNumber(playerID, serial, "ACTIVE") == 0
                and WR_GetOperativeRecordNumber(playerID, serial, "LOSS_TURN") >= 0 then
                table.insert(lines, string.format(
                    "  %s %s  Turns %d-%d // Level %d // %d combats // %d kills // Damage %d / %d",
                    WR_StatusBadge("LOST", "BAD"),
                    WR_OperativeCallsign(serial),
                    WR_GetOperativeRecordNumber(playerID, serial, "DEPLOY_TURN"),
                    WR_GetOperativeRecordNumber(playerID, serial, "LOSS_TURN"),
                    WR_GetOperativeRecordNumber(playerID, serial, "FINAL_LEVEL"),
                    WR_GetOperativeRecordNumber(playerID, serial, "COMBATS"),
                    WR_GetOperativeRecordNumber(playerID, serial, "KILLS"),
                    WR_GetOperativeRecordNumber(playerID, serial, "DAMAGE_DEALT"),
                    WR_GetOperativeRecordNumber(playerID, serial, "DAMAGE_TAKEN")
                ))
                archivedShown = archivedShown + 1
            end
        end

        if lifetime.losses > archivedShown then
            table.insert(lines, "  " .. tostring(lifetime.losses - archivedShown) .. " older archived records omitted from this readout.")
        end
    end
end

local function WR_BuildStatusText()
    local playerID, player = WR_GetActiveWhiteRoomPlayer()
    local lines = {}

    if player == nil then
        return "No active White Room civilization found in this game."
    end

    if WR_ACTIVE_TAB == "CITIES" then
        WR_AppendPanelHeader(lines, "City Adaptation Records", player)
        WR_AppendCities(lines, playerID, player)
    elseif WR_ACTIVE_TAB == "KIYOTAKA" then
        WR_AppendPanelHeader(lines, "Subject Dossier: Kiyotaka", player)
        WR_AppendKiyotaka(lines, playerID, player)
    elseif WR_ACTIVE_TAB == "UNITS" then
        WR_AppendPanelHeader(lines, "Operative Deployment", player)
        WR_AppendUnits(lines, playerID, player)
    elseif WR_ACTIVE_TAB == "TELEMETRY" then
        WR_AppendPanelHeader(lines, "Adaptation Telemetry", player)
        WR_AppendTelemetry(lines, playerID)
    else
        WR_AppendPanelHeader(lines, "Facility Readout", player)
        table.insert(lines, "Deployment overview: Kiyotaka " .. tostring(WR_CountUnitsOfType(player, UNIT_WR_KIYOTAKA)) .. " / 1    4th Gen Operatives " .. tostring(WR_CountOperatives(player)) .. " / 3")
        table.insert(lines, "")
        WR_AppendEmpire(lines, playerID)
    end

    return table.concat(lines, "[NEWLINE]")
end

local function WR_SetLabel(control, text)
    if control ~= nil and control.SetString ~= nil then
        control:SetString(text or "")
    end
end

local function WR_SetTooltip(control, text)
    if control ~= nil and control.SetToolTipString ~= nil then
        control:SetToolTipString(text or "")
    end
end

local function WR_SetSummaryMetric(captionControl, valueControl, caption, value)
    WR_SetLabel(captionControl, caption)
    WR_SetLabel(valueControl, value)
end

local function WR_SetMetricTooltip(captionControl, valueControl, text)
    WR_SetTooltip(captionControl, text)
    WR_SetTooltip(valueControl, text)
end

local function WR_TryIncludeIconSupport()
    local ok, err = pcall(function()
        include("IconSupport")
    end)

    if not ok then
        print("WR Status Panel: could not load IconSupport: " .. tostring(err))
    end
end

local function WR_SetCivIcon(control, iconSize)
    if control == nil then
        return false
    end

    if IconHookup == nil then
        control:SetHide(true)
        return false
    end

    local ok, result = pcall(IconHookup, 0, iconSize, WR_CIV_ICON_ATLAS, control)
    control:SetHide(not ok or result == false)
    return ok and result ~= false
end

local function WR_UpdateSummaryTooltips()
    WR_SetTooltip(Controls.SummaryTitle, "At-a-glance White Room readout for the active tab.")
    WR_SetMetricTooltip(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "")
    WR_SetMetricTooltip(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "")
    WR_SetMetricTooltip(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "")
    WR_SetMetricTooltip(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "")

    if WR_ACTIVE_TAB == "CITIES" then
        WR_SetMetricTooltip(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "Number of White Room cities currently monitored.")
        WR_SetMetricTooltip(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "City with the highest combined adaptation score.")
        WR_SetMetricTooltip(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "Total city-defense stacks from taking city damage.")
        WR_SetMetricTooltip(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "Total stored duplicate worked-improvement yield bonus across all cities. Each duplicate worked improvement gives +0.5% to its linked yield.")
    elseif WR_ACTIVE_TAB == "KIYOTAKA" then
        WR_SetMetricTooltip(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "Whether Kiyotaka is currently deployed.")
        WR_SetMetricTooltip(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "Kiyotaka's current hit points, if deployed.")
        WR_SetMetricTooltip(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "Combined visible Perfect Adaptation score from combat, attack, resistance, healing, low-HP power, movement chance, and class matchup counters.")
        WR_SetMetricTooltip(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "Movement-after-combat chance. Flow State becomes ready at 100%.")
    elseif WR_ACTIVE_TAB == "UNITS" then
        WR_SetMetricTooltip(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "Kiyotaka active count. The cap script limits this unit to one.")
        WR_SetMetricTooltip(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "4th Generation Operative active count. The cap script limits them to three.")
        WR_SetMetricTooltip(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "Lifetime confirmed kills recorded across all 4th Generation Operatives.")
        WR_SetMetricTooltip(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "Lifetime combat engagements recorded across all 4th Generation Operatives.")
    elseif WR_ACTIVE_TAB == "TELEMETRY" then
        WR_SetMetricTooltip(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "Total number of adaptation telemetry events recorded during this game.")
        WR_SetMetricTooltip(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "Newest records currently retained in the rotating telemetry buffer.")
        WR_SetMetricTooltip(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "Kiyotaka combat and survival records retained in the current feed.")
        WR_SetMetricTooltip(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "4th Generation Operative records retained in the current feed.")
    else
        WR_SetMetricTooltip(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "Trade-route learning. Stored fractional gold becomes applied once it reaches a full integer percent.")
        WR_SetMetricTooltip(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "Number of observed city-loss events that feed the captured-city learning mechanic.")
        WR_SetMetricTooltip(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "Empire-wide attack bonus against cities from observed city losses.")
        WR_SetMetricTooltip(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "Highest-scoring city by adaptation stacks and duplicate-yield progress.")
    end
end

local function WR_BuildCitySummary(playerID, player)
    local cityCount = 0
    local bestCityName = "None"
    local bestScore = -1
    local totalDefenseStacks = 0
    local totalRangedStacks = 0
    local totalDuplicatePercent = 0

    for city in player:Cities() do
        cityCount = cityCount + 1

        local hpStacks = WR_GetSavedNumber(WR_CitySaveKey("WR_CITY_HP_", playerID, city, "DEF_STACKS"))
        local rangedStacks = WR_GetSavedNumber(WR_CitySaveKey("WR_CITY_RANGED_", playerID, city, "ATTACK_STACKS"))
        local improvementCounts, yieldPercents = WR_CountWorkedImprovements(playerID, city)
        local cityScore = hpStacks + rangedStacks

        totalDefenseStacks = totalDefenseStacks + hpStacks
        totalRangedStacks = totalRangedStacks + rangedStacks

        for _, yieldName in ipairs(WR_YIELD_ORDER) do
            local percent = yieldPercents[yieldName] or 0
            totalDuplicatePercent = totalDuplicatePercent + percent
            cityScore = cityScore + (percent * 4)
        end

        if cityScore > bestScore then
            bestScore = cityScore
            bestCityName = city:GetName()
        end
    end

    return cityCount, bestCityName, totalDefenseStacks, totalRangedStacks, totalDuplicatePercent
end

local function WR_UnitHpLine(unit)
    if unit == nil then
        return "Not deployed"
    end

    return string.format("HP %d/100", 100 - unit:GetDamage())
end

local function WR_UpdateSummaryPanel()
    local playerID, player = WR_GetActiveWhiteRoomPlayer()
    if player == nil then
        WR_SetLabel(Controls.SummaryTitle, "No White Room civilization found")
        WR_SetSummaryMetric(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "", "")
        WR_SetSummaryMetric(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "", "")
        WR_SetSummaryMetric(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "", "")
        WR_SetSummaryMetric(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "", "")
        return
    end

    local tradeHalfStacks = WR_GetSavedNumber(WR_PlayerSaveKey("WR_TRADE_ROUTE_LEARNING_", playerID, "HALF_GOLD_STACKS"))
    local cityLossStacks = WR_GetSavedNumber(WR_PlayerSaveKey("WR_CAPTURED_CITY_LEARNING_", playerID, "CITY_LOSS_STACKS"))
    local cityCount, bestCityName, totalDefenseStacks, totalRangedStacks, totalDuplicatePercent = WR_BuildCitySummary(playerID, player)
    local kiyotaka = WR_FindKiyotaka(player)
    local kiyotakaProfile = WR_GetKiyotakaProfile(playerID)

    if WR_ACTIVE_TAB == "CITIES" then
        WR_SetLabel(Controls.SummaryTitle, "City Adaptation Records")
        WR_SetSummaryMetric(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "[ICON_CAPITAL] CITIES", tostring(cityCount))
        WR_SetSummaryMetric(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "[ICON_RESEARCH] MOST ADAPTED", bestCityName)
        WR_SetSummaryMetric(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "[ICON_STRENGTH] DEFENSE STACKS", tostring(totalDefenseStacks))
        WR_SetSummaryMetric(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "[ICON_GOLD] DUPLICATE YIELDS", "+" .. string.format("%.2f%%", totalDuplicatePercent))
    elseif WR_ACTIVE_TAB == "KIYOTAKA" then
        WR_SetLabel(Controls.SummaryTitle, "Subject Dossier: Kiyotaka")
        WR_SetSummaryMetric(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "[ICON_STRENGTH] DEPLOYMENT", kiyotaka ~= nil and "ACTIVE" or "MISSING")
        WR_SetSummaryMetric(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "[ICON_BULLET] VITALS", WR_UnitHpLine(kiyotaka))
        WR_SetSummaryMetric(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "[ICON_RESEARCH] ADAPTATION", "+" .. WR_FormatPercentFromHundredths(kiyotakaProfile.totalScore))
        WR_SetSummaryMetric(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "[ICON_MOVES] FLOW STATE", WR_StatusTag(kiyotakaProfile.moveChance >= 10000) .. " " .. WR_FormatPercentFromHundredths(kiyotakaProfile.moveChance))
    elseif WR_ACTIVE_TAB == "UNITS" then
        local operativeCount = WR_CountOperatives(player)
        local operativeLifetime = WR_GetOperativeLifetimeSummary(playerID)
        WR_SetLabel(Controls.SummaryTitle, "Operative Deployment")
        WR_SetSummaryMetric(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "[ICON_STRENGTH] KIYOTAKA", tostring(WR_CountUnitsOfType(player, UNIT_WR_KIYOTAKA)) .. " / 1")
        WR_SetSummaryMetric(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "[ICON_STRENGTH] OPERATIVES", tostring(operativeCount) .. " / 3")
        WR_SetSummaryMetric(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "[ICON_STRENGTH] LIFETIME KILLS", tostring(operativeLifetime.kills))
        WR_SetSummaryMetric(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "[ICON_BULLET] COMBAT RECORDS", tostring(operativeLifetime.combats))
    elseif WR_ACTIVE_TAB == "TELEMETRY" then
        local telemetry = WR_GetTelemetrySummary(playerID)
        WR_SetLabel(Controls.SummaryTitle, "Live Adaptation Telemetry")
        WR_SetSummaryMetric(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "[ICON_RESEARCH] LIFETIME EVENTS", tostring(telemetry.sequence))
        WR_SetSummaryMetric(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "[ICON_BULLET] RETAINED", tostring(telemetry.retained) .. " / " .. tostring(WR_TELEMETRY_MAX_EVENTS))
        WR_SetSummaryMetric(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "[ICON_STRENGTH] SUBJECT DATA", tostring(telemetry.subject))
        WR_SetSummaryMetric(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "[ICON_STRENGTH] OPERATIVE DATA", tostring(telemetry.operative))
    else
        WR_SetLabel(Controls.SummaryTitle, "Facility Readout")
        WR_SetSummaryMetric(Controls.SummaryMetricOneCaption, Controls.SummaryMetricOne, "[ICON_GOLD] TRADE GOLD", WR_FormatStoredApplied(tradeHalfStacks * 0.5, math.floor(tradeHalfStacks / 2)))
        WR_SetSummaryMetric(Controls.SummaryMetricTwoCaption, Controls.SummaryMetricTwo, "[ICON_CAPITAL] CITY LOSSES", tostring(cityLossStacks))
        WR_SetSummaryMetric(Controls.SummaryMetricThreeCaption, Controls.SummaryMetricThree, "[ICON_STRENGTH] VS CITIES", WR_FormatStoredApplied(cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK, math.floor(cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK)))
        WR_SetSummaryMetric(Controls.SummaryMetricFourCaption, Controls.SummaryMetricFour, "[ICON_RESEARCH] BEST CITY", bestCityName)
    end

    WR_UpdateSummaryTooltips()
end

local function WR_SetButtonString(control, text)
    if control ~= nil and control.SetText ~= nil then
        control:SetText(text)
    elseif control ~= nil and control.SetString ~= nil then
        control:SetString(text)
    end
end

local function WR_UpdateTabButtons()
    local presentation = WR_TAB_PRESENTATION[WR_ACTIVE_TAB] or WR_TAB_PRESENTATION.EMPIRE

    WR_SetButtonString(Controls.EmpireTabButton, "[ICON_GOLD] " .. (WR_ACTIVE_TAB == "EMPIRE" and "EMPIRE" or "Empire"))
    WR_SetButtonString(Controls.CitiesTabButton, "[ICON_CAPITAL] " .. (WR_ACTIVE_TAB == "CITIES" and "CITIES" or "Cities"))
    WR_SetButtonString(Controls.KiyotakaTabButton, "[ICON_RESEARCH] " .. (WR_ACTIVE_TAB == "KIYOTAKA" and "KIYOTAKA" or "Kiyotaka"))
    WR_SetButtonString(Controls.UnitsTabButton, "[ICON_STRENGTH] " .. (WR_ACTIVE_TAB == "UNITS" and "UNITS" or "Units"))
    WR_SetButtonString(Controls.TelemetryTabButton, "[ICON_RESEARCH] " .. (WR_ACTIVE_TAB == "TELEMETRY" and "TELEMETRY" or "Telemetry"))
    Controls.EmpireTabSelection:SetHide(WR_ACTIVE_TAB ~= "EMPIRE")
    Controls.CitiesTabSelection:SetHide(WR_ACTIVE_TAB ~= "CITIES")
    Controls.KiyotakaTabSelection:SetHide(WR_ACTIVE_TAB ~= "KIYOTAKA")
    Controls.UnitsTabSelection:SetHide(WR_ACTIVE_TAB ~= "UNITS")
    Controls.TelemetryTabSelection:SetHide(WR_ACTIVE_TAB ~= "TELEMETRY")
    WR_SetLabel(Controls.SystemStateLabel, presentation.state)
    WR_SetLabel(Controls.RecordStreamLabel, presentation.stream)
    WR_SetLabel(Controls.FooterStatusLabel, WR_ACTIVE_TAB == "TELEMETRY" and "FACILITY LINK: RECORDING" or "FACILITY LINK: STABLE")
    WR_SetButtonString(Controls.CompactButton, "[ICON_BULLET] " .. (WR_COMPACT_MODE and "Expanded" or "Compact"))
    WR_SetTooltip(Controls.EmpireTabButton, "Facility-level learning from trade routes and observed city losses.")
    WR_SetTooltip(Controls.CitiesTabButton, "Per-city adaptation records: damage defense, ranged strikes, duplicate yields, and worked improvements.")
    WR_SetTooltip(Controls.KiyotakaTabButton, "Kiyotaka's Perfect Adaptation dossier, including Flow State and class matchups.")
    WR_SetTooltip(Controls.UnitsTabButton, "Unique unit readiness, caps, technology requirements, and training status.")
    WR_SetTooltip(Controls.TelemetryTabButton, "Persistent turn-stamped records from White Room adaptation systems.")
    WR_SetTooltip(Controls.CompactButton, WR_COMPACT_MODE and "Show full White Room status details." or "Show a shorter White Room status readout.")
end

local WR_RefreshPanel

local function WR_SetActiveTab(tabName)
    WR_ACTIVE_TAB = tabName
    WR_UpdateTabButtons()
    WR_RefreshPanel()
end

WR_RefreshPanel = function()
    WR_UpdateTabButtons()
    WR_UpdateSummaryPanel()
    Controls.StatusText:SetString(WR_BuildStatusText())

    if WR_ACTIVE_TAB == "CITIES" then
        WR_SetTooltip(Controls.StatusText, "City records are sorted by adaptation score. Duplicate worked improvements give +0.5% per duplicate to their linked yield; whole-percent values are applied through hidden buildings.")
    elseif WR_ACTIVE_TAB == "KIYOTAKA" then
        WR_SetTooltip(Controls.StatusText, "Subject Dossier tracks Perfect Adaptation: kills, damage dealt, damage taken, low-HP survival, Flow State chance, and class-specific matchups.")
    elseif WR_ACTIVE_TAB == "UNITS" then
        WR_SetTooltip(Controls.StatusText, "Operative Deployment shows persistent callsigns, active service records, lifetime combat totals, and archived losses.")
    elseif WR_ACTIVE_TAB == "TELEMETRY" then
        WR_SetTooltip(Controls.StatusText, "Adaptation Telemetry retains the newest 32 subject, operative, city, empire, and surveillance records. Newest events appear first.")
    else
        WR_SetTooltip(Controls.StatusText, "Facility Readout tracks empire-wide White Room learning from trade routes and observed city losses.")
    end

    if Controls.StatusScrollPanel ~= nil and Controls.StatusScrollPanel.CalculateInternalSize ~= nil then
        Controls.StatusScrollPanel:CalculateInternalSize()
    end

    local playerID = WR_GetActiveWhiteRoomPlayer()
    if playerID ~= nil then
        WR_LAST_TELEMETRY_SEQUENCE = WR_GetTelemetrySequence(playerID)
    end
end

local function WR_ToggleCompactMode()
    WR_COMPACT_MODE = not WR_COMPACT_MODE
    WR_RefreshPanel()
end

local function WR_ShowPanel()
    WR_RefreshPanel()
    Controls.StatusPanel:SetHide(false)
end

local function WR_HidePanel()
    Controls.StatusPanel:SetHide(true)
end

local function WR_IsDiplomacyOpen()
    if WR_DIPLOMACY_OPEN then
        return true
    end

    return UI ~= nil
        and UI.GetLeaderHeadRootUp ~= nil
        and UI.GetLeaderHeadRootUp()
end

local function WR_IsDiploListOpen()
    if WR_DIPLO_LIST_CONTEXT == nil and ContextPtr.LookUpControl ~= nil then
        WR_DIPLO_LIST_CONTEXT = ContextPtr:LookUpControl("/InGame/WorldView/DiploCorner/DiploList")
    end

    return WR_DIPLO_LIST_CONTEXT ~= nil and not WR_DIPLO_LIST_CONTEXT:IsHidden()
end

local function WR_IsBlockingPopupOpen()
    return next(WR_OPEN_BLOCKING_POPUPS) ~= nil
end

local function WR_UpdateChromeVisibility()
    local playerID, player = WR_GetActiveWhiteRoomPlayer()
    local shouldHide = WR_CITY_SCREEN_OPEN
        or WR_IsDiplomacyOpen()
        or WR_IsDiploListOpen()
        or WR_IsBlockingPopupOpen()
        or player == nil

    Controls.WhiteRoomStatusButton:SetHide(shouldHide)

    if shouldHide then
        WR_HidePanel()
    end
end

local function WR_TogglePanel()
    if WR_CITY_SCREEN_OPEN
        or WR_IsDiplomacyOpen()
        or WR_IsDiploListOpen()
        or WR_IsBlockingPopupOpen() then
        WR_HidePanel()
        return
    end

    if Controls.StatusPanel:IsHidden() then
        WR_ShowPanel()
    else
        WR_HidePanel()
    end
end

WR_TryIncludeIconSupport()
WR_SetCivIcon(Controls.WhiteRoomButtonIcon, 32)
Controls.HeaderIconFrame:SetHide(not WR_SetCivIcon(Controls.HeaderCivIcon, 64))

Controls.WhiteRoomStatusButton:RegisterCallback(Mouse.eLClick, WR_TogglePanel)
Controls.EmpireTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("EMPIRE") end)
Controls.CitiesTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("CITIES") end)
Controls.KiyotakaTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("KIYOTAKA") end)
Controls.UnitsTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("UNITS") end)
Controls.TelemetryTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("TELEMETRY") end)
Controls.RefreshButton:RegisterCallback(Mouse.eLClick, WR_RefreshPanel)
Controls.CompactButton:RegisterCallback(Mouse.eLClick, WR_ToggleCompactMode)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, WR_HidePanel)

ContextPtr:SetInputHandler(function(uiMsg, wParam)
    if uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_ESCAPE and not Controls.StatusPanel:IsHidden() then
        WR_HidePanel()
        return true
    end

    return false
end)

if Events.ActivePlayerTurnStart ~= nil then
    Events.ActivePlayerTurnStart.Add(function()
        WR_UpdateChromeVisibility()

        if not Controls.StatusPanel:IsHidden() then
            WR_RefreshPanel()
        end
    end)
end

if Events.SerialEventEnterCityScreen ~= nil then
    Events.SerialEventEnterCityScreen.Add(function()
        WR_CITY_SCREEN_OPEN = true
        WR_UpdateChromeVisibility()
    end)
end

if Events.SerialEventExitCityScreen ~= nil then
    Events.SerialEventExitCityScreen.Add(function()
        WR_CITY_SCREEN_OPEN = false
        WR_UpdateChromeVisibility()
    end)
end

if Events.AILeaderMessage ~= nil then
    Events.AILeaderMessage.Add(function()
        WR_DIPLOMACY_OPEN = true
        WR_UpdateChromeVisibility()
    end)
end

if Events.LeavingLeaderViewMode ~= nil then
    Events.LeavingLeaderViewMode.Add(function()
        WR_DIPLOMACY_OPEN = false
        WR_UpdateChromeVisibility()
    end)
end

if Events.SerialEventGameMessagePopupShown ~= nil then
    Events.SerialEventGameMessagePopupShown.Add(function(popupInfo)
        local popupType = popupInfo ~= nil and popupInfo.Type or nil

        if popupType ~= nil and WR_BLOCKING_POPUP_TYPES[popupType] then
            WR_OPEN_BLOCKING_POPUPS[popupType] = true
            WR_UpdateChromeVisibility()
        end
    end)
end

if Events.SerialEventGameMessagePopupProcessed ~= nil then
    Events.SerialEventGameMessagePopupProcessed.Add(function(popupType)
        if popupType ~= nil and WR_BLOCKING_POPUP_TYPES[popupType] then
            WR_OPEN_BLOCKING_POPUPS[popupType] = nil
            WR_UpdateChromeVisibility()
        end
    end)
end

ContextPtr:SetUpdate(function(deltaTime)
    WR_DIPLO_LIST_POLL_ELAPSED = WR_DIPLO_LIST_POLL_ELAPSED + deltaTime
    WR_TELEMETRY_POLL_ELAPSED = WR_TELEMETRY_POLL_ELAPSED + deltaTime

    if WR_DIPLO_LIST_POLL_ELAPSED < 0.1 then
        return
    end

    WR_DIPLO_LIST_POLL_ELAPSED = 0

    local isOpen = WR_IsDiploListOpen()
    if isOpen ~= WR_DIPLO_LIST_WAS_OPEN then
        WR_DIPLO_LIST_WAS_OPEN = isOpen
        WR_UpdateChromeVisibility()
    end

    if WR_TELEMETRY_POLL_ELAPSED >= 0.5 then
        WR_TELEMETRY_POLL_ELAPSED = 0

        if (WR_ACTIVE_TAB == "TELEMETRY" or WR_ACTIVE_TAB == "UNITS")
            and not Controls.StatusPanel:IsHidden() then
            local playerID = WR_GetActiveWhiteRoomPlayer()
            if playerID ~= nil then
                local sequence = WR_GetTelemetrySequence(playerID)
                if sequence ~= WR_LAST_TELEMETRY_SEQUENCE then
                    WR_RefreshPanel()
                end
            end
        end
    end
end)

WR_UpdateChromeVisibility()

print("WR Status Panel: initialized")

-- White Room Kid Kiyotaka - In-game Status Panel

print("WhiteRoomStatusPanel.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local UNIT_WR_KIYOTAKA = GameInfoTypes.UNIT_WR_KIYOTAKA

local WR_STATUS_SAVE = Modding.OpenSaveData()
local WR_PERCENT_PER_DUPLICATE = 0.5
local WR_CITY_DEF_PERCENT_PER_STACK = 0.25
local WR_CITY_RANGED_PERCENT_PER_STACK = 0.25
local WR_CITY_LOSS_DEF_PERCENT_PER_STACK = 0.25
local WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK = 0.5
local WR_ACTIVE_TAB = "EMPIRE"
local WR_CITY_SCREEN_OPEN = false

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
    return WR_CountUnitsOfType(player, GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE)
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

local function WR_AppendPanelHeader(lines, title, player)
    table.insert(lines, WR_Header(title))
    table.insert(lines, WR_Divider())
    table.insert(lines, "Player: " .. (player:GetName() or "White Room") .. "    Turn: " .. tostring(Game.GetGameTurn()))
    table.insert(lines, "")
end

local function WR_AppendKiyotaka(lines, playerID, player)
    table.insert(lines, WR_Header("Deployment"))
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

    local keyPrefix = "WR_KIYOTAKA_" .. tostring(playerID) .. "_"
    table.insert(lines, "")
    table.insert(lines, WR_Header("Perfect Adaptation"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  Combat       +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "COMBAT")))
    table.insert(lines, "  Attack       +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "ATTACK")))
    table.insert(lines, "  Resistance   +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "RESISTANCE")))
    table.insert(lines, "  Healing      +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "HEALING")))
    table.insert(lines, "  Low-HP power +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "DESPERATION")))
    table.insert(lines, "  Flow State   " .. WR_StatusTag(WR_GetSavedNumber(keyPrefix .. "MOVE_CHANCE") >= 10000) .. " " .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "MOVE_CHANCE")))

    local classParts = {}
    for unitCombatInfo in GameInfo.UnitCombatInfos() do
        local suffix = string.gsub(unitCombatInfo.Type, "UNITCOMBAT_", "")
        local value = WR_GetSavedNumber(keyPrefix .. "CLASS_" .. suffix)
        if value > 0 then
            table.insert(classParts, string.format("%s +%s", string.gsub(suffix, "_", " "), WR_FormatPercentFromHundredths(value)))
        end
    end
    table.sort(classParts)

    if #classParts > 0 then
        table.insert(lines, "")
        table.insert(lines, WR_Header("Class Adaptations"))
        table.insert(lines, WR_Divider())
        for _, classLine in ipairs(classParts) do
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
        WR_AppendYieldLine(lines, "  Duplicate yields", card.yieldPercents)
        WR_AppendWorkedImprovements(lines, card.improvementCounts)
        table.insert(lines, "")
    end
end

local function WR_AppendUnits(lines, player)
    local kiyotakaCount = WR_CountUnitsOfType(player, UNIT_WR_KIYOTAKA)
    local operativeID = GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE
    local operativeCount = WR_CountUnitsOfType(player, operativeID)

    table.insert(lines, WR_Header("Kiyotaka Ayanokoji"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  " .. WR_StatusTag(kiyotakaCount > 0) .. " Active: " .. tostring(kiyotakaCount) .. " / 1")
    table.insert(lines, "  Tech: " .. WR_TechStatus(player, UNIT_WR_KIYOTAKA))
    table.insert(lines, "  Training: " .. WR_CanTrainStatus(player, UNIT_WR_KIYOTAKA))
    table.insert(lines, "  Cannot be purchased; extras are removed by the cap script.")
    table.insert(lines, "")
    table.insert(lines, WR_Header("4th Generation Operatives"))
    table.insert(lines, WR_Divider())
    table.insert(lines, "  " .. WR_StatusTag(operativeCount > 0) .. " Active: " .. tostring(operativeCount) .. " / 3")
    table.insert(lines, "  Tech: " .. WR_TechStatus(player, operativeID))
    table.insert(lines, "  Training: " .. WR_CanTrainStatus(player, operativeID))
    table.insert(lines, "  Cannot be purchased or gifted to City-States.")
end

local function WR_BuildStatusText()
    local playerID, player = WR_GetActiveWhiteRoomPlayer()
    local lines = {}

    if player == nil then
        return "No active White Room civilization found in this game."
    end

    if WR_ACTIVE_TAB == "CITIES" then
        WR_AppendPanelHeader(lines, "Cities", player)
        WR_AppendCities(lines, playerID, player)
    elseif WR_ACTIVE_TAB == "KIYOTAKA" then
        WR_AppendPanelHeader(lines, "Kiyotaka", player)
        WR_AppendKiyotaka(lines, playerID, player)
    elseif WR_ACTIVE_TAB == "UNITS" then
        WR_AppendPanelHeader(lines, "Unique Units", player)
        WR_AppendUnits(lines, player)
    else
        WR_AppendPanelHeader(lines, "Empire Learning", player)
        table.insert(lines, "Unit overview: Kiyotaka " .. tostring(WR_CountUnitsOfType(player, UNIT_WR_KIYOTAKA)) .. " / 1    4th Gen Operatives " .. tostring(WR_CountOperatives(player)) .. " / 3")
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
        WR_SetLabel(Controls.SummaryMetricOne, "")
        WR_SetLabel(Controls.SummaryMetricTwo, "")
        WR_SetLabel(Controls.SummaryMetricThree, "")
        WR_SetLabel(Controls.SummaryMetricFour, "")
        return
    end

    local tradeHalfStacks = WR_GetSavedNumber(WR_PlayerSaveKey("WR_TRADE_ROUTE_LEARNING_", playerID, "HALF_GOLD_STACKS"))
    local cityLossStacks = WR_GetSavedNumber(WR_PlayerSaveKey("WR_CAPTURED_CITY_LEARNING_", playerID, "CITY_LOSS_STACKS"))
    local cityCount, bestCityName, totalDefenseStacks, totalRangedStacks, totalDuplicatePercent = WR_BuildCitySummary(playerID, player)
    local kiyotaka = WR_FindKiyotaka(player)
    local keyPrefix = "WR_KIYOTAKA_" .. tostring(playerID) .. "_"

    if WR_ACTIVE_TAB == "CITIES" then
        WR_SetLabel(Controls.SummaryTitle, "City Adaptation Overview")
        WR_SetLabel(Controls.SummaryMetricOne, "Cities[NEWLINE]" .. tostring(cityCount))
        WR_SetLabel(Controls.SummaryMetricTwo, "Most Adapted[NEWLINE]" .. bestCityName)
        WR_SetLabel(Controls.SummaryMetricThree, "Defense Stacks[NEWLINE]" .. tostring(totalDefenseStacks))
        WR_SetLabel(Controls.SummaryMetricFour, "Duplicate Yields[NEWLINE]+" .. string.format("%.2f%%", totalDuplicatePercent))
    elseif WR_ACTIVE_TAB == "KIYOTAKA" then
        WR_SetLabel(Controls.SummaryTitle, "Kiyotaka Dossier")
        WR_SetLabel(Controls.SummaryMetricOne, "Deployment[NEWLINE]" .. (kiyotaka ~= nil and "Active" or "Missing"))
        WR_SetLabel(Controls.SummaryMetricTwo, "Vitals[NEWLINE]" .. WR_UnitHpLine(kiyotaka))
        WR_SetLabel(Controls.SummaryMetricThree, "Combat[NEWLINE]+" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "COMBAT")))
        WR_SetLabel(Controls.SummaryMetricFour, "Flow State[NEWLINE]" .. WR_StatusTag(WR_GetSavedNumber(keyPrefix .. "MOVE_CHANCE") >= 10000) .. " " .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "MOVE_CHANCE")))
    elseif WR_ACTIVE_TAB == "UNITS" then
        local operativeCount = WR_CountOperatives(player)
        WR_SetLabel(Controls.SummaryTitle, "Unique Unit Readiness")
        WR_SetLabel(Controls.SummaryMetricOne, "Kiyotaka[NEWLINE]" .. tostring(WR_CountUnitsOfType(player, UNIT_WR_KIYOTAKA)) .. " / 1")
        WR_SetLabel(Controls.SummaryMetricTwo, "Operatives[NEWLINE]" .. tostring(operativeCount) .. " / 3")
        WR_SetLabel(Controls.SummaryMetricThree, "Kiyotaka Tech[NEWLINE]" .. WR_TechStatus(player, UNIT_WR_KIYOTAKA))
        WR_SetLabel(Controls.SummaryMetricFour, "Operative Tech[NEWLINE]" .. WR_TechStatus(player, GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE))
    else
        WR_SetLabel(Controls.SummaryTitle, "Empire Learning Overview")
        WR_SetLabel(Controls.SummaryMetricOne, "Trade Gold[NEWLINE]" .. WR_FormatStoredApplied(tradeHalfStacks * 0.5, math.floor(tradeHalfStacks / 2)))
        WR_SetLabel(Controls.SummaryMetricTwo, "City Losses[NEWLINE]" .. tostring(cityLossStacks))
        WR_SetLabel(Controls.SummaryMetricThree, "Vs Cities[NEWLINE]" .. WR_FormatStoredApplied(cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK, math.floor(cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK)))
        WR_SetLabel(Controls.SummaryMetricFour, "Best City[NEWLINE]" .. bestCityName)
    end
end

local function WR_SetButtonDisabled(control, disabled)
    if control ~= nil and control.SetDisabled ~= nil then
        control:SetDisabled(disabled)
    end
end

local function WR_SetButtonString(control, text)
    if control ~= nil and control.SetText ~= nil then
        control:SetText(text)
    elseif control ~= nil and control.SetString ~= nil then
        control:SetString(text)
    end
end

local function WR_UpdateTabButtons()
    WR_SetButtonDisabled(Controls.EmpireTabButton, WR_ACTIVE_TAB == "EMPIRE")
    WR_SetButtonDisabled(Controls.CitiesTabButton, WR_ACTIVE_TAB == "CITIES")
    WR_SetButtonDisabled(Controls.KiyotakaTabButton, WR_ACTIVE_TAB == "KIYOTAKA")
    WR_SetButtonDisabled(Controls.UnitsTabButton, WR_ACTIVE_TAB == "UNITS")
    WR_SetButtonString(Controls.EmpireTabButton, WR_ACTIVE_TAB == "EMPIRE" and "[ Empire ]" or "Empire")
    WR_SetButtonString(Controls.CitiesTabButton, WR_ACTIVE_TAB == "CITIES" and "[ Cities ]" or "Cities")
    WR_SetButtonString(Controls.KiyotakaTabButton, WR_ACTIVE_TAB == "KIYOTAKA" and "[ Kiyotaka ]" or "Kiyotaka")
    WR_SetButtonString(Controls.UnitsTabButton, WR_ACTIVE_TAB == "UNITS" and "[ Units ]" or "Units")
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

    if Controls.StatusScrollPanel ~= nil and Controls.StatusScrollPanel.CalculateInternalSize ~= nil then
        Controls.StatusScrollPanel:CalculateInternalSize()
    end
end

local function WR_ShowPanel()
    WR_RefreshPanel()
    Controls.StatusPanel:SetHide(false)
end

local function WR_HidePanel()
    Controls.StatusPanel:SetHide(true)
end

local function WR_UpdateChromeVisibility()
    local playerID, player = WR_GetActiveWhiteRoomPlayer()
    local shouldHide = WR_CITY_SCREEN_OPEN or player == nil

    Controls.WhiteRoomStatusButton:SetHide(shouldHide)

    if shouldHide then
        WR_HidePanel()
    end
end

local function WR_TogglePanel()
    if WR_CITY_SCREEN_OPEN then
        WR_HidePanel()
        return
    end

    if Controls.StatusPanel:IsHidden() then
        WR_ShowPanel()
    else
        WR_HidePanel()
    end
end

Controls.WhiteRoomStatusButton:RegisterCallback(Mouse.eLClick, WR_TogglePanel)
Controls.EmpireTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("EMPIRE") end)
Controls.CitiesTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("CITIES") end)
Controls.KiyotakaTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("KIYOTAKA") end)
Controls.UnitsTabButton:RegisterCallback(Mouse.eLClick, function() WR_SetActiveTab("UNITS") end)
Controls.RefreshButton:RegisterCallback(Mouse.eLClick, WR_RefreshPanel)
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

WR_UpdateChromeVisibility()

print("WR Status Panel: initialized")

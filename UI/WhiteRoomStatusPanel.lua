-- White Room Kid Kiyotaka - In-game Status Panel

print("WhiteRoomStatusPanel.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local UNIT_WR_KIYOTAKA = GameInfoTypes.UNIT_WR_KIYOTAKA

local WR_STATUS_SAVE = Modding.OpenSaveData()
local WR_PERCENT_PER_DUPLICATE = 0.25
local WR_CITY_DEF_PERCENT_PER_STACK = 0.25
local WR_CITY_RANGED_PERCENT_PER_STACK = 0.25
local WR_CITY_LOSS_DEF_PERCENT_PER_STACK = 0.25
local WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK = 0.5

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

local function WR_AppendYieldLine(lines, label, yieldPercents)
    local parts = {}
    for _, yieldName in ipairs(WR_YIELD_ORDER) do
        local percent = yieldPercents[yieldName] or 0
        if percent > 0 then
            table.insert(parts, yieldName .. " +" .. tostring(percent) .. "%")
        end
    end

    if #parts == 0 then
        table.insert(lines, label .. ": no duplicate worked-improvement yield bonuses")
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
        table.insert(lines, "  Worked improvements: none tracked")
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

local function WR_CountOperatives(player)
    local operativeID = GameInfoTypes.UNIT_WR_FOURTH_GEN_OPERATIVE
    local count = 0

    if player == nil or operativeID == nil then
        return 0
    end

    for unit in player:Units() do
        if unit:GetUnitType() == operativeID then
            count = count + 1
        end
    end

    return count
end

local function WR_AppendKiyotaka(lines, playerID, player)
    table.insert(lines, "")
    table.insert(lines, "Kiyotaka Status")

    local unit = WR_FindKiyotaka(player)
    if unit == nil then
        table.insert(lines, "  Not currently deployed.")
    else
        local plot = unit:GetPlot()
        local location = "unknown location"
        if plot ~= nil then
            location = string.format("(%d, %d)", plot:GetX(), plot:GetY())
        end

        table.insert(lines, string.format(
            "  Deployed: level %d, XP %d, HP %d/100, location %s",
            unit:GetLevel(),
            unit:GetExperience(),
            100 - unit:GetDamage(),
            location
        ))
    end

    local keyPrefix = "WR_KIYOTAKA_" .. tostring(playerID) .. "_"
    table.insert(lines, "  Combat strength: +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "COMBAT")))
    table.insert(lines, "  Attack strength: +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "ATTACK")))
    table.insert(lines, "  Resistance: +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "RESISTANCE")))
    table.insert(lines, "  Healing received: +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "HEALING")))
    table.insert(lines, "  Low-HP combat strength: +" .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "DESPERATION")))
    table.insert(lines, "  Move-after-combat progress: " .. WR_FormatPercentFromHundredths(WR_GetSavedNumber(keyPrefix .. "MOVE_CHANCE")))

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
        table.insert(lines, "  Class adaptations: " .. table.concat(classParts, ", "))
    else
        table.insert(lines, "  Class adaptations: none yet")
    end
end

local function WR_BuildStatusText()
    local playerID, player = WR_GetActiveWhiteRoomPlayer()
    local lines = {}

    if player == nil then
        return "No active White Room civilization found in this game."
    end

    table.insert(lines, "Player: " .. (player:GetName() or "White Room"))
    table.insert(lines, "Turn: " .. tostring(Game.GetGameTurn()))
    table.insert(lines, "4th Generation Operatives: " .. tostring(WR_CountOperatives(player)) .. " / 3")

    local tradeHalfStacks = WR_GetSavedNumber(WR_PlayerSaveKey("WR_TRADE_ROUTE_LEARNING_", playerID, "HALF_GOLD_STACKS"))
    local cityLossStacks = WR_GetSavedNumber(WR_PlayerSaveKey("WR_CAPTURED_CITY_LEARNING_", playerID, "CITY_LOSS_STACKS"))

    table.insert(lines, "")
    table.insert(lines, "Empire Learning")
    table.insert(lines, "  Trade-route gold learning: +" .. WR_FormatHalfPercentStacks(tradeHalfStacks) .. " (applied +" .. tostring(math.floor(tradeHalfStacks / 2)) .. "% Gold)")
    table.insert(lines, "  Observed city losses: " .. tostring(cityLossStacks))
    table.insert(lines, "  Attack vs cities: +" .. tostring(math.floor(cityLossStacks * WR_CITY_LOSS_ATTACK_PERCENT_PER_STACK)) .. "%")
    table.insert(lines, "  Global city defense from city losses: +" .. string.format("%.2f%%", cityLossStacks * WR_CITY_LOSS_DEF_PERCENT_PER_STACK) .. " (applied +" .. tostring(math.floor(cityLossStacks * WR_CITY_LOSS_DEF_PERCENT_PER_STACK)) .. "%)")

    table.insert(lines, "")
    table.insert(lines, "Cities")

    local hasCities = false
    for city in player:Cities() do
        hasCities = true
        local hpStacks = WR_GetSavedNumber(WR_CitySaveKey("WR_CITY_HP_", playerID, city, "DEF_STACKS"))
        local rangedStacks = WR_GetSavedNumber(WR_CitySaveKey("WR_CITY_RANGED_", playerID, city, "ATTACK_STACKS"))
        local improvementCounts, yieldPercents = WR_CountWorkedImprovements(playerID, city)

        table.insert(lines, string.format("  %s", city:GetName()))
        table.insert(lines, string.format("    Damage defense stacks: %d (+%.2f%% city defense, applied +%d%%)", hpStacks, hpStacks * WR_CITY_DEF_PERCENT_PER_STACK, math.floor(hpStacks * WR_CITY_DEF_PERCENT_PER_STACK)))
        table.insert(lines, string.format("    Ranged strike stacks: %d (+%.2f%% city ranged attack, applied +%d%%)", rangedStacks, rangedStacks * WR_CITY_RANGED_PERCENT_PER_STACK, math.floor(rangedStacks * WR_CITY_RANGED_PERCENT_PER_STACK)))
        WR_AppendYieldLine(lines, "    Duplicate yields", yieldPercents)
        WR_AppendWorkedImprovements(lines, improvementCounts)
    end

    if not hasCities then
        table.insert(lines, "  No White Room cities found.")
    end

    WR_AppendKiyotaka(lines, playerID, player)

    return table.concat(lines, "[NEWLINE]")
end

local function WR_RefreshPanel()
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

local function WR_TogglePanel()
    if Controls.StatusPanel:IsHidden() then
        WR_ShowPanel()
    else
        WR_HidePanel()
    end
end

Controls.WhiteRoomStatusButton:RegisterCallback(Mouse.eLClick, WR_TogglePanel)
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
        if not Controls.StatusPanel:IsHidden() then
            WR_RefreshPanel()
        end
    end)
end

print("WR Status Panel: initialized")

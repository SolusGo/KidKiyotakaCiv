-- White Room Kid Kiyotaka - Unique Unit Unlock Presentation

print("WhiteRoomUnitUnlock.lua loaded")

local WR_CIVILIZATION = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local WR_SAVE = Modding.OpenSaveData()
local WR_PENDING_UNLOCKS = {}
local WR_CURRENT_UNLOCK = nil
local WR_CITY_SCREEN_OPEN = false
local WR_DIPLOMACY_OPEN = false

local WR_UNLOCK_DEFINITIONS = {
    {
        UnitType = "UNIT_WR_FOURTH_GEN_OPERATIVE",
        Artwork = "Art/UI/WR_UI_Operatives.dds",
        Capacity = 3,
        Title = "DOSSIER 04: THE DEMONIC GENERATION",
        Record = "GENERATION 04 // BETA",
        Program = "OPERATIVE FIELD PROGRAM",
        Status = "DEPLOYMENT READY",
        Body = "The Fourth Generation was never meant to be survivable. Seventy-four children entered the White Room and were subjected to the gruelling Beta curriculum, a course its own designer considered beyond the limits of humane education. Their days were consumed by examinations, memory trials, physical conditioning, swimming, and live martial training. Failure meant removal, while success only raised the standard.\n\nThese were the demons of the Demonic Fourth Generation: children forged under the most merciless curriculum in White Room history. Its doctrine has now left the laboratory. Fourth Generation Operatives can be trained.",
        Quote = "A standard made for monsters can only produce demons."
    },
    {
        UnitType = "UNIT_WR_KIYOTAKA",
        Artwork = "Art/UI/WR_UI_Subject.dds",
        Capacity = 1,
        Title = "SUBJECT A-04: THE MASTERPIECE",
        Record = "SUBJECT A-04",
        Program = "PERFECT ADAPTATION",
        Status = "DEPLOYMENT READY",
        Body = "\"You are on your own, Kiyotaka.\"\n\nHe learned that lesson before he could understand its cruelty. What separated Kiyotaka was not that he never lost, but his limitless curiosity and terrifying adaptability. Yuki once surpassed him in swimming. Shiro once surpassed him in martial arts and defeated him in an early bout. Kiyotaka observed, understood, and closed each gap until no one could keep pace.\n\nHe decoded the written examinations until no student could displace him, overtook Yuki in the pool, and turned his first defeat in each new fighting style into victory in the next match. One by one, the other children fell away. By nine, Kiyotaka alone remained, defeating multiple adult fighters. The White Room searched for the limit of a child. Subject A-04 kept moving that limit.",
        Quote = "Every failure became data. Every lesson became his."
    }
}

local function WR_Localize(tag)
    if tag == nil then
        return ""
    end

    local ok, value = pcall(Locale.ConvertTextKey, tag)
    if ok and value ~= nil then
        return value
    end

    return tostring(tag)
end

local function WR_GetActiveWhiteRoomPlayer()
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]

    if player == nil
        or not player:IsAlive()
        or WR_CIVILIZATION == nil
        or player:GetCivilizationType() ~= WR_CIVILIZATION then
        return nil, nil
    end

    return playerID, player
end

local function WR_ResolveUnlocks()
    local resolved = {}

    for _, definition in ipairs(WR_UNLOCK_DEFINITIONS) do
        local unitInfo = GameInfo.Units[definition.UnitType]
        local techInfo = unitInfo ~= nil and GameInfo.Technologies[unitInfo.PrereqTech] or nil

        if unitInfo ~= nil and techInfo ~= nil then
            definition.UnitID = unitInfo.ID
            definition.Combat = unitInfo.Combat or 0
            definition.Moves = unitInfo.Moves or 0
            definition.UnitName = WR_Localize(unitInfo.Description)
            definition.TechID = techInfo.ID
            definition.TechType = techInfo.Type
            definition.TechName = WR_Localize(techInfo.Description)
            definition.TechPortraitIndex = techInfo.PortraitIndex or 0
            definition.TechIconAtlas = techInfo.IconAtlas
            definition.PortraitIndex = unitInfo.PortraitIndex or 0
            definition.IconAtlas = unitInfo.IconAtlas
            table.insert(resolved, definition)
        else
            print("WhiteRoomUnitUnlock skipped unresolved unit " .. tostring(definition.UnitType))
        end
    end

    WR_UNLOCK_DEFINITIONS = resolved
end

local function WR_SeenKey(playerID, unlock)
    return "WR_UI_UNIT_UNLOCK_SEEN_" .. tostring(playerID) .. "_" .. tostring(unlock.UnitType)
end

local function WR_InitializedKey(playerID)
    return "WR_UI_UNIT_UNLOCK_INITIALIZED_" .. tostring(playerID)
end

local function WR_IsSeen(playerID, unlock)
    return WR_SAVE.GetValue(WR_SeenKey(playerID, unlock)) == 1
end

local function WR_MarkSeen(playerID, unlock)
    WR_SAVE.SetValue(WR_SeenKey(playerID, unlock), 1)
end

local function WR_TeamHasTech(player, techID)
    local team = player ~= nil and Teams[player:GetTeam()] or nil
    return team ~= nil and techID ~= nil and team:IsHasTech(techID)
end

local function WR_IsPresentationBlocked()
    local _, player = WR_GetActiveWhiteRoomPlayer()
    return player == nil or WR_CITY_SCREEN_OPEN or WR_DIPLOMACY_OPEN
end

local function WR_SetUnitPortrait(unlock)
    Controls.UnlockArtwork:SetTexture(unlock.Artwork)
end

local function WR_SetTechPortrait(unlock)
    local shown = false

    if unlock ~= nil and unlock.TechIconAtlas ~= nil and IconHookup ~= nil then
        local ok, result = pcall(
            IconHookup,
            unlock.TechPortraitIndex,
            64,
            unlock.TechIconAtlas,
            Controls.TechIcon
        )
        shown = ok and result ~= false
    end

    Controls.TechIconFrame:SetHide(not shown)
end

local function WR_ShowNextUnlock()
    if WR_CURRENT_UNLOCK ~= nil
        or #WR_PENDING_UNLOCKS == 0
        or WR_IsPresentationBlocked() then
        return
    end

    WR_CURRENT_UNLOCK = table.remove(WR_PENDING_UNLOCKS, 1)

    WR_SetUnitPortrait(WR_CURRENT_UNLOCK)
    WR_SetTechPortrait(WR_CURRENT_UNLOCK)
    Controls.TitleLabel:SetText(WR_CURRENT_UNLOCK.Title)
    Controls.UnitNameLabel:SetText(WR_CURRENT_UNLOCK.UnitName)
    Controls.TechLabel:SetText("Unlocked by " .. WR_CURRENT_UNLOCK.TechName)
    Controls.RecordLabel:SetText(WR_CURRENT_UNLOCK.Record)
    Controls.ProgramLabel:SetText(WR_CURRENT_UNLOCK.Program)
    Controls.StatusLabel:SetText(WR_CURRENT_UNLOCK.Status)
    Controls.BodyLabel:SetText(WR_CURRENT_UNLOCK.Body)
    Controls.UnlockStatsLabel:SetText(string.format(
        "%d STRENGTH    /    %d MOVEMENT    /    %d ACTIVE MAX    /    NO PURCHASE",
        WR_CURRENT_UNLOCK.Combat, WR_CURRENT_UNLOCK.Moves, WR_CURRENT_UNLOCK.Capacity
    ))
    Controls.BodyScrollPanel:CalculateInternalSize()
    if Controls.BodyScrollPanel.SetScrollValue ~= nil then Controls.BodyScrollPanel:SetScrollValue(0) end
    Controls.QuoteLabel:SetText("\"" .. WR_CURRENT_UNLOCK.Quote .. "\"")
    Controls.UnlockPanel:SetHide(false)
end

local function WR_CloseUnlock()
    Controls.UnlockPanel:SetHide(true)
    WR_CURRENT_UNLOCK = nil
    WR_ShowNextUnlock()
end

local function WR_ResumePresentation()
    if WR_IsPresentationBlocked() then
        return
    end

    if WR_CURRENT_UNLOCK ~= nil then
        Controls.UnlockPanel:SetHide(false)
    else
        WR_ShowNextUnlock()
    end
end

local function WR_AddNotification(player, unlock)
    if player == nil
        or NotificationTypes == nil
        or NotificationTypes.NOTIFICATION_GENERIC == nil then
        return
    end

    local body = unlock.UnitName .. " is now available.[NEWLINE]" .. unlock.Body
    local ok, err = pcall(function()
        player:AddNotification(
            NotificationTypes.NOTIFICATION_GENERIC,
            body,
            unlock.Title
        )
    end)

    if not ok then
        print("WhiteRoomUnitUnlock notification failed: " .. tostring(err))
    end
end

local function WR_QueueUnlock(playerID, player, unlock)
    if WR_IsSeen(playerID, unlock) then
        return
    end

    WR_MarkSeen(playerID, unlock)
    table.insert(WR_PENDING_UNLOCKS, unlock)
    WR_AddNotification(player, unlock)
    print("WhiteRoomUnitUnlock presented " .. tostring(unlock.UnitType))
    WR_ShowNextUnlock()
end

local function WR_InitializeActivePlayer()
    local playerID, player = WR_GetActiveWhiteRoomPlayer()
    if player == nil then
        return
    end

    local initializedKey = WR_InitializedKey(playerID)
    if WR_SAVE.GetValue(initializedKey) == 1 then
        return
    end

    -- Old saves should not receive every historical unlock at once.
    for _, unlock in ipairs(WR_UNLOCK_DEFINITIONS) do
        if WR_TeamHasTech(player, unlock.TechID) then
            WR_MarkSeen(playerID, unlock)
        end
    end

    WR_SAVE.SetValue(initializedKey, 1)
end

local function WR_CheckUnlockedTechnologies(playerID)
    local activePlayerID, player = WR_GetActiveWhiteRoomPlayer()
    if player == nil or (playerID ~= nil and playerID ~= activePlayerID) then
        return
    end

    WR_InitializeActivePlayer()

    for _, unlock in ipairs(WR_UNLOCK_DEFINITIONS) do
        if WR_TeamHasTech(player, unlock.TechID) then
            WR_QueueUnlock(activePlayerID, player, unlock)
        end
    end
end

local function WR_OnTeamTechResearched(teamID, techID)
    local playerID, player = WR_GetActiveWhiteRoomPlayer()
    if player == nil or player:GetTeam() ~= teamID then
        return
    end

    WR_InitializeActivePlayer()

    for _, unlock in ipairs(WR_UNLOCK_DEFINITIONS) do
        if unlock.TechID == techID then
            WR_QueueUnlock(playerID, player, unlock)
            return
        end
    end
end

local function WR_TryIncludeIconSupport()
    local ok, err = pcall(function()
        include("IconSupport")
    end)

    if not ok then
        print("WhiteRoomUnitUnlock could not load IconSupport: " .. tostring(err))
    end
end

WR_TryIncludeIconSupport()
WR_ResolveUnlocks()

Controls.AcknowledgeButton:RegisterCallback(Mouse.eLClick, WR_CloseUnlock)

-- Manual replays never change seen/progression keys or send new notifications.
if LuaEvents ~= nil then
    LuaEvents.WR_OpenPersonnelDossier.Add(function(requestedPlayerID, unitType)
        local playerID, player = WR_GetActiveWhiteRoomPlayer()
        if player == nil or requestedPlayerID ~= playerID or WR_IsPresentationBlocked() then return end
        for _, unlock in ipairs(WR_UNLOCK_DEFINITIONS) do
            if unlock.UnitType == unitType and WR_TeamHasTech(player, unlock.TechID) then
                if WR_CURRENT_UNLOCK == unlock then return end
                table.insert(WR_PENDING_UNLOCKS, unlock)
                WR_ShowNextUnlock()
                return
            end
        end
    end)
end

if Events.GameplaySetActivePlayer ~= nil then
    Events.GameplaySetActivePlayer.Add(function()
        Controls.UnlockPanel:SetHide(true)
        WR_CURRENT_UNLOCK = nil
        WR_PENDING_UNLOCKS = {}
    end)
end

ContextPtr:SetInputHandler(function(uiMsg, wParam)
    if uiMsg == KeyEvents.KeyDown
        and wParam == Keys.VK_ESCAPE
        and not Controls.UnlockPanel:IsHidden() then
        WR_CloseUnlock()
        return true
    end

    return false
end)

if GameEvents.TeamTechResearched ~= nil then
    GameEvents.TeamTechResearched.Add(WR_OnTeamTechResearched)
end

if GameEvents.PlayerDoTurn ~= nil then
    GameEvents.PlayerDoTurn.Add(WR_CheckUnlockedTechnologies)
end

if Events.SerialEventEnterCityScreen ~= nil then
    Events.SerialEventEnterCityScreen.Add(function()
        WR_CITY_SCREEN_OPEN = true
        Controls.UnlockPanel:SetHide(true)
    end)
end

if Events.SerialEventExitCityScreen ~= nil then
    Events.SerialEventExitCityScreen.Add(function()
        WR_CITY_SCREEN_OPEN = false
        WR_ResumePresentation()
    end)
end

if Events.AILeaderMessage ~= nil then
    Events.AILeaderMessage.Add(function()
        WR_DIPLOMACY_OPEN = true
        Controls.UnlockPanel:SetHide(true)
    end)
end

if Events.LeavingLeaderViewMode ~= nil then
    Events.LeavingLeaderViewMode.Add(function()
        WR_DIPLOMACY_OPEN = false
        WR_ResumePresentation()
    end)
end

WR_InitializeActivePlayer()

-- White Room Kid Kiyotaka - Contextual Flavor Presentation

print("WhiteRoomKiyotakaFlavor.lua loaded")

local CIV_WHITE_ROOM_KID = GameInfoTypes.CIVILIZATION_WHITE_ROOM_KID
local WR_FLAVOR_SAVE = Modding.OpenSaveData()
local WR_BANNER_BUFFER_SIZE = 8
local WR_ADAPTATION_TIERS = {100, 500, 1000, 2000, 3500, 5000, 7500, 10000}
local WR_TIER_ROMAN = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII"}
local WR_METRIC_ORDER = {"COMBAT", "ATTACK", "RESISTANCE", "HEALING", "DESPERATION", "MOVE_CHANCE"}

WR_KIYOTAKA_FLAVOR_ENABLED = WR_KIYOTAKA_FLAVOR_ENABLED ~= false
WR_KIYOTAKA_BARK_CHANCE_PERCENT = WR_KIYOTAKA_BARK_CHANCE_PERCENT or 35
WR_KIYOTAKA_BARK_COOLDOWN_TURNS = WR_KIYOTAKA_BARK_COOLDOWN_TURNS or 1

local WR_METRIC_LABELS = {
    COMBAT = "COMBAT ANALYSIS",
    ATTACK = "OFFENSIVE MODEL",
    RESISTANCE = "PAIN TOLERANCE",
    HEALING = "RECOVERY MODEL",
    DESPERATION = "CRITICAL RESPONSE",
    MOVE_CHANCE = "FLOW STATE"
}

local WR_FLAVOR_QUOTES = {
    DEPLOYMENT = {
        "Observation begins.",
        "Another environment. Another set of variables.",
        "There is no need to reveal more than necessary."
    },
    DAMAGE_DEALT = {
        "Your response was predictable.",
        "Every movement exposes the next one.",
        "The useful part was seeing how you reacted.",
        "That was enough to understand the pattern.",
        "The difference was decided before the exchange."
    },
    NO_DAMAGE = {
        "No adjustment was necessary.",
        "You were never close enough to matter.",
        "An answer without pressure reveals nothing.",
        "The margin remains acceptable."
    },
    COUNTERATTACK = {
        "You mistook observation for passivity.",
        "An attack is also an admission.",
        "Your initiative made the answer obvious.",
        "The opening belonged to you. The outcome did not."
    },
    WOUNDED_TARGET = {
        "The weakness was already exposed.",
        "Once the structure fails, force becomes unnecessary.",
        "A damaged pattern is easier to complete.",
        "There was nothing left to conceal."
    },
    KILL = {
        "The result was decided before the test began.",
        "You reached the limit of your usefulness.",
        "The final move only confirmed the analysis.",
        "There was never a second outcome.",
        "One less variable remains."
    },
    WOUNDED_KILL = {
        "The weakness was already exposed.",
        "The conclusion required no further study.",
        "You continued after the result was decided.",
        "A visible flaw is no longer a threat."
    },
    DAMAGE_TAKEN = {
        "Pain is only another measurement.",
        "A useful correction.",
        "Now I understand the weight behind it.",
        "Damage without a lesson would be wasteful.",
        "The next attempt will require something different."
    },
    BELOW_HALF = {
        "Pressure improves the quality of the data.",
        "The conditions are finally becoming useful.",
        "A disadvantage only matters if it remains unexplained.",
        "This is where the real test begins."
    },
    LOW_HP = {
        "Failure recorded. Countermeasure prepared.",
        "You failed to finish the experiment.",
        "The limit moved before you reached it.",
        "Survival is sufficient. Everything else can be corrected."
    },
    RECOVERY = {
        "The body adjusts. The lesson remains.",
        "A temporary defect. Nothing more.",
        "Recovery is simply the next stage of adaptation.",
        "The damage has already served its purpose."
    },
    FLOW_STATE = {
        "The pattern is complete.",
        "There is no longer a gap between decision and movement.",
        "The next position is already determined.",
        "Thought and action no longer need to be separated."
    },
    TIER = {
        "The previous standard is no longer relevant.",
        "Repeated pressure has produced a permanent answer.",
        "The model has been revised.",
        "What was difficult has become familiar."
    },
    CLASS_MILESTONE = {
        "Repetition has made your method obsolete.",
        "Your doctrine no longer contains uncertainty.",
        "The category is understood.",
        "Familiar opponents stop being opponents."
    },
    DEATH = {
        "SUBJECT 004 is no longer transmitting.",
        "The masterpiece record has been interrupted.",
        "Facility link lost. Subject recovery is impossible."
    }
}

local function WR_IsWhiteRoomPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and CIV_WHITE_ROOM_KID ~= nil
        and player:GetCivilizationType() == CIV_WHITE_ROOM_KID
end

local function WR_FlavorKey(playerID, suffix)
    return "WR_KIYOTAKA_FLAVOR_" .. tostring(playerID) .. "_" .. suffix
end

local function WR_BannerKey(playerID, suffix)
    return "WR_KIYOTAKA_BANNER_" .. tostring(playerID) .. "_" .. suffix
end

local function WR_BannerSlotKey(playerID, slot, suffix)
    return WR_BannerKey(playerID, "SLOT_" .. tostring(slot) .. "_" .. suffix)
end

local function WR_GetNumber(key)
    return tonumber(WR_FLAVOR_SAVE.GetValue(key)) or 0
end

local function WR_SetNumber(key, value)
    WR_FLAVOR_SAVE.SetValue(key, value or 0)
end

local function WR_SetText(key, value)
    WR_FLAVOR_SAVE.SetValue(key, tostring(value or ""))
end

local function WR_Random(maximum, reason)
    if maximum == nil or maximum <= 1 then
        return 0
    end

    if Game ~= nil and Game.Rand ~= nil then
        local ok, value = pcall(Game.Rand, maximum, reason or "White Room flavor")
        if ok and type(value) == "number" then
            return value
        end
    end

    return Game.GetGameTurn() % maximum
end

local function WR_SelectQuote(playerID, eventType)
    local pool = WR_FLAVOR_QUOTES[eventType] or WR_FLAVOR_QUOTES.DAMAGE_DEALT
    local index = WR_Random(#pool, "White Room Kiyotaka flavor quote") + 1
    local lastIndexKey = WR_FlavorKey(playerID, "LAST_QUOTE_" .. tostring(eventType))
    local lastIndex = WR_GetNumber(lastIndexKey)

    if #pool > 1 and index == lastIndex then
        index = (index % #pool) + 1
    end

    WR_SetNumber(lastIndexKey, index)
    return pool[index]
end

local function WR_ShouldShowBark(playerID, forceBark)
    if not WR_KIYOTAKA_FLAVOR_ENABLED or Game.GetActivePlayer() ~= playerID then
        return false
    end

    local turn = Game.GetGameTurn()
    local lastTurn = WR_GetNumber(WR_FlavorKey(playerID, "LAST_BARK_TURN"))
    if not forceBark and turn - lastTurn < WR_KIYOTAKA_BARK_COOLDOWN_TURNS then
        return false
    end

    if not forceBark and WR_Random(100, "White Room Kiyotaka bark chance") >= WR_KIYOTAKA_BARK_CHANCE_PERCENT then
        return false
    end

    WR_SetNumber(WR_FlavorKey(playerID, "LAST_BARK_TURN"), turn)
    return true
end

local function WR_ShowFloatingBark(playerID, unit, quote, forceBark)
    if not WR_ShouldShowBark(playerID, forceBark)
        or unit == nil
        or Events == nil
        or Events.AddPopupTextEvent == nil
        or Vector2 == nil
        or ToHexFromGrid == nil
        or HexToWorld == nil then
        return
    end

    local plot = unit:GetPlot()
    if plot == nil then
        return
    end

    pcall(function()
        local hex = ToHexFromGrid(Vector2(plot:GetX(), plot:GetY()))
        Events.AddPopupTextEvent(
            HexToWorld(hex),
            "[COLOR_POSITIVE_TEXT]\"" .. tostring(quote) .. "\"[ENDCOLOR]",
            true
        )
    end)
end

local function WR_QueueBanner(playerID, title, subtitle, quote)
    if not WR_KIYOTAKA_FLAVOR_ENABLED or Game.GetActivePlayer() ~= playerID then
        return
    end

    local sequenceKey = WR_BannerKey(playerID, "SEQUENCE")
    local sequence = WR_GetNumber(sequenceKey) + 1
    local slot = ((sequence - 1) % WR_BANNER_BUFFER_SIZE) + 1

    WR_SetNumber(sequenceKey, sequence)
    WR_SetNumber(WR_BannerSlotKey(playerID, slot, "SEQUENCE"), sequence)
    WR_SetNumber(WR_BannerSlotKey(playerID, slot, "TURN"), Game.GetGameTurn())
    WR_SetText(WR_BannerSlotKey(playerID, slot, "TITLE"), title)
    WR_SetText(WR_BannerSlotKey(playerID, slot, "SUBTITLE"), subtitle)
    WR_SetText(WR_BannerSlotKey(playerID, slot, "QUOTE"), quote)
end

function WR_KiyotakaFlavorEvent(playerID, unit, eventType, headline, detail, options)
    options = options or {}

    local quote = ""
    if WR_KIYOTAKA_FLAVOR_ENABLED then
        quote = WR_SelectQuote(playerID, eventType)
    end

    local telemetryDetail = tostring(detail or "No additional data.")
    if quote ~= "" then
        telemetryDetail = telemetryDetail .. " // SUBJECT NOTE // \"" .. quote .. "\""
    end

    if WR_RecordTelemetry ~= nil then
        WR_RecordTelemetry(playerID, "SUBJECT", headline, telemetryDetail)
    end

    if quote ~= "" and options.suppressBark ~= true then
        WR_ShowFloatingBark(playerID, unit, quote, options.forceBark == true)
    end

    if options.bannerTitle ~= nil then
        WR_QueueBanner(
            playerID,
            options.bannerTitle,
            options.bannerSubtitle or headline,
            quote
        )
    end

    return quote
end

local function WR_TierForValue(value)
    local tier = 0
    for index, threshold in ipairs(WR_ADAPTATION_TIERS) do
        if (value or 0) >= threshold then
            tier = index
        else
            break
        end
    end

    return tier
end

function WR_KiyotakaFlavorInitializeMilestones(playerID, metrics)
    if WR_FLAVOR_SAVE.GetValue(WR_FlavorKey(playerID, "MILESTONES_INITIALIZED")) == 1 then
        return
    end

    for _, metric in ipairs(WR_METRIC_ORDER) do
        WR_SetNumber(
            WR_FlavorKey(playerID, "TIER_" .. metric),
            WR_TierForValue(metrics ~= nil and metrics[metric] or 0)
        )
    end

    WR_SetNumber(WR_FlavorKey(playerID, "MILESTONES_INITIALIZED"), 1)
end

local function WR_InitializeClassMilestones(playerID)
    if WR_FLAVOR_SAVE.GetValue(WR_FlavorKey(playerID, "CLASS_MILESTONES_INITIALIZED")) == 1 then
        return
    end

    for unitCombatInfo in GameInfo.UnitCombatInfos() do
        local suffix = string.gsub(unitCombatInfo.Type or "", "UNITCOMBAT_", "")
        if suffix ~= "" then
            local classValue = WR_GetNumber(
                "WR_KIYOTAKA_" .. tostring(playerID) .. "_CLASS_" .. suffix
            )
            local classKey = string.gsub(string.upper(suffix), "[^A-Z0-9]", "_")
            WR_SetNumber(
                WR_FlavorKey(playerID, "CLASS_TIER_" .. classKey),
                WR_TierForValue(classValue)
            )
        end
    end

    WR_SetNumber(WR_FlavorKey(playerID, "CLASS_MILESTONES_INITIALIZED"), 1)
end

function WR_KiyotakaFlavorCheckMilestones(playerID, unit, metrics)
    WR_KiyotakaFlavorInitializeMilestones(playerID, metrics)
    WR_InitializeClassMilestones(playerID)

    local changes = {}
    for _, metric in ipairs(WR_METRIC_ORDER) do
        local tierKey = WR_FlavorKey(playerID, "TIER_" .. metric)
        local previousTier = WR_GetNumber(tierKey)
        local currentTier = WR_TierForValue(metrics ~= nil and metrics[metric] or 0)

        if currentTier > previousTier then
            WR_SetNumber(tierKey, currentTier)
            table.insert(changes, (WR_METRIC_LABELS[metric] or metric) .. " // TIER " .. WR_TIER_ROMAN[currentTier])
        end
    end

    if #changes > 0 then
        WR_KiyotakaFlavorEvent(
            playerID,
            unit,
            "TIER",
            "ADAPTATION THRESHOLD RECORDED // SUBJECT 004",
            table.concat(changes, " // "),
            {
                forceBark = true,
                bannerTitle = "SUBJECT 004 // ADAPTATION THRESHOLD",
                bannerSubtitle = table.concat(changes, "   ")
            }
        )
    end
end

function WR_KiyotakaFlavorCheckClassMilestone(playerID, unit, classLabel, classValue)
    local classKey = string.gsub(string.upper(tostring(classLabel or "UNKNOWN")), "[^A-Z0-9]", "_")
    local tierKey = WR_FlavorKey(playerID, "CLASS_TIER_" .. classKey)
    local previousTier = WR_GetNumber(tierKey)
    local currentTier = WR_TierForValue(classValue)

    if currentTier <= previousTier then
        return
    end

    WR_SetNumber(tierKey, currentTier)
    WR_KiyotakaFlavorEvent(
        playerID,
        unit,
        "CLASS_MILESTONE",
        "HOSTILE DOCTRINE DECODED // SUBJECT 004",
        tostring(classLabel) .. " // TIER " .. WR_TIER_ROMAN[currentTier],
        {
            forceBark = true,
            bannerTitle = "SUBJECT 004 // DOCTRINE DECODED",
            bannerSubtitle = tostring(classLabel) .. " adaptation reached Tier " .. WR_TIER_ROMAN[currentTier]
        }
    )
end

function WR_KiyotakaFlavorRegisterDeployment(playerID, unit, metrics)
    if unit == nil then
        return
    end

    WR_KiyotakaFlavorInitializeMilestones(playerID, metrics)
    WR_InitializeClassMilestones(playerID)

    local unitID = unit:GetID()
    local active = WR_GetNumber(WR_FlavorKey(playerID, "ACTIVE"))
    local currentUnitID = WR_GetNumber(WR_FlavorKey(playerID, "CURRENT_UNIT_ID"))
    if active == 1 and currentUnitID == unitID then
        return
    end

    WR_SetNumber(WR_FlavorKey(playerID, "ACTIVE"), 1)
    WR_SetNumber(WR_FlavorKey(playerID, "CURRENT_UNIT_ID"), unitID)
    local deployment = WR_GetNumber(WR_FlavorKey(playerID, "DEPLOYMENTS")) + 1
    WR_SetNumber(WR_FlavorKey(playerID, "DEPLOYMENTS"), deployment)

    WR_KiyotakaFlavorEvent(
        playerID,
        unit,
        "DEPLOYMENT",
        "SUBJECT 004 DEPLOYED",
        "Deployment record " .. tostring(deployment) .. " // Facility observation active",
        {
            forceBark = true,
            bannerTitle = "SUBJECT 004 // DEPLOYMENT AUTHORIZED",
            bannerSubtitle = "Perfect Adaptation is now under live observation"
        }
    )
end

function WR_KiyotakaFlavorRecordDeath(playerID, unit)
    WR_SetNumber(WR_FlavorKey(playerID, "ACTIVE"), 0)
    WR_SetNumber(WR_FlavorKey(playerID, "CURRENT_UNIT_ID"), 0)

    WR_KiyotakaFlavorEvent(
        playerID,
        unit,
        "DEATH",
        "SUBJECT 004 // SIGNAL LOST",
        "Kiyotaka was lost in combat // Perfect Adaptation record remains archived",
        {
            forceBark = false,
            suppressBark = true,
            bannerTitle = "SUBJECT 004 // SIGNAL LOST",
            bannerSubtitle = "The masterpiece record has been interrupted"
        }
    )
end

print("WR Kiyotaka Flavor: initialized with contextual barks, telemetry notes, and banner queue")

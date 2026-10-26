UI_SAVE_READS = 0
UI_SAVE_WRITES = 0
local originalSave = Modding.OpenSaveData()
Modding.OpenSaveData = function() return {
    GetValue = function(key) UI_SAVE_READS = UI_SAVE_READS + 1; return originalSave.GetValue(key) end,
    SetValue = function(key, value) UI_SAVE_WRITES = UI_SAVE_WRITES + 1; originalSave.SetValue(key, value) end
} end
Game.GetActivePlayer = function() return ACTIVE_PLAYER end
Mouse = { eLClick = 1 }
Keys = { VK_ESCAPE = 27 }
KeyEvents = { KeyDown = 2 }
UI = { GetLeaderHeadRootUp = function() return false end }
UIManager = { GetScreenSizeVal = function() return 1024, 768 end }
TECHS = {}
LuaEvents = eventBus()
LuaEvents.WR_OpenPersonnelDossier.Add(function(playerID, unitType)
    LAST_DOSSIER_REQUEST = { playerID = playerID, unitType = unitType }
end)
Teams = { [0] = { IsHasTech = function(_, id) return TECHS[id] or false end } }
for _, player in pairs(Players) do
    function player:GetTeam() return 0 end
    function player:CanTrain() return true end
    function player:AddNotification() end
end
GameInfoTypes.TECH_ROBOTICS = 21
GameInfoTypes.TECH_PLASTIC = 22
GameInfo.Units[11] = { ID = 11, Type = "UNIT_WR_KIYOTAKA", Description = "Kiyotaka Ayanokoji", Combat = 130, Moves = 3, PrereqTech = "TECH_ROBOTICS", IconAtlas = "KIYOTAKA" }
GameInfo.Units[12] = { ID = 12, Type = "UNIT_WR_FOURTH_GEN_OPERATIVE", Description = "4th Generation Operative", Combat = 85, Moves = 2, PrereqTech = "TECH_PLASTIC", IconAtlas = "OPERATIVES" }
GameInfo.Units.UNIT_WR_KIYOTAKA = GameInfo.Units[11]
GameInfo.Units.UNIT_WR_FOURTH_GEN_OPERATIVE = GameInfo.Units[12]
GameInfo.Technologies = { [21] = {ID = 21, Type = "TECH_ROBOTICS", Description = "Robotics", IconAtlas = "TECH"},
    [22] = {ID = 22, Type = "TECH_PLASTIC", Description = "Plastics", IconAtlas = "TECH"} }
GameInfo.Technologies.TECH_ROBOTICS = GameInfo.Technologies[21]
GameInfo.Technologies.TECH_PLASTIC = GameInfo.Technologies[22]
GameInfo.UnitCombatInfos = function() return iterator({ {Type = "UNITCOMBAT_SIEGE", Description = "Siege"} }) end
local city = newCity(0, 1, 8, 8, 0)
function city:GetNumCityPlots() return 0 end
function city:GetName() return "White Room" end
newUnit(0, 1, 11, 17)
for id = 2, 4 do
    newUnit(0, id, 12, id * 7)
    SAVE["WR_OPERATIVE_0_UNIT_" .. id .. "_SERIAL"] = id - 1
    local prefix = "WR_OPERATIVE_0_RECORD_" .. (id - 1) .. "_"
    SAVE[prefix .. "DEPLOY_TURN"] = 4
    SAVE[prefix .. "KILLS"] = id + 1
    SAVE[prefix .. "COMBATS"] = id * 4
end
SAVE.WR_OPERATIVE_0_NEXT_SERIAL = 3
SAVE.WR_OPERATIVE_0_TOTAL_KILLS = 12
SAVE.WR_OPERATIVE_0_TOTAL_COMBATS = 36
SAVE.WR_KIYOTAKA_0_COMBAT = 247
SAVE.WR_KIYOTAKA_0_ATTACK = 169
SAVE.WR_KIYOTAKA_0_RESISTANCE = 318
SAVE.WR_KIYOTAKA_0_HEALING = 143
SAVE.WR_KIYOTAKA_0_DESPERATION = 182
SAVE.WR_KIYOTAKA_0_MOVE_CHANCE = 2177
SAVE.WR_KIYOTAKA_0_CLASS_SIEGE = 125
SAVE.WR_TRADE_ROUTE_LEARNING_0_HALF_GOLD_STACKS = 14.5
SAVE.WR_CAPTURED_CITY_LEARNING_0_CITY_LOSS_STACKS = 9
Controls = {}
for id, attributes in pairs(UI_SEED) do
    local control = { text = attributes.String or "", hidden = attributes.Hidden == "1", callbacks = {}, texture = attributes.Texture }
    function control:SetString(value) self.text = tostring(value) end
    control.SetText = control.SetString
    function control:GetText() return self.text end
    function control:SetHide(value) self.hidden = value end
    function control:IsHidden() return self.hidden end
    function control:SetSizeVal(width, height) self.width, self.height = width, height end
    function control:SetOffsetVal(x, y) self.x, self.y = x, y end
    function control:SetTexture(value) self.texture = value end
    function control:SetDisabled(value) self.disabled = value end
    function control:SetToolTipString(value) self.tooltip = value end
    function control:RegisterCallback(event, callback) self.callbacks[event] = callback end
    function control:Click() if not self.disabled then self.callbacks[Mouse.eLClick]() end end
    function control:CalculateInternalSize() self.measured = true end
    function control:SetScrollValue(value) self.scroll = value end
    Controls[id] = control
end
ContextPtr = {
    SetInputHandler = function(_, callback) UI_INPUT = callback end,
    SetUpdate = function(_, callback) UI_UPDATE = callback end,
    LookUpControl = function() return { IsHidden = function() return true end } end
}
function include() end
function IconHookup(_, size, atlas, control)
    if atlas == "WR_WHITE_ROOM_ICON_ATLAS" then control:SetTexture("WR_WhiteRoom_Icon_" .. size .. ".dds") end
    return true
end

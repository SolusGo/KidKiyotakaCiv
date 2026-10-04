-- Gameplay battle snapshots shared by Kiyotaka and Operative records.
-- CP roles 0/1 are attacker/defender; other roles are not direct opponents.
WR_BattleTracking = { joined = {}, finished = {}, battles = {} }
local tracking = WR_BattleTracking

local function WR_Entity(member)
    local player = Players[member.playerID]
    if player == nil then return nil end
    if member.isCity then return player:GetCityByID(member.entityID) end
    return player:GetUnitByID(member.entityID)
end

local function WR_Snapshot(member)
    if member.destroyed or member.captured then
        member.damageAfter = member.maxHP
        return
    end
    local entity = WR_Entity(member)
    if entity ~= nil then
        member.damageAfter = math.max(member.damageAfter, entity:GetDamage())
    end
end

function tracking.FindKillPair(playerID, unitID, killerPlayerID)
    for index = #tracking.battles, 1, -1 do
        local battle = tracking.battles[index]
        for _, role in ipairs({ 0, 1 }) do
            local victim = battle.members[role]
            local killer = battle.members[1 - role]
            if victim ~= nil and not victim.isCity
                and victim.playerID == playerID and victim.entityID == unitID
                and killer ~= nil and not killer.isCity
                and killer.playerID == killerPlayerID and killer.playerID ~= playerID then
                return killer, victim, battle
            end
        end
    end
    return nil
end

GameEvents.BattleStarted.Add(function(battleType, x, y)
    tracking.battles[#tracking.battles + 1] = { battleType = battleType, x = x, y = y, members = {} }
end)

GameEvents.BattleJoined.Add(function(playerID, entityID, role, isCity)
    local battle = tracking.battles[#tracking.battles]
    if battle == nil or battle.members[role] ~= nil then return end
    local member = {
        playerID = playerID, entityID = entityID, role = role,
        isCity = isCity == true or isCity == 1, damageBefore = 0, damageAfter = 0,
        maxHP = 100, destroyed = false
    }
    local entity = WR_Entity(member)
    if entity == nil then return end
    member.damageBefore = entity:GetDamage()
    member.damageAfter = member.damageBefore
    member.maxHP = entity:GetMaxHitPoints()
    member.unitType = not member.isCity and entity:GetUnitType() or nil
    member.friendlyTerritory = entity:GetPlot() ~= nil and entity:GetPlot():GetOwner() == playerID
    member.x = entity:GetPlot() ~= nil and entity:GetPlot():GetX() or nil
    member.y = entity:GetPlot() ~= nil and entity:GetPlot():GetY() or nil
    battle.members[role] = member
    for _, handler in ipairs(tracking.joined) do handler(member, entity, battle) end
end)

-- Save terminal damage while a defeated unit still exists. This also preserves
-- the pre-heal damage of survivors before kill effects change their health.
GameEvents.UnitPrekill.Add(function(playerID, unitID, unitType, x, y, delay, killerPlayerID)
    for index = #tracking.battles, 1, -1 do
        local battle = tracking.battles[index]
        for _, member in pairs(battle.members) do
            if not member.isCity and member.playerID == playerID and member.entityID == unitID then
                member.destroyed = true
                member.killerPlayerID = killerPlayerID
                for _, participant in pairs(battle.members) do WR_Snapshot(participant) end
                return
            end
        end
    end
end)

-- A conquered city has a new owner/ID and its HP is reset before BattleFinished.
-- Preserve its terminal damage rather than reading the replacement city.
GameEvents.CityCaptureComplete.Add(function(oldOwnerID, isCapital, x, y, newOwnerID, population, wasConquest)
    if wasConquest ~= true and wasConquest ~= 1 then return end
    for index = #tracking.battles, 1, -1 do
        local battle = tracking.battles[index]
        for _, member in pairs(battle.members) do
            if member.isCity and member.playerID == oldOwnerID and member.x == x and member.y == y then
                member.captured = true
                for _, participant in pairs(battle.members) do WR_Snapshot(participant) end
                return
            end
        end
    end
end)

GameEvents.BattleFinished.Add(function()
    local battle = table.remove(tracking.battles)
    if battle == nil then return end
    for _, member in pairs(battle.members) do
        WR_Snapshot(member)
        member.damageDelta = math.max(0, member.damageAfter - member.damageBefore)
        member.unit = not member.isCity and not member.destroyed and WR_Entity(member) or nil
    end
    for _, handler in ipairs(tracking.finished) do handler(battle) end
end)

print("WR Battle Tracking: initialized with Community Patch gameplay events")

local Unlocker, Caffeine, Project = ...

--TODO
-- deleteExcessSoulShards
-- Add Menu and spells for: healthstone, drainlife, doom&agony, drainsoul farm
--felDomination add
--
--


local spells = Project.Spells

local Module = Caffeine.Module:New("lock")

local player            = Caffeine.UnitManager:Get('player')
local target            = Caffeine.UnitManager:Get('target')
local none              = Caffeine.UnitManager:Get('none')
local pet               = Caffeine.UnitManager:Get('pet')

local CombatAPL     = Caffeine.APL:New("default")
local RestingAPL    = Caffeine.APL:New("resting")

Project.Settings = Caffeine.Interface.Category:New("PokilockMenu")

local PokilockMenu = Caffeine.Interface.Hotbar:New({
    name = "PokilockMenu",
    options = Project.Settings,
    buttonCount = 2,
})

PokilockMenu:AddButton({
    name = "Toggle",
    texture = "Interface\\ICONS\\ability_dualwield",
    tooltip = "Toggle Pokilock",
    toggle = true,
    onClick = function()
        local module = Caffeine:FindModule("lock")
        if module then
            module:Toggle()
            if module.enabled then
                Caffeine:Print("Enabled", module.name)
            else
                Caffeine:Print("Disabled", module.name)
            end
        else
            Caffeine:Print("Module not found")
        end
    end,
})

local META = false

PokilockMenu:AddButton({
    name = "META",
    texture = "Interface\\ICONS\\spell_shadow_demonform",
    tooltip = "Toggle Metamorphosis",
    toggle = true,
    onClick = function()
        if META then
            META = false
        else
            META = true
        end
    end
})

local eventFrame = CreateFrame("Frame")

local inFlightSpells = {}

local function onSpellCastStart(self, event, unitTarget, castGUID, spellID)
    if unitTarget == "player" then
        local spellName = GetSpellInfo(spellID)
        inFlightSpells[spellName] = true
    end
end

local function onSpellCastEnd(self, event, unitTarget, castGUID, spellID)
    if unitTarget == "player" then
        local spellName = GetSpellInfo(spellID)
        inFlightSpells[spellName] = nil
    end
end

local function onCombatLogEvent(self, event)
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, missType, isOffHand, amountMissed = CombatLogGetCurrentEventInfo()

    if sourceGUID == UnitGUID("player") and inFlightSpells[spellName] then
        if subevent == "SPELL_MISSED" then
            print(spellName .. " missed due to " .. missType)
            inFlightSpells[spellName] = nil
        elseif subevent == "SPELL_DAMAGE" then
            inFlightSpells[spellName] = nil
        end
    end
end

eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_START" then
        onSpellCastStart(self, event, ...)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        onSpellCastEnd(self, event, ...)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        onCombatLogEvent(self, event, ...)
    end
end)

local wasCasting = {}
local caffeine = { buffer = 0.1 } -- replace with your actual values
local timers = {}

local healthstone = Caffeine.Item:New(36892, 36893, 36894) -- Assuming 36892 is the correct ID
local soulShard = Caffeine.Item:New(6265)
local soulShardCount = GetItemCount(6265) -- This is a WoW API function, not a Bastion function
local soulstone = Caffeine.Item:New(36895)
local spellstone = Caffeine.Item:New(41196, 41191, 41192, 41193, 41194, 41195)

local felArmor_aura = Caffeine.Globals.SpellBook:GetSpell(47893)
local life_tap_buff = Caffeine.Globals.SpellBook:GetSpell(63321)
local curse_of_elements_aura = Caffeine.Globals.SpellBook:GetSpell(47865) 
local immolate_aura = Caffeine.Globals.SpellBook:GetSpell(47811)
local metamorphosis_aura = Caffeine.Globals.SpellBook:GetSpell(47241)
local seed_of_corruption_aura = Caffeine.Globals.SpellBook:GetSpell(47836)
local corruption_debuff = Caffeine.Globals.SpellBook:GetSpell(47813)
local soul_fire_aura = Caffeine.Globals.SpellBook:GetSpell(63167) 
local molten_core_buff = Caffeine.Globals.SpellBook:GetSpell(71165) 
local soul_link_buff = Caffeine.Globals.SpellBook:GetSpell(25228)

function WasCastingCheck()
    local castingSpellName = UnitCastingInfo("player") or UnitChannelInfo("player")
    if castingSpellName then
        if not timers[castingSpellName] then
            timers[castingSpellName] = GetTime()
            wasCasting[castingSpellName] = true
        end
    end
    for castingSpell, startTime in pairs(timers) do
        if not wasCasting[castingSpell] or GetTime() - startTime > caffeine.buffer then
            wasCasting[castingSpell] = nil
            timers[castingSpell] = nil
        end
    end
end

local function hasSoulstone()
    local hasItem = GetItemCount(36895) > 0 -- Assuming 36895 is the ID of the soulstone
    return hasItem
end

local function hasSpellstone()
    local hasItem = GetItemCount(41196, 41191, 41192, 41193, 41194, 41195) > 0 -- Assuming 36895 is the ID of the soulstone
    return hasItem
end

local function hasHealthstone()
    local hasItem = GetItemCount(36892, 36893, 36894) > 0
    return hasItem
end

local function hasSoulShards()
    local soulShardCount = GetItemCount(6265) 
    return soulShardCount >= 1
end

function Buff()
    local spellstonelist = { 41196, 41191, 41192, 41193, 41194, 41195 }

    function _Use(item)
        local name, bag, slot = SecureCmdItemParse(item)
        if slot or GetItemInfo(name) then
            SecureCmdUseItem(name, bag, slot)
        end
    end

    local hasMH, mhExpires, _, _, hasOH, ohExpires, _ = GetWeaponEnchantInfo()

    if not (hasMH and mhExpires) and not IsPlayerMoving() and hasSoulShards() then
        for i = 1, #spellstonelist do
            if GetItemCount(spellstonelist[i]) >= 1 and (C_Container.GetItemCooldown(spellstonelist[i])) == 0 then
                local CurrentWeapon = GetInventoryItemID("player", 16)
                local spellstonename = GetItemInfo(spellstonelist[i])
                if spellstonename then
                    _Use(spellstonename)
                    UseInventoryItem(16)
                    spellstonecount = 0
                end
            end
        end
    end
end

function UseItemInSlot10()
    local itemID = GetInventoryItemID("player", 10)
    if not itemID then return end 

    local itemName = GetItemInfo(itemID)

    if player:IsAffectingCombat() and target:IsEnemy() and IsUsableItem(itemID) then
        UseInventoryItem(10)
    end
end

RestingAPL:AddSpell(
    spells.create_soulstone:CastableIf(function(self)
        return self:IsKnownAndUsable() and not hasSoulstone() and hasSoulShards()
    end):SetTarget(player)
)

RestingAPL:AddSpell(
    spells.create_healthstone:CastableIf(function(self)
        WasCastingCheck()
        return self:IsKnownAndUsable() and not hasHealthstone() and hasSoulShards() and not wasCasting["Create Healthstone"]
    end):SetTarget(player)
)

RestingAPL:AddSpell(
    spells.create_spellstone:CastableIf(function(self)
        return self:IsKnownAndUsable() and not hasSpellstone() and hasSoulShards()
    end):SetTarget(player)
)

RestingAPL:AddSpell(
    spells.fel_armor:CastableIf(function(self)
        return self:IsKnownAndUsable() and not player:GetAuras():FindMy(felArmor_aura):IsUp()
    end):SetTarget(player)
)

RestingAPL:AddSpell(
    spells.summon_felguard:CastableIf(function(self)
        return self:IsKnownAndUsable() and not pet:Exists() and hasSoulShards()
    end):SetTarget(none)
)

RestingAPL:AddSpell(
    spells.life_tap:CastableIf(function(self)
        local mana = UnitPower("player", 0) -- 0 is the power type for mana
        local maxMana = UnitPowerMax("player", 0)

        if mana < maxMana then
            return true
        end
        return false
    end):SetTarget(player)
)

RestingAPL:AddSpell(
    spells.soul_link:CastableIf(function(self)
        return self:IsKnownAndUsable() and pet:Exists() and not player:GetAuras():FindMy(soul_link_buff):IsUp()
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.life_tap:CastableIf(function(self)
        local mana = UnitPower("player", 0) -- 0 is the power type for mana
        local maxMana = UnitPowerMax("player", 0) -- Get player's maximum mana
        local manaPercentage = (mana / maxMana) * 100 -- Calculate mana percentage
        local health = UnitHealth("player") -- Get player's current health
        local maxHealth = UnitHealthMax("player") -- Get player's maximum health
        local healthPercentage = (health / maxHealth) * 100 -- Calculate health percentage
        local hasBuff = player:GetAuras():FindMy(life_tap_buff)
        local isInCombat = UnitAffectingCombat("player")
        --local isMoving = player:Moving()

        if manaPercentage < 15 or not hasBuff:IsUp() then
            return true
        end
        return false
    end):SetTarget(player)
)

CombatAPL:AddSpell(
    spells.seed_of_corruption:CastableIf(function(self)
        local numEnemiesInRange = target:GetEnemies(10) -- Replace 10 with the desired range

        return self:IsKnownAndUsable() 
            and not target:GetAuras():FindMy(seed_of_corruption_aura):IsUp() 
            and not target:GetAuras():FindMy(corruption_debuff):IsUp() 
            and (numEnemiesInRange > 2)
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.immolate:CastableIf(function(self)
        WasCastingCheck()
        return self:IsKnownAndUsable() and not target:GetAuras():FindMy(immolate_aura):IsUp() and not wasCasting["Immolate"]
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.corruption:CastableIf(function(self)
        return self:IsKnownAndUsable() and not target:GetAuras():FindMy(corruption_debuff):IsUp()
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.curse_of_the_elements:CastableIf(function(self)
        return self:IsKnownAndUsable() and not target:GetAuras():FindMy(curse_of_elements_aura):IsUp()
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.shadow_bolt:CastableIf(function(self)
        WasCastingCheck()
        return self:IsKnownAndUsable() and not target:GetAuras():FindMy(spells.shadow_bolt_buff):IsUp() and not wasCasting["Shadow Bolt"]
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.soul_fire:CastableIf(function(self)
        local buffRemains = target:GetAuras():FindMy(soul_fire_aura):GetRemainingTime() 
        if self:IsKnownAndUsable() and player:GetPower(7) > 0 and self:GetCastTime() < buffRemains then
            return true
        end
        return false
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.incinerate:CastableIf(function(self)
        local hasSoulFireAura = player:GetAuras():FindMy(soul_fire_aura):IsUp()
        local hasMoltenCoreBuff = player:GetAuras():FindMy(molten_core_buff):IsUp()
        local lowHealthEnemyInCombatExists = false

        Caffeine.UnitManager:EnumEnemies(function(enemy)
            if enemy:IsAffectingCombat() and enemy:GetHealthPercentage() < 35 then
                lowHealthEnemyInCombatExists = true
                return false 
            end
            return true 
        end)

        return self:IsKnownAndUsable() and (hasMoltenCoreBuff or (not hasSoulFireAura and lowHealthEnemyInCombatExists))
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.demonic_empowerment:CastableIf(function(self)
        return self:IsKnownAndUsable() and pet:Exists()
    end):SetTarget(target)
)

CombatAPL:AddSpell(
    spells.metamorphosis:CastableIf(function(self)
        return self:IsKnownAndUsable() and META
    end):SetTarget(player)
)

CombatAPL:AddSpell(
    spells.immolation_aura:CastableIf(function(self)
        local metamorphosisBuffRemains = player:GetAuras():FindMy(spells.metamorphosis):GetRemainingTime()
        local enemiesInRange = player:GetEnemies(10)

        return self:IsKnownAndUsable() and not player:GetAuras():FindMy(spells.immolation_aura):IsUp() and (metamorphosisBuffRemains < 15 or enemiesInRange > 2)
    end):SetTarget(player)
)

CombatAPL:AddSpell(
    spells.shadow_bolt:CastableIf(function(self)
        WasCastingCheck()
        return self:IsKnownAndUsable() and not wasCasting["Shadow Bolt"]
    end):SetTarget(target)
)

Module:Sync(function()
    if player:IsMounted() then 
        return 
    end

    if not player:IsAffectingCombat() then
        Buff()
        RestingAPL:Execute()
    elseif not player:IsCastingOrChanneling() and target:Exists() and target:IsHostile() and not target:IsDead() and player:IsAffectingCombat() then
        UseItemInSlot10()
        CombatAPL:Execute()
    end
end)

Caffeine:Register(Module)


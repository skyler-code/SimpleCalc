local _, addonTable = ...

addonTable.XPAC_VARIABLES = {}

addonTable.XPAC_VARIABLES['bonushealing'] = GetSpellBonusHealing
addonTable.XPAC_VARIABLES['healing'] = GetSpellBonusHealing

addonTable.XPAC_VARIABLES['defense'] = function()
    local skillRank, skillModifier = UnitDefense("player")
    return skillRank + skillModifier
end

if addonTable.playerClass == "DRUID" then
    addonTable.XPAC_VARIABLES['tree'] = function()
        if not C_SpellBook.IsSpellKnown(33891) then return 0 end
        local _, effectiveSpirit = UnitStat("player", LE_UNIT_STAT_SPIRIT)
        return effectiveSpirit * 0.25
    end
end
local _, addonTable = ...

addonTable.XPAC_VARIABLES = {}

addonTable.XPAC_VARIABLES['bonushealing'] = GetSpellBonusHealing

addonTable.XPAC_VARIABLES['defense'] = function()
    local skillRank, skillModifier = UnitDefense("player")
    return skillRank + skillModifier
end
local _, addonTable = ...

addonTable.CURRENCY_IDS = {
    arena        = Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID,
    champseals   = 241,
    conquest     = 221,
    cooking      = 81,
    honor        = Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID,
    justice      = JUSTICE_CURRENCY,
    valor        = VALOR_CURRENCY,
    jp           = JUSTICE_CURRENCY,
    vp           = VALOR_CURRENCY,
    tb           = 391,
    dmf          = 515,
    augustfrag   = 3350,
    augustshard  = 3414,
    cluster      = 3416,
}

addonTable.XPAC_VARIABLES = {}

addonTable.XPAC_VARIABLES['vpleft'] = function()
    local vpInfo = C_CurrencyInfo.GetCurrencyInfo(addonTable.CURRENCY_IDS.vp) or {}
    return vpInfo.maxQuantity - vpInfo.totalEarned
end

addonTable.XPAC_VARIABLES['repmod'] = function()
    local mod = 1
    if IsPlayerSpell(78632) then
        mod = mod + 0.1
    end
    if C_UnitAuras.GetPlayerAuraBySpellID(46668) or C_UnitAuras.GetPlayerAuraBySpellID(136583) then
        mod = mod + 0.1
    end
    return mod
end

-- (12 - item:94594) * 30 + (20 - item:94593) * 10 + 70 - (augustshard + item:266272 * 10)
addonTable.XPAC_VARIABLES['leggoshards'] = function()
    local shardsNeeded = 0

    if not C_QuestLog.IsQuestFlaggedCompleted(32597) then -- Heart of the Thunder King
        shardsNeeded = shardsNeeded + 70
    end

    if not C_QuestLog.IsQuestFlaggedCompleted(32591) then -- Secrets of the Empire
        shardsNeeded = shardsNeeded + (20 - C_Item.GetItemCount(94593, true)) * 10
    end

    if not C_QuestLog.IsQuestFlaggedCompleted(32596) then -- Echoes of the Titans
        shardsNeeded = shardsNeeded + (12 - C_Item.GetItemCount(94594, true)) * 30
    end

    local augustshards = (C_CurrencyInfo.GetCurrencyInfo(addonTable.CURRENCY_IDS.augustshard) or {}).quantity or 0
    local shardsInBags = C_Item.GetItemCount(266272, true) * 10
    shardsNeeded = shardsNeeded - (augustshards + shardsInBags)

    return shardsNeeded
end
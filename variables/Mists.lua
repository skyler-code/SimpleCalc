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
    cele         = 3350,
}

addonTable.XPAC_VARIABLES = {}

addonTable.XPAC_VARIABLES['vpleft'] = function()
    local vpInfo = (C_CurrencyInfo.GetCurrencyInfo(addonTable.CURRENCY_IDS.vp) or {})
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
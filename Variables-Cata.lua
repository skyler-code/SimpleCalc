if WOW_PROJECT_ID ~= WOW_PROJECT_CATACLYSM_CLASSIC then return end
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
    sidereal     = 2589,
    scourgestone = 2711,
    tb           = 391,
    dmf          = 515,
    moltenfront  = 416,
    fissure      = 3148,
}

addonTable.XPAC_VARIABLES = {}

addonTable.XPAC_VARIABLES['vpleft'] = function()
    local vpInfo = (C_CurrencyInfo.GetCurrencyInfo(addonTable.CURRENCY_IDS.vp) or {})
    return vpInfo.maxQuantity - vpInfo.totalEarned
end

addonTable.XPAC_VARIABLES['heroicsleft'] = function()
    return ceil(addonTable.XPAC_VARIABLES.vpleft() / 240)
end
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end
local _, addonTable = ...

addonTable.CURRENCY_IDS = {
    garrison  = 824,
    orderhall = 1220,
    resources = Constants.CurrencyConsts.WAR_RESOURCES_CURRENCY_ID,
    dubloon   = 1710,
    stygia    = 1767,
    anima     = Constants.CurrencyConsts.CURRENCY_ID_RESERVOIR_ANIMA,
    ash       = 1828,
    honor     = Constants.CurrencyConsts.HONOR_CURRENCY_ID,
    conquest  = Constants.CurrencyConsts.CONQUEST_CURRENCY_ID,
}

addonTable.XPAC_VARIABLES = {}

for k,v in ipairs({addonTable.CURRENCY_IDS.conquest, addonTable.CURRENCY_IDS.honor}) do
    local pvpInfo = C_CurrencyInfo.GetCurrencyInfo(v) or {}
    local pvpName = (pvpInfo.name or ""):lower()
    addonTable.XPAC_VARIABLES['max'..pvpName] = function()
        return C_CurrencyInfo.GetCurrencyInfo(v).maxQuantity
    end
    addonTable.XPAC_VARIABLES[pvpName..'left'] = function()
        local pInfo = C_CurrencyInfo.GetCurrencyInfo(v)
        return pInfo.maxQuantity - pInfo.quantity
    end
end
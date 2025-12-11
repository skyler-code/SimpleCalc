local _, addonTable = ...

addonTable.CURRENCY_IDS = {
    arena        = Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID,
    champseals   = 241,
    conquest     = 221,
    dalaran      = 81,
    honor        = Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID,
    justice      = JUSTICE_CURRENCY,
    valor        = VALOR_CURRENCY,
    jp           = JUSTICE_CURRENCY,
    vp           = VALOR_CURRENCY,
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

-- if Skillet then
--     addonTable.XPAC_VARIABLES['borean'] = function()
--         local needed = 0
--         for k, v in ipairs(Skillet:GetShoppingList(UnitName('player'))) do
--             if v.id == 33568 then
--                 needed = needed + v.count
--             end
--         end
--         return needed
--     end
-- end
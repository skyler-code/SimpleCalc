local _, addonTable = ...

addonTable.XPAC_VARIABLES = {}

if C_Seasons.GetActiveSeason() == 109 then -- Titan Reforged
    addonTable.CURRENCY_IDS = {
        dalaran      = 81,
        honor        = Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID,
        venture      = 201,
        ember        = 3403,
        fragment     = 3406,
    }
    addonTable.XPAC_VARIABLES['embersleft'] = function()
        local currencyInfo = (C_CurrencyInfo.GetCurrencyInfo(addonTable.CURRENCY_IDS.ember) or {})
        return currencyInfo.maxWeeklyQuantity - currencyInfo.quantityEarnedThisWeek
    end
else
    addonTable.CURRENCY_IDS = {
        arena        = Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID,
        champseals   = 241,
        conquest     = 221,
        triumph      = 301,
        dalaran      = 81,
        heroism      = 101,
        valor        = 102,
        frost        = 341,
        venture      = 201,
        honor        = Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID,
    }
end

addonTable.XPAC_VARIABLES['defense'] = function()
    local skillRank, skillModifier = UnitDefense("player")
    return skillRank + skillModifier
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
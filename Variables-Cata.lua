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

local baseHP = {
    [55] = 1359,
    [56] = 1421,
    [57] = 1485,
    [58] = 1551,
    [59] = 1619,
    [60] = 1689,
    [61] = 1902,
    [62] = 2129,
    [63] = 2357,
    [64] = 2612,
    [65] = 2883,
    [66] = 3169,
    [67] = 3455,
    [68] = 3774,
    [69] = 4109,
    [70] = 4444,
    [71] = 4720,
    [72] = 5013,
    [73] = 5325,
    [74] = 5656,
    [75] = 6008,
    [76] = 6381,
    [77] = 6778,
    [78] = 7199,
    [79] = 7646,
    [80] = 8121,
    [81] = 11349,
    [82] = 15860,
    [83] = 22164,
    [84] = 30974,
    [85] = 43285,
}

local function IsVengeanceKnown()
    return IsPlayerSpell(93099) or IsPlayerSpell(84840) or IsPlayerSpell(84839) or IsPlayerSpell(93098)
end

if IsVengeanceKnown() then
    addonTable.XPAC_VARIABLES['maxveng'] = function()
        return baseHP[UnitLevel("player")] * 0.1 + UnitStat("player", LE_UNIT_STAT_STAMINA)
    end
end

addonTable.XPAC_VARIABLES['vpleft'] = function()
    local vpInfo = (C_CurrencyInfo.GetCurrencyInfo(addonTable.CURRENCY_IDS.vp) or {})
    return vpInfo.maxQuantity - vpInfo.totalEarned
end

addonTable.XPAC_VARIABLES['heroicsleft'] = function()
    return ceil(addonTable.XPAC_VARIABLES.vpleft() / 240)
end
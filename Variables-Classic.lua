if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end
local _, addonTable = ...

local GetItemCount = C_Item.GetItemCount

addonTable.XPAC_VARIABLES = {}

addonTable.XPAC_VARIABLES['honor'] = function()
    return select(2, GetPVPThisWeekStats())
end

addonTable.XPAC_VARIABLES['adturnin'] = function()
    local count = 0
    for itemID, turnInCount in pairs({[12843]=1, [12841]=10,[12840]=20}) do
        local turnins = floor(GetItemCount(itemID, true) / turnInCount)
        if turnins > 0 then
            count = count + turnins
        end
    end
    return count
end

addonTable.XPAC_VARIABLES['bonushealing'] = GetSpellBonusHealing

local ZG_COINS = {
    {19698, 19699, 19700}, --Zulian, Razzashi, and Hakkari Coins
    {19701, 19702, 19703}, --Gurubashi, Vilebranch, and Witherbark Coins
    {19704, 19705, 19706}, --Sandfury, Skullsplitter, and Bloodscalp Coins
}

addonTable.XPAC_VARIABLES['zgcoins'] = function()
    local count = 0
    for _, coinArray in ipairs(ZG_COINS) do
        local min = math.huge
        for _, coinID in ipairs(coinArray) do
            local coinCount = GetItemCount(coinID, true)
            if coinCount < min then
                min = coinCount
            end
        end
        count = count + min
    end
    return count
end

addonTable.XPAC_VARIABLES['bijous'] = function()
    local count = 0
    for _, bijouId in ipairs({19707, 19708, 19709, 19710, 19711, 19712, 19713, 19714, 19715}) do
        count = count + GetItemCount(bijouId, true)
    end
    return count
end

addonTable.XPAC_VARIABLES['defense'] = function()
    local skillRank, skillModifier = UnitDefense("player")
    return skillRank + skillModifier
end
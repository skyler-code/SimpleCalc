-- Initialize SimpleCalc
local addonName = ...
local SimpleCalc = CreateFrame( 'Frame', addonName )
local scversion = GetAddOnMetadata( addonName, 'Version' )

if scversion == "@project-version@" then
    scversion = "DevBuild"
end

local tinsert, tsort, pairs, strfind = tinsert, table.sort, pairs, strfind
local ceil, min, max = ceil, min, max

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local JP_CONVERSION_RATE = 11.58
local BADGE_CAP = ceil(4000/JP_CONVERSION_RATE)

local ITEM_LINK_STR_MATCH = "item[%-?%d:]+"

local gprint = print
local function print(...)
    gprint("|cff33ff99"..addonName.."|r:",...)
end

local function UnescapeStr(str)
    local escapes = {
        "|c........", -- color start
        "|r", -- color end
        "|h",
        "|H", -- links
        "|T.-|t", -- textures
        "{.-}", -- raid icons
        "%b[]", -- stuff in brackets
    }
    for _, v in pairs(escapes) do
        str = str:gsub(v, "")
    end
    return str
end

local function StrItemCountSub(str)
    for itemLink in str:gmatch(ITEM_LINK_STR_MATCH) do
        str = str:gsub(itemLink, GetItemCount(itemLink, true))
    end
    return UnescapeStr(str)
end

local function StrVariableSub( str, k, v )
    return str:gsub( '%f[%a_]' .. k .. '%f[^%a_]', v )
end

local function Usage()
    print( addonName .. ' (v' .. scversion .. ') - Simple mathematical calculator' )
    print( 'Usage: /calc <value> <symbol> <value>' )
    print( 'Example: /calc 1650 + 2200 - honor' )
    print( 'value - A numeric or game value (honor, maxhonor, health, mana (or power), copper, silver, gold)' )
    print( 'symbol - A mathematical symbol (+, -, /, *)' )
    print( 'variable - A name to store a value under for future use' )
    print( 'Use /calc listvar to see your saved variables' )
    print( 'Use /calc clearvar <global(g) | char(c) | all> to clear your saved variables. Defaults to all.' )
    print( 'Use /calc addvar for info how to add variables' )
end

local function AddVarUsage()
    print( 'Usage: /calc addvar <global(g)|char(c)> <variable> = <value|variable|expression>' )
    print( 'Example: /calc addvar g mainGold = gold' )
    print( 'Note: Character variables are prioritized over global when evaluating expressions.' )
end

local function EvalString( str )
    local strFunc = loadstring( 'return ' .. str )
    if ( pcall( strFunc ) ) then
        return strFunc()
    end
end

local function SortTableForListing( t ) -- https://www.lua.org/pil/19.3.html
    local a = {}
    for n, v in pairs( t ) do
        local exV = type(v) == "function" and v() or v
        tinsert( a, n .. " = " .. exV )
    end
    tsort( a )
    return a
end

local function GetPlayerItemLevel()
    local IGNORED_ILVL_SLOTS = {
        [INVSLOT_BODY] = true,
        [INVSLOT_TABARD] = true
    }
    local playerItemLevel = 0
    if GetAverageItemLevel then
        playerItemLevel = select(2, GetAverageItemLevel())
    else
        local t, c = 0, 0
        for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
            if not IGNORED_ILVL_SLOTS[i] then
                local k = GetInventoryItemLink("player", i)
                if k then
                    local l = select(4, GetItemInfo(k))
                    t = t + l
                end
                c = c + 1
            end
        end
        if c > 0 then
            playerItemLevel = t / c
        end
    end
    return ("%.2f"):format(playerItemLevel)
end

function SimpleCalc:OnLoad()
    -- Register our slash commands
    for k, v in pairs({ addonName, "calc" }) do
        _G["SLASH_"..addonName:upper()..k] = "/" .. v
    end
    SlashCmdList[addonName:upper()] = function(...) self:ParseParameters(...) end

    -- Initialize our variables
    SimpleCalc_CharVariables = SimpleCalc_CharVariables or {}
    calcVariables = calcVariables or {}
    
    SimpleCalc_LastResult = SimpleCalc_LastResult or 0

    -- Let the user know we're here
    print( 'v' .. scversion .. ' initiated! Type: /calc for help.' )
end

function SimpleCalc:OnEvent(event, eventAddon)
    if event == "ADDON_LOADED" and eventAddon == addonName then
        self:OnLoad()
        self:UnregisterEvent(event)
    end
end

function SimpleCalc:GetVariables()
    if not self.variables then
        local p = "player"
        self.variables = {
            exalted   = function() return 42000 - select(5,GetWatchedFactionInfo()) or 0 end,
            armor     = function() return select(3, UnitArmor(p)) end,
            hp        = function() return UnitHealthMax(p) end,
            power     = function() return UnitPowerMax(p) end,
            copper    = function() return GetMoney() end,
            silver    = function() return GetMoney() / 100 end,
            gold      = function() return GetMoney() / 10000 end,
            maxxp     = function() return UnitXPMax(p) end,
            ilvl      = GetPlayerItemLevel,
            xp        = function() return UnitXP(p) end,
            xpleft    = function() if UnitLevel(p) == GetMaxPlayerLevel() then return 0 end return UnitXPMax(p) - UnitXP(p) end,
            last      = function() return SimpleCalc_LastResult end,
        }
        self.variables.health = self.variables.hp
        self.variables.mana = self.variables.power

        if not isClassic and GetTotalAchievementPoints then
            self.variables.achieves = function() return GetTotalAchievementPoints() or 0 end
        end

        local CURRENCY_IDS = {}
        if isRetail then
            CURRENCY_IDS = {
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
            for k,v in ipairs({CURRENCY_IDS.conquest, CURRENCY_IDS.honor}) do
                local pvpInfo = C_CurrencyInfo.GetCurrencyInfo(v) or {}
                local pvpName = (pvpInfo.name or ""):lower()
                self.variables['max'..pvpName] = function() return C_CurrencyInfo.GetCurrencyInfo(v).maxQuantity end
                self.variables[pvpName..'left'] = function()
                    local pInfo = C_CurrencyInfo.GetCurrencyInfo(v)
                    return pInfo.maxQuantity - pInfo.quantity
                end
            end
        else
            if isWrath then
                CURRENCY_IDS = {
                    arena        = Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID,
                    champseals   = 241,
                    conquest     = 221,
                    cooking      = 81,
                    heroism      = 101,
                    honor        = Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID,
                    jctoken      = 61,
                    justice      = 42,
                    sidereal     = 2589,
                    stonekeeper  = 161,
                    triumph      = 301,
                    valor        = 102,
                    venture      = 201,
                    wintergrasp  = 126,
                    scourgestone = 2711,
                    frost        = 341,
                }
                self.variables['badgecap'] = BADGE_CAP
                self.variables['jp'] = function()
                    local triumph = (C_CurrencyInfo.GetCurrencyInfo(CURRENCY_IDS.triumph) or {}).quantity or 0
                    local frost = (C_CurrencyInfo.GetCurrencyInfo(CURRENCY_IDS.frost) or {}).quantity or 0
                    return JP_CONVERSION_RATE * (triumph + frost)
                end
                self.variables['extrafrost'] = function()
                    local triumph = (C_CurrencyInfo.GetCurrencyInfo(CURRENCY_IDS.triumph) or {}).quantity or 0
                    local frost = (C_CurrencyInfo.GetCurrencyInfo(CURRENCY_IDS.frost) or {}).quantity or 0
                    return max(frost - min(BADGE_CAP - triumph, BADGE_CAP), 0)
                end
            else
                self.variables['honor'] = function() return select(2, GetPVPThisWeekStats()) end
            end

            for i = 1, NUM_STATS do
                local statName = _G["SPELL_STAT"..i.."_NAME"]:lower()
                self.variables[statName] = function() return select(2, UnitStat(p, i)) end
            end
        end

        for k, v in pairs( CURRENCY_IDS ) do
            self.variables[k] = function()
                return (C_CurrencyInfo.GetCurrencyInfo(v) or {}).quantity or 0
            end
        end
    end
    return self.variables
end

-- Parse any user-passed parameters
function SimpleCalc:ParseParameters( input )
    local lowerParam = input:lower()
    local i = 0
    local addVar, calcVariable, varIsGlobal, clearVar, clearGlobal, clearChar

    if ( lowerParam == '' or lowerParam == 'help' ) then
        return Usage()
    end

    for param in lowerParam:gmatch( '[^%s]+' ) do -- This loops through the user input (stuff after /calc). We're going to be checking for arguments such as 'help' or 'addvar' and acting accordingly.
        if ( i == 0 ) then
            if ( param == 'addvar' ) then
                addVar = true
            elseif ( param == 'listvar' ) then
                return self:ListVariables()
            elseif ( param == 'clearvar' ) then
                clearVar = true
            end
        end
        if ( addVar ) then -- User entered addvar so let's loop through the rest of the params.
            if ( i == 1 ) then
                if ( param == 'global' or param == 'g' ) then
                    varIsGlobal = true
                elseif ( param ~= 'char' and param ~= 'c' ) then
                    print( 'Invalid input: ' .. param )
                    AddVarUsage()
                    return
                end
            elseif ( i == 2 ) then -- Should be variable name
                if ( param:match( '[^a-z]' ) ) then
                    print( 'Invalid input: ' .. param )
                    print( 'Variable name can only contain letters!' )
                    return
                else
                    calcVariable = param;
                end
            elseif ( i == 3 ) then -- Should be '='
                if ( param ~= '=' ) then
                    print( 'Invalid input: ' .. param )
                    print( 'You must use an equals sign!' )
                    return
                end
            elseif ( i == 4 ) then -- Should be number
                local newParamStr = param;
                if ( newParamStr:match( '[a-z]' ) ) then
                    newParamStr = self:ApplyVariables( newParamStr )
                end
                local evalParam = EvalString( newParamStr )
                if ( not tonumber( evalParam ) ) then
                    print( 'Invalid input: ' .. param )
                    print( 'Variables can only be set to numbers or existing variables!' )
                else
                    local saveLocation, saveLocationStr = SimpleCalc_CharVariables, '[Character] '
                    if ( varIsGlobal ) then
                        saveLocation, saveLocationStr = calcVariables, '[Global] '
                    end
                    if ( evalParam ~= 0 ) then
                        saveLocation[calcVariable] = evalParam
                        print( saveLocationStr .. 'set \'' .. calcVariable .. '\' to ' .. evalParam )
                    else -- Variables set to 0 are just wiped out
                        saveLocation[calcVariable] = nil
                        print( saveLocationStr .. 'Reset variable: ' .. calcVariable )
                    end
                end
                return
            end
        elseif ( clearVar ) then
            if ( i == 1 ) then
                if ( param == 'global' or param == 'g' ) then
                    clearGlobal = true
                elseif ( param == 'char' or param == 'c' ) then
                    clearChar = true
                end
            end
        end
        i = i + 1
    end

    if ( addVar ) then -- User must have just typed /calc addvar so we'll give them a usage message.
        return AddVarUsage()
    end

    if ( clearVar ) then
        if ( clearGlobal ) then
            calcVariables = {}
            print( 'Global user variables cleared!' )
        elseif ( clearChar ) then
            SimpleCalc_CharVariables = {}
            print( 'Character user variables cleared!' )
        else
            calcVariables, SimpleCalc_CharVariables = {}, {}
            print( 'All user variables cleared!' )
        end
        return
    end

    local paramEval = lowerParam;

    if ( paramEval:match( '^[%%%+%-%*%^%/]' ) ) then
        paramEval = format( '%s%s', SimpleCalc_LastResult, paramEval )
        input = format( '%s%s', SimpleCalc_LastResult, input )
    end

    if ( paramEval:match( '[a-z]' ) ) then
        paramEval = self:ApplyVariables( paramEval )
    end

    if ( paramEval:match( '[a-z]' ) ) then
        print( 'Unrecognized variable!' )
        print( paramEval )
        return
    end

    paramEval = paramEval:gsub( '%s+', '' ) -- Clean up whitespace
    local evalStr = EvalString( paramEval )

    if ( evalStr ) then
        print( paramEval .. ' = ' .. evalStr )
        SimpleCalc_LastResult = evalStr
    else
        print( 'Could not evaluate expression! Maybe an unrecognized symbol?' )
        print( paramEval )
    end
end

function SimpleCalc:getVariableTables()
    local system = { type='System', list=self:GetVariables() }
    local global = { type='Global', list=calcVariables, showEmpty=true }
    local character = { type='Character', list=SimpleCalc_CharVariables, showEmpty=true }
    return pairs( { system, global, character } )
end

function SimpleCalc:ListVariables()
    local function list( var )
        local returnStr
        for _,v in pairs( SortTableForListing( var.list ) ) do
            if returnStr then
                returnStr = format( '%s, %s', returnStr, v )
            else
                returnStr = format( '%s variables: %s', var.type, v)
            end
        end
        if var['showEmpty'] and not returnStr then
            returnStr = format( 'There are no %s user variables.', var.type:lower() )
        end
        print( returnStr )
    end
    for _,varType in self:getVariableTables() do
        list( varType )
    end
end

function SimpleCalc:ApplyVariables( str )
    str = StrItemCountSub(str)
    for _,varType in self:getVariableTables() do
        for k, v in pairs( varType.list ) do
            str = StrVariableSub( str, k, v )
        end
    end
    return str
end

SimpleCalc:RegisterEvent("ADDON_LOADED")
SimpleCalc:SetScript("OnEvent", function(self, ...) self:OnEvent(...) end)
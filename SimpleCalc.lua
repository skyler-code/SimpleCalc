-- Initialize SimpleCalc
local addonName = ...
local SimpleCalc = CreateFrame( 'Frame', addonName )
local scversion = GetAddOnMetadata( addonName, 'Version' )

local ITEM_LINK_STR_MATCH = "item[%-?%d:]+"

-- Output errors
local function Error( message )
    DEFAULT_CHAT_FRAME:AddMessage( '['.. addonName ..']: ' .. message, 0.8, 0.2, 0.2 )
end

-- Output messages
local function Message( message )
    DEFAULT_CHAT_FRAME:AddMessage( '['.. addonName ..']: ' .. message, 0.5, 0.5, 1 )
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
    local _, count = str:gsub(ITEM_LINK_STR_MATCH, '')
    for i = 1, count do
        local itemLink = str:match(ITEM_LINK_STR_MATCH)
        if itemLink then
            local itemCount = GetItemCount(itemLink, true)
            str = str:gsub(itemLink, itemCount)
        end
    end
    str = UnescapeStr(str)
    return str
end

local function StrVariableSub( str, k, v )
    return str:gsub( '%f[%a_]' .. k .. '%f[^%a_]', v )
end

local function Usage()
    Message( addonName .. ' (v' .. scversion .. ') - Simple mathematical calculator' )
    Message( 'Usage: /calc <value> <symbol> <value>' )
    Message( 'Example: /calc 1650 + 2200 - honor' )
    Message( 'value - A numeric or game value (honor, maxhonor, health, mana (or power), copper, silver, gold)' )
    Message( 'symbol - A mathematical symbol (+, -, /, *)' )
    Message( 'variable - A name to store a value under for future use' )
    Message( 'Use /calc listvar to see your saved variables' )
    Message( 'Use /calc clearvar <global(g) | char(c) | all> to clear your saved variables. Defaults to all.' )
    Message( 'Use /calc addvar for info how to add variables' )
end

local function AddVarUsage()
    Message( 'Usage: /calc addvar <global(g)|char(c)> <variable> = <value|variable|expression>' )
    Message( 'Example: /calc addvar g mainGold = gold' )
    Message( 'Note: Character variables are prioritized over global when evaluating expressions.' )
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
        table.insert( a, n .. " = " .. exV )
    end
    table.sort( a )
    return a
end

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local function GetMaxLevel()
    if GetMaxLevelForPlayerExpansion then
        return GetMaxLevelForPlayerExpansion()
    end
    if MAX_PLAYER_LEVEL_TABLE and GetServerExpansionLevel then
        return MAX_PLAYER_LEVEL_TABLE[GetServerExpansionLevel()]
    end
    return 60
end

function SimpleCalc:OnLoad()
    -- Register our slash commands
    local slashCommands = { addonName:lower(), "calc" }
    for k, v in pairs(slashCommands) do
        _G["SLASH_"..addonName:upper()..k] = "/" .. v
    end
    SlashCmdList[addonName:upper()] = function(...) self:ParseParameters(...) end

    -- Initialize our variables
    SimpleCalc_CharVariables = SimpleCalc_CharVariables or {}
    calcVariables = calcVariables or {}
    
    SimpleCalc_LastResult = SimpleCalc_LastResult or 0

    -- Let the user know we're here
    Message( 'v' .. scversion .. ' initiated! Type: /calc for help.' )
end

function SimpleCalc:OnEvent(event, eventAddon)
    if event == "ADDON_LOADED" and eventAddon == addonName then
        self:OnLoad()
        self:UnregisterEvent("ADDON_LOADED")
    end
end

function SimpleCalc:GetVariables()
    local p = "player"
    local variables = {
        armor     = function() return select(3, UnitArmor(p)) end,
        hp        = function() return UnitHealthMax(p) end,
        power     = function() return UnitPowerMax(p) end,
        copper    = function() return GetMoney() end,
        silver    = function() return GetMoney() / 100 end,
        gold      = function() return GetMoney() / 10000 end,
        maxxp     = function() return UnitXPMax(p) end,
        xp        = function() return UnitXP(p) end,
        xpleft    = function() if UnitLevel(p) == GetMaxLevel() then return 0 end return UnitXPMax(p) - UnitXP(p) end,
        last      = function() return SimpleCalc_LastResult end,
    }
    variables.health = variables.hp
    variables.mana = variables.power

    if isRetail then
        local CURRENCY_IDS = {
            garrison  = 824,
            orderhall = 1220,
            resources = 1560,
            oil       = 1101,
            dubloon   = 1710,
            stygia    = 1767,
            anima     = Constants.CurrencyConsts.CURRENCY_ID_RESERVOIR_ANIMA,
            ash       = 1828, 
            honor     = Constants.CurrencyConsts.HONOR_CURRENCY_ID,
            conquest  = Constants.CurrencyConsts.CONQUEST_CURRENCY_ID,
        }
        for k, v in pairs( CURRENCY_IDS ) do
            variables[k] = function()
                local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(v) or {}
                return currencyInfo.quantity or 0
            end
        end
        variables.achieves = GetTotalAchievementPoints
        variables.ilvl = function() return ("%.2f"):format(select(2, GetAverageItemLevel())) end
        for k,v in pairs({CURRENCY_IDS.conquest, CURRENCY_IDS.honor}) do
            local pvpInfo = C_CurrencyInfo.GetCurrencyInfo(v) or {}
            local pvpName = string.lower(pvpInfo.name or "")
            variables['max'..pvpName] = function() return C_CurrencyInfo.GetCurrencyInfo(v).maxQuantity end
            variables[pvpName..'left'] = function()
                local pInfo = C_CurrencyInfo.GetCurrencyInfo(v)
                return pInfo.maxQuantity - pInfo.quantity
            end
        end
    else
        for i = 1, 5 do
            variables[string.lower(_G["SPELL_STAT"..i.."_NAME"])] = function() return select(2, UnitStat(p, i)) or 0 end
        end
    end

    return variables
end

-- Parse any user-passed parameters
function SimpleCalc:ParseParameters( paramStr )
    local lowerParam = paramStr:lower()
    local i = 0
    local addVar, calcVariable, varIsGlobal, clearVar, clearGlobal, clearChar

    if lowerParam == '' or lowerParam == 'help' then
        return Usage()
    end

    for param in lowerParam:gmatch( '[^%s]+' ) do -- This loops through the user input (stuff after /calc). We're going to be checking for arguments such as 'help' or 'addvar' and acting accordingly.
        if i == 0 then
            if param == 'addvar' then
                addVar = true
            elseif param == 'listvar' then
                self:ListVariables()
                return
            elseif param == 'clearvar' then
                clearVar = true
            end
        end
        if addVar then -- User entered addvar so let's loop through the rest of the params.
            if i == 1 then
                if param == 'global' or param == 'g' then
                    varIsGlobal = true
                elseif param ~= 'char' and param ~= 'c' then
                    Error( 'Invalid input: ' .. param )
                    AddVarUsage()
                    return
                end
            elseif i == 2 then -- Should be variable name
                if param:match( '[^a-z]' ) then
                    Error( 'Invalid input: ' .. param )
                    Error( 'Variable name can only contain letters!' )
                    return
                else
                    calcVariable = param
                end
            elseif i == 3 then -- Should be '='
                if param ~= '=' then
                    Error( 'Invalid input: ' .. param )
                    Error( 'You must use an equals sign!' )
                    return
                end
            elseif i == 4 then -- Should be number
                local newParamStr = param
                if newParamStr:match( '[a-z]' ) then
                    newParamStr = self:ApplyVariables( newParamStr )
                end
                local evalParam = EvalString( newParamStr )
                if not tonumber( evalParam ) then
                    Error( 'Invalid input: ' .. param )
                    Error( 'Variables can only be set to numbers or existing variables!' )
                else
                    local saveLocation, saveLocationStr = SimpleCalc_CharVariables, '[Character] '
                    if varIsGlobal then
                        saveLocation, saveLocationStr = calcVariables, '[Global] '
                    end
                    if evalParam ~= 0 then
                        saveLocation[calcVariable] = evalParam
                        Message( saveLocationStr .. 'set \'' .. calcVariable .. '\' to ' .. evalParam )
                    else -- Variables set to 0 are just wiped out
                        saveLocation[calcVariable] = nil
                        Message( saveLocationStr .. 'Reset variable: ' .. calcVariable )
                    end
                end
                return
            end
        elseif clearVar then
            if i == 1 then
                if param == 'global' or param == 'g' then
                    clearGlobal = true
                elseif param == 'char' or param == 'c' then
                    clearChar = true
                end
            end
        end
        i = i + 1
    end

    if addVar then -- User must have just typed /calc addvar so we'll give them a usage message.
        AddVarUsage()
        return
    end

    if clearVar then
        if clearGlobal then
            calcVariables = {}
            Message( 'Global user variables cleared!' )
        elseif clearChar then
            SimpleCalc_CharVariables = {}
            Message( 'Character user variables cleared!' )
        else
            calcVariables, SimpleCalc_CharVariables = {}, {}
            Message( 'All user variables cleared!' )
        end
        return
    end

    local paramEval = lowerParam

    if paramEval:match( '^[%%%+%-%*%^%/]' ) then
        paramEval = format( '%s%s', SimpleCalc_LastResult, paramEval )
        paramStr = format( '%s%s', SimpleCalc_LastResult, paramStr )
    end

    if paramEval:match( '[a-z]' ) then
        paramEval = self:ApplyVariables( paramEval )
    end

    if paramEval:match( '[a-z]' ) then
        Error( 'Unrecognized variable!' )
        Error( paramEval )
        return
    end

    paramEval = paramEval:gsub( '%s+', '' ) -- Clean up whitespace
    local evalStr = EvalString( paramEval )

    if evalStr then
        Message( paramEval .. ' = ' .. evalStr )
        SimpleCalc_LastResult = evalStr
    else
        Error( 'Could not evaluate expression! Maybe an unrecognized symbol?' )
        Error( paramEval )
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
        Message( returnStr )
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
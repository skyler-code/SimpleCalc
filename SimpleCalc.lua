-- Initialize SimpleCalc
local addonName = GetAddOnInfo("SimpleCalc")
local SimpleCalc = CreateFrame( 'Frame', addonName, UIParent )
local scversion = GetAddOnMetadata( addonName, 'Version' )


local CURRENCY_IDS = {
    garrison  = 824,
    orderhall = 1220,
    resources = 1560,
    oil       = 1101,
    dubloon   = 1710
}

function SimpleCalc:OnLoad()
    -- Register our slash commands
    SLASH_SIMPLECALC1 = '/simplecalc';
    SLASH_SIMPLECALC2 = '/calc';
    SlashCmdList['SIMPLECALC'] = function(...) self:ParseParameters(...); end

    -- Initialize our variables
    if ( not SimpleCalc_CharVariables ) then
        SimpleCalc_CharVariables = {};
    end
    if ( not calcVariables ) then
        calcVariables = {};
    end
    if ( not SimpleCalc_LastResult ) then
        self:setLastResult(0)
    else
        self:setLastResult(SimpleCalc_LastResult);
    end

    self:InitializeVariables()

    -- Let the user know we're here
    self:Message( 'v' .. scversion .. ' initiated! Type: /calc for help.' );
end

function SimpleCalc:OnEvent(event, eventAddon)
    if event == "ADDON_LOADED" and eventAddon == addonName then
        self:OnLoad()
    end
end

function SimpleCalc:InitializeVariables()
    local p = "player"
    self.variables = {
        achieves  = function() return GetTotalAchievementPoints() end,
        maxhonor  = function() return UnitHonorMax(p) end,
        maxhonour = function() return UnitHonorMax(p) end,
        honorLeft = function() return UnitHonorMax(p) - UnitHonor(p) end,
        health    = function() return UnitHealthMax(p) end,
        hp        = function() return UnitHealthMax(p) end,
        power     = function() return UnitPowerMax(p) end,
        mana      = function() return UnitPowerMax(p) end,
        copper    = function() return GetMoney() end,
        silver    = function() return GetMoney() / 100 end,
        gold      = function() return GetMoney() / 10000 end,
        maxxp     = function() return UnitXPMax(p) end,
        xp        = function() return UnitXP(p) end,
        xpleft    = function() return UnitXPMax(p) - UnitXP(p) end,
        ap        = function() return select(1, self:getAzeritePower()) or 0 end,
        apmax     = function() return select(2, self:getAzeritePower()) or 0 end,
        apleft    = function() local tXP, nRC = self:getAzeritePower(); return nRC - tXP end,
        last      = function() return self.lastResult end
    }

    for k, v in pairs( CURRENCY_IDS ) do
        self.variables[k] = function() return select(2, GetCurrencyInfo( v )) or 0 end
    end

end

-- Parse any user-passed parameters
function SimpleCalc:ParseParameters( paramStr )
    local lowerParam = paramStr:lower();
    local i = 0;
    local addVar, calcVariable, varIsGlobal, clearVar, clearGlobal, clearChar;

    if ( lowerParam == '' or lowerParam == 'help' ) then
        self:Usage();
        return;
    end

    for param in lowerParam:gmatch( '[^%s]+' ) do -- This loops through the user input (stuff after /calc). We're going to be checking for arguments such as 'help' or 'addvar' and acting accordingly.
        if ( i == 0 ) then
            if ( param == 'addvar' ) then
                addVar = true;
            elseif ( param == 'listvar' ) then
                self:ListVariables();
                return;
            elseif ( param == 'clearvar' ) then
                clearVar = true;
            end
        end
        if ( addVar ) then -- User entered addvar so let's loop through the rest of the params.
            if ( i == 1 ) then
                if ( param == 'global' or param == 'g' ) then
                    varIsGlobal = true;
                elseif ( param ~= 'char' and param ~= 'c' ) then
                    self:Error( 'Invalid input: ' .. param );
                    self:AddVarUsage();
                    return;
                end
            elseif ( i == 2 ) then -- Should be variable name
                if ( param:match( '[^a-z]' ) ) then
                    self:Error( 'Invalid input: ' .. param );
                    self:Error( 'Variable name can only contain letters!' );
                    return;
                else
                    calcVariable = param;
                end
            elseif ( i == 3 ) then -- Should be '='
                if ( param ~= '=' ) then
                    self:Error( 'Invalid input: ' .. param );
                    self:Error( 'You must use an equals sign!' );
                    return;
                end
            elseif ( i == 4 ) then -- Should be number
                local newParamStr = param;
                if ( newParamStr:match( '[a-z]' ) ) then
                    newParamStr = self:ApplyVariables( newParamStr );
                end
                local evalParam = self:EvalString( newParamStr );
                if ( not tonumber( evalParam ) ) then
                    self:Error( 'Invalid input: ' .. param );
                    self:Error( 'Variables can only be set to numbers or existing variables!' );
                else
                    local saveLocation, saveLocationStr = SimpleCalc_CharVariables, '[Character] ';
                    if ( varIsGlobal ) then
                        saveLocation, saveLocationStr = calcVariables, '[Global] '
                    end
                    if ( evalParam ~= 0 ) then
                        saveLocation[calcVariable] = evalParam;
                        self:Message( saveLocationStr .. 'set \'' .. calcVariable .. '\' to ' .. evalParam );
                    else -- Variables set to 0 are just wiped out
                        saveLocation[calcVariable] = nil;
                        self:Message( saveLocationStr .. 'Reset variable: ' .. calcVariable );
                    end
                end
                return;
            end
        elseif ( clearVar ) then
            if ( i == 1 ) then
                if ( param == 'global' or param == 'g' ) then
                    clearGlobal = true;
                elseif ( param == 'char' or param == 'c' ) then
                    clearChar = true;
                end
            end
        end
        i = i + 1;
    end

    if ( addVar ) then -- User must have just typed /calc addvar so we'll give them a usage message.
        self:AddVarUsage();
        return;
    end

    if ( clearVar ) then
        if ( clearGlobal ) then
            calcVariables = {};
            self:Message( 'Global user variables cleared!' );
        elseif ( clearChar ) then
            SimpleCalc_CharVariables = {};
            self:Message( 'Character user variables cleared!' );
        else
            calcVariables, SimpleCalc_CharVariables = {}, {};
            self:Message( 'All user variables cleared!' );
        end
        return;
    end

    local paramEval = lowerParam;

    if ( paramEval:match( '^[%%%+%-%*%^%/]' ) ) then
        paramEval = format( '%s%s', self.lastResult, paramEval );
        paramStr = format( '%s%s', self.lastResult, paramStr );
    end

    if ( paramEval:match( '[a-z]' ) ) then
        paramEval = self:ApplyVariables( paramEval );
    end

    if ( paramEval:match( '[a-z]' ) ) then
        self:Error( 'Unrecognized variable!' );
        self:Error( paramEval );
        return;
    end

    paramEval = paramEval:gsub( '%s+', '' ); -- Clean up whitespace
    local evalStr = self:EvalString( paramEval );

    if ( evalStr ) then
        self:Message( paramEval .. ' = ' .. evalStr )
        self:setLastResult(evalStr)
    else
        self:Error( 'Could not evaluate expression! Maybe an unrecognized symbol?' );
        self:Error( paramEval );
    end
end

function SimpleCalc:setLastResult(val)
    SimpleCalc_LastResult = val
    self.lastResult = val
end

function SimpleCalc:getVariableTables()
    local system = { type='System', list=self.variables };
    local global = { type='Global', list=calcVariables, showEmpty=true };
    local character = { type='Character', list=SimpleCalc_CharVariables, showEmpty=true };
    return ipairs( { system, global, character } )
end

function SimpleCalc:ListVariables()
    local function list( var )
        local returnStr;
        for _,k in ipairs( self:sortTableForListing( var['list'] ) ) do
            if ( not returnStr ) then
                returnStr = format( '%s variables: %s', var['type'], k );
            else
                returnStr = format( '%s, %s', returnStr, k );
            end
        end
        if( var['showEmpty'] and not returnStr) then
            returnStr = format( 'There are no %s user variables.', var['type']:lower() );
        end
        self:Message( returnStr );
    end
    for _,varType in self:getVariableTables() do
        list( varType );
    end
end

function SimpleCalc:ApplyVariables( str )
    for _,varType in self:getVariableTables() do
        for k, v in pairs( varType['list'] ) do
            str = self:strVariableSub( str, k, v );
        end
    end
    return str;
end

function SimpleCalc:getAzeritePower()
    if not C_AzeriteItem or not C_AzeriteItem.HasActiveAzeriteItem() then
        return 0, 0;
    end

    local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem();
    return C_AzeriteItem.GetAzeriteItemXPInfo( azeriteItemLocation );
end

function SimpleCalc:strVariableSub( str, k, v )
    return str:gsub( '%f[%a_]' .. k .. '%f[^%a_]', v );
end

function SimpleCalc:Usage()
    self:Message( addonName .. ' (v' .. scversion .. ') - Simple mathematical calculator' );
    self:Message( 'Usage: /calc <value> <symbol> <value>' );
    self:Message( 'Usage: /calc addvar <variable> = <value>' );
    self:Message( 'Example: 1650 + 2200 - honor' );
    self:Message( 'value - A numeric or game value (honor, maxhonor, health, mana (or power), copper, silver, gold)' );
    self:Message( 'symbol - A mathematical symbol (+, -, /, *)' );
    self:Message( 'variable - A name to store a value under for future use' );
    self:Message( 'Use /calc listvar to see SimpleCalc\'s and your saved variables' );
    self:Message( 'Use /calc clearvar <global(g)|char(c)|all> to clear your saved variables. Defaults to all.' );
end

function SimpleCalc:AddVarUsage()
    self:Message( 'Usage: /calc addvar <global(g)|char(c)> <variable> = <value|variable|expression>' );
    self:Message( 'Example: /calc addvar g mainGold = gold' );
    self:Message( 'Note: Character variables are prioritized over global when evaluating expressions.' );
end

-- Output errors
function SimpleCalc:Error( message )
    DEFAULT_CHAT_FRAME:AddMessage( '['.. addonName ..']: ' .. message, 0.8, 0.2, 0.2 );
end

-- Output messages
function SimpleCalc:Message( message )
    DEFAULT_CHAT_FRAME:AddMessage( '['.. addonName ..']: ' .. message, 0.5, 0.5, 1 );
end

function SimpleCalc:EvalString( str )
    local strFunc = loadstring( 'return ' .. str );
    if ( pcall( strFunc ) ) then
        return strFunc();
    end
    return nil;
end

function SimpleCalc:sortTableForListing( t ) -- https://www.lua.org/pil/19.3.html
    local a = {};
    for n, v in pairs( t ) do
        local exV = type(v) == "function" and v() or v
        table.insert( a, n .. " = " .. exV );
    end
    table.sort( a );
    return a;
end

SimpleCalc:RegisterEvent("ADDON_LOADED")
SimpleCalc:SetScript("OnEvent", SimpleCalc.OnEvent)
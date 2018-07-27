-- Initialize SimpleCalc
local SimpleCalc = CreateFrame( 'Frame', 'SimpleCalc', UIParent );
local scversion = GetAddOnMetadata( 'SimpleCalc', 'Version' );

local CURRENCY_IDS = {
    GARRISON = 824,
    ORDERHALL = 1220,
    RESOURCES = 1560
};

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
  
    -- Let the user know we're here
    self:Message( 'v' .. scversion .. ' initiated! Type: /calc for help.' );
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
        self:Message( paramStr .. ' = ' .. evalStr );
    else
        self:Error( 'Could not evaluate expression! Maybe an unrecognized symbol?' );
        self:Error( paramEval );
    end
end

function SimpleCalc:getSystemVariables()
    local tXP, nRC = self:getAzeritePower();
    local charGold = GetMoney();
    local charHonorMax = UnitHonorMax( 'player' );
    local charHonor = UnitHonor( 'player' );
    local charHP = UnitHealthMax( 'player' );
    local charMana = UnitPowerMax( 'player' );
    return {
        achieves   = GetTotalAchievementPoints(),
        maxhonor   = charHonorMax,
        maxhonour  = charHonorMax,
        honorleft  = charHonorMax - charHonor,
        honourleft = charHonorMax - charHonor,
        honor      = charHonor,
        honour     = charHonor,
        health     = charHP,
        hp         = charHP,
        power      = charMana,
        mana       = charMana,
        copper     = charGold,
        silver     = charGold / 100,
        gold       = charGold / 10000,
        maxxp      = UnitXPMax( 'player' ),
        xp         = UnitXP( 'player' ),
        ap         = tXP,
        apmax      = nRC,
        garrison   = self:getCurrencyAmount( CURRENCY_IDS.GARRISON ),
        orderhall  = self:getCurrencyAmount( CURRENCY_IDS.ORDERHALL ),
        resources  = self:getCurrencyAmount( CURRENCY_IDS.RESOURCES )
    };
end

function SimpleCalc:ListVariables()
    local systemVars, globalVars, userVars;
    local charVars = self:getSystemVariables();
    for k, v in pairs( charVars ) do
        if ( not systemVars ) then
            systemVars = format( 'System variables: %s = %s', k, v );
        else
            systemVars = format( '%s, %s = %s', systemVars, k, v );
        end
    end
    for k, v in pairs( calcVariables ) do
        if ( not globalVars ) then
            globalVars = format( 'Global user variables: %s = %s', k, v );
        else
            globalVars = format( '%s, %s = %s', globalVars, k, v );
        end
    end
    for k, v in pairs( SimpleCalc_CharVariables ) do
        if ( not userVars ) then
            userVars = format( 'Character user variables: %s = %s', k, v );
        else
            userVars = format( '%s, %s = %s', userVars, k, v );
        end
    end
    if ( not globalVars ) then
        globalVars = 'There are no global user variables.';
    end
    if ( not userVars ) then
        userVars = 'There are no character user variables.';
    end
    self:Message( systemVars );
    self:Message( globalVars );
    self:Message( userVars );
end

function SimpleCalc:ApplyVariables( str )
    local charVars = self:getSystemVariables();
    -- Apply reserved variables
    for k, v in pairs( charVars ) do
        str = self:strVariableSub( str, k, v );
    end
    -- Apply character user variables
    for k, v in pairs( SimpleCalc_CharVariables ) do
        str = self:strVariableSub( str, k, v );
    end
    -- Apply global user variables
    for k, v in pairs( calcVariables ) do
        str = self:strVariableSub( str, k, v );
    end
    return str;
end

function SimpleCalc:getCurrencyAmount( currencyID )
    local _, currencyAmount = GetCurrencyInfo( currencyID );
    return format( '%s', currencyAmount );
end

function SimpleCalc:getAzeritePower()
    if ( not C_AzeriteItem.HasActiveAzeriteItem() ) then
        return 0, 0;
    end

    local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem();
    return C_AzeriteItem.GetAzeriteItemXPInfo( azeriteItemLocation );
end

function SimpleCalc:strVariableSub( str, k, v )
    return str:gsub( '%f[%a_]' .. k .. '%f[^%a_]', v );
end

function SimpleCalc:Usage()
    self:Message( 'SimpleCalc (v' .. scversion .. ') - Simple mathematical calculator' );
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
    DEFAULT_CHAT_FRAME:AddMessage( '[SimpleCalc] ' .. message, 0.8, 0.2, 0.2 );
end

-- Output messages
function SimpleCalc:Message( message )
    DEFAULT_CHAT_FRAME:AddMessage( '[SimpleCalc]: ' .. message, 0.5, 0.5, 1 );
end

function SimpleCalc:EvalString( str )
    local strFunc = loadstring( 'return ' .. str );
    if ( pcall( strFunc ) ) then
        return strFunc();
    end
    return nil;
end

SimpleCalc:OnLoad();
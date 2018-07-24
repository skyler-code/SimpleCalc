-- Initialize SimpleCalc
scversion = GetAddOnMetadata( 'SimpleCalc', 'Version' );
local GARRISON_CURRENCY_ID = 824;
local ORDERHALL_CURRENCY_ID = 1220;
local RESOURCE_CURRENCY_ID = 1560;

function SimpleCalc_OnLoad()
    -- Register our slash commands
    SLASH_SIMPLECALC1 = '/simplecalc';
    SLASH_SIMPLECALC2 = '/calc';
    SlashCmdList['SIMPLECALC'] = SimpleCalc_ParseParameters;

    -- Initialize our variables
    if ( not SimpleCalc_CharVariables ) then
        SimpleCalc_CharVariables = {};
    end
    if ( not calcVariables ) then
        calcVariables = {};
    end
  
    -- Let the user know we're here
    SimpleCalc_Message( 'v' .. scversion .. ' initiated! Type: /calc for help.' );
end

-- Parse any user-passed parameters
function SimpleCalc_ParseParameters( paramStr )
    paramStr = paramStr:lower();
    local i = 0;
    local addVar, calcVariable, varIsGlobal, clearVar, clearGlobal, clearChar;
    local charVars = {
        [0]  = { achieves   = GetTotalAchievementPoints() },
        [1]  = { maxhonor   = UnitHonorMax( 'player' ) },
        [2]  = { maxhonour  = UnitHonorMax( 'player' ) },
        [3]  = { honor      = UnitHonor( 'player' ) },
        [4]  = { honour     = UnitHonor( 'player' ) },
        [5]  = { health     = UnitHealthMax( 'player' ) },
        [6]  = { hp         = UnitHealthMax( 'player' ) },
        [7]  = { power      = UnitPowerMax( 'player' ) },
        [8]  = { mana       = UnitPowerMax( 'player' ) },
        [9]  = { copper     = GetMoney() },
        [10] = { silver     = GetMoney() / 100 },
        [11] = { gold       = GetMoney() / 10000 },
        [12] = { maxxp      = UnitXPMax( 'player' ) },
        [13] = { xp         = UnitXP( 'player' ) },
        [14] = { garrison   = SimpleCalc_getCurrencyAmount( GARRISON_CURRENCY_ID ) },
        [15] = { orderhall  = SimpleCalc_getCurrencyAmount( ORDERHALL_CURRENCY_ID ) },
        [16] = { resources  = SimpleCalc_getCurrencyAmount( RESOURCE_CURRENCY_ID ) }
    }
    
    if ( paramStr == '' or paramStr == 'help' ) then
        SimpleCalc_Usage();
        return;
    end
    
    for param in paramStr:gmatch( '[^%s]+' ) do -- This loops through the user input (stuff after /calc). We're going to be checking for arguments such as 'help' or 'addvar' and acting accordingly.
        if ( i == 0 ) then
            if ( param == 'addvar' ) then
                addVar = true;
            elseif ( param == 'listvar' ) then
                SimpleCalc_ListVariables( charVars );
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
                    SimpleCalc_Error( 'Invalid input: ' .. param );
                    SimpleCalc_AddVarUsage();
                    return;
                end
            elseif ( i == 2 ) then -- Should be variable name
                if not ( param:match( '[a-zA-Z]+' ) ) then
                    SimpleCalc_Error( 'Invalid input: ' .. param );
                    SimpleCalc_Error( 'New variable must contain 1 letter!' );
                    return;
                else
                    calcVariable = param;
                end
            elseif ( i == 3 ) then -- Should be '='
                if ( param ~= '=' ) then
                    SimpleCalc_Error( 'Invalid input: ' .. param );
                    SimpleCalc_Error( 'You must use an equals sign!' );
                    return;
                end
            elseif ( i == 4 )then -- Should be number
                local newParamStr = SimpleCalc_ApplyVariables( param, charVars );
                local evalParam = SimpleCalc_EvalString( newParamStr );
                if ( not tonumber( evalParam ) ) then
                    SimpleCalc_Error( 'Invalid input: ' .. param );
                    SimpleCalc_Error( 'Variables can only be set to numbers or existing variables!' );
                else
                    local saveLocation, saveLocationStr = SimpleCalc_CharVariables, 'Character';
                    if ( varIsGlobal ) then
                        saveLocation, saveLocationStr = calcVariables, 'Global';
                    end
                    if ( evalParam ~= 0 ) then
                        saveLocation[calcVariable] = evalParam;
                        SimpleCalc_Message( '[' .. saveLocationStr .. '] ' .. 'set ' .. calcVariable .. ' to ' .. evalParam );
                    else -- Variables set to 0 are just wiped out
                        saveLocation[calcVariable] = nil;
                        SimpleCalc_Message( '[' .. saveLocationStr .. '] ' .. 'Reset variable: ' .. calcVariable );
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
        SimpleCalc_AddVarUsage();
        return;
    end

    if ( clearVar ) then
        if ( clearGlobal ) then
            calcVariables = {};
            SimpleCalc_Message( 'Global user variables cleared!' );
        elseif ( clearChar ) then
            SimpleCalc_CharVariables = {};
            SimpleCalc_Message( 'Character user variables cleared!' );
        else
            calcVariables, SimpleCalc_CharVariables = {}, {};
            SimpleCalc_Message( 'All user variables cleared!' );
        end
        return;
    end

    local paramEval = SimpleCalc_ApplyVariables( paramStr, charVars );
    
    if ( paramEval:match( '[a-zA-Z]+' ) ) then
        SimpleCalc_Error( 'Unrecognized variable!' );
        SimpleCalc_Error( paramEval );
        return;
    end
    
    paramEval = paramEval:gsub( '%s+', '' ); -- Clean up whitespace
    local evalStr = SimpleCalc_EvalString( paramEval );

    if ( evalStr ) then
        SimpleCalc_Message( paramStr .. ' = ' .. evalStr );
    else
        SimpleCalc_Error( 'Could not evaluate expression! Maybe an unrecognized symbol?' );
        SimpleCalc_Error( paramEval );
    end
end

function SimpleCalc_ListVariables( charVars )
    local systemVars, globalVars, userVars;
    for i = 0, #charVars, 1 do
        for k, v in pairs( charVars[i] ) do
            if ( i == 0 ) then
                systemVars = format( 'System variables: %s = %s', k, v );
            else
                systemVars = format( '%s, %s = %s', systemVars, k, v );
            end
        end
    end
    for k, v in pairs( calcVariables ) do
        if ( not globalVars ) then
            globalVars = format( 'Global user variables: %s = %s', k, v );
        else
            globalVars = format( '%s, %s = %s', userVars, k, v );
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
    SimpleCalc_Message( systemVars );
    SimpleCalc_Message( globalVars );
    SimpleCalc_Message( userVars );
end

function SimpleCalc_ApplyVariables( str, charVars )
    -- Apply reserved variables
    for i = 0, #charVars, 1 do
        for k, v in pairs( charVars[i] ) do
            if str:find( k ) then
                str = str:gsub( k, v );
            end
        end
    end
    -- Apply global user variables
    for k, v in pairs( calcVariables ) do
        str = str:gsub( k, v );
    end
    -- Apply character user variables
    for k, v in pairs( SimpleCalc_CharVariables ) do
        str = str:gsub( k, v );
    end
    return str;
end

function SimpleCalc_getCurrencyAmount( currencyID )
    local _, currencyAmount = GetCurrencyInfo( currencyID );
    return format( '%s', currencyAmount );
end

function SimpleCalc_Usage()
    SimpleCalc_Message( 'SimpleCalc (v' .. scversion .. ') - Simple mathematical calculator' );
    SimpleCalc_Message( 'Usage: /calc <value> <symbol> <value>' );
    SimpleCalc_Message( 'Usage: /calc addvar <variable> = <value>' );
    SimpleCalc_Message( 'Example: 1650 + 2200 - honor' );
    SimpleCalc_Message( 'value - A numeric or game value (honor, maxhonor, health, mana (or power), copper, silver, gold)' );
    SimpleCalc_Message( 'symbol - A mathematical symbol (+, -, /, *)' );
    SimpleCalc_Message( 'variable - A name to store a value under for future use' );
    SimpleCalc_Message( 'Use /calc listvar to see SimpleCalc\'s and your saved variables' );
    SimpleCalc_Message( 'Use /calc clearvar <global(g)|char(c)|all> to clear your saved variables. Defaults to all.' );
end

function SimpleCalc_AddVarUsage()
    SimpleCalc_Message( 'Usage: /calc addvar <global(g)|char(c)> <variable> = <value|variable|expression>' );
    SimpleCalc_Message( 'Example: /calc addvar g mainGold = gold' );
    SimpleCalc_Message( 'Note: Global variables are prioritized over the character\'s when evaluating expressions.' );
end

-- Output errors
function SimpleCalc_Error( message )
    DEFAULT_CHAT_FRAME:AddMessage( '[SimpleCalc] ' .. message, 0.8, 0.2, 0.2 );
end

-- Output messages
function SimpleCalc_Message( message )
    DEFAULT_CHAT_FRAME:AddMessage( '[SimpleCalc]: ' .. message, 0.5, 0.5, 1 );
end

function SimpleCalc_EvalString( str )
    local strFunc = loadstring( 'return ' .. str );
    if ( pcall( strFunc ) ) then
        return strFunc();
    else
        return false;
    end
end

local SimpleCalc = CreateFrame( 'Frame', 'SimpleCalc', UIParent );
SimpleCalc:SetScript( 'OnEvent', function() SimpleCalc_OnLoad() end );
SimpleCalc:RegisterEvent( 'PLAYER_LOGIN' );
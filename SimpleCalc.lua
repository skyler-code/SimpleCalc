-- Initialize SimpleCalc
scversion = GetAddOnMetadata( "SimpleCalc", "Version" );
local GARRISON_CURRENCY_ID = 824;
local ORDERHALL_CURRENCY_ID = 1220;
local RESOURCE_CURRENCY_ID = 1560;

function SimpleCalc_getCurrencyAmount( currencyID )
    local _, currencyAmount = GetCurrencyInfo( currencyID );
    return format( "%s", currencyAmount );
end

local CHARVARS = {
    [0]  = { achieves = GetTotalAchievementPoints() },
    [1]  = { maxhonor = UnitHonorMax( 'player' ) },
    [2]  = { maxhonour = UnitHonorMax( 'player' ) },
    [3]  = { honor = UnitHonor( 'player' ) },
    [4]  = { honour = UnitHonor( 'player' ) },
    [5]  = { health = UnitHealthMax( 'player' ) },
    [6]  = { hp = UnitHealthMax( 'player' ) },
    [7]  = { power = UnitPowerMax( 'player' ) },
    [8]  = { mana = UnitPowerMax( 'player' ) },
    [9]  = { copper = GetMoney() },
    [10] = { silver = GetMoney() / 100 },
    [11] = { gold = GetMoney() / 10000 },
    [12] = { maxxp= UnitXPMax( 'player' ) },
    [13] = { xp = UnitXP( 'player' ) },
    [14] = { garrison = SimpleCalc_getCurrencyAmount( GARRISON_CURRENCY_ID ) },
    [15] = { orderhall = SimpleCalc_getCurrencyAmount( ORDERHALL_CURRENCY_ID ) },
    [16] = { resources = SimpleCalc_getCurrencyAmount( RESOURCE_CURRENCY_ID ) }
}

function SimpleCalc_OnLoad()
    -- Register our slash commands
    SLASH_SIMPLECALC1 = "/simplecalc";
    SLASH_SIMPLECALC2 = "/calc";
    SlashCmdList["SIMPLECALC"] = SimpleCalc_ParseParameters;

    -- Initialize our variables
    if ( not calcVariables ) then
        calcVariables = {};
    end
  
    -- Let the user know we're here
    SimpleCalc_Message( "v" .. scversion .. " initiated! Type: /calc for help." );
end

-- Parse any user-passed parameters
function SimpleCalc_ParseParameters( paramStr )
    paramStr = string.lower( paramStr );
    local i = 0;
    local addVar = false;
    local calcVariable = "";
    
    if ( paramStr == "" or paramStr == "help" ) then
        SimpleCalc_Usage();
        return;
    end
    
    for param in string.gmatch( paramStr, "[^%s]+" ) do -- This loops through the user input (stuff after /calc). We're going to be checking for arguments such as "help" or "addvar" and acting accordingly.
        i = i + 1;
        if ( i == 1 ) then
            if ( param == "addvar" ) then
                addVar = true;
            elseif ( param == "listvar" ) then
                SimpleCalc_ListVariables();
                return;
            elseif ( param == "clearvar" ) then
                calcVariables = {};
                SimpleCalc_Message( "User variables cleared!" );
                return;
            end
        end
        if ( addVar ) then -- User entered addvar so let's loop through the rest of the params.
            if ( i == 2 ) then -- Should be variable name
                if not ( string.match( param, "[a-zA-Z]+" ) ) then
                    SimpleCalc_Error( "Invalid input: " .. param );
                    SimpleCalc_Error( "New variable must contain 1 letter!" );
                    return;
                else
                    calcVariable = param;
                end
            elseif ( i == 3 ) then -- Should be "="
                if not ( string.match( param, "=" ) ) then
                    SimpleCalc_Error( "Invalid input: " .. param );
                    SimpleCalc_Error( "You must use an equals sign!" );
                    return;
                end
            elseif ( i == 4 )then -- Should be number
                local newParamStr = SimpleCalc_ApplyVariables( param );
                local evalParam = SimpleCalc_EvalString( newParamStr );
                if ( tonumber( evalParam ) == nil ) then
                    SimpleCalc_Error( "Invalid input: " .. param );
                    SimpleCalc_Error( "Variables can only be set to numbers or existing variables!" );
                    return;
                else
                    if ( evalParam ~= 0 ) then
                        calcVariables[calcVariable] = {};
                        calcVariables[calcVariable][1] = calcVariable;
                        calcVariables[calcVariable][2] = evalParam;
                        SimpleCalc_Message( 'Set ' .. calcVariable .. ' to ' .. evalParam );
                        return;
                    else -- Variables set to 0 are just wiped out
                        calcVariables[calcVariable] = nil;
                        SimpleCalc_Message( 'Reset variable : ' .. calcVariable );
                        return;
                    end
                    addVar = false; -- This means there were no errors, so we'll reset.
                end
            end
        end
    end
    
    if ( addVar ) then -- User must have just typed /calc addvar so we'll give them a usage message.
        SimpleCalc_Message( "Usage: /calc addvar <variable> = <value>" );
        return;
    end

    local paramEval = SimpleCalc_ApplyVariables( paramStr );
    
    if ( string.match( paramEval, "[a-zA-Z]+" ) ) then
        SimpleCalc_Error( "Unrecognized variable!" );
        SimpleCalc_Error( paramEval );
        return;
    end
    
    paramEval = paramEval:gsub( "%s+", "" ); -- Clean up whitespace
    local evalStr = SimpleCalc_EvalString( paramEval );

    if ( evalStr ) then
        SimpleCalc_Message( paramStr .. " = " .. evalStr );
    else
        SimpleCalc_Error( "Could not evaluate expression! Maybe an unrecognized symbol?" );
        SimpleCalc_Error( paramEval );
    end
end

function SimpleCalc_ListVariables()
    local userVars = "";
    local systemVars = "";
    for i = 0, #CHARVARS, 1 do
        for k, v in pairs( CHARVARS[i] ) do
            if ( systemVars == "" ) then
                systemVars = format( "System variables: %s = %s", k, v );
            else
                systemVars = format( "%s, %s = %s", systemVars, k, v );
            end
        end
    end
    for i, calcVar in pairs( calcVariables ) do
        if( calcVar[1] and calcVar[2] ) then
            if ( userVars == "" ) then
                userVars = format( "User variables: %s = %s", calcVar[1], calcVar[2] );
            else
                userVars = format( "%s, %s = %s", userVars, calcVar[1], calcVar[2] );
            end
        end
    end
    SimpleCalc_Message( systemVars );
    if ( userVars == "" ) then
        userVars = "There are no user variables.";
    end
    SimpleCalc_Message( userVars );
end

function SimpleCalc_ApplyVariables( str )
    -- Apply reserved variables
    for i = 0, #CHARVARS, 1 do
        for k, v in pairs( CHARVARS[i] ) do
            if str:find( k ) then
                str = str:gsub( k, v );
            end
        end
    end
    -- Apply user variables
    for i, calcVar in pairs( calcVariables ) do
        if ( calcVar[1] and calcVar[2] ) then
            str = str:gsub( calcVar[1], calcVar[2] );
        end
    end
    return str;
end

function SimpleCalc_Usage()
    SimpleCalc_Message( "SimpleCalc (v" .. scversion .. ") - Simple mathematical calculator" );
    SimpleCalc_Message( "Usage: /calc <value> <symbol> <value>" );
    SimpleCalc_Message( "Usage: /calc addvar <variable> = <value>" );
    SimpleCalc_Message( "Example: 1650 + 2200 - honor" );
    SimpleCalc_Message( "value - A numeric or game value (honor, maxhonor, health, mana (or power), copper, silver, gold)" );
    SimpleCalc_Message( "symbol - A mathematical symbol (+, -, /, *)" );
    SimpleCalc_Message( "variable - A name to store a value under for future use" );
    SimpleCalc_Message( "Use /calc listvar to see SimpleCalc's and your saved variables" );
    SimpleCalc_Message( "Use /calc clearvar to clear your saved variables" );
end

-- Output errors
function SimpleCalc_Error( message )
    DEFAULT_CHAT_FRAME:AddMessage( "[SimpleCalc] " .. message, 0.8, 0.2, 0.2 );
end

-- Output messages
function SimpleCalc_Message( message )
    DEFAULT_CHAT_FRAME:AddMessage( "[SimpleCalc] " .. message, 0.5, 0.5, 1 );
end

function SimpleCalc_EvalString( str )
    local strFunc = loadstring( "return " .. str );
    if ( pcall( strFunc ) ) then
        return strFunc();
    else
        return false;
    end
end

local SimpleCalc = CreateFrame( "Frame", "SimpleCalc", UIParent );
SimpleCalc:SetScript( "OnEvent", function() SimpleCalc_OnLoad() end );
SimpleCalc:RegisterEvent( "PLAYER_LOGIN" );
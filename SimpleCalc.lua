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
            if( param == "addvar" )then
                addVar = true;
            elseif( param == "listvar" )then
                SimpleCalc_Message( SimpleCalc_ListUserVariables() );
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
            elseif( i == 3 ) then -- Should be "="
                if not ( string.match( param, "=" ) ) then
                    SimpleCalc_Error( "Invalid input: " .. param );
                    SimpleCalc_Error( "You must use an equals sign!" );
                    return;
                end
            elseif( i == 4 )then -- Should be number
                local evalParam = SimpleCalc_EvalString( param );
                if ( tonumber( evalParam ) == nil ) then
                    SimpleCalc_Error( "Invalid input: " .. param );
                    SimpleCalc_Error( "Variables can only be set to numbers!" );
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
        SimpleCalc_Message("Usage: /calc addvar <variable> = <value>");
        return;
    end

    local paramEval = SimpleCalc_ApplyReservedVariables( paramStr );
    paramEval = SimpleCalc_ApplyUserVariables( paramEval );
    
    if( string.match( paramEval, "[a-zA-Z]+") ) then
        SimpleCalc_Error( "Unrecognized variable!" );
        SimpleCalc_Error( paramEval );
        return;
    end
    
    paramEval = paramEval:gsub( "%s+", "" ); -- Clean up whitespace
    paramEval = SimpleCalc_EvalString( paramEval );
    
    SimpleCalc_Message( paramStr .. " = " ..paramEval );
end

function SimpleCalc_ListUserVariables()
    local listStr = "";
    for i,calcVar in pairs( calcVariables ) do
        if( calcVar[1] and calcVar[2] ) then
            if ( listStr == "" ) then
                listStr = format( "Saved Variables: %s = %s", calcVar[1], calcVar[2] );
            else
                listStr = format( "%s, %s = %s", listStr, calcVar[1], calcVar[2] );
            end
        end
    end
    return listStr;
end

function SimpleCalc_ApplyReservedVariables(str)
    for i = 0, #CHARVARS, 1 do
        for k, v in pairs( CHARVARS[i] ) do
            if str:find( k ) then
                str = str:gsub( k, v );
            end
        end
    end
    return str;
end

function SimpleCalc_ApplyUserVariables( str )
    for i,calcVar in pairs( calcVariables ) do
        if( calcVar[1] and calcVar[2] ) then
            str = str:gsub( calcVar[1],calcVar[2] );
        end
    end
    return str;
end

-- Inform the user of our their options
function SimpleCalc_Usage()
    SimpleCalc_Message( "SimpleCalc (v" .. scversion .. ") - Simple mathematical calculator" );
    SimpleCalc_Message( "Usage: /calc <value> <symbol> <value>" );
    SimpleCalc_Message( "Usage: /calc addvar <variable> = <value>" );
    SimpleCalc_Message( "Example: 1650 + 2200 - honor" );
    SimpleCalc_Message( "value - A numeric or game value (honor, maxhonor, health, mana (or power), copper, silver, gold)" );
    SimpleCalc_Message( "symbol - A mathematical symbol (+, -, /, *)" );
    SimpleCalc_Message( "variable - A name to store a value under for future use" );
    SimpleCalc_Message( "Use /calc listvar to see your saved variables" );
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
    return assert( loadstring( "return " .. str ) )();
end

local SimpleCalc = CreateFrame( "Frame", "SimpleCalc", UIParent );
SimpleCalc:SetScript( "OnEvent", function() SimpleCalc_OnLoad() end );
SimpleCalc:RegisterEvent( "PLAYER_LOGIN" );
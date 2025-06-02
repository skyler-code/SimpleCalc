-- Initialize SimpleCalc
local addonName, addonTable = ...
local SimpleCalc = CreateFrame( 'Frame', addonName )
local scversion = C_AddOns.GetAddOnMetadata( addonName, 'Version' )

if scversion == "@project-version@" then
    scversion = "DevBuild"
end

local ITEM_LINK_STR_MATCH = "item[%-?%d:]+"

local DefaultDB = {
    global = {},
    profiles = {},
    lastResult = 0,
}

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
        str = str:gsub(itemLink, C_Item.GetItemCount(itemLink, true))
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
    if strFunc and pcall(strFunc) then
        return strFunc()
    end
end

local function SortTableForListing( t ) -- https://www.lua.org/pil/19.3.html
    local a = {}
    for n, v in pairs( t ) do
        local exV = type(v) == "function" and v() or v
        tinsert( a, n .. " = " .. exV )
    end
    table.sort( a )
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
                local item = Item:CreateFromEquipmentSlot(i)
                if item then
                    t = t + item:GetCurrentItemLevel()
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

    self.charKey = FULL_PLAYER_NAME:format(UnitName("player"), GetRealmName())

    if not SimpleCalcDB then
        SimpleCalcDB = DefaultDB
    end
    self.db = SimpleCalcDB
    self.pdb = self.db.profiles[self.charKey]
    if not self.db.profiles[self.charKey] then
        self.db.profiles[self.charKey] = {}
    end
    self.pdb = self.db.profiles[self.charKey]

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
        self.variables = {
            armor     = function() return select(3, UnitArmor("player")) end,
            hp        = function() return UnitHealthMax("player") end,
            power     = function() return UnitPowerMax("player") end,
            copper    = function() return GetMoney() end,
            silver    = function() return GetMoney() / 100 end,
            gold      = function() return GetMoney() / 10000 end,
            maxxp     = function() return UnitXPMax("player") end,
            ilvl      = GetPlayerItemLevel,
            xp        = function() return UnitXP("player") end,
            xpleft    = function() if UnitLevel("player") == GetMaxPlayerLevel() then return 0 end return UnitXPMax("player") - UnitXP("player") end,
            last      = function() return self.db.lastResult end,
        }

        self.variables.health = self.variables.hp
        self.variables.mana = self.variables.power

        for repIndex, repRequired in pairs({ [6] = 9000, [7] = 21000, [8] = 42000 } ) do
            self.variables[GetText("FACTION_STANDING_LABEL"..repIndex, 2):lower()] = function()
                return repRequired - (select(5,GetWatchedFactionInfo()) or 0)
            end
        end

        if LibStub then
            local Junker = LibStub("AceAddon-3.0"):GetAddon("Junker")
            if Junker and Junker.GetCurrentProfit then
                self.variables.profit = function()
                    return Junker:GetCurrentProfit()
                end
            end
        end

        if GetTotalAchievementPoints and GetTotalAchievementPoints() ~= nil then
            self.variables.achieves = GetTotalAchievementPoints
        end

        if addonTable.XPAC_VARIABLES then
            for k, v in pairs(addonTable.XPAC_VARIABLES) do
                self.variables[k] = v
            end
        end

        if addonTable.CURRENCY_IDS then
            for k, v in pairs( addonTable.CURRENCY_IDS ) do
                self.variables[k] = function()
                    return (C_CurrencyInfo.GetCurrencyInfo(v) or {}).quantity or 0
                end
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
                    local saveLocation, saveLocationStr = self.pdb, '[Character] '
                    if ( varIsGlobal ) then
                        saveLocation, saveLocationStr = self.db.global, '[Global] '
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
            SimpleCalcDB.global = {}
            print( 'Global user variables cleared!' )
        elseif ( clearChar ) then
            SimpleCalcDB.profiles[self.charKey] = {}
            print( 'Character user variables cleared!' )
        else
            SimpleCalcDB.global, SimpleCalcDB.profiles[self.charKey] = {}, {}
            print( 'All user variables cleared!' )
        end
        return
    end

    local paramEval = lowerParam;

    if ( paramEval:match( '^[%%%+%-%*%^%/]' ) ) then
        paramEval = format( '%s%s', self.db.lastResult, paramEval )
        input = format( '%s%s', self.db.lastResult, input )
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
        self.db.lastResult = evalStr
    else
        print( 'Could not evaluate expression! Maybe an unrecognized symbol?' )
        print( paramEval )
    end
end

function SimpleCalc:getVariableTables()
    local system = { type='System', list=self:GetVariables() }
    local global = { type='Global', list=self.db.global, showEmpty=true }
    local character = { type='Character', list=self.pdb, showEmpty=true }
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

function SimpleCalc:Calculate(input)
    return EvalString(self:ApplyVariables(input))
end

SimpleCalc:RegisterEvent("ADDON_LOADED")
SimpleCalc:SetScript("OnEvent", SimpleCalc.OnEvent)
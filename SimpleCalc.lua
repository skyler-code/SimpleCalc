-- Initialize SimpleCalc
local addonName = ...
local SimpleCalc = CreateFrame( 'Frame', addonName )
local scversion = GetAddOnMetadata( addonName, 'Version' )

local tinsert, tsort, pairs = tinsert, table.sort, pairs

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local ITEM_LINK_STR_MATCH = "item[%-?%d:]+"

local gprint = print
local function print(...)
    gprint("|cff33ff99["..addonName.."]|r:",...)
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

-- From AceConsole-3.0.lua

local function nils(n, ...)
	if n>1 then
		return nil, nils(n-1, ...)
	elseif n==1 then
		return nil, ...
	else
		return ...
	end
end

--- Retreive one or more space-separated arguments from a string.
-- Treats quoted strings and itemlinks as non-spaced.
-- @param str The raw argument string
-- @param numargs How many arguments to get (default 1)
-- @param startpos Where in the string to start scanning (default  1)
-- @return Returns arg1, arg2, ..., nextposition\\
-- Missing arguments will be returned as nils. 'nextposition' is returned as 1e9 at the end of the string.
function SimpleCalc:GetArgs(str, numargs, startpos)
	numargs = numargs or 1
	startpos = max(startpos or 1, 1)

	local pos=startpos

	-- find start of new arg
	pos = strfind(str, "[^ ]", pos)
	if not pos then	-- whoops, end of string
		return nils(numargs, 1e9)
	end

	if numargs<1 then
		return pos
	end

	-- quoted or space separated? find out which pattern to use
	local delim_or_pipe
	local ch = strsub(str, pos, pos)
	if ch=='"' then
		pos = pos + 1
		delim_or_pipe='([|"])'
	elseif ch=="'" then
		pos = pos + 1
		delim_or_pipe="([|'])"
	else
		delim_or_pipe="([| ])"
	end

	startpos = pos

	while true do
		-- find delimiter or hyperlink
		local ch,_
		pos,_,ch = strfind(str, delim_or_pipe, pos)

		if not pos then break end

		if ch=="|" then
			-- some kind of escape

			if strsub(str,pos,pos+1)=="|H" then
				-- It's a |H....|hhyper link!|h
				pos=strfind(str, "|h", pos+2)	-- first |h
				if not pos then break end

				pos=strfind(str, "|h", pos+2)	-- second |h
				if not pos then break end
			elseif strsub(str,pos, pos+1) == "|T" then
				-- It's a |T....|t  texture
				pos=strfind(str, "|t", pos+2)
				if not pos then break end
			end

			pos=pos+2 -- skip past this escape (last |h if it was a hyperlink)

		else
			-- found delimiter, done with this arg
			return strsub(str, startpos, pos-1), self:GetArgs(str, numargs-1, pos+1)
		end

	end

	-- search aborted, we hit end of string. return it all as one argument. (yes, even if it's an unterminated quote or hyperlink)
	return strsub(str, startpos), nils(numargs-1, 1e9)
end


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
    print( 'v' .. scversion .. ' initiated! Type: /calc for help.' )
end

function SimpleCalc:OnEvent(event, eventAddon)
    if event == "ADDON_LOADED" and eventAddon == addonName then
        self:OnLoad()
        self:UnregisterEvent("ADDON_LOADED")
    end
end

function SimpleCalc:GetVariables()
    local p = "player"
    if self.variables then return self.variables end
    self.variables = {
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
    self.variables.health = self.variables.hp
    self.variables.mana = self.variables.power

    if isRetail then
        local CURRENCY_IDS = {
            garrison  = 824,
            orderhall = 1220,
            resources = Constants.CurrencyConsts.WAR_RESOURCES_CURRENCY_ID,
            oil       = 1101,
            dubloon   = 1710,
            stygia    = 1767,
            anima     = Constants.CurrencyConsts.CURRENCY_ID_RESERVOIR_ANIMA,
            ash       = 1828, 
            honor     = Constants.CurrencyConsts.HONOR_CURRENCY_ID,
            conquest  = Constants.CurrencyConsts.CONQUEST_CURRENCY_ID,
        }
        for k, v in pairs( CURRENCY_IDS ) do
            self.variables[k] = function()
                local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(v) or {}
                return currencyInfo.quantity or 0
            end
        end
        self.variables.achieves = GetTotalAchievementPoints
        self.variables.ilvl = function() return ("%.2f"):format(select(2, GetAverageItemLevel())) end
        for k,v in pairs({CURRENCY_IDS.conquest, CURRENCY_IDS.honor}) do
            local pvpInfo = C_CurrencyInfo.GetCurrencyInfo(v) or {}
            local pvpName = string.lower(pvpInfo.name or "")
            self.variables['max'..pvpName] = function() return C_CurrencyInfo.GetCurrencyInfo(v).maxQuantity end
            self.variables[pvpName..'left'] = function()
                local pInfo = C_CurrencyInfo.GetCurrencyInfo(v)
                return pInfo.maxQuantity - pInfo.quantity
            end
        end
    else
        for i = 1, 5 do
            self.variables[string.lower(_G["SPELL_STAT"..i.."_NAME"])] = function() return select(2, UnitStat(p, i)) or 0 end
        end
    end

    return self.variables
end

-- Parse any user-passed parameters
function SimpleCalc:ParseParameters( input )
	local arg1, arg2, arg3, arg4, arg5 = self:GetArgs(input, 5, 1)

    if not arg1 or arg1:lower() == 'help' then
        return Usage()
    end

    arg1 = arg1:lower()

    if arg1 == "listvar" then
        return self:ListVariables()
    end

    if arg1 == "clearvar" then
        if arg2 == 'global' or arg2 == 'g' then
            calcVariables = {}
            print( 'Global user variables cleared!' )
        elseif arg2 == 'char' or arg2 == 'c' then
            SimpleCalc_CharVariables = {}
            print( 'Character user variables cleared!' )
        else
            calcVariables, SimpleCalc_CharVariables = {}, {}
            print( 'All user variables cleared!' )
        end
        return
    end

    if arg1 == 'addvar' then
        if not arg2 or not arg3 or not arg4 or not arg5 then
            return AddVarUsage()
        end
        arg2 = arg2:lower()
        arg3 = arg3:lower()
        arg4 = arg4:lower()
        arg5 = arg5:lower()

        if arg2 ~= 'global' and arg2 ~= 'g' and arg2 ~= 'char' and arg2 ~= 'c' then
            print( 'Invalid input: ' .. arg2 )
            return AddVarUsage()
        end

        if arg3:match( '[^a-z]' ) then
            print( 'Invalid input: ' .. arg3 )
            print( 'Variable name can only contain letters!' )
            return
        end

        if arg4 ~= '=' then
            print( 'Invalid input: ' .. arg4 )
            print( 'You must use an equals sign!' )
            return
        end

        if arg5:match( '[a-z]' ) then
            arg5 = self:ApplyVariables( arg5 )
        end
        local evalParam = EvalString( arg5 )
        if not tonumber( evalParam ) then
            print( 'Invalid input: ' .. arg5 )
            print( 'Variables can only be set to numbers or existing variables!' )
        else
            local saveLocation, saveLocationStr = SimpleCalc_CharVariables, '[Character] '
            if arg2 == 'global' or arg2 == 'g' then
                saveLocation, saveLocationStr = calcVariables, '[Global] '
            end
            if evalParam ~= 0 then
                saveLocation[arg3] = evalParam
                print( saveLocationStr .. 'set \'' .. arg3 .. '\' to ' .. evalParam )
            else -- Variables set to 0 are just wiped out
                saveLocation[arg3] = nil
                print( saveLocationStr .. 'Reset variable: ' .. arg3 )
            end
        end
        return
    end

    if arg1:match( '^[%%%+%-%*%^%/]' ) then
        arg1 = format( '%s%s', SimpleCalc_LastResult, arg1 )
        paramStr = format( '%s%s', SimpleCalc_LastResult, paramStr )
    end

    if arg1:match( '[a-z]' ) then
        arg1 = self:ApplyVariables( arg1 )
    end

    if arg1:match( '[a-z]' ) then
        print( 'Unrecognized variable!' )
        print( arg1 )
        return
    end

    arg1 = arg1:gsub( '%s+', '' ) -- Clean up whitespace
    local evalStr = EvalString( arg1 )

    if evalStr then
        print( arg1 .. ' = ' .. evalStr )
        SimpleCalc_LastResult = evalStr
    else
        print( 'Could not evaluate expression! Maybe an unrecognized symbol?' )
        print( arg1 )
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
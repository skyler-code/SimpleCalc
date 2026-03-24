-- Initialize SimpleCalc
local addonName, addonTable = ...
local SimpleCalc = {}
_G[addonName] = SimpleCalc

addonTable.playerClass = PlayerUtil.GetClassFile()

local printColor = CreateColor(0.2, 1.0, 0.6)
local gprint = print
local function print(...)
    gprint(printColor:WrapTextInColorCode(addonName)..":",...)
end

local Syndicator = Syndicator
local realmName
local function GetItemCount(itemLink)
    if Syndicator then
        local inventorySearch = Syndicator.API.GetInventoryInfoByItemLink(itemLink, false, true)
        if inventorySearch then
            realmName = realmName or GetNormalizedRealmName()
            local count = 0
            for _, v in ipairs(inventorySearch.characters) do
                if v.realmNormalized == realmName then
                    count = count + v.bags + v.bank
                end
            end
            return count
        end
        return 0
    else
        return C_Item.GetItemCount(itemLink, true)
    end
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
    for itemLink in str:gmatch("item[%-?%d:]+") do
        str = str:gsub(itemLink, GetItemCount(itemLink))
    end
    return UnescapeStr(str)
end

local function StrVariableSub(str, k, v)
    return str:gsub('%f[%a_]' .. k .. '%f[^%a_]', v)
end

local function Usage()
    local scversion = C_AddOns.GetAddOnMetadata(addonName, 'Version')
    if scversion == "@project-version@" then
        scversion = "DevBuild"
    end
    print(addonName .. ' (v' .. scversion .. ') - Simple mathematical calculator')
    print('Usage: /calc <value> <symbol> <value>')
    print('Example: /calc 1650 + 2200 - honor')
    print('value - A numeric or game value (honor, maxhonor, health, mana (or power), copper, silver, gold)')
    print('symbol - A mathematical symbol (+, -, /, *)')
    print('variable - A name to store a value under for future use')
    print('Use /calc listvar to see your saved variables')
    print('Use /calc clearvar <global(g) | char(c) | all> to clear your saved variables. Defaults to all.')
    print('Use /calc addvar for info how to add variables')
end

local function AddVarUsage()
    print('Usage: /calc addvar <global(g)|char(c)> <variable> = <value|variable|expression>')
    print('Example: /calc addvar g mainGold = gold')
    print('Note: Character variables are prioritized over global when evaluating expressions.')
end

local function EvalString(str)
    local success, eval = pcall(loadstring('return ' .. str))
    if success then
        return eval
    end
end

local function SortTableForListing(t) -- https://www.lua.org/pil/19.3.html
    local a = {}
    for n in pairs(t) do
        tinsert(a, n .. " = " .. GetValueOrCallFunction(t, n))
    end
    sort(a)
    return a
end

local function GetWatchedFactionData()
    if C_Reputation and C_Reputation.GetWatchedFactionData then
        return C_Reputation.GetWatchedFactionData()
    end
    local name, reaction, currentReactionThreshold, nextReactionThreshold, currentStanding, factionID = GetWatchedFactionInfo()
    if name then
        return {
            name = name,
            reaction = reaction,
            currentReactionThreshold = currentReactionThreshold,
            nextReactionThreshold = nextReactionThreshold,
            currentStanding = currentStanding,
            factionID = factionID
        }
    end
end

local scanTooltip
local function GetScanTooltip()
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", addonName.."ScanTooltip", nil, "GameTooltipTemplate")
        scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    return scanTooltip
end

function SimpleCalc:RegisterDB()
    self.charKey = FULL_PLAYER_NAME:format(UnitName("player"), GetRealmName())
    if not SimpleCalcDB then
        SimpleCalcDB = {
            global = {},
            profiles = {},
        }
    end
    self.db = SimpleCalcDB
    if not self.db.profiles[self.charKey] then
        self.db.profiles[self.charKey] = {
            lastResult = 0
        }
    end
    self.pdb = self.db.profiles[self.charKey] or {}
end

function SimpleCalc:OnLoad()
    -- Register our slash commands
    RegisterNewSlashCommand(function(...) self:ParseParameters(...) end, addonName, "calc")

    self:RegisterDB()
end

function SimpleCalc:GetVariables()
    if not self.variables then
        self.variables = {
            armor     = function() return select(3, UnitArmor("player")) end,
            hp        = function() return UnitHealthMax("player") end,
            power     = function() return UnitPowerMax("player") end,
            copper    = GetMoney,
            silver    = function() return GetMoney() / 100 end,
            gold      = function() return GetMoney() / 10000 end,
            ilvl      = function() return RoundToSignificantDigits((select(2, GetAverageItemLevel())), 2) end,
            xp        = function() return UnitXP("player") end,
            maxxp     = function() return UnitXPMax("player") end,
            xpleft    = function() return UnitLevel("player") < GetMaxPlayerLevel() and UnitXPMax("player") - UnitXP("player") or 0 end,
            last      = function() return self.pdb.lastResult or 0 end,
            repair    = function()
                            local totalRepair = 0
                            for invSlot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
                                local currentDurability, maxDurability = GetInventoryItemDurability(invSlot)
                                if currentDurability and currentDurability < maxDurability then
                                    totalRepair = totalRepair + select(3, GetScanTooltip():SetInventoryItem('player', invSlot, true))
                                end
                            end
                            return totalRepair / 10000
                        end
        }

        self.variables.health = self.variables.hp
        self.variables.mana = self.variables.power

        for repIndex, repRequired in pairs({ [5] = 3000, [6] = 9000, [7] = 21000, [8] = 42000 }) do
            self.variables[GetText("FACTION_STANDING_LABEL"..repIndex):lower()] = function()
                local watchedFaction = GetWatchedFactionData()
                if not watchedFaction then return 0 end
                return max(repRequired - watchedFaction.currentStanding, 0)
            end
        end

        EventUtil.ContinueOnAddOnLoaded("Junker", function()
            local Junker = LibStub("AceAddon-3.0"):GetAddon("Junker")
            if Junker and Junker.GetCurrentProfit then
                self.variables.profit = function()
                    return Junker:GetCurrentProfit()
                end
            end
        end)

        EventUtil.ContinueOnAddOnLoaded("RepBuddy", function()
            self.variables.repearnedtoday = function()
                local watchedFaction = GetWatchedFactionData()
                if not watchedFaction then return 0 end
                return LibStub("AceAddon-3.0"):GetAddon("RepBuddy"):GetTodaysFactionGains(watchedFaction.name)
            end
            self.variables.repearnedyesterday = function()
                local watchedFaction = GetWatchedFactionData()
                if not watchedFaction then return 0 end
                return LibStub("AceAddon-3.0"):GetAddon("RepBuddy"):GetYesterdaysFactionGains(watchedFaction.name)
            end
        end)

        if GetTotalAchievementPoints() ~= nil then
            self.variables.achieves = GetTotalAchievementPoints
        end

        MergeTable(self.variables, addonTable.XPAC_VARIABLES or {})

        if addonTable.CURRENCY_IDS then
            for k, v in pairs(addonTable.CURRENCY_IDS) do
                self.variables[k] = function()
                    return (C_CurrencyInfo.GetCurrencyInfo(v) or {}).quantity or 0
                end
            end
        end
    end
    return self.variables
end

-- Parse any user-passed parameters
function SimpleCalc:ParseParameters(input)
    local lowerParam = input:lower()
    local i = 0
    local addVar, calcVariable, varIsGlobal, clearVar, clearGlobal, clearChar

    if lowerParam == '' or lowerParam == 'help' then
        return Usage()
    end

    for param in lowerParam:gmatch('[^%s]+') do -- This loops through the user input (stuff after /calc). We're going to be checking for arguments such as 'help' or 'addvar' and acting accordingly.
        if i == 0 then
            if param == 'addvar' then
                addVar = true
            elseif param == 'listvar' then
                return self:ListVariables()
            elseif param == 'clearvar' then
                clearVar = true
            end
        end
        if addVar then -- User entered addvar so let's loop through the rest of the params.
            if i == 1 then
                if param == 'global' or param == 'g' then
                    varIsGlobal = true
                elseif param ~= 'char' and param ~= 'c' then
                    print('Invalid input: ' .. param)
                    AddVarUsage()
                    return
                end
            elseif i == 2 then -- Should be variable name
                if param:match('[^a-z]') then
                    print('Invalid input: ' .. param)
                    print('Variable name can only contain letters!')
                    return
                else
                    calcVariable = param;
                end
            elseif i == 3 then -- Should be '='
                if param ~= '=' then
                    print('Invalid input: ' .. param)
                    print('You must use an equals sign!')
                    return
                end
            elseif i == 4 then -- Should be number
                local newParamStr = param;
                if newParamStr:match('[a-z]') then
                    newParamStr = self:ApplyVariables(newParamStr)
                end
                local evalParam = EvalString(newParamStr)
                if not tonumber(evalParam) then
                    print('Invalid input: ' .. param)
                    print('Variables can only be set to numbers or existing variables!')
                else
                    local saveLocation, saveLocationStr = self.pdb, '[Character] '
                    if varIsGlobal then
                        saveLocation, saveLocationStr = self.db.global, '[Global] '
                    end
                    if evalParam ~= 0 then
                        saveLocation[calcVariable] = evalParam
                        print(saveLocationStr .. 'set \'' .. calcVariable .. '\' to ' .. evalParam)
                    else -- Variables set to 0 are just wiped out
                        saveLocation[calcVariable] = nil
                        print(saveLocationStr .. 'Reset variable: ' .. calcVariable)
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
        return AddVarUsage()
    end

    if clearVar then
        if clearGlobal then
            SimpleCalcDB.global = {}
            print('Global user variables cleared!')
        elseif clearChar then
            SimpleCalcDB.profiles[self.charKey] = {}
            print('Character user variables cleared!')
        else
            SimpleCalcDB.global, SimpleCalcDB.profiles[self.charKey] = {}, {}
            print('All user variables cleared!')
        end
        return
    end

    local paramEval = lowerParam;

    if paramEval:match('^[%%%+%-%*%^%/]') then
        paramEval = format('%s%s', self.pdb.lastResult or 0, paramEval)
        input = format('%s%s', self.pdb.lastResult or 0, input)
    end

    if paramEval:match('[a-z]') then
        paramEval = self:ApplyVariables(paramEval)
    end

    if paramEval:match('[a-z]') then
        print('Unrecognized variable!')
        print(paramEval)
        return
    end

    paramEval = paramEval:gsub('%s+', '') -- Clean up whitespace
    local evalStr = EvalString(paramEval)

    if evalStr then
        print(paramEval .. ' = ' .. evalStr)
        self.pdb.lastResult = evalStr
    else
        print('Could not evaluate expression! Maybe an unrecognized symbol?')
        print(paramEval)
    end
end

function SimpleCalc:GetVariableTables()
    local system = { type='System', list=self:GetVariables() }
    local global = { type='Global', list=self.db.global, showEmpty=true }
    local character = { type='Character', list=self.pdb, showEmpty=true }
    return pairs({ system, global, character })
end

function SimpleCalc:ListVariables()
    local function list(var)
        local returnStr
        for _,v in pairs(SortTableForListing(var.list)) do
            if returnStr then
                returnStr = format('%s, %s', returnStr, v)
            else
                returnStr = format('%s variables: %s', var.type, v)
            end
        end
        if var.showEmpty and not returnStr then
            returnStr = format('There are no %s user variables.', var.type:lower())
        end
        print(returnStr)
    end
    for _,varType in self:GetVariableTables() do
        list(varType)
    end
end

function SimpleCalc:ApplyVariables(str)
    str = StrItemCountSub(str)
    for _, varType in self:GetVariableTables() do
        for k, v in pairs(varType.list) do
            str = StrVariableSub(str, k, v)
        end
    end
    return str
end

function SimpleCalc:Calculate(input)
    return EvalString(self:ApplyVariables(input))
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    SimpleCalc:OnLoad()
end)
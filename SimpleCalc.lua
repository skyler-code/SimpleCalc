-- Initialise SimpleCalc
scversion = GetAddOnMetadata("SimpleCalc", "Version");
local GetEquippedArtifactInfo = _G.C_ArtifactUI.GetEquippedArtifactInfo
local GetCostForPointAtRank = _G.C_ArtifactUI.GetCostForPointAtRank

function SimpleCalc_OnLoad(self)
	-- Register our slash commands
	SLASH_SIMPLECALC1="/simplecalc";
	SLASH_SIMPLECALC2="/calc";
	SlashCmdList["SIMPLECALC"]=SimpleCalc_ParseParameters;

	-- Initialise our variables
	if (not calcVariables) then
		calcVariables={};
	end
  
	-- Let the user know that we're here
	DEFAULT_CHAT_FRAME:AddMessage("[+] SimpleCalc (v"..scversion..") initiated! Type: /calc for help.", 1, 1, 1);
end

-- Parse any user-passed parameters
function SimpleCalc_ParseParameters(paramStr)
	
	i=0;
	paramStr=string.lower(paramStr);
	addVar=false;
	calcVariable="";
	
	if(paramStr == "") then
		SimpleCalc_Usage();
		return;
	end
	
	for param in string.gmatch(paramStr, "[^%s]+") do -- This loops through the user input (stuff after /calc). We're going to be checking for arguments such as "help" or "addvar" and acting accordingly.
		i=i+1;
		if(i==1) then
			if(param=="help") then
				SimpleCalc_Usage();
				return;
			end
			if(param=="addvar")then
				addVar=true;
			end
		end
		if(addVar) then -- User entered addvar so let's loop through the rest of the params.
			if(i==2) then -- Should be variable name
				if not (string.match(param, "[a-zA-Z]+")) then
					SimpleCalc_Error("Invalid input: "..param);
					SimpleCalc_Error("New variable must contain 1 letter!");
					return;
				else
					calcVariable = param;
				end
			elseif(i==3) then -- Should be "="
				if not (string.match(param, "=")) then
					SimpleCalc_Error("Invalid input: "..param);
					SimpleCalc_Error("You must use an equals sign!");
					return;
				end
			elseif(i==4)then -- Should be number
				if (tonumber(param)==nil) then
					SimpleCalc_Error("Invalid input: "..param);
					SimpleCalc_Error("Variables can only be set to numbers!");
					return;
				else
					if (tonumber(param) ~= 0) then
						calcVariables[calcVariable]={};
						calcVariables[calcVariable][1]=calcVariable; 
						calcVariables[calcVariable][2]=param;
						SimpleCalc_Message('Set ' .. calcVariable .. ' to ' .. numberFormat(param));
						return;
					else -- Variables set to 0 are just wiped out
						calcVariables[calcVariable]=nil;
						SimpleCalc_Message('Unset variable : ' .. calcVariable);
						return;
					end
					addVar = false; -- This means there were no errors, so we'll reset.
				end
			
			end
		end
	end
	
	if(addVar) then -- User must have just typed /calc addvar so we'll give them a usage message.
		SimpleCalc_Message("Usage: /calc addvar <variable> = <value>");
		return;
	end

	paramEval = paramStr;
	paramEval = paramEval:gsub("achieves",GetTotalAchievementPoints());
	paramEval = paramEval:gsub("honor",UnitHonor('player'));
	paramEval = paramEval:gsub("honour",UnitHonor('player'));
	paramEval = paramEval:gsub("maxhonor",UnitHonorMax('player'));
	paramEval = paramEval:gsub("maxhonour",UnitHonorMax('player'));
	paramEval = paramEval:gsub("health",UnitHealthMax('player'));
	paramEval = paramEval:gsub("hp",UnitHealthMax('player'));
	paramEval = paramEval:gsub("power",UnitPowerMax('player'));
	paramEval = paramEval:gsub("mana",UnitPowerMax('player'));
	paramEval = paramEval:gsub("copper",GetMoney());
	paramEval = paramEval:gsub("silver",GetMoney() / 100);
	paramEval = paramEval:gsub("gold",GetMoney() / 10000);
	paramEval = paramEval:gsub("artifactpowermax",GetTotalAchievementPoints());
	paramEval = paramEval:gsub("artifactpower",getAPInfo("totalXP"));
	paramEval = paramEval:gsub("apmax",GetTotalAchievementPoints());
	paramEval = paramEval:gsub("ap",getAPInfo("nextRankCost"));
	paramEval = paramEval:gsub("xpmax",UnitXPMax('player'));
	paramEval = paramEval:gsub("xp",UnitXP('player'));
	for i,calcVar in pairs(calcVariables) do
		if(calcVar[1] and calcVar[2]) then
			paramEval = paramEval:gsub(calcVar[1],calcVar[2]);
		end
	end
	
	if(string.match(paramEval, "[a-zA-Z]+")) then 
		SimpleCalc_Error("Unrecognized variable!");
		SimpleCalc_Error(paramEval);
		return;
	end
	local result = evalString( paramEval, nil );
	SimpleCalc_Message(paramStr.." = "..result);
end

function getAPInfo(ap)
	if(GetEquippedArtifactInfo() == nil) then
		return 0;
	end
	local itemID, altItemID, name, icon, totalXP, pointsSpent = GetEquippedArtifactInfo()
	local pointsAvailable = 0
	local nextRankCost = GetCostForPointAtRank(pointsSpent + pointsAvailable) or 0
	while totalXP >= nextRankCost  do
		totalXP = totalXP - nextRankCost
		pointsAvailable = pointsAvailable + 1
		nextRankCost = GetCostForPointAtRank(pointsSpent + pointsAvailable) or 0
	end
	
	if(ap == "totalXP") then
		return totalXP;
	elseif(ap=="nextRankCost") then
		return nextRankCost;
	end
end

-- Inform the user of our their options
function SimpleCalc_Usage()
	SimpleCalc_Message("SimpleCalc (v"..scversion..") - Simple mathematical calculator");
	SimpleCalc_Message("Usage: /calc <value> <symbol> <value>");
	SimpleCalc_Message("Usage: /calc addvar <variable> = <value>");
	SimpleCalc_Message("Example: 1650 + 2200 - honor (note the spaces)");
	SimpleCalc_Message("value - A numeric or game value (honor, maxhonor, artifactpower, artifactpowermax, health, mana (or power), copper, silver, gold)");
	SimpleCalc_Message("symbol - A mathematical symbol (+, -, /, *, ^)");
	SimpleCalc_Message("variable - A name to store a value under for future use");
end

-- Output errors
function SimpleCalc_Error(message)
	DEFAULT_CHAT_FRAME:AddMessage("[SimpleCalc] " .. message, 0.8, 0.2, 0.2);
end


-- Output messages
function SimpleCalc_Message(message)
	DEFAULT_CHAT_FRAME:AddMessage("[SimpleCalc] " .. message, 0.5, 0.5, 1);
end


-- Number formatting function, taken from http://lua-users.org/wiki/FormattingNumbers
function numberFormat(amount)
	local formatted=amount;
	while true do  
		formatted, k=string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2');
		if (k==0) then
			break;
		end
	end
	return formatted;
end

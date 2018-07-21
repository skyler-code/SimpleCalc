-- Initialize SimpleCalc
scversion = GetAddOnMetadata("SimpleCalc", "Version");

function SimpleCalc_OnLoad(self)
	-- Register our slash commands
	SLASH_SIMPLECALC1="/simplecalc";
	SLASH_SIMPLECALC2="/calc";
	SlashCmdList["SIMPLECALC"]=SimpleCalc_ParseParameters;

	-- Initialize our variables
	if (not calcVariables) then
		calcVariables={};
	end
  
	-- Let the user know we're here
	DEFAULT_CHAT_FRAME:AddMessage("[+] SimpleCalc (v"..scversion..") initiated! Type: /calc for help.", 1, 1, 1);
end

-- Parse any user-passed parameters
function SimpleCalc_ParseParameters(paramStr)
	
	local i=0;
	local paramStr=string.lower(paramStr);
	local addVar=false;
	local calcVariable="";
	
	if(paramStr == "" or paramStr == "help") then
		SimpleCalc_Usage();
		return;
	end
	
	for param in string.gmatch(paramStr, "[^%s]+") do -- This loops through the user input (stuff after /calc). We're going to be checking for arguments such as "help" or "addvar" and acting accordingly.
		i=i+1;
		if(i==1) then
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
						SimpleCalc_Message('Set ' .. calcVariable .. ' to ' .. SimpleCalc_numberFormat(param));
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

	local paramEval = paramStr;
	local plr = 'player';
	local charVars = {
		[0]={achieves=GetTotalAchievementPoints()},
		[1]={maxhonor=UnitHonorMax(plr)},
		[2]={maxhonour=UnitHonorMax(plr)},
		[3]={honor=UnitHonor(plr)},
		[4]={honour=UnitHonor(plr)},
		[5]={health=UnitHealthMax(plr)},
		[6]={hp=UnitHealthMax(plr)},
		[7]={power=UnitPowerMax(plr)},
		[8]={mana=UnitPowerMax(plr)},
		[9]={rp=UnitPowerMax(plr)},
		[10]={rage=UnitPowerMax(plr)},
		[11]={copper=GetMoney()},
		[12]={silver=GetMoney()/100},
		[13]={gold=GetMoney()/10000},
		[14]={maxxp = UnitXPMax('player')},
		[15]={xp=UnitXP('player')},
		[16]={garrison=SimpleCalc_getCurrencyAmount(824)},
		[17]={orderhall=SimpleCalc_getCurrencyAmount(1220)},
		[18]={resources=SimpleCalc_getCurrencyAmount(1560)}
	}

	for i=0,#charVars,1 do
		for k, v in pairs(charVars[i]) do
			if paramEval:find(k) then
				paramEval = paramEval:gsub(k,v);
			end
		end
	end

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
	
	paramEval = paramEval:gsub("%s+", ""); -- Clean up whitespace
	paramEval = assert(loadstring("return " .. paramEval))();
	
	SimpleCalc_Message(paramStr.." = "..paramEval);
end

-- Inform the user of our their options
function SimpleCalc_Usage()
	SimpleCalc_Message("SimpleCalc (v"..scversion..") - Simple mathematical calculator");
	SimpleCalc_Message("Usage: /calc <value> <symbol> <value>");
	SimpleCalc_Message("Usage: /calc addvar <variable> = <value>");
	SimpleCalc_Message("Example: 1650 + 2200 - honor");
	SimpleCalc_Message("value - A numeric or game value (honor, maxhonor, artifactpower, artifactpowermax, health, mana (or power), copper, silver, gold)");
	SimpleCalc_Message("symbol - A mathematical symbol (+, -, /, *)");
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
function SimpleCalc_numberFormat(amount)
	local formatted=amount;
	while true do
		formatted, k=string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2');
		if (k==0) then
			break;
		end
	end
	return formatted;
end

function SimpleCalc_getCurrencyAmount(currencyID)
	local _, currencyAmount = GetCurrencyInfo(currencyID);
	return format("%s", currencyAmount);
end

function SimpleCalc_formatVariable(string, var, newVal)
	return string:gsub("achieves",GetTotalAchievementPoints());
end
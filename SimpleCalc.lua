-- Initialise SimpleCalc
scversion = GetAddOnMetadata("SimpleCalc", "Version");
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
  DEFAULT_CHAT_FRAME:AddMessage("[+] SimpleCalc (v "..scversion..") initiated! Type: /calc for help.", 1, 1, 1);

  -- Request Conquest Point info from server
  RequestPVPRewards()
end

-- Parse any user-passed parameters
function SimpleCalc_ParseParameters(paramStr)

  local params={};

  local i=0;
  local a=nil;
  local b=nil;
  local result=0;
  local paramCount=0;
  local GetArenaCurrency = function() return select(2,GetCurrencyInfo(390)) or 0 end
  local GetHonorCurrency = function() return select(2,GetCurrencyInfo(392)) or 0 end
  local GetJusticeCurrency = function() return select(2,GetCurrencyInfo(395)) or 0 end
  local GetValorCurrency = function() return select(2,GetCurrencyInfo(396)) or 0 end
  local GetValorCap = function() return select(5,GetCurrencyInfo(396))/100 - select(4,GetCurrencyInfo(396)) or 0 end
  local GetArenaCap = function() return select(2,GetPVPRewards()) - select(1,GetPVPRewards()) or 0 end
  RequestPVPRewards()

  paramStr=string.lower(paramStr);
  for param in string.gmatch(paramStr, "[^%s]+") do

    i=i+1;
    paramCount=paramCount+1;

    -- Make sure that we've been passed a number or a variable
    if (i==1 or i==3) then
      -- Take a copy of our parameter
      if (i==1) then
        paramOriginal=param;
      end
      -- Check whether we have a number
      if (string.match(param, '[^%d\.-]')) then
        -- If we have something other than a number, see whether it's a recognised game value
        if (param=='honour' or param=='honor') then
          param=GetHonorCurrency();
        elseif (param=='conquest' or param=='cp') then
          param=GetArenaCurrency();
		elseif (param=='jp' or param=='justice') then
		  param=GetJusticeCurrency();
		elseif (param=='valor' or param=='vp') then
		  param=GetValorCurrency();
		elseif (param=='vpcap') then
		  param=GetValorCap();
		elseif (param=='cpcap') then
		  param=GetArenaCap();
		elseif (param=='achieves' or param=='ap') then
		  param=GetTotalAchievementPoints();
        elseif (param=='health') then
          param=UnitHealthMax('player')
        elseif (param=='power' or param=='mana') then
          param=UnitPowerMax('player')
        elseif (param=='copper') then
          param=GetMoney();
        elseif (param=='silver') then
          param=GetMoney() / 100;
        elseif (param=='gold') then
          param=GetMoney() / 10000;
        elseif (calcVariables[param]) then  -- Check whether this is a user defined variable
          param=calcVariables[param];
        end
      end
    end

    if (i==1) then
      a=param;
    elseif (i==2) then
      symbol=param;
    elseif (i==3) then
      b=param;

      -- Make sure that we're dealing with numbers
      if (symbol~='=' and not tonumber(a)) then
        SimpleCalc_Error(paramStr .. ': \'' .. a .. '\' isn\'t a recognised variable, and doesn\'t look like a number!');
        return false
      elseif (symbol~='=' and not tonumber(b)) then
        SimpleCalc_Error(paramStr .. ': \'' .. b .. '\' isn\'t a recognised variable, and doesn\'t look like a number!');
        return false
      end

      -- Perform the operation
      -- Can't find any way around doing things this way...
      if (symbol=='+') then
        result=a + b;
      elseif (symbol=='-') then
        result=a - b;
      elseif (symbol=='*') then
        result=a * b;
      elseif (symbol=='/') then
        result=a / b;
      elseif (symbol=='^') then
        result=a ^ b;
      elseif (symbol=='=' and paramCount==3) then
        -- Make sure that we're dealing with a number
        if (tonumber(b)==nil) then
          SimpleCalc_Error('Can\'t set value \'' .. b .. '\' as it doesn\'t look like a number!');
          return false
        end
        calcVariable = paramOriginal;
        result = b;
      elseif (symbol=='=') then
        SimpleCalc_Error('When setting variables, the variable name must be the first parameter');
      else
        SimpleCalc_Error('Unrecognised symbol: ' .. symbol);
        if (symbol=='x') then
          SimpleCalc_Error('Perhaps you meant '*' (multiply)?');
        end
        return false;
      end

      -- Reset for another loop
      i=1;
      symbol=nil;
      a=result;
      b=nil;

    end

  end

  if (symbol and not b) then
    SimpleCalc_Error('Unbalanced parameter count. Trailing symbol: ' .. symbol .. '?');
  end

  if (paramCount >= 3) then
    if (not calcVariable) then
      SimpleCalc_Message(paramStr .. ' = ' .. numberFormat(result));
    elseif (calcVariable) then
      -- Show any calculations performed
      if (paramCount > 3) then
        paramStr=string.sub(paramStr, string.find(paramStr, '= ') + 2);
        SimpleCalc_Message(paramStr .. ' = ' .. numberFormat(result));
      end
      -- Set or unset the variable and inform the user
      if (result ~= 0) then
        calcVariables[calcVariable]=result;
        SimpleCalc_Message('Set ' .. calcVariable .. ' to ' .. numberFormat(result));
      else
        calcVariables[calcVariable]=nil;
        SimpleCalc_Message('Unset variable ' .. calcVariable);
      end
      calcVariable=nil;
    end
  elseif (calcVariables[paramStr]) then
    SimpleCalc_Message('Variable \'' .. paramStr .. '\' is set to ' .. numberFormat(calcVariables[paramStr]));
  else
    SimpleCalc_Usage();
  end

end


-- Inform the user of our their options
function SimpleCalc_Usage()
  SimpleCalc_Message("SimpleCalc (v "..scversion..") - Simple mathematical calculator");
  SimpleCalc_Message("Usage: /calc <value> <symbol> <value>");
  SimpleCalc_Message("Usage: /calc <variable> = <value>");
  SimpleCalc_Message("Example: 1650 + 2200 - honor (note the spaces)");
  SimpleCalc_Message("value - A numeric or game value (honor, conquest, valor, justice, health, mana (or power), copper, silver, gold)");
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
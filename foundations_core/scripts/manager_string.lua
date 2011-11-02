-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

--
--
--  EXISTENCE FUNCTIONS
--
--

function isWord(sWord, targetval)
	if sWord then
		if type(targetval) == "string" then
			if sWord == targetval then
				return true;
			end

		elseif type(targetval) == "table" then
			if contains(targetval, sWord) then
				return true;
			end
		end
	end
	
	return false;
end

function contains(set, item)
	for i = 1, #set do
		if set[i] == item then
			return true;
		end
	end
	return false;
end

function isNumberString(sWord)
	if sWord then
		if string.match(sWord, "^[%+%-]?%d+$") then
			return true;
		end
	end
	return false;
end

function isDiceString(sWord)
	if sWord then
		if string.match(sWord, "^[d%d%+%-]+$") then
			return true;
		end
	end
	return false;
end

--
--
-- PARSE FUNCTIONS
--
--

function parseWords(s, extra_delimiters)
	local delim = "^%w%+%-'’:";
	if extra_delimiters then
		delim = delim .. extra_delimiters;
	end
	return split(s, delim, true); 
end

-- 
-- SPLIT CLAUSES
--
-- The source string is divided into substrings as defined by the delimiters parameter.  
-- Each resulting string is stored in a table along with the start and end position of
-- the result string within the original string.  The result tables are combined into
-- a table which is then returned.
--
-- NOTE: Set trimspace flag to trim any spaces that trail delimiters before next result 
-- string
--

function split(sToSplit, sDelimiters, bTrimSpace)
	-- SETUP
	local aStrings = {};
	local aStringStats = {};
  	local sNextString = "";
	
  	-- BUILD DELIMITER PATTERN
  	local sDelimiterPattern = "[" .. sDelimiters .. "]+";
  	if bTrimSpace then
  		sDelimiterPattern = sDelimiterPattern .. "%s*";
  	end
  	
  	-- DEAL WITH LEADING/TRAILING SPACES
  	local nStringStart = 1;
  	local nStringEnd = #sToSplit;
  	if bTrimSpace then
  		_, nStringStart, nStringEnd = trimString(sToSplit);
  	end
  	
  	-- SPLIT THE STRING, BASED ON THE DELIMITERS
  	local nIndex = nStringStart;
  	local nDelimiterStart, nDelimiterEnd = string.find(sToSplit, sDelimiterPattern, nIndex);
  	while nDelimiterStart do
  		sNextString = string.sub(sToSplit, nIndex, nDelimiterStart - 1);
  		if sNextString ~= "" then
  			table.insert(aStrings, sNextString);
  			table.insert(aStringStats, {startpos = nIndex, endpos = nDelimiterStart});
  		end
  		
  		nIndex = nDelimiterEnd + 1;
  		nDelimiterStart, nDelimiterEnd = string.find(sToSplit, sDelimiterPattern, nIndex);
  	end
  	sNextString = string.sub(sToSplit, nIndex, nStringEnd);
	if sNextString ~= "" then
		table.insert(aStrings, sNextString);
		table.insert(aStringStats, {startpos = nIndex, endpos = nStringEnd + 1});
	end
	
	-- RESULTS
	return aStrings, aStringStats;
end

--
-- TRIM STRING
--
-- Strips any spacing characters from the beginning and end of a string.
--
-- The function returns the following parameters:
--   1. The trimmed string
--   2. The starting position of the trimmed string within the original string
--   3. The ending position of the trimmed string within the original string
--

function trimString(s)
	local pre_starts, pre_ends = string.find(s, "^%s+");
	local post_starts, post_ends = string.find(s, "%s+$");
	
	if pre_ends then
		s = string.gsub(s, "^%s+", "");
	else
		pre_ends = 0;
	end
	if post_starts then
		s = string.gsub(s, "%s+$", "");
	end
	
	return s, pre_ends + 1, pre_ends + #s;
end

--
--
--  CONVERSION FUNCTIONS
--
--

-- NOTE: Ignores negative dice references
function convertStringToDice(s)
	-- SETUP
	local dice = {};
	local modifier = 0;
	
	-- PARSING
	if s then
		for sign, v in string.gmatch(s, "([+-]?)([%wd]+)") do

			-- SIGN
			local signmultiplier = 1;
			if sign == "-" then
				signmultiplier = -1;
			end
			-- DIE REFERENCE
			local diecountstr, dietypestr = string.match(v, "^(%d*)([dD]%w+)");
			if dietypestr then
				dietypestr = "d"..string.upper(string.sub(dietypestr,2))
				local diecount = tonumber(diecountstr) or 1;
				for i = 1, diecount do
					table.insert(dice, dietypestr);
					if dietypestr == "d100" then
						table.insert(dice, "d10");
					end
				end

			-- OR ASSUME NUMBER REFERENCE
			else
				local num = tonumber(v) or 0;
				modifier = modifier + (signmultiplier * num);

			end
		end
	end
	
	-- RESULTS
	return dice, modifier;
end

function convertDiceToString(dice, mod, bSign)
	local s = "";
	
	if dice then
		local diecount = {};

		-- PARSING
		for k, v in pairs(dice) do
	
			-- DRAGINFO DIE INFORMATION IS TWO LEVELS
			if type(v) == "table" then
				for k2, v2 in pairs(v) do
					if diecount[v2] then
						diecount[v2] = diecount[v2] + 1;
					else
						diecount[v2] = 1;
					end
				end

			-- OUTPUT FROM DIEFIELD IS ONE LEVEL
			else
				if diecount[v] then
					diecount[v] = diecount[v] + 1;
				else
					diecount[v] = 1;
				end

			end
		end

		-- HANDLE d100 DICE
		if (diecount["d100"] and diecount["d10"]) then
			diecount["d10"] = diecount["d10"] - diecount["d100"];
			if diecount["d10"] < 0 then
				diecount["d10"] = 0;
			end
		end
		
		-- BUILD STRING
		for k, v in pairs(diecount) do
			if s ~= "" then
				s = s .. "+";
			end
			s = s .. v .. k;
		end
	end
	
	-- ADD OPTIONAL MODIFIER
	if mod then
		if mod > 0 then
			if s == "" and not bSign then
				s = s .. mod
			else
				s = s .. "+" .. mod;
			end
		elseif mod < 0 then
			s = s .. mod;
		end
	end
	
	-- RESULTS
	return s;
end

function convertDiceWordArrayToDiceString(aDice, bPenalty)
	
	-- BASIC CONVERSION
	local sDice = table.concat(aDice, "+");
	sDice = string.gsub(sDice, "%+%+", "+");
	sDice = string.gsub(sDice, "%+%-", "-");
	
	-- HANDLE PENALTY CONVERSION
	local sSign = string.sub(sDice, 1, 1);
	if bPenalty then
		if sSign == "-" then
			-- NOTHING
		elseif sSign == "+" then
			sDice = "-" .. string.sub(sDice, 2);
		else
			sDice = "-" .. sDice;
		end
	
	-- OTHERWISE, JUST CHECK FOR LEADING PLUS SIGN
	else
		if sSign == "+" then
			sDice = string.sub(sDice, 2);
		end
	end
	
	-- RESULTS
	return sDice;
end

function convertAbilityWordArrayToEffectString(aAbilities, bPenalty)
	
	-- SETUP
	local aResults = {};
	
	-- CONVERT EACH ABILITY
	for keyAbility, sAbility in pairs(aAbilities) do
		local sEffectAbility = "[";
		
		if bPenalty then
			sEffectAbility = sEffectAbility .. "-";
		else
			sEffectAbility = sEffectAbility .. "+";
		end
		
		if string.sub(sAbility, 1, 4) == "half" then
			sEffectAbility = sEffectAbility .. "H";
			sAbility = string.sub(sAbility, 5);
		elseif string.sub(sAbility, 1, 6) == "double" then
			sEffectAbility = sEffectAbility .. "2";
			sAbility = string.sub(sAbility, 7);
		end
		
		if sAbility == "level" then
			sEffectAbility = sEffectAbility .. "LVL";
		else
			sEffectAbility = sEffectAbility .. string.upper(string.sub(sAbility, 1, 3));
		end
		
		sEffectAbility = sEffectAbility .. "]";
		
		table.insert(aResults, sEffectAbility);
	end
	
	-- RESULTS
	return table.concat(aResults, " ");
end

--
-- EVAL DICE STRING
--
-- Evaluates a string that contains an arbitrary number of numerical terms and dice expressions
-- 
-- NOTE: Dice expressions are automatically evaluated randomly without rolling the 
-- physical dice on-screen, or ignored if the bAllowDice flag not set.
--

function evalDiceString(sDice, bAllowDice)
	local nTotal = 0;
	
	for sSign, sVal, sDieType in string.gmatch(sDice, "([%-%+]?)(%d+)d?(%d*)") do

		local nVal = tonumber(sVal) or 0;
		local nSubtotal = 0;

		if sDieType ~= "" then
			if bAllowDice then
				for i = 1, val do
					nSubtotal = nSubtotal + math.random(tonumber(sDieType) or 0);
				end
			end
		else
			nSubtotal = nVal;
		end

		if sSign == "-" then
			nSubtotal = 0 - nSubtotal;
		end
		
		nTotal = nTotal + nSubtotal;
	end
	
	return nTotal;
end

function evalDice(aDice, nMod, isCritical)
	local nTotal = 0;
	for keyDie, sDie in pairs(aDice) do
		local nDieSides = tonumber(string.match(sDie, "d(%d+)")) or 0;
		if nDieSides > 0 then
			if isCritical then
				nTotal = nTotal + nDieSides;
			else
				nTotal = nTotal + math.random(nDieSides);
			end
		end
	end
	if nMod then
		nTotal = nTotal + nMod;
	end
	return nTotal;
end


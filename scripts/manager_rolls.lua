-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- REGISTER A GENERAL HANDLER
	ChatManager.registerRollHandler("", processDiceLanded);
	
end

--function onClose()
	-- UNREGISTER A GENERAL HANDLER
	--ChatManager.unregisterRollHandler("", processDiceLanded);
	
	-- UNREGISTER SPECIFIC HANDLERS
	--ChatManager.unregisterRollHandler("save", processSaveRoll);
	--ChatManager.unregisterRollHandler("autosave", processSaveRoll);
	--ChatManager.unregisterRollHandler("recharge", processRechargeRoll);
--end

function processPercentiles(draginfo)
	local aDragDieList = draginfo.getDieList();
	if not aDragDieList then
		return nil;
	end

	local aD100Indexes = {};
	local aD10Indexes = {};
	for k, v in pairs(aDragDieList) do
		if v["type"] == "d100" then
			table.insert(aD100Indexes, k);
		elseif v["type"] == "d10" then
			table.insert(aD10Indexes, k);
		end
	end

	local nMaxMatch = #aD100Indexes;
	if #aD10Indexes < nMaxMatch then
		nMaxMatch = #aD10Indexes;
	end
	if nMaxMatch <= 0 then
		return aDragDieList;
	end
	
	local nMatch = 1;
	local aNewDieList = {};
	for k, v in pairs(aDragDieList) do
		if v["type"] == "d100" then
			if nMatch > nMaxMatch then
				table.insert(aNewDieList, v);
			else
				v["result"] = aDragDieList[aD100Indexes[nMatch]]["result"] + aDragDieList[aD10Indexes[nMatch]]["result"];
				table.insert(aNewDieList, v);
				nMatch = nMatch + 1;
			end
		elseif v["type"] == "d10" then
			local bInsert = true;
			for i = 1, nMaxMatch do
				if aD10Indexes[i] == k then
					bInsert = false;
				end
			end
			if bInsert then
				table.insert(aNewDieList, v);
			end
		else
			table.insert(aNewDieList, v);
		end
	end

	return aNewDieList;
end



function createRollMessage(draginfo, rSourceActor)
	-- UNPACK DATA
	local sType = draginfo.getType();
	local sDesc = draginfo.getDescription();

	-- DETERMINE META-ROLL MODIFIERS
	-- NOTE: SHOULD BE MUTUALLY EXCLUSIVE
	local isDiceTower = string.match(sDesc, "^%[TOWER%]");
	local isGMOnly = string.match(sDesc, "^%[GM%]");
	
	-- APPLY MOD STACK, IF APPROPRIATE
	if not isDiceTower and not (sType == "autosave") and not (sType == "recharge") then
		ModifierStack.applyToRoll(draginfo);
		sDesc = draginfo.getDescription();
	end

	-- DICE TOWER AND GM FLAG HANDLING
	if isDiceTower then
		-- MAKE SURE SOURCE ACTOR IS EMPTY
		rSourceActor = nil;
	elseif isGMOnly then
		-- STRIP GM FROM DESCRIPTION
		sDesc = string.sub(sDesc, 6);
	end

	-- Build the basic message to deliver
	local rMessage = ChatManager.createBaseMessage(rSourceActor);
	rMessage.text = rMessage.text .. sDesc;
	rMessage.dice = processPercentiles(draginfo) or {};
	rMessage.diemodifier = draginfo.getNumberData();
	
	-- Check to see if this roll should be secret (GM or dice tower tag)
	if isDiceTower then
		rMessage.dicesecret = true;
		rMessage.sender = "";
		rMessage.icon = "dicetower_icon";
	elseif isGMOnly then
		rMessage.dicesecret = true;
		rMessage.text = "[GM] " .. rMessage.text;
	elseif User.isHost() and OptionsManager.isOption("REVL", "off") then
		rMessage.dicesecret = true;
	end

	-- RETURN MESSAGE RECORD
	return rMessage;
end

function processDiceLanded(draginfo)
	-- Figure out what type of roll we're handling
	local dragtype = draginfo.getType();
	local dragdesc = draginfo.getDescription();
	
	-- Get actors
	local rSourceActor, rTargetActor = CombatCommon.getActionActors(draginfo);
	local bMultiRoll = false;
	

	-- BUILD THE BASIC ROLL MESSAGE
	local entry = createRollMessage(draginfo, rSourceActor);

	-- BUILD TOTALS AND HANDLE SPECIAL CONDITIONS FOR DAMAGE ROLLS
	local add_total = true;
	local total = 0;
	
		
	-- BUILD BASIC TOTAL FOR NON-DAMAGE ROLLS
	for i,d in ipairs(entry.dice) do
		total = total + d.result;
	end
	
	
	-- Add the roll modifier to the total
	total = total + entry.diemodifier;

				
	-- Add the total, if the auto-total option is on
	if OptionsManager.isOption("TOTL", "on") and add_total then
		entry.dicedisplay = 1;
	end
	local result_str = "";
	
	-- Add any special results
	if result_str ~= "" then
		entry.text = entry.text .. result_str;
	end

	-- Deliver the chat entry
	ChatManager.deliverMessage(entry);
		
	if dragtype == "init" then
		-- Set the initiative for this creature in the combat tracker
		if rSourceActor then
			NodeManager.set(rSourceActor.nodeCT, "initresult", "number", total);
		end
	end
end

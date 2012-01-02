-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

--
--  DATA STRUCTURES
--

-- rCreature
--		sType
--		sName
--		nodeCreature
--		sCreatureNode
--		nodeCT
-- 		sCTNode

-- rEffect
--		sName = ""
--		sExpire = ""
-- 		nInit = #
--		sSource = ""
--		nGMOnly = 0, 1
--		sApply = "", "once", "single"

--
--  GENERAL ACTIONS SUPPORT
--  (DRAG AND DOUBLE-CLICK)
--

function baseAction(actiontype, val, desc, dice, rSourceActor, rTargetActor)
	-- If no dice variable defined, then we want to use the default die (d20)
	if not dice then
		dice = { "d20" };
	end

	-- If empty dice set, then make it a d0 to hide GM rolls
	if dice and #dice == 0 then
		dice = { "d0" };
	end
	
	return desc, val, dice;
end

function dragAction(draginfo, actiontype, val, desc, rSourceActor, dice, isOverrideUserSetting)
	-- APPLY COMMON ACTION MODIFIERS
	desc, val, dice = baseAction(actiontype, val, desc, dice, rSourceActor, nil);
	
	-- HANDLE HIDDEN ROLLS
	if User.isHost() and OptionsManager.isOption("REVL", "off") then
		local isGMOnly = string.match(desc, "^%[GM%]");
		local isDiceTower = string.match(desc, "^%[TOWER%]");
		if not isGMOnly and not isDiceTower then
			desc = "[GM] " .. desc;
		end
	end
	
	-- Make sure we're on slot 1
	draginfo.setSlot(1);

	-- Set the drag type based on user settings and the information passed
	if OptionsManager.isOption("DRGR", "on") or isOverrideUserSetting then
		draginfo.setType(actiontype);
		draginfo.setDieList(dice);
	else
		draginfo.setType("number");
	end

	-- Set the description and modifier value
	draginfo.setDescription(desc);
	draginfo.setNumberData(val);

	-- If we have a node reference, then use it
	if rSourceActor then
		if rSourceActor.sCTNode ~= "" then
			draginfo.setShortcutData("combattracker_entry", rSourceActor.sCTNode);
		elseif rSourceActor.sCreatureNode ~= "" then
			if rSourceActor.sType == "pc" then
				draginfo.setShortcutData("charsheet", rSourceActor.sCreatureNode);
			elseif rSourceActor.sType == "npc" then
				draginfo.setShortcutData("npc", rSourceActor.sCreatureNode);
			end
		end
	end

	-- We've handled this drag scenario
	return true;
end

function dclkAction(actiontype, val, desc, rSourceActor, rTargetActor, dice, isOverrideUserSetting, other_custom)
	-- APPLY COMMON ACTION MODIFIERS
	desc, val, dice = baseAction(actiontype, val, desc, dice, rSourceActor, rTargetActor);
	
	-- Decide what to do based on user settings
	local opt_dclk = OptionsManager.getOption("DCLK");
	if opt_dclk ~= "on" and not isOverrideUserSetting then
		if opt_dclk == "mod" then
			ModifierStack.addSlot(desc, val);
		end
		return true;
	end

	-- HANDLE HIDDEN ROLLS
	if User.isHost() and OptionsManager.isOption("REVL", "off") then
		local isGMOnly = string.match(desc, "^%[GM%]");
		local isDiceTower = string.match(desc, "^%[TOWER%]");
		if not isGMOnly and not isDiceTower then
			desc = "[GM] " .. desc;
		end
	end
	
	-- If we have a node reference, then use it
	local custom = CombatCommon.buildCustomRollArray(rSourceActor, rTargetActor);
	if other_custom then
		for k,v in pairs(other_custom) do
			custom[k] = v;
		end
	end

	
	
	

		-- BASIC THROW THE DICE
		ChatManager.DieControlThrow(actiontype, val, desc, custom, dice);
	
	
	-- We've handled this double-click scenario
	return true;
end


--
--  EFFECT SUPPORT
--  (DRAG, DOUBLE-CLICK, ENCODE/DECODE)
--

function getEffectTargets(rActor, rEffect)
	local bSelfTargeted = false;
	if (rEffect and rEffect.sTargeting == "self") then
		bSelfTargeted = true;
	end
	
	local sTargetType, aTargets = TargetingManager.getTargets(rActor, bSelfTargeted);

	if sTargetType == "targetpc" then
		aTargets[1] = CombatCommon.getCTFromNode(aTargets[1]);
		if not aTargets[1] then
			ChatManager.SystemMessage("[ERROR] Self-targeting of effects requires PC to be added to combat tracker.");
			sTargetType = "";
		end
	end
	
	return sTargetType, aTargets;
end

function dragEffect(draginfo, rActor, rEffect)
	encodeEffectForDrag(draginfo, rActor, rEffect);
	return true;
end

function dclkEffect(rActor, rEffect, rTargetActor)
	local sTargetType = "targetct";
	local aTargets = {};
	if rTargetActor and rTargetActor.nodeCT then
		table.insert(aTargets, rTargetActor.sCTNode);
	else
		sTargetType, aTargets = getEffectTargets(rActor, rEffect);
	end

	if #aTargets > 0 then
		for keyTarget, sTargetNode in pairs(aTargets) do
			ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_APPLYEFF, 
					{sTargetNode, 
					rEffect.sName or "", 
					rEffect.sExpire or "", 
					rEffect.nInit or 0, 
					rEffect.sSource or "", 
					rEffect.nGMOnly or 0, 
					rEffect.sApply or ""});
		end
	else
		ChatManager.reportEffect(rEffect);
	end

	return true;
end

function encodeEffectAsText(rEffect, sTarget)
	local aMessage = {};
	
	if rEffect then
		if rEffect.nGMOnly == 1 then
			table.insert(aMessage, "[GM]");
		end
		table.insert(aMessage, "[EFFECT] " .. rEffect.sName .. " EXPIRES " .. rEffect.sExpire);
		if rEffect.nInit and StringManager.isWord(rEffect.sExpire, {"endnext", "start", "end" }) then
			table.insert(aMessage, "[INIT " .. rEffect.nInit .. "]");
		end
		if rEffect.sApply and rEffect.sApply ~= "" then
			table.insert(aMessage, "[" .. string.upper(rEffect.sApply) .. "]");
		end
		if sTarget then
			table.insert(aMessage, "[to " .. sTarget .. "]");
		end
		if rEffect.sSource and rEffect.sSource ~= "" then
			table.insert(aMessage, "[by " .. NodeManager.get(DB.findNode(rEffect.sSource), "name", "") .. "]");
		end
	end
	
	return table.concat(aMessage, " ");
end

function encodeEffectForDrag(draginfo, rActor, rEffect)
	if rEffect and rEffect.sName ~= "" then
		draginfo.setType("effect");
		draginfo.setDescription(rEffect.sName);

		draginfo.setSlot(1);
		draginfo.setStringData(rEffect.sName);
		
		draginfo.setSlot(2);
		draginfo.setStringData(rEffect.sExpire);
		draginfo.setNumberData(rEffect.nInit or 0);

		draginfo.setSlot(3);
		draginfo.setStringData(rEffect.sSource or "");
		draginfo.setNumberData(rEffect.nGMOnly or 0);
		
		draginfo.setSlot(4);
		draginfo.setStringData(rEffect.sApply or "");

		draginfo.setSlot(5);
		if Input.isShiftPressed() then
			local sTargetType, aTargets = getEffectTargets(rActor);
			draginfo.setStringData(table.concat(aTargets, "|"));
		end
		
	end
end

function decodeEffectFromDrag(draginfo)
	local rEffect = nil;
	
	if draginfo.getType() == "effect" then
		rEffect = {};

		draginfo.setSlot(1);
		rEffect.sName = draginfo.getStringData();
		
		draginfo.setSlot(2);
		rEffect.sExpire = draginfo.getStringData();
		local nTempInit = draginfo.getNumberData() or 0;
		draginfo.setSlot(3);
		local sEffectSource = draginfo.getStringData();
		if sEffectSource and sEffectSource ~= "" then
			rEffect.sSource = sEffectSource;
			rEffect.nInit = nTempInit;
		else
			rEffect.sSource = "";
			rEffect.nInit = 0;
		end
		rEffect.nGMOnly = draginfo.getNumberData() or 0;

		draginfo.setSlot(4);
		local sApply = draginfo.getStringData();
		if sApply and sApply ~= "" then
			rEffect.sApply = sApply;
		else
			rEffect.sApply = "";
		end
		
		draginfo.setSlot(5);
		local sThirdPartyTargets = draginfo.getStringData();
		if sThirdPartyTargets and sThirdPartyTargets ~= "" then
			rEffect.targets = StringManager.split(sThirdPartyTargets, "|");
		end
		
	elseif draginfo.getType() == "number" then
		local sDesc = draginfo.getDescription();
		local sEffectName, sEffectExpire = string.match(sDesc, "%[EFFECT%] (.+) EXPIRES ?(%a*)");
		if sEffectName and sEffectExpire then
			rEffect = {};
			
			rEffect.sName = sEffectName;
			rEffect.sExpire = sEffectExpire;
			
			rEffect.sSource = "";
			local sEffectInit = string.match(sDesc, "%[INIT (%d+)%]");
			if sEffectInit then
				rEffect.nInit = tonumber(sEffectInit) or 0;
			else
				rEffect.nInit = 0;
			end

			if string.match(sDesc, "%[GM%]") then
				rEffect.nGMOnly = 1;
			else
				rEffect.nGMOnly = 0;
			end

			if string.match(sDesc, "%[ONCE%]") then
				rEffect.sApply = "once";
			elseif string.match(sDesc, "%[SINGLE%]") then
				rEffect.sApply = "single";
			else
				rEffect.sApply = "";
			end
		end
	end
	
	return rEffect;
end

function buildInitRoll(rCreature, rInit)
	-- SETUP
	local dice = { "d20" };
	local mod = rInit.mod;
	
	-- BUILD THE OUTPUT
	local s = "Initiative";
			
	-- RESULTS
	return s, dice, mod;
end


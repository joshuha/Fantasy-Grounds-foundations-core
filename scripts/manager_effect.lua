-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function message(sMsg, nodeCTEntry, gmflag, target)
	-- ADD NAME OF CT ENTRY TO NOTIFICATION
	if nodeCTEntry then
		sMsg = sMsg .. " [on " .. NodeManager.get(nodeCTEntry, "name", "") .. "]";
	end

	-- BUILD MESSAGE OBJECT
	local msg = {font = "msgfont", icon = "indicator_effect", text = sMsg};
	
	-- DELIVER MESSAGE BASED ON TARGET AND GMFLAG
	if target then
		if msguser == "" then
			ChatManager.addMessage(msg);
		else
			ChatManager.deliverMessage(msg, msguser);
		end
	elseif gmflag then
		msg.text = "[GM] " .. msg.text;
		if User.isHost() then
			ChatManager.addMessage(msg);
		else
			ChatManager.deliverMessage(msg, User.getUsername());
		end
	else
		ChatManager.deliverMessage(msg);
	end
end

function parseEffect(s)
	local effectlist = {};
	
	local eff_clause;
	for eff_clause in string.gmatch(s, "([^;]*);?") do
		local words = StringManager.parseWords(eff_clause, "%[%]");
		if #words > 0 then
			local eff_type = string.match(words[1], "^([^:]+):");
			local eff_dice = {};
			local eff_mod = 0;
			local eff_remainder = {};
			local rem_index = 1;
			if eff_type then
				rem_index = 2;

				local valcheckstr = "";
				local type_remainder = string.sub(words[1], #eff_type + 2);
				if type_remainder == "" then
					valcheckstr = words[2] or "";
					rem_index = rem_index + 1;
				else
					valcheckstr = type_remainder;
				end
				
				if StringManager.isDiceString(valcheckstr) then
					eff_dice, eff_mod = StringManager.convertStringToDice(valcheckstr);
				elseif valcheckstr ~= "" then
					table.insert(eff_remainder, valcheckstr);
				end
			end
			
			for i = rem_index, #words do
				table.insert(eff_remainder, words[i]);
			end

			table.insert(effectlist, {type = eff_type or "", mod = eff_mod, dice = eff_dice, remainder = eff_remainder});
		end
	end
	
	return effectlist;
end

function rebuildParsedEffect(aEffectComps)
	local aEffect = {};
	
	for keyComp, rComp in ipairs(aEffectComps) do
		local aComp = {};
		if rComp.type ~= "" then
			table.insert(aComp, rComp.type .. ":");
		end

		local sDiceString = StringManager.convertDiceToString(rComp.dice, rComp.mod);
		if sDiceString ~= "" then
			table.insert(aComp, sDiceString);
		end
		
		for keyRemainder, sRemainder in ipairs(rComp.remainder) do
			table.insert(aComp, sRemainder);
		end
		
		table.insert(aEffect, table.concat(aComp, " "));
	end
	
	return table.concat(aEffect, "; ");
end

function getEffectsString(node_ctentry, bPublicOnly)
	-- Make sure we can get to the effects list
	local node_list_effects = NodeManager.createChild(node_ctentry, "effects");
	if not node_list_effects then
		return "";
	end

	-- Start with an empty effects list string
	local aOutputEffects = {};
	
	-- Iterate through each effect
	for k,v in pairs(node_list_effects.getChildren()) do
		if NodeManager.get(v, "isactive", 0) ~= 0 then
			local sLabel = NodeManager.get(v, "label", "");

			local bAddEffect = true;
			local bGMOnly = false;
			if sLabel == "" then
				bAddEffect = false;
			elseif NodeManager.get(v, "isgmonly", 0) == 1 then
				if User.isHost() and not bPublicOnly then
					bGMOnly = true;
				else
					bAddEffect = false;
				end
			end

			if bAddEffect then
				local aAddCompList = {};
				local bTargeted = false;
				local aEffectComps = EffectsManager.parseEffect(sLabel);
				for kEffectComp, vEffectComp in ipairs(aEffectComps) do
					if vEffectComp.type == "AFTER" then
						table.insert(aAddCompList, {type = "", mod = 0, dice = {}, remainder = {"[+]"}});
						break;
					elseif vEffectComp.remainder[1] == "TRGT" then
						bTargeted = true;
					else
						table.insert(aAddCompList, vEffectComp);
					end
				end
				
				if isTargetedEffect(v) then
					local sTargets = table.concat(getEffectTargets(v, true), ",");
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[TRGT: " .. sTargets .. "]"}});
				elseif bTargeted then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"TRGT"}});
				end
				local sApply = NodeManager.get(v, "apply", "");
				if sApply == "once" then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"ONCE"}});
				elseif sApply == "single" then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"SINGLE"}});
				end
				
				local sOutputLabel = rebuildParsedEffect(aAddCompList);
				if bGMOnly then
					sOutputLabel = "(" .. sOutputLabel .. ")";
				end

				table.insert(aOutputEffects, sOutputLabel);
			end
		end
	end
	
	-- Return the final effect list string
	return table.concat(aOutputEffects, " | ");
end

function isGMEffect(nodeActor, nodeEffect)
	local bGMOnly = false;
	if nodeEffect then
		bGMOnly = (NodeManager.get(nodeEffect, "isgmonly", 0) == 1);
	end
	if nodeActor then
		if (NodeManager.get(nodeActor, "type", "") ~= "pc") and 
				(NodeManager.get(nodeActor, "show_npc", 0) == 0) then
			bGMOnly = true;
		end
	end
	return bGMOnly;
end

function isTargetedEffect(nodeEffect)
	local bTargeted = false;

	if nodeEffect then
		local nodeTargetList = nodeEffect.getChild("targets");
		if nodeTargetList then
			if nodeTargetList.getChildCount() > 0 then
				bTargeted = true;
			end
		end
	end

	return bTargeted;	
end

function getEffectTargets(nodeEffect, bUseName)
	local aTargets = {};
	
	if nodeEffect then
		local nodeTargetList = nodeEffect.getChild("targets");
		if nodeTargetList then
			for keyTarget, nodeTarget in pairs(nodeTargetList.getChildren()) do
				local sNode = NodeManager.get(nodeTarget, "noderef", "");
				if bUseName then
					local nodeTargetCT = DB.findNode(sNode);
					table.insert(aTargets, NodeManager.get(nodeTargetCT, "name", ""));
				else
					table.insert(aTargets, sNode);
				end
			end
		end
	end

	return aTargets;
end

function removeEffect(nodeCTEntry, sEffPatternToRemove)
	-- VALIDATE
	if not nodeCTEntry or not sEffPatternToRemove then
		return;
	end

	-- GET EFFECTS LIST
	local nodeEffectsList = NodeManager.createChild(nodeCTEntry, "effects");
	if not nodeEffectsList then
		return;
	end

	-- COMPARE EFFECT NAMES TO EFFECT TO REMOVE
	for keyEffect, nodeEffect in pairs(nodeEffectsList.getChildren()) do
		local s = NodeManager.get(nodeEffect, "label", "");
		if string.match(s, sEffPatternToRemove) then
			nodeEffect.delete();
			return;
		end
	end
end

function addEffect(sUser, sIdentity, nodeCT, rNewEffect, sEffectTargetNode, bShowMsg)
	-- VALIDATE
	if not nodeCT or not rNewEffect or not rNewEffect.sName then
		return;
	end
	rNewEffect.sExpire = rNewEffect.sExpire or "";
	rNewEffect.nInit = rNewEffect.nInit or 0;
	
	-- GET EFFECTS LIST
	local sCTName = NodeManager.get(nodeCT, "name", "");
	local nodeEffectsList = NodeManager.createChild(nodeCT, "effects");
	if not nodeEffectsList then
		return;
	end
	
	-- TRACK ALTERNATE EFFECT APPLICATION MESSAGES
	local sMsg = "";
	
	-- PARSE NEW EFFECT
	local aNewEffectParse = parseEffect(rNewEffect.sName);
	
		if rNewEffect.sExpire == "" and StringManager.isWord(rNewEffect.sApply, {"once", "single"}) then
			rNewEffect.sExpire = "end";
			rNewEffect.nInit = nActiveInit;
		end
	
	
	-- CHECKS TO IGNORE NEW EFFECT (DUPLICATE, SHORTER, WEAKER)
	local nodeTargetEffect = nil;
	for k, v in pairs(nodeEffectsList.getChildren()) do
		-- PARSE EFFECT FROM LIST
		local sEffectName = NodeManager.get(v, "label", "");
		local sEffectExpire = NodeManager.get(v, "expiration", "");
		local nEffectInit = NodeManager.get(v, "effectinit", 0);

		local aEffectParse = parseEffect(sEffectName);

		-- CHECK FOR DUPLICATE OR SHORTER EFFECT
		-- NOTE: ONLY IF LABEL AND MODIFIER ARE THE SAME
		if sEffectName == rNewEffect.sName then
			-- COMPARE EXPIRATIONS
			local bLonger = false;
			if rNewEffect.sExpire == "" then
				if sEffectExpire ~= "" then
					bLonger = true;
				end
			elseif rNewEffect.sExpire == "endnext" then
				if StringManager.isWord(sEffectExpire, {"start", "end"}) then
					bLonger = true;
				elseif sEffectExpire == "endnext" then
					local nCurrentInit = NodeManager.get(CombatCommon.getActiveCT(), "initresult", 10000);
					if ((nEffectInit - nCurrentInit) * (rNewEffect.nInit - nCurrentInit) < 0) then
						if rNewEffect.nInit > nEffectInit then
							bLonger = true;
						end
					else
						if rNewEffect.nInit < nEffectInit then
							bLonger = true;
						end
					end
				end
			elseif StringManager.isWord(rNewEffect.sExpire, {"start", "end"}) then
				if StringManager.isWord(sEffectExpire, {"start", "end"}) then
					local nCurrentInit = NodeManager.get(CombatCommon.getActiveCT(), "initresult", 10000);
					local nCurrentValue = nCurrentInit * 3;

					local nEffectValue = nEffectInit * 3;
					if sEffectExpire == "start" then
						nEffectValue = nEffectValue + 1;
					elseif sEffectExpire == "end" then
						nEffectValue = nEffectValue - 1;
					end

					local nNewEffectValue = rNewEffect.nInit * 3;
					if rNewEffect.sExpire == "start" then
						nNewEffectValue = nNewEffectValue + 1;
					elseif rNewEffect.sExpire == "end" then
						nNewEffectValue = nNewEffectValue - 1;
					end
					
					if ((nEffectValue - nCurrentValue) * (nNewEffectValue - nCurrentValue) < 0) then
						if nNewEffectValue > nEffectValue then
							bLonger = true;
						end
					else
						if nNewEffectValue < nEffectValue then
							bLonger = true;
						end
					end
				end
			end
			
			-- IF LONGER EFFECT, THEN UPDATE EFFECT; OTHERWISE, NOTIFY AND EXIT
			if bLonger then
				nodeTargetEffect = v;
				sMsg = "Effect ['" .. rNewEffect.sName .."'] -> [REPLACED SHORTER] [on " .. sCTName .. "]";
				break;
			end

			message("Effect ['" .. rNewEffect.sName .. "'] -> [ALREADY EXISTS]", nodeCT, false, sUser);
			return;
		end
		
		
	end  -- END EFFECTS LOOP
	
	-- BLANK EFFECT CHECK
	if not nodeTargetEffect then
		for k, v in pairs(nodeEffectsList.getChildren()) do
			if NodeManager.get(v, "label", "") == "" then
				nodeTargetEffect = v;
				break;
			end
		end
	end
	
	-- CREATE EFFECT, IF ONE NOT PROVIDED
	if not nodeTargetEffect then
		nodeTargetEffect = NodeManager.createChild(nodeEffectsList);
	end
	
	-- ADD EFFECT DETAILS
	NodeManager.set(nodeTargetEffect, "label", "string", rNewEffect.sName);
	NodeManager.set(nodeTargetEffect, "expiration", "string", rNewEffect.sExpire);
	NodeManager.set(nodeTargetEffect, "effectinit", "number", rNewEffect.nInit);
	NodeManager.set(nodeTargetEffect, "isgmonly", "number", rNewEffect.nGMOnly);
	if rNewEffect.sApply then
		NodeManager.set(nodeTargetEffect, "apply", "string", rNewEffect.sApply);
	end

	-- BUILD MESSAGE
	local msg = {font = "msgfont", icon = "indicator_effect"};
	if sMsg ~= "" then
		msg.text = sMsg;
	else
		msg.text = "Effect ['" .. rNewEffect.sName .. "'] -> [to " .. sCTName .. "]";
	end
	
	-- HANDLE APPLIED BY SETTING
	if rNewEffect.sSource and rNewEffect.sSource ~= "" then
		NodeManager.set(nodeTargetEffect, "source_name", "string", rNewEffect.sSource);
		msg.text = msg.text .. " [by " .. NodeManager.get(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
	end
	
	-- HANDLE EFFECT TARGET SETTING
	if sEffectTargetNode and sEffectTargetNode ~= "" then
		TargetingManager.addTarget("host", nodeTargetEffect.getNodeName(), sEffectTargetNode);
	end
	
	-- SEND MESSAGE
	if bShowMsg then
		if isGMEffect(nodeCT, nodeTargetEffect) then
			if sUser == "" then
				msg.text = "[GM] " .. msg.text;
				ChatManager.addMessage(msg);
			elseif sUser ~= "" then
				ChatManager.addMessage(msg);
				ChatManager.deliverMessage(msg, sUser);
			end
		else
			ChatManager.deliverMessage(msg);
		end
	end
end

-- MAKE SURE AT LEAST ONE EFFECT REMAINS AFTER DELETING
function deleteEffect(nodeEffect)
	local nodeEffectList = nodeEffect.getParent();
	nodeEffect.delete();
	if nodeEffectList.getChildCount() == 0 then
		NodeManager.createChild(nodeEffectList);
	end
end

function expireEffect(nodeActor, nodeEffect, nExpireComponent, bOverride)
	-- VALIDATE
	if not nodeEffect then
		return false;
	end

	-- PARSE THE EFFECT
	local sEffect = NodeManager.get(nodeEffect, "label", "");
	local listEffectComp = parseEffect(sEffect);

	-- DETERMINE MESSAGE VISIBILITY
	local bGMOnly = isGMEffect(nodeActor, nodeEffect);

	-- CHECK FOR PARTIAL EXPIRATION
	if nExpireComponent > 0 then
		if #listEffectComp > 1 then
			table.remove(listEffectComp, nExpireComponent);

			local sNewEffect = rebuildParsedEffect(listEffectComp);
			NodeManager.set(nodeEffect, "label", "string", sNewEffect);

			message("Effect ['" .. sEffect .. "'] -> [SINGLE MOD USED]", nodeActor, bGMOnly);
			return true;
		end
	end
	
	-- CHECK FOR FOLLOW-ON
	local i = 1;
	while i <= #listEffectComp do
		if listEffectComp[i].type == "AFTER" then
			break;
		end
		i = i + 1;
	end
	
	-- IF WE HAVE FOLLOW-ON, THEN STRIP OUT EXPIRED PART OF EFFECT
	local sMsg = "";
	if i <= #listEffectComp and not bOverride then
		sMsg = "Effect ['" .. sEffect .. "'] -> [UPDATED]";

		local sNewExpiration = table.concat(listEffectComp[i].remainder, " ");
		local aNewEffectComp = {};
		for j = i + 1, #listEffectComp do
			table.insert(aNewEffectComp, listEffectComp[j]);
		end
		local sNewEffect = rebuildParsedEffect(aNewEffectComp);
		
		NodeManager.set(nodeEffect, "label", "string", sNewEffect);
		NodeManager.set(nodeEffect, "expiration", "string", sNewExpiration);

	-- IF NO FOLLOW-ON, THEN DELETE THE EFFECT
	else
		sMsg = "Effect ['" .. sEffect .. "'] -> [EXPIRED]";

		deleteEffect(nodeEffect);
	end

	-- SEND NOTIFICATION TO THE HOST
	message(sMsg, nodeActor, bGMOnly);
	return true;
end


function processEffects(nodeActorList, nodeCurrentActor, nodeNewActor)
	-- SETUP CURRENT AND NEW INITIATIVE VALUES
	local nCurrentInit = 10000;
	if nodeCurrentActor then
		nCurrentInit = NodeManager.get(nodeCurrentActor, "initresult", 0); 
	end
	local nNewInit = -10000;
	if nodeNewActor then
		nNewInit = NodeManager.get(nodeNewActor, "initresult", 0);
	end
	
	-- ITERATE THROUGH EACH ACTOR
	for keyActor, nodeActor in pairs(nodeActorList.getChildren()) do
		-- ITERATE THROUGH EACH EFFECT
		local nodeEffectList = nodeActor.getChild("effects");
		for keyEffect, nodeEffect in pairs(nodeEffectList.getChildren()) do
			-- MAKE SURE THE EFFECT IS ACTIVE
			if NodeManager.get(nodeEffect, "isactive", 0) == 1 then
			
				-- GET EFFECT DETAILS
				local sEffName = NodeManager.get(nodeEffect, "label", "");
				local sEffExp = NodeManager.get(nodeEffect, "expiration", "");
				local nEffInit = NodeManager.get(nodeEffect, "effectinit", "");
				
				-- HANDLE END OF TURN EFFECTS FOR CURRENT ACTOR
				local flagEndEffect = false;
				if sEffExp == "end" then
					if nEffInit <= nCurrentInit and nEffInit > nNewInit then
						expireEffect(nodeActor, nodeEffect, 0);
					end
				elseif sEffExp == "endnext" then
					if nEffInit <= nCurrentInit and nEffInit > nNewInit then
						NodeManager.set(nodeEffect, "expiration", "string", "end");
					end
				elseif sEffExp == "save" and nodeActor == nodeCurrentActor then
					makeEffectSave(nodeActor, nodeEffect);
				end
					
				-- HANDLE START OF TURN EFFECTS
				if sEffExp == "start" then
					if nEffInit < nCurrentInit and nEffInit >= nNewInit then
						expireEffect(nodeActor, nodeEffect, 0);
					end
				end
				
				
			end -- END ACTIVE EFFECT CHECK
		end -- END EFFECT LOOP
	end -- END ACTOR LOOP
end


function evalEffect(rActor, s)
	-- VALIDATE
	if not s then
		return "";
	end
	if not rActor then
		return s;
	end
	
	-- SETUP
	local aNewEffect = {};
	
	-- PARSE EFFECT STRING
	local aEffectComp = StringManager.split(s, ";", true);
	for keyComp, sComp in pairs(aEffectComp) do
		local aWords = StringManager.parseWords(sComp, "%[%]");
		
		if #aWords > 0 then
			if string.match(aWords[1], ":$") then
				local aTempWords = { aWords[1] };
				local nTotalMod = 0;
				
				local i = 2;
			
				while aWords[i] do
					table.insert(aTempWords, aWords[i]);
					
					i = i + 1;
				end
				
				if StringManager.isDiceString(aTempWords[2]) then
					if nTotalMod ~= 0 then
						local aTempDice, nTempMod = StringManager.convertStringToDice(aTempWords[2]);
						nTempMod = nTempMod + nTotalMod;
						aTempWords[2] = StringManager.convertDiceToString(aTempDice, nTempMod);
					end
				end

				table.insert(aNewEffect, table.concat(aTempWords, " "));
			else
				table.insert(aNewEffect, sComp);
			end
		end
	end
	
	return table.concat(aNewEffect, "; ");
end

function getEffectsByType(node_ctentry, effecttype, aFilter, rFilterActor, bTargetedOnly)
	-- GET EFFECTS LIST
	local node_list_effects = NodeManager.createChild(node_ctentry, "effects");
	if not node_list_effects then
		return {};
	end

	-- SETUP
	local results = {};
	
	-- SEPARATE FILTERS
	local aRangeFilter = {};
	local aOtherFilter = {};
	if aFilter then
		for k, v in pairs(aFilter) do
			if StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v);
			else
				table.insert(aOtherFilter, v);
			end
		end
	end
	
	-- DETERMINE WHETHER EFFECT COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETING
	local bTargetSupport = StringManager.isWord(effecttype, DataCommon.targetableeffectcomps);
	
	-- ITERATE THROUGH EFFECTS
	for k,v in pairs(node_list_effects.getChildren()) do
		-- MAKE SURE EFFECT IS ACTIVE
		if NodeManager.get(v, "isactive", 0) ~= 0 then
			-- PARSE EFFECT
			local sLabel = NodeManager.get(v, "label", "");
			local sApply = NodeManager.get(v, "apply", "");
			local effect_list = EffectsManager.parseEffect(sLabel);

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN GET ANY EFFECT TARGETS
			local aEffectTargets = {};
			if bTargetSupport then
				local nodeTargetList = v.getChild("targets");
				for keyTarget, nodeTarget in pairs(nodeTargetList.getChildren()) do
					table.insert(aEffectTargets, NodeManager.get(nodeTarget, "noderef", ""));
				end
			end

			-- LOOK THROUGH EFFECT CLAUSES FOR A TYPE (or TYPE/SUBTYPE) MATCH
			local nMatch = 0;
			for i = 1, #effect_list do
				
				-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
				if StringManager.contains({"AFTER", "FAIL"}, effect_list[i].type) then
					break;
				end

				-- STRIP OUT ENERGY OR BONUS TYPES FOR SUBTYPE COMPARISON
				local aEffectRangeFilter = {};
				local aEffectOtherFilter = {};
				for k2, v2 in pairs(effect_list[i].remainder) do
					if StringManager.contains(DataCommon.dmgtypes, v2) then
					elseif StringManager.contains(DataCommon.bonustypes, v2) then
					elseif StringManager.contains(DataCommon.rangetypes, v2) then
						table.insert(aEffectRangeFilter, v2);
					else
						table.insert(aEffectOtherFilter, v2);
					end
				end
			
				-- CHECK TO MAKE SURE THIS COMPONENT MATCHES THE ONE WE'RE SEARCHING FOR
				local comp_match = false;
				if effect_list[i].type == effecttype then
					comp_match = true;

					-- IF EFFECT TARGETED AND THIS COMPONENT SUPPORTS TARGETING,
					-- THEN ONLY APPLY IF TARGET ACTOR MATCHES
					if (#aEffectTargets > 0) then
						comp_match = false;
						if rFilterActor and rFilterActor.nodeCT then
							for keyTarget, sTargetNode in pairs(aEffectTargets) do
								if sTargetNode == rFilterActor.sCTNode then
									comp_match = true;
								end
							end
						end
					elseif bTargetedOnly then
						comp_match = false;
					end
				
					-- CHECK THE FILTERS
					if #aEffectRangeFilter > 0 then
						local bRangeMatch = false;
						for k2, v2 in pairs(aRangeFilter) do
							if StringManager.contains(aEffectRangeFilter, v2) then
								bRangeMatch = true;
								break;
							end
						end
						if not bRangeMatch then
							comp_match = false;
						end
					end
					if #aEffectOtherFilter > 0 then
						local bOtherMatch = false;
						for k2, v2 in pairs(aOtherFilter) do
							if StringManager.contains(aEffectOtherFilter, v2) then
								bOtherMatch = true;
								break;
							end
						end
						if not bOtherMatch then
							comp_match = false;
						end
					end
				end

				-- WE FOUND A MATCH
				if comp_match then
					nMatch = i;
					table.insert(results, effect_list[i]);
				end
			end -- END EFFECT COMPONENT LOOP

			-- REMOVE ONE-SHOT EFFECTS
			if nMatch > 0 then
				if sApply == "once" then
					ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_EXPIREEFF, {node_ctentry.getNodeName(), v.getNodeName(), 0});
				elseif sApply == "single" then
					ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_EXPIREEFF, {node_ctentry.getNodeName(), v.getNodeName(), nMatch});
				end
			end
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end


function isEffectTarget(nodeEffect, nodeTarget)
	local bMatch = false;
	
	if nodeEffect and nodeTarget then
		local nodeTargetList = nodeEffect.getChild("targets");
		if nodeTargetList then
			for k, v in pairs(nodeTargetList.getChildren()) do
				if NodeManager.get(v, "noderef", "") == nodeTarget.getNodeName() then
					bMatch = true;
					break;
				end
			end
		end
	end

	return bMatch;
end


function expireSingleEffects(nodeSourceActor, aEffects)
	if not aEffects then
		return;
	end
	
	for k,v in pairs(aEffects) do
		local sApply = NodeManager.get(v.node, "apply", "");
		if sApply == "once" then
			ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_EXPIREEFF, {nodeSourceActor.getNodeName(), v.node.getNodeName(), 0});
		elseif sApply == "single" then
			ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_EXPIREEFF, {nodeSourceActor.getNodeName(), v.node.getNodeName(), v.match or 0});
		end
	end
end


function hasEffect(nodeSourceActor, sEffect, nodeTargetActor, bTargetedOnly, bIgnoreEffectTargets)
	-- Parameter validation
	if not sEffect then
		return false;
	end
	
	-- Make sure we can get to the effects list
	local node_list_effects = NodeManager.createChild(nodeSourceActor, "effects");
	if not node_list_effects then
		return false;
	end

	-- Iterate through each effect
	local aMatch = {};
	for k,v in pairs(node_list_effects.getChildren()) do
		if NodeManager.get(v, "isactive", 0) ~= 0 then
			-- Parse each effect label
			local sLabel = NodeManager.get(v, "label", "");
			local effect_list = StringManager.split(sLabel, ";", true);
			local bTargeted = EffectsManager.isTargetedEffect(v);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for i = 1, #effect_list do
				if string.sub(effect_list[i], 1, 6) == "AFTER:" or string.sub(effect_list[i], 1, 5) == "FAIL:" then
					break;
				end
				
				if string.lower(effect_list[i]) == string.lower(sEffect) then
					if bTargeted and not bIgnoreEffectTargets then
						if nodeTargetActor then
							if isEffectTarget(v, nodeTargetActor) then
								table.insert(aMatch, v);
								nMatch = i;
							end
						end
					elseif not bTargetedOnly then
						table.insert(aMatch, v);
						nMatch = i;
					end
				end
				
			end
			
			-- If matched, then remove one-off effects
			if nMatch > 0 then
				local sApply = NodeManager.get(v, "apply", "");
				if sApply == "once" then
					ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_EXPIREEFF, {nodeSourceActor.getNodeName(), v.getNodeName(), 0});
				elseif sApply == "single" then
					ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_EXPIREEFF, {nodeSourceActor.getNodeName(), v.getNodeName(), nMatch});
				end
			end
		end
	end
	
	-- Return results
	if #aMatch > 0 then
		return true;
	end
	return false;
end

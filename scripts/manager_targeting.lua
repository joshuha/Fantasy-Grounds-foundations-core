-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function getTargets(rActor, bSelfTargeted)
	local sTargetType = "targetct";
	local aTargets = {};
	
	if rActor then
		-- CHECK SELF-TARGET MODIFIER KEY
		if (OptionsManager.isOption("SELF", "alt") and Input.isAltPressed()) then
			bSelfTargeted = true;
		end
		
		-- CHECK FOR SELF-TARGETING
		if bSelfTargeted then
			if rActor.nodeCT then
				table.insert(aTargets, rActor.sCTNode);
			elseif rActor.sType == "pc" and rActor.nodeCreature then
				sTargetType = "targetpc";
				table.insert(aTargets, rActor.sCreatureNode);
			end

		-- CHECK FOR CLIENT OR HOST TARGETING
		elseif rActor.nodeCT then
			local nodeTargetList = rActor.nodeCT.getChild("targets");
			if nodeTargetList then
				local sTargetType = "client";
				if User.isHost() then
					sTargetType = "host";
				end

				for keyTarget, nodeTarget in pairs(nodeTargetList.getChildren()) do
					if NodeManager.get(nodeTarget, "type", "") == sTargetType then
						table.insert(aTargets, NodeManager.get(nodeTarget, "noderef", ""));
					end
				end
			end
		end
	end
	
	return sTargetType, aTargets;
end

function toggleTarget(sTargetType, sSourceNode, sTargetNode)
	local nodeSource = DB.findNode(sSourceNode);
	if nodeSource then
		if isTarget(sTargetType, nodeSource, sTargetNode) then
			removeTarget(sTargetType, nodeSource, sTargetNode);
		else
			addTarget(sTargetType, sSourceNode, sTargetNode);
		end
	end
end

function isTarget(sTargetType, nodeSource, sTargetNode)
	-- GET TARGET LIST
	local nodeTargetList = nodeSource.getChild("targets");
	if not nodeTargetList then
		return false;
	end
	
	-- CHECK TO SEE IF TARGET ALREADY ON LIST
	for keyTarget, nodeTarget in pairs(nodeTargetList.getChildren()) do
		if (NodeManager.get(nodeTarget, "noderef", "") == sTargetNode) and 
				(NodeManager.get(nodeTarget, "type", "") == sTargetType) then
			return true;
		end
	end
	
	-- NO MATCH FOUND
	return false;
end

function addTarget(sTargetType, sSourceNode, sTargetNode)
	-- GET SOURCE NODE
	local nodeSource = DB.findNode(sSourceNode);
	if not nodeSource then
		return;
	end

	-- GET TARGET LIST
	local nodeTargetList = nodeSource.getChild("targets");
	if not nodeTargetList then
		return;
	end
	
	-- CHECK TO SEE IF TARGET ALREADY ON LIST
	for keyTarget, nodeTarget in pairs(nodeTargetList.getChildren()) do
		if (NodeManager.get(nodeTarget, "noderef", "") == sTargetNode) and 
				(NodeManager.get(nodeTarget, "type", "") == sTargetType) then
			return;
		end
	end

	-- ADD THE NEW TARGET TO THE LIST
	local nodeNewTarget = nodeTargetList.createChild();
	if nodeNewTarget then
		NodeManager.set(nodeNewTarget, "type", "string", sTargetType);
		NodeManager.set(nodeNewTarget, "noderef", "string", sTargetNode);
	end
end

function addFactionTargetsHost(nodeSource, sFaction, bNegated)
	-- VALIDATE
	if not nodeSource then
		return;
	end
	
	-- GET TRACKER
	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return;
	end

	-- ITERATE THROUGH TRACKER ENTRIES TO GET FACTION
	for keyEntry, nodeEntry in pairs(nodeTracker.getChildren()) do
		if bNegated then
			if NodeManager.get(nodeEntry, "friendfoe", "") ~= sFaction then
				addTarget("host", nodeSource.getNodeName(), nodeEntry.getNodeName());
			end
		else
			if NodeManager.get(nodeEntry, "friendfoe", "") == sFaction then
				addTarget("host", nodeSource.getNodeName(), nodeEntry.getNodeName());
			end
		end
	end
end

function addFactionTargetsClient(ctrlImage, bNegated)
	-- VALIDATE
	local sClientID = User.getCurrentIdentity();
	if not sClientID then
		ChatManager.SystemMessage("[WARNING] Unable to target, no active identity selected.");
		return;
	end
	local nodePlayerCT = CombatCommon.getCTFromNode("charsheet." .. sClientID);
	if not nodePlayerCT then
		ChatManager.SystemMessage("[WARNING] Unable to target, active character is not on combat tracker.");
		return;
	end

	-- GET TRACKER (ASSUME SUCCESS, SINCE WE GOT A PLAYER CT ENTRY)
	local nodeTracker = DB.findNode("combattracker");

	-- GET PLAYER FACTION
	local sFaction = NodeManager.get(nodePlayerCT, "friendfoe", "");
	
	-- BUILD AN IMAGE MAP
	local aImageTokenMap = {};
	for kToken, vToken in pairs(ctrlImage.getTokens()) do
		aImageTokenMap[vToken.getId()] = vToken;
	end
	
	-- ITERATE THROUGH CT ENTRIES TO COMPARE FACTION
	for keyEntry, nodeEntry in pairs(nodeTracker.getChildren()) do
		if bNegated then
			if NodeManager.get(nodeEntry, "friendfoe", "") ~= sFaction then
				local nTokenID = tonumber(NodeManager.get(nodeEntry, "tokenrefid", "")) or 0;
				if aImageTokenMap[nTokenID] then
					-- ONLY TARGET ENEMY TOKENS IF THEY ARE VISIBLE
					if aImageTokenMap[nTokenID].isVisible() then
						aImageTokenMap[nTokenID].setTarget(true, sClientID);
					end
				end
			end
		else
			if NodeManager.get(nodeEntry, "friendfoe", "") == sFaction then
				local nTokenID = tonumber(NodeManager.get(nodeEntry, "tokenrefid", "")) or 0;
				if aImageTokenMap[nTokenID] then
					aImageTokenMap[nTokenID].setTarget(true, sClientID);
				end
			end
		end
	end
end

function removeTarget(sTargetType, nodeSource, sTargetNode)
	if User.isHost() then
		if nodeSource then
			local nodeTargetList = nodeSource.getChild("targets");
			if nodeTargetList then
				for keyTarget, nodeTarget in pairs(nodeTargetList.getChildren()) do
					if (NodeManager.get(nodeTarget, "type", "") == sTargetType) and
							(NodeManager.get(nodeTarget, "noderef", "") == sTargetNode) then
						if sTargetType == "client" then
							TargetingManager.removeClientTarget("", NodeManager.get(nodeSource, "name"), sTargetNode)
						else
							nodeTarget.delete();
						end
					end
				end
			end
		end
	else
		ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_REMOVECLIENTTARGET, { NodeManager.get(nodeSource, "name", ""), sTargetNode });
	end
end

function removeClientTarget(msguser, sSourceName, sTargetNode)
	local sSourceIdentity = nil;
	for k, v in ipairs(User.getAllActiveIdentities()) do
		if User.getIdentityLabel(v) == sSourceName then
			sSourceIdentity = v;
			break;
		end
	end
	if not sSourceIdentity then
		local msg = {font = "systemfont"};
		msg.text = "[WARNING] Unable to remove client target, attacker does not match any current client identity";
		ChatManager.deliverMessage(msg, msguser);
		return;
	end

	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return;
	end

	for keyCTEntry, nodeCTEntry in pairs(nodeTracker.getChildren()) do
		if nodeCTEntry.getNodeName() == sTargetNode then
			local tokenCT = TokenManager.getTokenFromCT(nodeCTEntry);
			if tokenCT then
				tokenCT.setTarget(false, sSourceIdentity);
			end
			break;
		end
	end
end

function removeTargetFromAllEntries(sTargetType, sTargetNode)
	local nodeTracker = DB.findNode("combattracker");
	if nodeTracker then
		for keyCTEntry, nodeCTEntry in pairs(nodeTracker.getChildren()) do
			removeTarget(sTargetType, nodeCTEntry, sTargetNode);
			
			local nodeEffects = nodeCTEntry.getChild("effects");
			if nodeEffects then
				for keyEffect, nodeEffect in pairs(nodeEffects.getChildren()) do
					local nodeTargets = nodeEffect.getChild("targets");
					if nodeTargets then
						local bHasTargets = false;
						if nodeTargets.getChildCount() > 0 then
							removeTarget(sTargetType, nodeEffect, sTargetNode);
					
							if nodeTargets.getChildCount() == 0 then
								EffectsManager.expireEffect(nodeCTEntry, nodeEffect, 0, true);
							end
						end
					end
				end
			end
		end
	end
end

function clearTargets(sTargetType, nodeSource)
	if nodeSource then
		local nodeTargetList = nodeSource.getChild("targets");
		if nodeTargetList then
			for keyTarget, nodeTarget in pairs(nodeTargetList.getChildren()) do
				if NodeManager.get(nodeTarget, "type", "") == sTargetType then
					nodeTarget.delete();
				end
			end
		end
	end
end

function clearTargetsClient(ctrlImage)
	local sClientID = User.getCurrentIdentity();
	if sClientID and ctrlImage then
		for kToken, vToken in pairs(ctrlImage.getTokens()) do
			if vToken.isTargetedByIdentity(sClientID) then
				vToken.setTarget(false, sClientID);
			end
		end
	end
end

function getCTFromIdentity(nodeTracker, sIdentity)
	local sIdentityLabel = User.getIdentityLabel(sIdentity);
	if not sIdentityLabel then
		return nil;
	end
	
	for k, v in pairs(nodeTracker.getChildren()) do
		if NodeManager.get(v, "type", "") == "pc" then
			if NodeManager.get(v, "name", "") == sIdentityLabel then
				return v;
			end
		end
	end
	
	return nil;
end

function rebuildClientTargeting()
	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return;
	end

	local aClientTargets = {};
	
	for keyEntry, nodeEntry in pairs(nodeTracker.getChildren()) do
		-- Clear current target list in window
		clearTargets("client", nodeEntry);
		
		-- Get targeting data from default client targeting support
		local instanceToken = Token.getToken(NodeManager.get(nodeEntry, "tokenrefnode", ""), NodeManager.get(nodeEntry, "tokenrefid", ""));
		if instanceToken then
			local aTargeting = instanceToken.getTargetingIdentities();
			for i = #aTargeting, 1, -1 do
				local winTargetingCTNode = getCTFromIdentity(nodeTracker, aTargeting[i]);
				if winTargetingCTNode then
					table.insert(aClientTargets, {nodeAttacker = winTargetingCTNode.getNodeName(), nodeDefender = nodeEntry.getNodeName()});
				end
			end
		end
	end

	-- Using the target table, add target to windows
	for keyTarget, rTarget in pairs(aClientTargets) do
		TargetingManager.addTarget("client", rTarget.nodeAttacker, rTarget.nodeDefender);
	end
end

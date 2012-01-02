-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

--
--	GENERAL
--

function getActiveInit()
	local nActiveInit = nil;
	
	local nodeActive = getActiveCT();
	if nodeActive then
		nActiveInit = NodeManager.get(nodeActive, "initresult", 0);
	end
	
	return nActiveInit;
end

--
--  NODE TRANSLATION
--

function getActiveCT()
	-- FIND TRACKER NODE
	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return nil;
	end

	-- LOOK FOR ACTIVE NODE
	for keyEntry, nodeEntry in pairs(nodeTracker.getChildren()) do
		if NodeManager.get(nodeEntry, "active", 0) == 1 then
			return nodeEntry;
		end
	end

	-- IF NO ACTIVE NODES, THEN RETURN NIL
	return nil;
end

function getCTFromNode(varNode)
	-- SETUP
	local sNode = "";
	if type(varNode) == "string" then
		sNode = varNode;
	elseif type(varNode) == "databasenode" then
		sNode = varNode.getNodeName();
	else
		return nil;
	end
	
	-- FIND TRACKER NODE
	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return nil;
	end

	-- Check for exact CT match
	for keyEntry, nodeEntry in pairs(nodeTracker.getChildren()) do
		if nodeEntry.getNodeName() == sNode then
			return nodeEntry;
		end
	end

	-- Otherwise, check for link match
	for keyEntry, nodeEntry in pairs(nodeTracker.getChildren()) do
		local nodeLink = nodeEntry.getChild("link");
		if nodeLink then
			local sRefClass, sRefNode = nodeLink.getValue();
			if sRefNode == sNode then
				return nodeEntry;
			end
		end
	end

	return nil;	
end

function getCTFromTokenRef(nodeContainer, nId)
	if not nodeContainer then
		return nil;
	end
	
	-- FIND TRACKER NODE
	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return nil;
	end
	
	local sContainerNode = nodeContainer.getNodeName();

	-- LOOK FOR ACTIVE NODE
	for keyEntry, nodeEntry in pairs(nodeTracker.getChildren()) do
		local sCTContainerName = NodeManager.get(nodeEntry, "tokenrefnode", "");
		local nCTId = tonumber(NodeManager.get(nodeEntry, "tokenrefid", "")) or 0;
		if (sCTContainerName == sContainerNode) and (nCTId == nId) then
			return nodeEntry;
		end
	end

	-- IF NO MATCHES, THEN RETURN NIL
	return nil;
end

function getCTFromToken(token)
	-- GET TOKEN CONTAINER AND ID
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getCTFromTokenRef(nodeContainer, nID);
end


--
-- DROP HANDLING
--

function onDrop(nodetype, nodename, draginfo)
	local rSourceActor, rTargetActor = getDropActors(nodetype, nodename, draginfo);
	if rTargetActor then
		local dragtype = draginfo.getType();

		-- FACTION CHANGES
		if dragtype == "combattrackerff" and User.isHost() then
			NodeManager.set(rTargetActor.nodeCT, "friendfoe", "string", draginfo.getStringData());
			return true;
		end

		-- TARGETING
		if dragtype == "targeting" and User.isHost() then
			onTargetingDrop(rSourceActor, rTargetActor, draginfo);
			return true;
		end

		-- EFFECTS
		if dragtype == "effect" then
			onEffectDrop(rSourceActor, rTargetActor, draginfo);
			return true;
		end

		-- NUMBER DROPS
		if dragtype == "number" then
			onNumberDrop(rSourceActor, rTargetActor, draginfo);
			return true;
		end
	end
end

function onNumberDrop(rSourceActor, rTargetActor, draginfo)
		
	-- CHECK FOR EFFECTS
	if string.match(draginfo.getDescription(), "%[EFFECT") then
		onEffectDrop(rSourceActor, rTargetActor, draginfo);
		return;
	end
end

function getDropActors(nodetype, nodename, draginfo)
	local rSourceActor = getActionActors(draginfo);
	local rTargetActor = getActor(nodetype, nodename);
	return rSourceActor, rTargetActor;
end

function buildCustomRollArray(rSourceActor, rTargetActor)
	-- SETUP
	local custom = {};

	-- ENCODE SOURCE ACTOR (CT, PC, NPC)
	if rSourceActor then
		local sSourceType = "ct";
		local nodeSource = rSourceActor.nodeCT;
		if not nodeSource then
			if rSourceActor.sType == "pc" then
				sSourceType = "pc";
			elseif rSourceActor.sType == "npc" then
				sSourceType = "npc";
			end
			nodeSource = rSourceActor.nodeCreature;
		end
		if nodeSource then
			custom[sSourceType] = nodeSource;
		end
	end
	
	-- ENCODE TARGET ACTOR (CT, PC) (NO NPC TARGETING)
	if rTargetActor then
		local sSourceType = "targetct";
		local nodeSource = rTargetActor.nodeCT;
		if not nodeSource then
			if rTargetActor.sType == "pc" then
				sSourceType = "targetpc";
				nodeSource = rSourceActor.nodeCreature;
			end
		end
		if nodeSource then
			custom[sSourceType] = nodeSource.getNodeName();
		end
	end

	-- RESULTS
	return custom;
end

function onTargetingDrop(rSourceActor, rTargetActor, draginfo)
	if rTargetActor.nodeCT then
		-- ADD CREATURE TARGET
		if rSourceActor then
			if rSourceActor.nodeCT then
				TargetingManager.addTarget("host", rSourceActor.sCTNode, rTargetActor.sCTNode);
			end

		-- ADD EFFECT TARGET
		else
			local sRefClass, sRefNode = draginfo.getShortcutData();
			if sRefClass and sRefNode then
				if sRefClass == "combattracker_effect" then
					TargetingManager.addTarget("host", sRefNode, rTargetActor.sCTNode);
				end
			end
		end
	end
end


function onEffectDrop(rSourceActor, rTargetActor, draginfo)
	-- GET EFFECT INFORMATION
	local rEffect = RulesManager.decodeEffectFromDrag(draginfo);
	if not rEffect then
		return;
	end

	-- IF NO EXPLICIT EFFECT SOURCE, THEN USE THE SOURCE ACTOR
	if rEffect.sSource == "" then
		if rSourceActor and rSourceActor.sType == "pc" then
			if rSourceActor.nodeCT then
				rEffect.sSource = rSourceActor.sCTNode;
				rEffect.nInit = NodeManager.get(rSourceActor.nodeCT, "initresult", 0);
			end
		end
	end

	-- IF STILL NO SOURCE, THEN USE THE ACTIVE IDENTITY
	if rEffect.sSource == "" then
		local nodeTempCT = nil;
		if User.isHost() then
			nodeTempCT = CombatCommon.getActiveCT();
		else
			nodeTempCT = CombatCommon.getCTFromNode("charsheet." .. User.getCurrentIdentity());
		end
		if nodeTempCT then
			rEffect.sSource = nodeTempCT.getNodeName();
			rEffect.nInit = NodeManager.get(nodeTempCT, "initresult", 0);
		end
	end
	
	-- HANDLE REDUCED CLIENT ACCESS
	if not User.isHost() then
		-- DISABLED EFFECT DROP
		if OptionsManager.isOption("PDRP", "off") then
			return;
		end
		
		-- REPORT ONLY EFFECT DROP
		if OptionsManager.isOption("PDRP", "report") then
			ChatManager.reportEffect(rEffect, rTargetActor.sName);
			return;
		end
	end

	-- DETERMINE TARGET CT NODE
	if not rTargetActor.nodeCT then
		ChatManager.SystemMessage("[ERROR] Effect dropped on target which is not listed in the combat tracker.");
		return;
	end

	-- IF SOURCE AND TARGET HAVE SAME NAME, THEN CLEAR THE SOURCE NAME
	if rEffect.sSource == rTargetActor.sCTNode then
		rEffect.sSource = "";
	end
	
	-- HANDLE THIRD PARTY TARGETING
	local aTargetActors = {};
	local sEffectTargetNode = "";
	if rEffect.targets then
		aTargetActors = rEffect.targets;
		sEffectTargetNode = rTargetActor.sCTNode;
	else
		table.insert(aTargetActors, rTargetActor.sCTNode);
	end

	-- ADD THE EFFECT
	for k, v in pairs(aTargetActors) do
		ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_APPLYEFF, 
				{v, 
				rEffect.sName or "", 
				rEffect.sExpire or "", 
				rEffect.nInit or 0, 
				rEffect.sSource or "", 
				rEffect.nGMOnly or 0, 
				rEffect.sApply or "", 
				sEffectTargetNode});
	end
end


--
-- END TURN
--

function endTurn(msguser)
	-- Check if the special message user is the same as the owner of the active CT node
	local rActor = getActor("ct", getActiveCT());
	if rActor and rActor.sType == "pc" and rActor.nodeCreature then
		if rActor.nodeCreature.getOwner() == msguser then
			-- Make sure the combat tracker is up on the host
			local wnd = Interface.findWindow("combattracker_window", "combattracker");
			if not wnd then
				local msg = {font = "systemfont"};
				msg.text = "[WARNING] Turns can only be ended when the host combat tracker is open";
				ChatManager.deliverMessage(msg, msguser);
				return;
			end

			-- Everything checks out, so advance the turn
			wnd.list.nextActor();
		end
	end
end


--
-- ROLL HELPERS
--

function getActor(sActorType, varActor)
	-- GET ACTOR NODE
	local nodeActor = nil;
	if type(varActor) == "string" then
		nodeActor = DB.findNode(varActor);
	elseif type(varActor) == "databasenode" then
		nodeActor = varActor;
	end
	if not nodeActor then
		return nil;
	end

	-- BASED ON ORIGINAL ACTOR NODE, FILL IN THE OTHER INFORMATION
	local rActor = nil;
	if sActorType == "ct" then
		rActor = {};
		rActor.sType = NodeManager.get(nodeActor, "type", "npc");
		rActor.sName = NodeManager.get(nodeActor, "name", "");
		rActor.nodeCT = nodeActor;
		
		local nodeLink = nodeActor.getChild("link");
		if nodeLink then
			local sRefClass, sRefNode = nodeLink.getValue();
			if rActor.sType == "pc" and sRefClass == "charsheet" then
				rActor.nodeCreature = DB.findNode(sRefNode);
			elseif rActor.sType == "npc" and sRefClass == "npc" then
				rActor.nodeCreature = DB.findNode(sRefNode);
			end
		end

	elseif sActorType == "pc" then
		rActor = {};
		rActor.sType = "pc";
		rActor.nodeCreature = nodeActor;
		rActor.nodeCT = getCTFromNode(nodeActor);
		rActor.sName = NodeManager.get(rActor.nodeCT or rActor.nodeCreature, "name", "");

	elseif sActorType == "npc" then
		rActor = {};
		rActor.sType = "npc";
		rActor.nodeCreature = nodeActor;
		
		-- IF ACTIVE CT IS THIS NPC TYPE, THEN ASSOCIATE
		local nodeActiveCT = getActiveCT();
		if nodeActiveCT then
			local nodeLink = nodeActiveCT.getChild("link");
			if nodeLink then
				local sRefClass, sRefNode = nodeLink.getValue();
				if sRefNode == nodeActor.getNodeName() then
					rActor.nodeCT = nodeActiveCT;
				end
			end
		end
		-- OTHERWISE, ASSOCIATE WITH UNIQUE CT, IF POSSIBLE
		if not rActor.nodeCT then
			local nodeTracker = DB.findNode("combattracker");
			if nodeTracker then
				local bMatch = false;
				for keyEntry, nodeEntry in pairs(nodeTracker.getChildren()) do
					local nodeLink = nodeEntry.getChild("link");
					if nodeLink then
						local sRefClass, sRefNode = nodeLink.getValue();
						if sRefNode == nodeActor.getNodeName() then
							if bMatch then
								rActor.nodeCT = nil;
								break;
							end
							
							rActor.nodeCT = nodeEntry;
							bMatch = true;
						end
					end
				end
			end
		end
		
		rActor.sName = NodeManager.get(rActor.nodeCT or rActor.nodeCreature, "name", "");
	end
	
	-- TRACK THE NODE NAMES AS WELL
	if rActor.nodeCT then
		rActor.sCTNode = rActor.nodeCT.getNodeName();
	else
		rActor.sCTNode = "";
	end
	if rActor.nodeCreature then
		rActor.sCreatureNode = rActor.nodeCreature.getNodeName();
	else
		rActor.sCreatureNode = "";
	end
	
	-- RETURN ACTOR INFORMATION
	return rActor;
end

function getActionActors(draginfo)
	-- SETUP
	local rSourceActor = nil;
	local rTargetActor = nil;
	local nodeTargetEffect = nil;

	-- CHECK FOR DRAG INFORMATION
	if draginfo then
		local varCustom = draginfo.getCustomData();

		-- CHECK FOR CUSTOM DATA
		if varCustom then
			-- GET CUSTOM SOURCE ACTOR
			if varCustom["ct"] then
				rSourceActor = getActor("ct", varCustom["ct"]);

			elseif varCustom["pc"] then
				rSourceActor = getActor("pc", varCustom["pc"]);

			elseif varCustom["npc"] then
				rSourceActor = getActor("npc", varCustom["npc"]);
			end
			
			-- GET CUSTOM TARGET ACTOR
			if varCustom["targetct"] then
				local aTargets = StringManager.split(varCustom["targetct"], ChatManager.SPECIAL_MSG_SEP);
				if #aTargets > 1 then
					rTargetActor = {};
					rTargetActor.sType = "multi";
					rTargetActor.aActors = {};
					for keyTarget, sTargetNode in pairs(aTargets) do
						table.insert(rTargetActor.aActors, getActor("ct", sTargetNode));
					end
				elseif #aTargets == 1 then
					rTargetActor = getActor("ct", aTargets[1]);
				end

			elseif varCustom["targetpc"] then
				rTargetActor = getActor("pc", varCustom["targetpc"]);
			end
			
			-- GET CUSTOM TARGET EFFECT
			if varCustom["effect"] then
				nodeTargetEffect = varCustom["effect"];
			end

		-- IF NO CUSTOM DATA, THEN TRY THE SHORTCUT DATA
		else
			-- GET SHORTCUT SOURCE ACTOR
			local sRefClass, sRefNode = draginfo.getShortcutData();
			if sRefClass and sRefNode then
				if sRefClass == "combattracker_entry" then
					rSourceActor = getActor("ct", sRefNode);

				elseif sRefClass == "charsheet" then
					rSourceActor = getActor("pc", sRefNode);

				elseif sRefClass == "npc" then
					rSourceActor = getActor("npc", sRefNode);
				end
			end
			
			-- GET TARGET EFFECT INFO FROM STRING DATA, DEPENDING ON DRAG TYPE
			local dragtype = draginfo.getType();
			if dragtype == "save" or dragtype == "autosave" then
				local sEffectNode = draginfo.getStringData();
				if sEffectNode then
					nodeTargetEffect = DB.findNode(sEffectNode);
				end
			end
		end
	end
	
	-- RESULTS
	return rSourceActor, rTargetActor, nodeTargetEffect;
end



-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--  DATA STRUCTURES
--
-- rActor
--		sType
--		sName
--		nodeCreature
--		sCreatureNode
--		nodeCT
-- 		sCTNode
--

function getActor(sActorType, varActor)
	-- GET ACTOR NODE
	local nodeActor = nil;
	if type(varActor) == "string" then
		if varActor ~= "" then
			nodeActor = DB.findNode(varActor);
		end
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
		rActor.nodeCT = CombatCommon.getCTFromNode(nodeActor);
		rActor.sName = NodeManager.get(rActor.nodeCT or rActor.nodeCreature, "name", "");

	elseif sActorType == "npc" then
		rActor = {};
		rActor.sType = "npc";
		rActor.nodeCreature = nodeActor;
		
		-- IF ACTIVE CT IS THIS NPC TYPE, THEN ASSOCIATE
		local nodeActiveCT = CombatCommon.getActiveCT();
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

function getActorFromToken(token)
	local nodeCT = CombatCommon.getCTFromToken(token);
	if nodeCT then
		return getActor("ct", nodeCT.getNodeName());
	end
	
	return nil;
end


-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		Token.onAdd = onAdd;
		Token.onDelete = onDelete;

		Token.onClickRelease = onClickRelease;
		Token.onWheel = onWheel;

		Token.onContainerChanged = onContainerChanged;
		Token.onScaleChanged = onScaleChanged;
		Token.onTargetUpdate = onTargetUpdate;
	end

	Token.onDrop = onDrop;
end

function getTokenFromCT(nodeCTEntry)
	return Token.getToken(NodeManager.get(nodeCTEntry, "tokenrefnode", ""), NodeManager.get(nodeCTEntry, "tokenrefid", ""));
end

function onAdd(tokeninstance)
	tokeninstance.registerMenuItem("Reset individual token scaling", "minimize", 2);
	tokeninstance.onMenuSelection = onTokenMenuSelection;
	
	updateAttributesFromToken(tokeninstance);
end

function onTokenMenuSelection(tokeninstance, selection)
	if selection == 2 then
		tokeninstance.setScale(1);
	end
end

function onDelete(tokeninstance)
	local nodeCT = CombatCommon.getCTFromToken(tokeninstance);
	if nodeCT then
		NodeManager.set(nodeCT, "tokenrefnode", "string", "");
		NodeManager.set(nodeCT, "tokenrefid", "string", "");
		NodeManager.set(nodeCT, "tokenscale", "number", 1);
	end
end

function onClickRelease(tokeninstance, button)
	if Input.isControlPressed() and button == 2 then
		tokeninstance.setScale(1);
		return true;
	end
	if Input.isShiftPressed() and button == 1 then
		local rSource = ActorManager.getActor("ct", CombatCommon.getActiveCT());
		local rTarget = ActorManager.getActorFromToken(tokeninstance);
		if rSource and rTarget then
			TargetingManager.toggleTarget("host", rSource.sCTNode, rTarget.sCTNode);
		end
		return true;
	end
end

function onWheelHelper(tokeninstance, notches)
	if not tokeninstance then
		return;
	end
	
	if Input.isShiftPressed() then
		newscale = math.floor(tokeninstance.getScale() + notches);
		if newscale < 1 then
			newscale = 1;
		end
	else
		newscale = tokeninstance.getScale() + (notches * 0.1);
		if newscale < 0.1 then
			newscale = 0.1;
		end
	end
	
	tokeninstance.setScale(newscale);
end

function onWheelCT(nodeCTEntry, notches)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		onWheelHelper(tokeninstance, notches);
	end
end

function onWheel(tokeninstance, notches)
	if Input.isControlPressed() then
		onWheelHelper(tokeninstance, notches);
		return true;
	end
end

function onDrop(tokeninstance, draginfo)
	local nodeCT = CombatCommon.getCTFromToken(tokeninstance);
	if nodeCT then
		CombatCommon.onDrop("ct", nodeCT.getNodeName(), draginfo);
	end
end

function onContainerChanged(tokeninstance, nodeOldContainer, nOldId)
	local nodeCT = CombatCommon.getCTFromTokenRef(nodeOldContainer, nOldId);
	if nodeCT then
		local nodeNewContainer = tokeninstance.getContainerNode();
		if nodeNewContainer then
			NodeManager.set(nodeCT, "tokenrefnode", "string", nodeNewContainer.getNodeName());
			NodeManager.set(nodeCT, "tokenrefid", "string", tokeninstance.getId());
			NodeManager.set(nodeCT, "tokenscale", "number", tokeninstance.getScale());
		else
			NodeManager.set(nodeCT, "tokenrefnode", "string", "");
			NodeManager.set(nodeCT, "tokenrefid", "string", "");
			NodeManager.set(nodeCT, "tokenscale", "number", 1);
		end
	end
end

function onScaleChanged(tokeninstance)
	local nodeCT = CombatCommon.getCTFromToken(tokeninstance);
	if nodeCT then
		NodeManager.set(nodeCT, "tokenscale", "number", tokeninstance.getScale());
	end
end

function onTargetUpdate(tokeninstance)
	TargetingManager.rebuildClientTargeting();
end

function toggleClientTarget(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		if tokeninstance.isTargetedByIdentity() then
			tokeninstance.setTarget(false);
		else
			tokeninstance.setTarget(true);
		end
	end
end

function updateAttributesFromToken(tokeninstance)
	local nodeCTEntry = CombatCommon.getCTFromToken(tokeninstance);
	if nodeCTEntry then
		updateAttributesHelper(tokeninstance, nodeCTEntry);
	end
end

function updateAttributes(nodeCTEntry)
	local tokeninstance = TokenManager.getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateAttributesHelper(tokeninstance, nodeCTEntry);
	end
end

function updateAttributesHelper(tokeninstance, nodeCTEntry)
	tokeninstance.setTargetable(true);
	tokeninstance.setActivable(true);
	
	updateNameHelper(tokeninstance, nodeCTEntry);
	updateActiveHelper(tokeninstance, nodeCTEntry);
	updateFactionHelper(tokeninstance, nodeCTEntry);
	updateUnderlayHelper(tokeninstance, nodeCTEntry);
end

function updateName(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateNameHelper(tokeninstance, nodeCTEntry);
	end
end

function updateNameHelper(tokeninstance, nodeCTEntry)
	tokeninstance.setName(NodeManager.get(nodeCTEntry, "name", ""));
end

function updateVisibility(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		if NodeManager.get(nodeCTEntry, "type", "") == "pc" then
			tokeninstance.setVisible(true);
		else
			if NodeManager.get(nodeCTEntry, "show_npc", 0) == 1 then
				tokeninstance.setVisible(nil);
			else
				tokeninstance.setVisible(false);
			end
		end
	end
end

function updateActive(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateActiveHelper(tokeninstance, nodeCTEntry);
	end
end

function updateActiveHelper(tokeninstance, nodeCTEntry)
	if tokeninstance.isActivable() then
		if NodeManager.get(nodeCTEntry, "active", 0) == 1 then
			tokeninstance.setActive(true);
		else
			tokeninstance.setActive(false);
		end
	end
end

function updateFaction(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateFactionHelper(tokeninstance, nodeCTEntry);
	end
end

function updateFactionHelper(tokeninstance, nodeCTEntry)
	if NodeManager.get(nodeCTEntry, "friendfoe", "") == "friend" then
		tokeninstance.setModifiable(true);
		tokeninstance.setVisible(true);
	else
		tokeninstance.setModifiable(false);
		updateVisibility(nodeCTEntry);
	end
end

function updateUnderlay(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateUnderlayHelper(tokeninstance, nodeCTEntry);
	end
end

function updateUnderlayHelper(tokeninstance, nodeCTEntry)
	local nSpace = math.ceil(NodeManager.get(nodeCTEntry, "space", 1)) / 2;
	local nReach = math.ceil(NodeManager.get(nodeCTEntry, "reach", 1)) + nSpace;

	-- RESET UNDERLAYS
	tokeninstance.removeAllUnderlays();

	-- ADD REACH UNDERLAY
	if NodeManager.get(nodeCTEntry, "type", "") == "pc" then
		tokeninstance.addUnderlay(nReach, "4f000000", "hover");
	else
		tokeninstance.addUnderlay(nReach, "4f000000", "hover,gmonly");
	end

	-- ADD SPACE/FACTION/HEALTH UNDERLAY
	local sFaction = NodeManager.get(nodeCTEntry, "friendfoe", "");
	if sFaction == "friend" then
		tokeninstance.addUnderlay(nSpace, "2f00ff00");
	elseif sFaction == "foe" then
		tokeninstance.addUnderlay(nSpace, "2fff0000");
	elseif sFaction == "neutral" then
		tokeninstance.addUnderlay(nSpace, "2fffff00");
	end
end

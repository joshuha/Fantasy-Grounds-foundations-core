-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

targetingon = false;
effectson = false;

function onInit()
	-- Set the displays to what should be shown
	setTargetingVisible(false);
	setEffectsVisible(false);

	-- Acquire token reference, if any
	linkToken();
	
	-- Set up the PC links
	if type.getValue() == "pc" then
		linkPCFields();
	end
	
	-- Update the displays
	updateDisplay();
		
	-- Register the deletion menu item for the host
	registerMenuItem("Delete Entry", "delete", 6);
	registerMenuItem("Confirm Entry Delete", "delete", 6, 7);

	-- Track the effects list
	effects.getDatabaseNode().onChildUpdate = onEffectsChanged;
	effects.getDatabaseNode().onChildAdded = onEffectsChanged;
	onEffectsChanged();
	
	-- Track the targets list
	targets.getDatabaseNode().onChildUpdate = onTargetsChanged;
	targets.getDatabaseNode().onChildAdded = onTargetsChanged;
	onTargetsChanged();
	
	-- ENSURE ONE ENTRY FOR LAYOUT STABILITY
	if #(effects.getWindows()) == 0 then
		effects.createWindow();
	end
end

function updateDisplay()
	local sFaction = friendfoe.getStringValue();

	if type.getValue() ~= "pc" then
		name.setFrame("textlinesmall", 0, 0, 0, 0);
	end

	if isActive() then
		name.setFont("ct_active");
		
		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end
	else
		name.setFont("ct_name");
		
		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end

function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
	if imageinstance then
		token.link(imageinstance);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		delete();
	end
end

function delete()
	-- Remember node name
	local sNode = getDatabaseNode().getNodeName();
	
	-- Clear any effects first, so that saves aren't triggered by nextActor
	effects.reset(false);
	
	-- Move to the next actor, if this CT entry is active
	if isActive() then
		windowlist.nextActor();
	end

	-- If this is an NPC with a token on the map, then remove the token also
	if type.getValue() ~= "pc" then
		token.deleteReference();
	end

	-- Delete the database node and close the window
	getDatabaseNode().delete();

	-- Update list information (global subsection toggles, targeting)
	windowlist.onVisibilityToggle();
	windowlist.onEntrySectionToggle();
	windowlist.deleteTarget(sNode);
	TargetingManager.rebuildClientTargeting();
end

function onTypeChanged()
	-- If a PC, then set up the links to the char sheet
	local sType = type.getValue();
	if sType == "pc" then
		linkPCFields();
	end

	-- If a NPC, then show the NPC display button; otherwise, hide it
	if sType == "npc" then
		show_npc.setVisible(true);
	else
		show_npc.setVisible(false);
	end
end

function onFactionChanged()
	-- Update the entry frame
	updateDisplay();

	-- Update the token underlay to friend-or-foe status
	TokenManager.updateFaction(getDatabaseNode());
	updateTokenUnderlay();
end

function updateTokenUnderlay()
	TokenManager.updateUnderlay(getDatabaseNode());
end

function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode());
	windowlist.onVisibilityToggle();
end

function onEffectsChanged()
	-- SET THE EFFECTS CONTROL STRING
	local affectedby = EffectsManager.getEffectsString(getDatabaseNode());
	effects_str.setValue(affectedby);
	
	-- UPDATE VISIBILITY
	if affectedby == "" or effectson then
		effects_label.setVisible(false);
		effects_str.setVisible(false);
	else
		effects_label.setVisible(true);
		effects_str.setVisible(true);
	end
	setSpacerState();
end

function onTargetsChanged()
	-- VALIDATE (SINCE THIS FUNCTION CAN BE CALLED BEFORE FULLY INSTANTIATED)
	if not targets_str then
		return;
	end
	
	-- GET TARGET NAMES
	local aTargetNames = {};
	for keyTarget, winTarget in pairs(targets.getWindows()) do
		local sTargetName = NodeManager.get(DB.findNode(winTarget.noderef.getValue()), "name", "");
		if sTargetName == "" then
			sTargetName = "<Target>";
		end
		table.insert(aTargetNames, sTargetName);
	end

	-- SET THE TARGETS CONTROL STRING
	targets_str.setValue(table.concat(aTargetNames, ", "));
	
	-- UPDATE VISIBILITY
	if #aTargetNames == 0 or targetingon then
		targets_label.setVisible(false);
		targets_str.setVisible(false);
	else
		targets_label.setVisible(true);
		targets_str.setVisible(true);
	end
	setSpacerState();
end

function setSpacerState()
	if effects_label.isVisible() then
		if targets_label.isVisible() then
			spacer2.setAnchoredHeight(2);
		else
			spacer2.setAnchoredHeight(6);
		end
	else
		spacer2.setAnchoredHeight(0);
	end
end

function linkPCFields(src)
	local src = link.getTargetDatabaseNode();
	if src then
		name.setLink(NodeManager.createChild(src, "name", "string"), true);
	end
end

--
-- SECTION VISIBILITY FUNCTIONS
--

function setTargetingVisible(v)
	if activatetargeting.getValue() then
		v = true;
	end
	if type.getValue() ~= "pc" and active.getState() then
		v = true;
	end
	
	targetingon = v;
	targetingicon.setVisible(v);
	
	targeting_add_button.setVisible(v);
	targeting_clear_button.setVisible(v);
	targets.setVisible(v);
	
	onTargetsChanged();
end


function setEffectsVisible(v)
	if activateeffects.getValue() then
		v = true;
	end
	
	effectson = v;
	effecticon.setVisible(v);
	
	effects.setVisible(v);
	if v then
		effects.checkForEmpty();
	end
	
	onEffectsChanged();
end

-- Activity state

function isActive()
	return active.getState();
end

function setActive(state)
	-- Set the active indicator
	active.setState(state);
	
	-- Visible changes
	updateDisplay();
	
	-- Notifications 
	if state then
		-- Turn notification
		local msg = {font = "narratorfont", icon = "indicator_flag"};
		msg.text = "[TURN] " .. name.getValue();

		if OptionsManager.isOption("RSHE", "on") then
			local sEffects = EffectsManager.getEffectsString(getDatabaseNode(), true);
			if sEffects ~= "" then
				msg.text = msg.text .. " - " .. "[" .. sEffects .. "]";
			end
		end
		
		if type.getValue() == "pc" then
			-- Player Turn notification
			ChatManager.deliverMessage(msg);
			
			-- Ring bell also, if option enabled
			if OptionsManager.isOption("RING", "on") then
				local usernode = link.getTargetDatabaseNode();
				if usernode then
					local ownerid = User.getIdentityOwner(usernode.getName());
					if ownerid then
						User.ringBell(ownerid);
					end
				end
			end
		else
			-- DM Turn notification
			if show_npc.getState() then
				ChatManager.deliverMessage(msg);
			else
				msg.text = "[GM] " .. msg.text;
				ChatManager.addMessage(msg);
			end
		end
	end
end

-- Client Visibility

function isClientVisible()
	if type.getValue() == "pc" then
		return true;
	end
	if show_npc.getState() then
		return true;
	end
	return false;
end

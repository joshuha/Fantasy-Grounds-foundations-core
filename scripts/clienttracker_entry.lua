-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local tokenref = nil;

function onInit()
	-- Acquire token reference, if any
	linkToken();
	
	-- Update the wound and status displays
	onActiveChanged();
	onFactionChanged();
	onTypeChanged();
	
	-- Track the effects list
	local node_list_effects = NodeManager.createChild(getDatabaseNode(), "effects");
	if node_list_effects then
		node_list_effects.onChildUpdate = onEffectsChanged;
		node_list_effects.onChildAdded = onEffectsChanged;
	else
		getDatabaseNode().onChildAdded = onCTEntryChildAdded;
	end
	onEffectsChanged();
end

function onCTEntryChildAdded(source, child)
	if child.getName() == "effects" then
		source.onChildAdded = function () end;
		
		child.onChildUpdate = onEffectsChanged;
		child.onChildAdded = onEffectsChanged;
	end
end

function getTokenReference()
	return tokenref;
end

function linkToken()
	if tokenrefid and tokenrefnode then
		local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
		if imageinstance then
			tokenref = imageinstance;
		end
	end
end

function updateDisplay()
	if active.getValue() == 1 then
		name.setFont("ct_active");

		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		local sFaction = friendfoe.getValue();
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end

		windowlist.scrollToWindow(self);
	else
		name.setFont("ct_name");

		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		local sFaction = friendfoe.getValue();
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

function onActiveChanged()
	-- Update the active icon
	active_icon.setVisible(active.getValue() ~= 0);
	
	-- Update the display
	updateDisplay();
end

function onFactionChanged()
	-- Update the faction icon
	friendfoe_icon.updateIcon(friendfoe.getValue());
	
	-- Update the display
	updateDisplay();
end

function onTypeChanged()
	-- Update what fields are visible
	updateDisplay();
end

function onEffectsChanged()
	-- Rebuild the effects list
	local affectedby = EffectsManager.getEffectsString(getDatabaseNode());
	
	-- Update the effects line in the client combat tracker
	if affectedby == "" then
		effects_label.setVisible(false);
		effects_str.setVisible(false);
	else
		effects_label.setVisible(true);
		effects_str.setVisible(true);
	end
	effects_str.setValue(affectedby);
end


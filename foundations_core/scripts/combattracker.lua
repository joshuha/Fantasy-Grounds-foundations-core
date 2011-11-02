-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

enableglobaltoggle = true;
enablevisibilitytoggle = true;

ct_active_name = "";
aHostTargeting = {};

function onInit()
	Interface.onHotkeyActivated = onHotkey;

	-- Make sure all the clients can see the combat tracker
	for k,v in ipairs(User.getAllActiveIdentities()) do
		local username = User.getIdentityOwner(v);
		if username then
			NodeManager.addWatcher("combattracker", username);
			NodeManager.addWatcher("combattracker_props", username);
		end
	end

	-- Create a blank window if one doesn't exist already
	if not getNextWindow(nil) then
		NodeManager.createWindow(self);
	end

	-- Register a menu item to create a CT entry
	registerMenuItem("Create Item", "insert", 5);
	
	-- Rebuild targeting information
	TargetingManager.rebuildClientTargeting();
	
	-- Initialize global buttons
	onVisibilityToggle();
	onEntrySectionToggle();
end

function onSortCompare(w1, w2)
	if w1.initresult.getValue() ~= w2.initresult.getValue() then
		return w1.initresult.getValue() < w2.initresult.getValue();
	end
	
	return w1.name.getValue() > w2.name.getValue();
end

function onMenuSelection(selection)
	if selection == 5 then
		NodeManager.createWindow(self);
	end
end

function onHotkey(draginfo)
	if draginfo.isType("combattrackernextactor") then
		nextActor();
		return true;
	end
	if draginfo.isType("combattrackernextround") then
		nextRound();
		return true;
	end
end

function getCTFromIdentity(sIdentity)
	local sIdentityLabel = User.getIdentityLabel(sIdentity);
	for k, v in pairs(getWindows()) do
		if v.type.getValue() == "pc" then
			if v.name.getValue() == sIdentityLabel then
				return v;
			end
		end
	end
	
	return nil;
end

function deleteTarget(sNode)
	TargetingManager.removeTargetFromAllEntries("host", sNode);
end

function toggleVisibility()
	if not enablevisibilitytoggle then
		return;
	end
	
	local visibilityon = window.button_global_visibility.getState();
	for k,v in pairs(getWindows()) do
		if v.type.getValue() ~= "pc" then
			if visibilityon ~= v.show_npc.getState() then
				v.show_npc.setState(visibilityon);
			end
		end
	end
end

function toggleTargeting()
	if not enableglobaltoggle then
		return;
	end
	
	local targetingon = window.button_global_targeting.getValue();
	for k,v in pairs(getWindows()) do
		if targetingon ~= v.activatetargeting.getValue() then
			v.activatetargeting.setValue(targetingon);
			v.setTargetingVisible(v.activatetargeting.getValue());
		end
	end
end

function toggleEffects()
	if not enableglobaltoggle then
		return;
	end
	
	local effectson = window.button_global_effects.getValue();
	for k,v in pairs(getWindows()) do
		if effectson ~= v.activateeffects.getValue() then
			v.activateeffects.setValue(effectson);
			v.setEffectsVisible(v.activateeffects.getValue());
			v.effects.checkForEmpty();
		end
	end
end

function onVisibilityToggle()
	local anyVisible = false;
	for k,v in pairs(getWindows()) do
		if v.type.getValue() ~= "pc" and v.show_npc.getState() then
			anyVisible = true;
		end
	end
	
	enablevisibilitytoggle = false;
	window.button_global_visibility.setState(anyVisible);
	enablevisibilitytoggle = true;
end

function onEntrySectionToggle()
	local anyTargeting = false;
	local anyEffects = false;

	for k,v in pairs(getWindows()) do
		if v.activatetargeting.getValue() then
			anyTargeting = true;
		end
		if v.activateeffects.getValue() then
			anyEffects = true;
		end
	end

	enableglobaltoggle = false;
	window.button_global_targeting.setValue(anyTargeting);
	window.button_global_effects.setValue(anyEffects);
	enableglobaltoggle = true;
end

function addPc(source)
	-- Parameter validation
	if not source then
		return nil;
	end

	-- Create a new combat tracker window
	local wnd = NodeManager.createWindow(self);
	if not wnd then
		return nil;
	end

	-- Shortcut
	wnd.link.setValue("charsheet", source.getNodeName());

	-- Type
	-- NOTE: Set to PC after link set, so that fields are linked correctly
	wnd.type.setValue("pc");

	-- Token
	local tokenval = NodeManager.get(source, "combattoken", nil);
	if tokenval then
		wnd.token.setPrototype(tokenval);
	end

	-- FoF
	wnd.friendfoe.setStringValue("friend");
	
	return wnd;
end

function addBattle(source)
	-- Parameter validation
	if not source then
		return nil;
	end

	-- Cycle through the NPC list, and add them to the tracker
	local nodeList = source.getChild("npclist");
	if nodeList then
		for k,v in pairs(nodeList.getChildren()) do

			local nodeLink = v.getChild("link");
			if nodeLink then
				
				local aPlacement = {};
				local nodePlacementList = v.getChild("maplink");
				if nodePlacementList then
					for kPlacement, vPlacement in pairs(nodePlacementList.getChildren()) do
						local rPlacement = {};
						rPlacement.imagelink = NodeManager.get(vPlacement, "imagelink", "");
						rPlacement.imagex = NodeManager.get(vPlacement, "imagex", 0);
						rPlacement.imagey = NodeManager.get(vPlacement, "imagey", 0);
						table.insert(aPlacement, rPlacement);
					end
				end
				
				local nCount = NodeManager.get(v, "count", 0);
				for i = 1, nCount do
				
					local npcclass, npcnodename = nodeLink.getValue();
					local npcnode = DB.findNode(npcnodename);
					
					local wnd = addNpc(npcnode, NodeManager.get(v, "name", ""), NodeManager.get(v, "leveladj", 0));
					if wnd then
						local npctoken = NodeManager.get(v, "token", "");
						if npctoken ~= "" then
							wnd.token.setPrototype(npctoken);
							
							if aPlacement[i] and aPlacement[i].imagelink ~= "" then
								local tokenAdded = Token.addToken(aPlacement[i].imagelink, npctoken, aPlacement[i].imagex, aPlacement[i].imagey);
								if tokenAdded then
									wnd.token.link(tokenAdded);
								end
							end
						end
					else
						ChatManager.SystemMessage("Could not add '" .. NodeManager.get(v, "name", "") .. "' to combat tracker");
					end
				end
			end
		end
	end
end

function addNpc(source, name, leveladj)
	-- Parameter validation
	if not source then
		return nil;
	end
	if not leveladj then
		leveladj = 0;
	end

	-- Determine the options relevant to adding NPCs
	local opt_nnpc = OptionsManager.getOption("NNPC");

	-- Create a new NPC window to hold the data
	local wnd = NodeManager.createWindow(self);
	if not wnd then
		return nil;
	end

	-- SETUP
	local base_effects = {};

	-- Shortcut
	wnd.link.setValue("npc", source.getNodeName());

	-- Type
	wnd.type.setValue("npc");

	-- Name
	local namelocal = name;
	if not namelocal then
		namelocal = NodeManager.get(source, "name", "");
	end
	local namecount = 0;
	local highnum = 0;
	local last_init = 0;
	wnd.name.setValue(namelocal);

	-- If multiple NPCs of same name, then figure out what initiative they go on and potentially append a number
	if string.len(namelocal) > 0 then
		for k, v in ipairs(getWindows()) do
			if wnd.name.getValue() == getWindows()[k].name.getValue() then
				namecount = 0;
				for l, w in ipairs(getWindows()) do
					local check = null;
					if getWindows()[l].name.getValue() == namelocal then
						check = 0;
					elseif string.sub(getWindows()[l].name.getValue(), 1, string.len(namelocal)) == namelocal then
						check = tonumber(string.sub(getWindows()[l].name.getValue(), string.len(namelocal)+2));
					end
					if check then
						namecount = namecount + 1;
						local cur_init = getWindows()[l].initresult.getValue();
						if cur_init ~= 0 then
							last_init = cur_init;
						end
						if highnum < check then
							highnum = check;
						end
					end
				end 
				if opt_nnpc == "append" then
					getWindows()[k].name.setValue(wnd.name.getValue().." "..highnum+1); 
				elseif opt_nnpc == "random" then
					getWindows()[k].name.setValue(randomName(getWindows(), wnd.name.getValue())); 
				end
			end
		end
	end
	if namecount < 2 then
        wnd.name.setValue(namelocal);
	end
	
	-- Token
	local tokenval = NodeManager.get(source, "token", nil);
	if tokenval then
		wnd.token.setPrototype(tokenval);
	end
	
	-- FoF
	wnd.friendfoe.setStringValue("foe");
		
	
	return wnd;
end

function onDrop(x, y, draginfo)
	-- Capture certain drag types meant for the host only
	local dragtype = draginfo.getType();

	-- PC
	if dragtype == "playercharacter" then
		addPc(draginfo.getDatabaseNode());
		TargetingManager.rebuildClientTargeting();
		return true;
	end

	if dragtype == "shortcut" then
		local class, datasource = draginfo.getShortcutData();

		-- NPC
		if class == "npc" then
			addNpc(draginfo.getDatabaseNode());
			return true;
		end

		-- ENCOUNTER
		if class == "battle" then
			addBattle(draginfo.getDatabaseNode());
			return true;
		end
	end

	-- Capture any drops meant for specific CT entries
	local wnd = getWindowAt(x,y);
	if wnd then
		return CombatCommon.onDrop("ct", wnd.getDatabaseNode().getNodeName(), draginfo);
	end
end

function getActiveEntry()
	for k, v in ipairs(getWindows()) do
		if v.isActive() then
			return v;
		end
	end
	
	return nil;
end

function requestActivation(entry)
	-- Make all the CT entries inactive
	for k, v in ipairs(getWindows()) do
		v.setActive(false);
	end
	
	-- Make the given CT entry active
	entry.setActive(true);
	
	-- Scroll to the CT window
	scrollToWindow(entry);

		
	-- If we created a new speaker, then remove it
	if ct_active_name ~= "" then
		GmIdentityManager.removeIdentity(ct_active_name);
		ct_active_name = "";
	end

	-- Check the option to set the active CT as the GM voice
	if OptionsManager.isOption("CTAV", "on") then
		-- Set up the current CT entry as the speaker if NPC, otherwise just change the GM voice
		if entry.type.getValue() == "pc" then
			GmIdentityManager.activateGMIdentity();
		else
			local name = entry.name.getValue();
			if GmIdentityManager.existsIdentity(name) then
				GmIdentityManager.setCurrent(name);
			else
				ct_active_name = name;
				GmIdentityManager.addIdentity(name);
			end
		end
	end
end

function nextActor()
	local active = getActiveEntry();
	if active then
		
	end
	
	-- Find the next actor.  If no next actor, then start the next round
	local nextactor = getNextWindow(active);
	if nextactor then
		if active then
			EffectsManager.processEffects(getDatabaseNode(), active.getDatabaseNode(), nextactor.getDatabaseNode());
		else
			EffectsManager.processEffects(getDatabaseNode(), nil, nextactor.getDatabaseNode());
		end
		requestActivation(nextactor);
	else
		nextRound();
	end
end

function nextRound()
	-- IF ACTIVE ACTOR, THEN PROCESS EFFECTS
	local active = getActiveEntry();
	if active then
		EffectsManager.processEffects(getDatabaseNode(), active.getDatabaseNode(), nil);
		active.setActive(false);
	end

	-- ADVANCE ROUND COUNTER
	window.roundcounter.setValue(window.roundcounter.getValue() + 1);
	
	-- ANNOUNCE NEW ROUND
	local msg = {font = "narratorfont", icon = "indicator_flag"};
	msg.text = "[ROUND " .. window.roundcounter.getValue() .. "]";
	ChatManager.deliverMessage(msg);
	
	-- CHECK OPTION TO SEE IF WE SHOULD GO AHEAD AND MOVE TO FIRST ROUND
	if OptionsManager.isOption("RNDS", "off") and getNextWindow(nil) then
		nextActor();
	end
end

function stripCreatureNumber(s)
	local starts, ends, creature_number = string.find(s, " ?(%d+)$");
	if not starts then
		return s;
	end
	return string.sub(s, 1, starts), creature_number;
end


function resetInit()
	-- Set all CT entries to inactive and reset their init value
	for k, v in ipairs(getWindows()) do
		v.setActive(false);
		v.initresult.setValue(0);
		v.immediate_check.setState(false);
	end
	
	-- Remove the active CT from the speaker list
	if ct_active_name ~= "" then
		GmIdentityManager.removeIdentity(ct_active_name);
		ct_active_name = "";
	end

	-- Reset the round counter
	window.roundcounter.setValue(1);
end


function clearExpiringEffects()
	for k, v in ipairs(getWindows()) do
		local effcount = #(v.effects.getWindows());

		-- Clear any effects that have an expiration value
		for k2, v2 in ipairs(v.effects.getWindows()) do
			if v2.expiration.getStringValue() ~= "" or v2.apply.getStringValue() ~= "" or v2.label.getValue() == "" then
				v.effects.deleteChild(v2, false);
				effcount = effcount - 1;
			end
		end
		
		-- Clear any effects that are recharges
		for k2, v2 in ipairs(v.effects.getWindows()) do
			local sEffectName = v2.label.getValue();
			local effectlist = EffectsManager.parseEffect(sEffectName);
			for i = 1, #effectlist do
				if effectlist[i].type == "RCHG" then
					v.effects.deleteChild(v2, false);
					effcount = effcount - 1;
				end
			end
		end
		
		-- If no effects left, then clear the effects completely
		if effcount == 0 then
			v.effects.checkForEmpty();
			v.activateeffects.setValue(false);
			v.setEffectsVisible(false);
		end
	end
	
	-- Synch the global effects toggle
	onEntrySectionToggle();
end

function resetEffects()
	for k, v in ipairs(getWindows()) do
		-- Delete all current effects
		v.effects.reset(true);

		-- Hide the effects sub-section
		v.activateeffects.setValue(false);
		v.setEffectsVisible(false);
	end
	
	-- Synch the global effects toggle
	onEntrySectionToggle();
end

function deleteNPCs()
	for k, v in ipairs(getWindows()) do
		if v.type.getValue() == "npc" then
			v.delete();
		end
	end
end

function randomName(wintable, base_name)
	local new_name = base_name .. " " .. math.random(#wintable * 2) + 1	
	for l, w in ipairs(wintable) do
		if wintable[l].name.getValue() == new_name then
			new_name = randomName(wintable,base_name);
		end
	end
	return new_name
end

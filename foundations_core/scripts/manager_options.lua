-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local sets = {};
local options = {};
local callbacks = {};

function isMouseWheelEditEnabled()
	return isOption("MWHL", "on") or Input.isControlPressed();
end

function onInit()
	registerOption("DCLK", true, "Client", "Mouse: Double click action", "option_entry_radio", 
			{ labels = "Roll|Mod|Off", values = "on|mod|off", optionwidth = 70, default = "on" });
	registerOption("DRGR", true, "Client", "Mouse: Drag rolling", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "on" });
	registerOption("MWHL", true, "Client", "Mouse: Wheel editing", "option_entry_radio", 
			{ labels = "Always|Ctrl", values = "on|ctrl", optionwidth = 70, default = "ctrl" });
	registerOption("SELF", true, "Client", "Target: Self", "option_entry_radio", 
			{ labels = "Alt|Off", values="alt|off", optionwidth = 70, default = "alt" });

	
	registerOption("CTAV", false, "Game (GM)", "Chat: Set GM voice to active CT", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	registerOption("SHPW", false, "Game (GM)", "Chat: Show all whispers to GM", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	registerOption("TOTL", false, "Game (GM)", "Chat: Show roll totals", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	registerOption("REVL", false, "Game (GM)", "Chat: Show GM rolls", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	registerOption("SHRL", false, "Game (GM)", "Chat: Show name on rolls", "option_entry_radio", 
			{ labels = "All|PC|Off", values = "all|pc|off", optionwidth = 70, default = "off" });
	registerOption("PCHT", false, "Game (GM)", "Chat: Show portraits", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	registerOption("TBOX", false, "Game (GM)", "Table: Dice tower", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	
	
	registerOption("NNPC", false, "Combat (GM)", "NPC: Auto numbering", "option_entry_radio", 
			{ labels = "Append|Random|Off", values = "append|random|off", optionwidth = 70, default = "off" });
	registerOption("PDRP", false, "Combat (GM)", "Target: Enable PC actions", "option_entry_radio", 
			{ labels = "On|Report|Off", values = "on|report|off", optionwidth = 70, default = "off" });
	registerOption("RING", false, "Combat (GM)", "Turn: Ring bell on PC turn", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	registerOption("RSHE", false, "Combat (GM)", "Turn: Show effects", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	registerOption("RNDS", false, "Combat (GM)", "Turn: Stop at round start", "option_entry_radio", 
			{ labels = "On|Off", values = "on|off", optionwidth = 70, default = "off" });
	
	
end

function populate(win)
	for keySet, rSet in pairs(sets) do
		local winSet = win.grouplist.createWindow();
		if winSet then
			winSet.label.setValue(keySet);
			
			for keyOption, rOption in pairs(rSet) do
				local winOption = winSet.options_list.createWindowWithClass(rOption.sType);
				if winOption then
					winOption.setLabel(rOption.sLabel);
					winOption.initialize(rOption.sKey, rOption.aCustom);
					winOption.setLocked(not (rOption.bLocal or User.isHost()));
				end
			end

			winSet.options_list.applySort();
		end
	end
	
	win.grouplist.applySort();
end

function registerOption(sKey, bLocal, sGroup, sLabel, sOptionType, aCustom)
	local rOption = {};
	rOption.sKey = sKey;
	rOption.bLocal = bLocal;
	rOption.sLabel = sLabel;
	rOption.aCustom = aCustom;
	rOption.sType = sOptionType;
	
	if not sets[sGroup] then
		sets[sGroup] = {};
	end
	table.insert(sets[sGroup], rOption);
	
	options[sKey] = rOption;
	options[sKey].value = (options[sKey].aCustom[default]) or "";
	
	linkNode(sKey);
end

function linkNode(sKey)
	if options[sKey] and not options[sKey].bLinked and not options[sKey].bLocal then
		local nodeOptions = DB.createNode("options");
		if nodeOptions then
			local nodeOption = NodeManager.createChild(nodeOptions, sKey, "string");
			if nodeOption then
				nodeOption.onUpdate = onOptionChanged;
				options[sKey].bLinked = true;
			end
		end
	end
end

function onOptionChanged(nodeOption)
	local sKey = nodeOption.getName();
	makeCallback(sKey);
end

function registerCallback(sKey, fCallback)
	if not callbacks[sKey] then
		callbacks[sKey] = {};
	end
	
	table.insert(callbacks[sKey], fCallback);

	linkNode(sKey);
end

function unregisterCallback(sKey, fCallback)
	if callbacks[sKey] then
		for k, v in pairs(callbacks[sKey]) do
			if v == fCallback then
				callbacks[sKey][k] = nil;
			end
		end
	end
end

function makeCallback(sKey)
	if callbacks[sKey] then
		for k, v in pairs(callbacks[sKey]) do
			v(sKey);
		end
	end
end

function setOption(sKey, sValue)
	if options[sKey] then
		if options[sKey].bLocal then
			CampaignRegistry["Opt" .. sKey] = sValue;
			makeCallback(sKey);
		else
			if not User.isHost() then
				return;
			end
			local nodeOptions = DB.createNode("options");
			if not nodeOptions then
				return;
			end
			local nodeOption = NodeManager.createChild(nodeOptions, sKey, "string");
			if not nodeOption then
				return;
			end

			nodeOption.setValue(sValue);
		end
	end
end

function isOption(sKey, sTargetValue)
	return (getOption(sKey) == sTargetValue);
end

function getOption(sKey)
	if options[sKey] then
		if options[sKey].bLocal then
			if CampaignRegistry["Opt" .. sKey] then
				return CampaignRegistry["Opt" .. sKey];
			end
		else
			local nodeOptions = DB.findNode("options");
			if nodeOptions then
				local nodeOption = nodeOptions.getChild(sKey);
				if nodeOption then
					local sValue = nodeOption.getValue();
					if sValue ~= "" then
						return sValue;
					end
				end
			end
		end

		return (options[sKey].aCustom.default) or "";
	end

	return "";
end

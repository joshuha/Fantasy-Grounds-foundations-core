-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

-- Export structures
local hostnodes = {};
local commonnodes = {};
local clientnodes = {};
local tokenlist = {};

local moduleproperties = {};

local hasindex = false;


function onInit()
	registerMenuItem("Export", "edit", 5);
end

function getExportState(window)
	if window and window.access then
		return window.access.getStringValue();
	end
end

function getIndexState(window)
	if window and window.index and window.index.getState() then
		return true;
	else
		return false;
	end
end

function addExportNode(node, exportstate, indexstate, exportclass)
	-- Find the correct export table
	local nodetable = nil;
	if exportstate == "host" then
		nodetable = hostnodes;
	elseif exportstate == "common" then
		nodetable = commonnodes;
	elseif exportstate == "client" then
		nodetable = clientnodes;
	else
		return;
	end
	
	local libnodename = "library." .. moduleproperties.namecompact;
	
	-- Create node
	local nodeentrytable = {};
	
	nodeentrytable.import = node.getNodeName();

	if node.getCategory() then
		nodeentrytable.category = node.getCategory();
		nodeentrytable.category.mergeid = moduleproperties.mergeid;
	end
	
	nodetable[node.getNodeName()] = nodeentrytable;

	-- Create index entry
	if indexstate then
		-- Create index if required
		if not nodetable[libnodename] then
			local indextable = {};
			
			indextable.createstring = { name = moduleproperties.name, categoryname = moduleproperties.indexgroup };
			indextable.static = true;
			
			nodetable[libnodename] = indextable;
		end
		
		local libraryentryname = libnodename .. ".entries." .. exportclass .. node.getName();
		local libraryentrytable = {};
		
		libraryentrytable.createlink = { librarylink = { class = exportclass, recordname = node.getNodeName() } };
		libraryentrytable.createstring = { name = node.getChild("name").getValue() };
		
		nodetable[libraryentryname] = libraryentrytable;
		
		hasindex = true;
	end
end

function onMenuSelection(...)
	-- Reset data
	hostnodes = {};
	commonnodes = {};
	clientnodes = {};
	tokenlist = {};
	moduleproperties = {};
	hasindex = false;

	-- Global properties
	moduleproperties.name = name.getValue();
	moduleproperties.file= file.getValue();
	moduleproperties.author = author.getValue();
	moduleproperties.thumbnail = thumbnail.getValue();
	moduleproperties.indexgroup = indexgroup.getValue();
	moduleproperties.mergeid = mergeid.getValue();

	moduleproperties.namecompact = string.lower(string.gsub(moduleproperties.name, "%W", ""));
	
	-- Pre checks
	if moduleproperties.name == "" then
		ChatManager.SystemMessage("Module name not specified");
		name.setFocus(true);
		return;
	end
	if moduleproperties.file == "" then
		ChatManager.SystemMessage("Module file not specified");
		file.setFocus(true);
		return;
	end
	
	-- Loop through categories
	for ck, cw in ipairs(categories.getWindows()) do
		-- Construct export lists
		if cw.all.getState() then
			-- Add all child nodes
			local sourcenode = DB.findNode(cw.exportsource);
			local exportstate = getExportState(cw);
			local indexstate = getIndexState(cw);
			
			if sourcenode then
				for nk, nv in pairs(sourcenode.getChildren()) do
					if nv.getType() == "node" then
						addExportNode(nv, exportstate, indexstate, cw.exportclass);
					end
				end
			end
		else
			-- Loop through entries in category
			for ek, ew in ipairs(cw.entries.getWindows()) do
				local exportstate = getExportState(ew);
				local indexstate = getIndexState(ew);
				
				addExportNode(ew.getDatabaseNode(), exportstate, indexstate, cw.exportclass);
			end
		end
	end
	
	-- Tokens
	for tk, tw in ipairs(tokens.getWindows()) do
		table.insert(tokenlist, tw.token.getPrototype());
	end
	
	-- Post checks
	if hasindex and moduleproperties.indexgroup == "" then
		ChatManager.SystemMessage("Indexes used and index group not specified");
		indexgroup.setFocus(true);
		return;
	end
	
	-- Export
	if not Module.export(moduleproperties.name, moduleproperties.file, moduleproperties.author, hostnodes, commonnodes, clientnodes, tokenlist, moduleproperties.thumbnail) then
		ChatManager.SystemMessage("Module export failed!");
	else
		ChatManager.SystemMessage("Module exported successfully");
	end
end

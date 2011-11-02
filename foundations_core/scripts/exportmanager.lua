-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

aExport = {};

function onInit()
	if User.isHost() then
		ChatManager.registerSlashHandler("/export", processExport);

		-- Register Standard Camapign Nodes for /export
	    registerExportNode({ name = "encounter", class = "encounter", label = "Story" });
		registerExportNode({ name = "image", class = "imagewindow", label = "Images & Maps" });
		registerExportNode({ name = "battle", class = "battle", label = "Encounters" });
		registerExportNode({ name = "npc", class = "npc", label = "Personalities" });
		registerExportNode({ name = "item", class = "item", label = "Items" });
	end
end

function processExport(params)
	Interface.openWindow("export", "");
end

function retrieveExportNodes()
	return aExport;
end

function registerExportNode(rExport)
	table.insert(aExport, rExport)
end

function unregisterExportNode(rExport)
	local nIndex = nil;
	
	for k,v in pairs(aExport) do
		if string.upper(v.name) == string.upper(rExport.name) then
			nIndex = k;
		end
	end
	
	if nIndex then
		table.remove(aExport, nIndex);
	end
end

-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function clearSelection()
	for k, w in ipairs(getWindows()) do
		w.base.setFrame(nil);
	end
end

function addIdentity(id, aLabels, nodeLocal)
	for k, v in ipairs(activeidentities) do
		if v == id then
			return nil;
		end
	end

	local wnd = NodeManager.createWindow(self);
	if wnd then
		wnd.setId(id);
		wnd.name.setValue(aLabels[1] or "");

		local aVisibleLabels = {};
		if aLabels[2] then
			table.insert(aVisibleLabels, aLabels[2]);
		end
		if aLabels[3] and aLabels[3] ~= 0 then
			table.insert(aVisibleLabels, aLabels[3]);
		end
			
		wnd.setLocalNode(nodeLocal);

		if id then
			wnd.portrait.setIcon("portrait_" .. id .. "_charlist");
		end
	end
	
	return wnd;
end

function onInit()
	activeidentities = User.getAllActiveIdentities();

	getWindows()[1].close();
	createWindowWithClass("identityselection_newentry");

	localIdentities = User.getLocalIdentities();
	for n, v in ipairs(localIdentities) do
		local aLabels = {};
		aLabels[1] = NodeManager.get(v.databasenode, "name", "");
		aLabels[2] = NodeManager.get(v.databasenode, "class.base", "");
		aLabels[3] = NodeManager.get(v.databasenode, "level", 0);
		
		addIdentity(v.id, aLabels, v.databasenode);
	end

	User.getRemoteIdentities("charsheet", "name,class.base,#level", addIdentity);
end

-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local bIntact = true;
local bShared = false;

function buildMenu()
	resetMenuItems();
	
	if not bIntact then
		registerMenuItem("Revert Changes", "shuffle", 8);
	end
	
	if bShared then
		registerMenuItem("Stop sharing sheet", "unshare", 3);
	end
end

function onIntegrityChange()
	local node = getDatabaseNode();
	bIntact = node.isIntact();
	
	if bIntact then
		modified.setIcon("indicator_record_intact");
	else
		modified.setIcon("indicator_record_dirty");
	end
	
	buildMenu();
end

function onObserverUpdate()
	local node = getDatabaseNode();
	
	if User.isHost() then
		local sOwner = node.getOwner();

		if owner then
			if sOwner then
				owner.setValue("[" .. sOwner .. "]");
				owner.setVisible(true);
			else
				owner.setVisible(false);
			end
		end

		local aHolderNames = {};
		local aHolders = node.getHolders();
		for keyHolder, sHolder in pairs(aHolders) do
			if sOwner then
				if sOwner ~= sHolder then
					table.insert(aHolderNames, sHolder);
				end
			else
				table.insert(aHolderNames, sHolder);
			end
		end
		
		bShared = (#aHolderNames > 0);
		if bShared then
			access.setIcon("indicator_record_shared");
			access.setVisible(true);
			access.setTooltipText("Shared with: " .. table.concat(aHolderNames, ", "));
		else
			access.setVisible(false);
		end
		
		buildMenu();
	else
		if node.isOwner() then
			access.setVisible(false);
		else
			access.setIcon("indicator_record_readonly");
			access.setVisible(true);
		end
	end
end

function unshare()
	local node = getDatabaseNode();
	if node then
		node.removeAllHolders(true);
	end
	onObserverUpdate();
end

function onInit()
	local node = getDatabaseNode();
	
	if User.isHost() and node.getModule() then
		modified.setTooltipText(node.getModule());
		modified.setVisible(true);

		node.onIntegrityChange = onIntegrityChange;
		onIntegrityChange(node);
	end

	node.onObserverUpdate = onObserverUpdate;
	onObserverUpdate(node);
end

function onMenuSelection(selection)
	if selection == 3 then
		unshare();

	elseif selection == 8 then
		getDatabaseNode().revert();
	end
end

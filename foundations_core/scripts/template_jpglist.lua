-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

-- AKA The Never Empty List

function onInit()
	-- NOTE: Disabled, since it causes infinite loop when powerlistitem deleted after drop when client connected
	--checkForEmpty();
	
	local localmenutext = "Add Item";
	if menutext then
		localmenutext = "Add " .. menutext[1];
	end
	registerMenuItem(localmenutext, "pointer", 2);
end

-- See if the user has requested another item
function onMenuSelection(selection)
	if selection == 2 then
		local node = NodeManager.createChild(getDatabaseNode());
		if self.onCreateChild then
			self.onCreateChild(node);
		end
	end
end

function checkForEmpty()
	if not getNextWindow(nil) then
		local node = NodeManager.createChild(getDatabaseNode());
		if self.onCreateChild then
			self.onCreateChild(node);
		end
	end
end

function deleteChild(child, checkforempty_flag)
	child.getDatabaseNode().delete();

	if checkforempty_flag then
		checkForEmpty();
	end
end

function reset(checkforempty_flag)
	for k,v in pairs(getWindows()) do
		v.getDatabaseNode().delete();
	end

	if checkforempty_flag then
		checkForEmpty();
	end
end

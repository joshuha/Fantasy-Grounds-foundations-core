-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	User.onIdentityActivation = onIdentityActivation;
	CharacterSheetManager.populate("mini", self)
end

-- Close this sheet if the user releases its identity
function onIdentityActivation(identity, username, activated)
	if not activated and User.getUsername() == username and identity == getDatabaseNode().getName() then
		close()
	end
end

function onMenuSelection(selection, subselection)	

end

-- callback method for CharacterSheetManager to add sheets to this window
function addSheet(name, windowclass, tabicon)
	createControl(windowclass, name)
	tabs.registerTab(name, tabicon)
end
-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local linknode = link.getTargetDatabaseNode();
	if linknode then
		name.setValue(NodeManager.get(linknode, "name", ""));
	end

	if myfilter then
		myfilter.setValue(0);
	end
end

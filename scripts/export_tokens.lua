-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	if draginfo.isType("token") then
		local prototype = draginfo.getTokenData();

		-- Check for duplicates
		for k,v in ipairs(getWindows()) do
			if v.token.getPrototype() == prototype then
				return true;
			end
		end
		
		local wnd = NodeManager.createWindow(self);
		if wnd then
			wnd.token.setPrototype(prototype);
		end
		
		return true;
	end
end
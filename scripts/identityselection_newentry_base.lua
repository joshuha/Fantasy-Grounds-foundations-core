-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onDoubleClick(x, y)
	if not User.isLocal() then
		if not bRequested then
			User.requestIdentity(nil, "charsheet", "name", nil, window.requestResponse);
			bRequested = true;
		end
	else
		Interface.openWindow("charsheet", User.createLocalIdentity());
		window.windowlist.window.close();
	end
	return true;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	window.windowlist.clearSelection();
	setFrame("sheetfocus", -2, -2, -1, -1);
	return true;
end

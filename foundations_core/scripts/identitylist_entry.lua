-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

gmidentity = false;

function createLabel(name, isgm)
	identityname = name;
	gmidentity = isgm;

	namewidget = addTextWidget("chatfont", name);
	namewidget.setPosition("center", 0, 0);
	namewidget.setMaxWidth(60);
	
	if gmidentity then
		namewidget.setFont("chatitalicfont");
	else
		resetMenuItems();
		registerMenuItem("Remove", "erase", 1);
	end
end

function rename(name)
	if namewidget then
		namewidget.setText(name);
	end
	
	identityname = name;
end

function setCurrent(state)
	if state then
		if gmidentity then
			namewidget.setFont("chatbolditalicfont");
		else
			namewidget.setFont("narratorfont");
		end
	else
		if gmidentity then
			namewidget.setFont("chatitalicfont");
		else
			namewidget.setFont("chatfont");
		end
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if button == 1 then
		GmIdentityManager.setCurrent(identityname);
	elseif button == 2 then
		GmIdentityManager.removeIdentity(identityname);
	end
	return true;
end

function onMenuSelection(...)
	GmIdentityManager.removeIdentity(identityname);
end

function onInit()
end
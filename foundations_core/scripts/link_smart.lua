-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	setHoverCursor("hand");
end

function getTarget()
	local sClass = "";
	local sNode = "";
	local nodeTarget;
	
	local nodeWin = window.getDatabaseNode();
	local sSource = getName();
	if sSource ~= "" then
		if nodeWin then
			nodeTarget = nodeWin.getChild(sSource);
			if nodeTarget then
				sClass, sNode = nodeTarget.getValue();
			end
		end
	end
	
	if sClass == "" and defaultclass then
		sClass = defaultclass[1];
		if nodeWin then
			sNode = nodeWin.getNodeName();
			nodeTarget = nodeWin;
		end
	end
	
	return sClass, sNode, nodeTarget;
end

function getSource(bCreate)
	local nodeTarget = nil;
	
	local nodeWin = window.getDatabaseNode();
	local sSource = getName();
	if nodeWin and sSource ~= "" then
		if bCreate then
			nodeTarget = nodeWin.createChild(sSource, "windowreference");
		else
			nodeTarget = nodeWin.getChild(sSource);
		end
	end
	
	return nodeTarget;
end

function setValue(...)
	local nodeSource = getSource(true);
	if nodeSource then
		nodeSource.setValue(...);
	end
end

function onClickDown(button, x, y)
	if button == 2 then
		return true;
	end
end

function onClickRelease(button, x, y)
	if button == 2 then
		local nodeSource = getSource();
		if nodeSource then
			nodeSource.setValue("", "");
		end
		return true;
	end
end

function onButtonPress()
	local sClass, sNode = getTarget();

	local win = Interface.findWindow(sClass, sNode);
	if win then
		if toggle then
			win.close();
		else
			win.bringToFront();
		end
	else
		Interface.openWindow(sClass, sNode);
	end

	return true;
end

function onDrag(button, x, y, draginfo)
	if dragging then
		return true;
	end
	
	local sClass, sNode, nodeTarget = getTarget();

	draginfo.setType("shortcut");
	draginfo.setIcon(icon[1].normal[1]);
	draginfo.setDescription(NodeManager.get(nodeTarget, "name", ""));
	draginfo.setShortcutData(sClass, sNode);
	
	dragging = true;
	return true;
end

function onDragEnd(draginfo)
	dragging = false;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		setValue(draginfo.getShortcutData());
		
		return true;
	end
end

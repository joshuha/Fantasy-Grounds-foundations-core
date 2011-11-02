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
	if nodeWin and defaultclass then
		sClass = defaultclass[1];
		sNode = nodeWin.getNodeName();
		nodeTarget = nodeWin;
	end
	
	return sClass, sNode, nodeTarget;
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

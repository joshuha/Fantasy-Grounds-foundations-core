-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local nodeSource = nil;

function onInit()
	activewidget = addBitmapWidget(activeicon[1]);
	activewidget.setVisible(false);

	nodeSource = NodeManager.createChild(window.getDatabaseNode(), getName(), "number");
	if nodeSource then
		nodeSource.onUpdate = onValueChanged;
	end
	
	updateDisplay();
end

function onValueChanged()
	updateDisplay();
end

function updateDisplay()
	local state = getState();

	activewidget.setVisible(state);
	
	TokenManager.updateActive(window.getDatabaseNode());
	window.setTargetingVisible(false);
end

function setState(state)
	local datavalue = 1;
	if state == nil or state == false or state == 0 then
		datavalue = 0;
	end
	
	if nodeSource then
		nodeSource.setValue(datavalue);
	end
end

function getState()
	local datavalue = 0;
	if nodeSource then
		datavalue = nodeSource.getValue();
	end
	return datavalue ~= 0;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not getState() and User.isHost() then
		window.windowlist.requestActivation(window);
	end
	return true;
end

function onDrag(button, x, y, draginfo)
	if dragging then
		return true;
	end
	
	draginfo.setType("combattrackeractivation");
	draginfo.setIcon(activeicon[1]);

	activewidget.setVisible(false);

	dragging = true;
	return true;
end

function onDragEnd(draginfo)
	if getState() then
		activewidget.setVisible(true);
	end
	dragging = false;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackeractivation") then
		window.windowlist.requestActivation(window);
		return true;
	end
end
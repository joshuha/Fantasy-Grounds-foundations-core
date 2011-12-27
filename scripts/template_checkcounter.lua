-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local slots = {};
local enabled = true;

local maxnode = nil;
local maxnodename = "";
local currentnode = nil;
local currentnodename = "";

function onInit()
	-- Get any custom fields
	if sourcefields then
		if sourcefields[1].maximum then
			maxnodename = sourcefields[1].maximum[1];
		end
		if sourcefields[1].current then
			currentnodename = sourcefields[1].current[1];
		end
	end

	-- Synch to the data nodes
	local node = window.getDatabaseNode();
	local bWatchUpdate = false;
	if maxnodename ~= "" then
		-- If this is a new counter, then set our max value to 1 by default.
		maxnode = window.getDatabaseNode().getChild(maxnodename);
		if not maxnode then
			maxnode = NodeManager.createChild(node, maxnodename, "number");
			if maxnode then
				maxnode.setValue(1);
			end
		end
		if maxnode then
			maxnode.onUpdate = update;
		else
			bWatchUpdate = true;
		end
	end
	if currentnodename ~= "" then
		currentnode = NodeManager.createChild(window.getDatabaseNode(), currentnodename, "number");
		if currentnode then
			currentnode.onUpdate = update;
		else
			bWatchUpdate = true;
		end
	end
	if node and bWatchUpdate then
		node.onChildAdded = registerUpdate;
	end
	
	-- Update the view we show he world
	updateSlots();
end

function registerUpdate(nodeSource, nodeChild)
	if nodeChild.getName() == maxnodename then
		maxnode = nodeChild;
	elseif nodeChild.getName() == currentnodename then
		currentnode = nodeChild;
	else
		return;
	end

	if maxnode and currentnode then
		nodeSource.onChildAdded = function () end;
	end
	
	nodeChild.onUpdate = update;
	update();
end

-- Disables incrementing, can still decrement
function disable()
	enabled = false;
	updateSlots();
end

-- Enables incrementing
function enable()
	enabled = true;
	updateSlots();
end

function setMaxValue(p)
	maxnode.setValue(p);
end

function getMaxValue()
	return maxnode.getValue();
end

function setValue(n)
	local p = maxnode.getValue();
	
	if p < 1 or n < 0 then
		currentnode.setValue(0);
	elseif n > p then
		currentnode.setValue(p);
	else
		currentnode.setValue(n);
	end
end

function getValue()
	return currentnode.getValue();
end

function update()
	updateSlots();
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function updateSlots()
	-- Clear
	for k, v in ipairs(slots) do
		v.destroy();
	end
	
	slots = {};
	
	-- Construct based on values
	local p = maxnode.getValue();
	local c = currentnode.getValue();

	for i = 1, p do
		local widget = nil;

		if i > c then
			if enabled then
				widget = addBitmapWidget(stateicons[1].off[1]);
			else
				widget = addBitmapWidget(stateicons[1].on[1]);
				widget.setColor("4fffffff");
			end
		else
			widget = addBitmapWidget(stateicons[1].on[1]);
		end

		local pos = spacing[1]*(i-0.5);
		widget.setPosition("left", pos, 0);
		
		slots[i] = widget;
	end
	
	-- Handle the case where p < 1
	-- i.e. We always want to show at least one widget, even if it's disabled.
	if p < 1 then
		local widget = addBitmapWidget(stateicons[1].on[1]);
		widget.setColor("4fffffff");
		widget.setPosition("left", (spacing[1]*0.5), 0);
		slots[1] = widget;
	end

	-- Set the control width
	setAnchoredWidth(spacing[1] * #slots);
end

function onWheel(notches)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end
	
	if enabled or notches < 0 then
		setValue(getValue() + notches);
	end
	return true;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	local n = currentnode.getValue();
	local clickpos = math.floor(x / spacing[1]) + 1;

	if clickpos > n then
		if not enabled then
			return true;
		end
		setValue(n + 1);
	else
		setValue(n - 1);
	end

	return true;
end

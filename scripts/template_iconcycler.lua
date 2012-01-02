-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local srcnode = nil;
local srcnodetype = "string";
local srcnodename = "";
local readonlyflag = false;

local cycleindex = 0;

local icons = {};
local values = {};
local tooltips = {};

function onInit()
	-- Get any custom fields
	if parameters then
		if parameters[1].icons then
			icons = StringManager.split(parameters[1].icons[1], "|");
		end
		if parameters[1].values then
			values = StringManager.split(parameters[1].values[1], "|");
		end

		if parameters[1].tooltips then
			tooltips = StringManager.split(parameters[1].tooltips[1], "|");
		end

		if parameters[1].defaulticon then
			icons[0] = parameters[1].defaulticon[1];
			values[0] = "";
		end
		if parameters[1].defaulttooltip then
			tooltips[0] = parameters[1].defaulttooltip[1];
		end
	end
	
	-- SET ACCESS RIGHTS
	if readonly then
		readonlyflag = true;
	end
	if gmonly and not User.isHost() then
		readonlyflag = true;
	end
	
	-- SET UP DATA CONNECTION
	if not sourceless then
		srcnodename = getName();
		if source then
			if source[1].name then
				srcnodename = source[1].name[1];
			end
			if source[1].type then
				if source[1].type[1] == "number" then
					srcnodetype = "number";
				end
			end
		end
	end
	if srcnodename ~= "" then
		-- DETERMINE DB READ-ONLY STATE
		local node = window.getDatabaseNode();
		if NodeManager.isReadOnly(node) then
			readonlyflag = true;
		end

		-- LINK TO DATABASE NODE, AND FUTURE UPDATES
		srcnode = NodeManager.createChild(node, srcnodename, srcnodetype);
		if srcnode then
			srcnode.onUpdate = update;
		elseif node then
			node.onChildAdded = registerUpdate;
		end
		
		-- SYNCHRONIZE DATA VALUES
		synchData();
	end
	
	-- UPDATE DISPLAY
	updateDisplay();
end

function registerUpdate(nodeSource, nodeChild)
	if nodeChild.getName() == srcnodename then
		nodeSource.onChildAdded = function () end;
		nodeChild.onUpdate = update;
		srcnode = nodeChild;
		update();
	end
end

function synchData()
	if srcnodetype == "number" then
		if srcnode then
			cycleindex = srcnode.getValue();
		else
			cycleindex = 0;
		end
	else
		local srcval = "";
		if srcnode then
			srcval = srcnode.getValue();
		end

		local nMatch = 0;
		for k, v in pairs(values) do
			if v == srcval then
				nMatch = k;
			end
		end

		cycleindex = nMatch;
	end
end

function updateDisplay()
	if not icons[cycleindex] then
		cycleindex = 0;
	end
	
	setIcon(icons[cycleindex] or "");
	setTooltipText(tooltips[cycleindex] or "");
end

function update()
	synchData();
	updateDisplay();
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function getSourceNode()
	return srcnode;
end

function setIndex(srcval)
	if type(srcval) ~= "number" then
		return;
	end

	if srcnode then
		if srcnodetype == "number" then
			srcnode.setValue(srcval);
		else
			if srcval > 0 and srcval <= #values then
				srcnode.setValue(values[srcval]);
			else
				srcnode.setValue("");
			end
		end
	else
		if srcval > 0 and srcval <= #icons then
			cycleindex = srcval;
		else
			cycleindex = 0;
		end

		updateDisplay();
		if self.onValueChanged then
			self.onValueChanged();
		end
	end

end

function setStringValue(srcval)
	if type(srcval) ~= "string" then
		return;
	end
	
	if srcnode then
		if srcnodetype == "number" then
			if srcnode then
				local nMatch = 0;
				for k, v in pairs(values) do
					if v == srcval then
						nMatch = k;
					end
				end

				srcnode.setValue(nMatch);
			end
		else
			if srcnode then
				srcnode.setValue(srcval);
			end
		end
	else
		local nMatch = 0;
		for k, v in pairs(values) do
			if v == srcval then
				nMatch = k;
			end
		end

		cycleindex = nMatch;
	end
end

function getIndex()
	return cycleindex;
end

function getStringValue()
	if cycleindex > 0 and cycleindex <= #values then
		return values[cycleindex];
	end
	
	return "";
end

function cycleIcon()
	if cycleindex < #icons then
		cycleindex = cycleindex + 1;
	else
		cycleindex = 0;
	end

	if srcnode then
		if srcnodetype == "number" then
			srcnode.setValue(cycleindex);
		else
			srcnode.setValue(getStringValue());
		end
	else
		updateDisplay();
		if self.onValueChanged then
			self.onValueChanged();
		end
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not readonlyflag then
		cycleIcon();
	end
	return true;
end

function setLocked(val)
	if val == nil or val == false or val == 0 then
		readonlyflag = false;
	else
		readonlyflag = true;
	end
end

function isLocked()
	return readonlyflag;
end

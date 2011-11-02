-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local localvalue = false;

function getValue()
	return localvalue;
end

function setValue(v)
	if v == true or v == 1 then
		localvalue = true;
	else
		localvalue = false;
	end
		
	update();
end

function updateDisplay()
	if localvalue then
		setColor("ffffffff");
	else
		setColor("7fffffff");
	end
end

function update()
	updateDisplay();
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	setValue(not getValue());
	return true;
end

function onInit()
	-- Set the initial icon to off
	setIcon(icon[1]);

	-- Use internal value, initialize to checked if <checked /> is specified
	if checked then
		localvalue = true;
	end

	-- Update the display
	updateDisplay();
end

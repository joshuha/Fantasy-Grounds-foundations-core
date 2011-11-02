-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local startx, dx;

function onClickDown(button, x, y)
	local w, h = getSize();
	startx = x;

	if window.active then
		setIcon(states[1].unloading[1]);
	else
		setIcon(states[1].loading[1]);
	end
	
	return true;
end

function onClickRelease(button, x, y)
	if window.active then
		setIcon(states[1].loaded[1]);
	else
		setIcon(states[1].unloaded[1]);
	end
	
	return true;
end

function onDragEnd(dragdata)
	local w, h = getSize();
	
	if window.active then
		if dx > w/2 then
			window.deactivate();
		else
			setIcon(states[1].loaded[1]);
		end
	else
		if dx < -w/2 then
			window.activate();
		else
			setIcon(states[1].unloaded[1]);
		end
	end
end

function onDrag(button, x, y, dragdata)
	local w, h = getSize();
	
	dx = x - startx;
	
	if window.active then
		if dx > w/2 then
			setIcon(states[1].unloaded[1]);
		else
			setIcon(states[1].unloading[1]);
		end
	else
		if dx < -w/2 then
			setIcon(states[1].loaded[1]);
		else
			setIcon(states[1].loading[1]);
		end
	end

	return true;
end

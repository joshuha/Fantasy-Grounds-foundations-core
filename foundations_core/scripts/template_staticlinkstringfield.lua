-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

hoverontext = false;

function onHover(oncontrol)
	if not oncontrol then
		setUnderline(false);
		hoverontext = false;
	end
end

function onHoverUpdate(x, y)
	if getIndexAt(x, y) < #getValue() then
		setUnderline(true);
		hoverontext = true;
	else
		setUnderline(false);
		hoverontext = false;
	end
end

function onClickDown(button, x, y)
	if hoverontext then
		return true;
	else
		return false;
	end
end

function onClickRelease(button, x, y)
	if hoverontext then
		if self.activate then
			self.activate();
		elseif linktarget then
			window[linktarget[1]].activate();
		end
		return true;
	end
end

function onDrag(button, x, y, draginfo)
	if dragging then
		return true;
	end
	
	if linktarget and hoverontext then
		if window[linktarget[1]].onDrag then
			dragging = window[linktarget[1]].onDrag(button, x, y, draginfo);
			return true;
		end
	else
		return false;
	end
end
					
function onDragEnd(draginfo)
	if dragging then
		dragging = false;
		window[linktarget[1]].onDragEnd(draginfo);
	end
end

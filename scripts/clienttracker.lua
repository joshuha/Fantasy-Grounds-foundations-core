-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onSortCompare(w1, w2)
	if w1.initresult.getValue() ~= w2.initresult.getValue() then
		return w1.initresult.getValue() < w2.initresult.getValue();
	end
		
	if w1.init.getValue() ~= w2.init.getValue() then
		return w1.init.getValue() < w2.init.getValue();
	end
	
	return w1.name.getValue() > w2.name.getValue();
end

function onFilter(w)
	if w.type.getValue() == "pc" then
		return true;
	end
	if w.show_npc.getValue() ~= 0 then
		return true;
	end
	return false;
end

function onDrop(x, y, draginfo)
	local wnd = getWindowAt(x,y);
	if wnd then
		return CombatCommon.onDrop("ct", wnd.getDatabaseNode().getNodeName(), draginfo);
	end
end

function onClickDown(button, x, y)
	if (Input.isShiftPressed()) then
		return true;
	end
end

function onClickRelease(button, x, y)
	if (Input.isShiftPressed()) then
		local wnd = getWindowAt(x, y);
		if wnd then
			local refToken = wnd.getTokenReference();
			if refToken then
				if refToken.isTargetedByIdentity() then
					refToken.setTarget(false);
				else
					refToken.setTarget(true);
				end
			end
		end

		return true;
	end
end

-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

slots = {};

function resetCounters()
	for k, v in ipairs(slots) do
		v.destroy();
	end
	
	slots = {};
end

function addCounter()
	local widget = addBitmapWidget(counters[1].icon[1]);
	widget.setPosition("topleft", counters[1].offset[1].x[1] + counters[1].spacing[1] * #slots, counters[1].offset[1].y[1]);
	table.insert(slots, widget);
end

function onHoverUpdate(x, y)
	ModifierStack.hoverDisplay(getCounterAt(x, y));
end

function onHover(oncontrol)
	if not oncontrol then
		ModifierStack.hoverDisplay(0);
	end
end

function getCounterAt(x, y)
	for i = 1, #slots do
		local slotcenterx = counters[1].offset[1].x[1] + counters[1].spacing[1] * (i-1);
		local slotcentery = counters[1].offset[1].y[1];
		
		local size = tonumber(counters[1].hoversize[1]);
		
		if math.abs(slotcenterx - x) <= size and math.abs(slotcenterx - x) <= size then
			return i;
		end
	end
	
	return 0;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	local n = getCounterAt(x, y);
	if n ~= 0 then
		ModifierStack.removeSlot(n);
	end
	return true;
end

function onEffectDrop(rEffect)
	local aEffectComps = EffectsManager.parseEffect(rEffect.sName);
	for i = 1, #aEffectComps do
		if aEffectComps[i].mod ~= 0 then
			local sLabel = aEffectComps[i].type;
			if #(aEffectComps[i].remainder) > 0 then
				sLabel = sLabel .. ": " .. table.concat(aEffectComps[i].remainder, " ");
			end

			ModifierStack.addSlot(sLabel, aEffectComps[i].mod);
			break;
		end
	end
end

function onDrop(x, y, draginfo)
	local dragtype = draginfo.getType();
	
	-- Effect handling
	local rEffect = RulesManager.decodeEffectFromDrag(draginfo);
	if rEffect then
		onEffectDrop(rEffect);
		return true;
	end
	
	-- Special handling for numbers, since they may come from chat window
	if dragtype == "number" then
		-- Strip any names or totals that were added
		local dragtext = draginfo.getDescription();
		dragtext = string.gsub(dragtext, "^(.*)-> ", "");

		-- Then, add to the modifier stack
		ModifierStack.addSlot(dragtext, draginfo.getNumberData());
		return true;
	
	-- Accept dice rolls by ignoring the dice
	elseif dragtype == "dice"  or dragtype == "init" then
		ModifierStack.addSlot(draginfo.getDescription(), draginfo.getNumberData());
		return true;
	end

	return false;
end

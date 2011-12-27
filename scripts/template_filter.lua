-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function hide()
	setVisible(false);
	window[trigger[1]].setVisible(true);
end

function onEnter()
	hide();
	return true;
end

function onLoseFocus()
	hide();
end

function onValueChanged()
	-- The target value is a series of consecutive window lists or sub windows
	local targetnesting = {};
	
	for w in string.gmatch(target[1], "(%w+)") do
		table.insert(targetnesting, w);
	end

	local target = window[targetnesting[1]];
	applyTo(target, targetnesting, 2);

	window[trigger[1]].updateWidget(getValue() ~= "");
end

function applyTo(target, nesting, index)
	local targettype = type(target);
	
	if targettype == "windowlist" then
		if index > #nesting then
			target.applyFilter();
			return;
		end
		
		for k, w in pairs(target.getWindows()) do
			applyTo(w[nesting[index]], nesting, index+1);
		end
	elseif targettype == "subwindow" then
		applyTo(target.subwindow[nesting[index]], nesting, index+1);
	end
end

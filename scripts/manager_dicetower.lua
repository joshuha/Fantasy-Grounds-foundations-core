-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local control = nil;

function registerControl(ctrl)
	control = ctrl;
	activate();
end

function activate()
	OptionsManager.registerCallback("TBOX", update);
	OptionsManager.registerCallback("REVL", update);

	update();
end

function update()
	if control then
		if OptionsManager.isOption("TBOX", "on") then
			if User.isHost() and OptionsManager.isOption("REVL", "off") then
				control.setVisible(false);
			else
				control.setVisible(true);
			end
		else
			control.setVisible(false);
		end
	end
end

function onDrop(draginfo)
	if control then
		if OptionsManager.isOption("TBOX", "on") then
			-- Make sure we add in the modifier stack, if any
			ModifierStack.applyToRoll(draginfo);

			-- Build a dice string by processing the die list
			local dicestr = StringManager.convertDiceToString(draginfo.getDieList());
			if draginfo.getNumberData() ~= 0 then
				if draginfo.getNumberData() > 0 then
					dicestr = dicestr .. "+" .. draginfo.getNumberData();
				else
					dicestr = dicestr .. draginfo.getNumberData();
				end
			end

			-- Send the special message for dice tower drops
			ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_DICETOWER, {draginfo.getType(), draginfo.getDescription(), dicestr});
		end
	end

	-- Let FG know that this drop event is handled
	return true;
end

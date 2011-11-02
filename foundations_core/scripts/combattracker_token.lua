-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local scaleWidget = nil;

--
--  LINKED TOKEN FUNCTIONS
--

function link(newTokenInstance)
	local nodeContainer = nil;
	if newTokenInstance then
		nodeContainer = newTokenInstance.getContainerNode();
	end
	
	if nodeContainer then
		window.tokenrefnode.setValue(nodeContainer.getNodeName());
		window.tokenrefid.setValue(newTokenInstance.getId());
		window.tokenscale.setValue(newTokenInstance.getScale());
	else
		window.tokenrefnode.setValue("");
		window.tokenrefid.setValue("");
		window.tokenscale.setValue(1);
	end

	TokenManager.updateAttributes(window.getDatabaseNode());

	return true;
end

function replace(newTokenInstance)
	local oldTokenInstance = TokenManager.getTokenFromCT(window.getDatabaseNode());
	if oldTokenInstance and oldTokenInstance ~= newTokenInstance then
		oldTokenInstance.delete();
	end

	link(newTokenInstance);
end

function deleteReference()
	local tokeninstance = TokenManager.getTokenFromCT(window.getDatabaseNode());
	if tokeninstance then
		tokeninstance.delete();
	end
end

--
--
-- CT TOKEN EVENT HANDLERS
--
--

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "token" then
		local prototype, dropref = draginfo.getTokenData();
		setPrototype(prototype);
		replace(dropref);
		return true;
	elseif sDragType == "number" then
		return window.wounds.onDrop(x, y, draginfo);
	end
end

function onDragEnd(draginfo)
	local prototype, dropref = draginfo.getTokenData();
	if dropref then
		replace(dropref);
	end
	return true;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	-- LEFT CLICK TO SET TOKEN ACTIVE
	if button == 1 then
		if Input.isShiftPressed() then
			local nodeActiveCT = CombatCommon.getActiveCT();
			if nodeActiveCT then
				local nodeWin = window.getDatabaseNode();
				if nodeWin then
					TargetingManager.toggleTarget("host", nodeActiveCT.getNodeName(), nodeWin.getNodeName());
				end
			end
		else
			local tokeninstance = TokenManager.getTokenFromCT(window.getDatabaseNode());
			if tokeninstance then
				tokeninstance.setActive(not tokeninstance.isActive());
			end
		end
	
	-- MIDDLE CLICK TO RESET SCALE
	else
		local tokeninstance = TokenManager.getTokenFromCT(window.getDatabaseNode());
		if tokeninstance then
			tokeninstance.setScale(1.0);
		end
	end

	return true;
end

function onWheel(notches)
	TokenManager.onWheelCT(window.getDatabaseNode(), notches);
	return true;
end

function onScaleChanged()
	local scale = window.tokenscale.getValue();
	
	if scale == 1 then
		if scaleWidget then
			scaleWidget.setVisible(false);
		end
	else
		if not scaleWidget then		
			scaleWidget = addTextWidget("sheetlabelsmall", "0");
			scaleWidget.setFrame("tempmodmini", 4, 1, 6, 3);
			scaleWidget.setPosition("topright", -2, 2);
		end
		scaleWidget.setVisible(true);
		scaleWidget.setText(string.format("%.1f", scale));
	end
end

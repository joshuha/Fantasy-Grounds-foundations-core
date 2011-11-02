-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function setActiveState(sUserState)
	if sUserState == "idle" then
		statewidget.setBitmap("indicator_idling");
	elseif sUserState == "typing" then
		statewidget.setBitmap("indicator_typing");
	elseif sUserState == "afk" then
		statewidget.setBitmap("indicator_afk");
	else
		statewidget.setBitmap();
	end
end

function setCurrent(nCurrentState, sUserState)
	if nCurrentState then
		namewidget.setFont("mini_name_selected");
		setActiveState(sUserState);
	else
		namewidget.setFont("mini_name");
		setActiveState("active");
	end
end

function setName(sName)
	if sName ~= "" then
		namewidget.setText(sName);
	else
		namewidget.setText("- Unnamed -");
	end
end

function updateColor()
	colorwidget.setColor(User.getIdentityColor(identityname));
	colorwidget.setVisible(true);
end

function createWidgets(name)
	identityname = name;

	portraitwidget = addBitmapWidget("portrait_" .. name .. "_charlist");

	namewidget = addTextWidget("mini_name", "- Unnamed -");
	namewidget.setPosition("center", 0, 36);
	namewidget.setFrame("mini_name", 5, 2, 5, 2);
	namewidget.setMaxWidth(70);
	
	statewidget = addBitmapWidget();
	statewidget.setPosition("center", -23, -23);
	
	colorwidget = addBitmapWidget("indicator_pointer");
	colorwidget.setPosition("center", 36, 16);
	colorwidget.setVisible(false);

	resetMenuItems();
	if User.isHost() then
		registerMenuItem("Ring Bell", "bell", 5);
		registerMenuItem("Kick", "kick", 3);
		registerMenuItem("Kick Confirm", "kickconfirm", 3, 5);
	elseif User.isOwnedIdentity(name) then
		registerMenuItem("Toggle AFK", "hand", 3);
		registerMenuItem("Release", "erase", 5);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if User.isHost() then
		bringCharacterToTop();
	else
		if User.isOwnedIdentity(identityname) then
			local nOwned = 0;
			local aActive = User.getAllActiveIdentities();
			for k, v in pairs(aActive) do
				if User.isOwnedIdentity(v) then
					nOwned = nOwned + 1;
				end
			end

			setCurrentIdentity(identityname);
			if nOwned == 1 then
				bringCharacterToTop();
			end
		end
	end
	return true;
end

function onDoubleClick(x, y)
	bringCharacterToTop();
	return true;
end

function onDrag(button, x, y, draginfo)
	if dragging then
		return true;
	end
	
	if User.isHost() or User.isOwnedIdentity(identityname) then
		draginfo.setType("playercharacter");
		draginfo.setTokenData("portrait_" .. identityname .. "_token");
		draginfo.setShortcutData("charsheet", "charsheet." .. identityname);
		draginfo.setStringData(identityname);
		
		local base = draginfo.createBaseData();
		base.setType("token");
		base.setTokenData("portrait_" .. identityname .. "_token");
	
		dragging = true;
		return true;
	end
end

function onDragEnd(draginfo)
	dragging = false;
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if CombatCommon.onDrop("pc", "charsheet." .. identityname, draginfo) then
			return true;
		end
		
		-- Default number drop behavior
		if draginfo.isType("number") then
			local msg = {};
			msg.text = draginfo.getDescription() .. " [to " .. User.getIdentityLabel(identityname) .."]";
			msg.font = "systemfont";
			msg.icon = "portrait_" .. identityname .. "_targetportrait";
			msg.dice = {};
			msg.diemodifier = draginfo.getNumberData();
			msg.dicesecret = false;
			
			ChatManager.deliverMessage(msg);
			return true;
		end

		-- Send dropped string as whisper
		if draginfo.isType("string") then
			local msg = {};
			msg.text = draginfo.getStringData();
			msg.font = "whisperfont";

			msg.sender = "<whisper>";
			ChatManager.deliverMessage(msg, User.getIdentityOwner(identityname));

			msg.sender = "-> " .. User.getIdentityLabel(identityname);
			ChatManager.addMessage(msg);

			return true;
		end
		
		-- Shortcut shared to single client
		if draginfo.isType("shortcut") then
			local wnd = Interface.openWindow(draginfo.getShortcutData());
			if wnd then
				wnd.share(User.getIdentityOwner(identityname));
			end
		
			return true;
		end
	end

	-- Portrait selection
	if draginfo.isType("portraitselection") then
		User.setPortrait(identityname, draginfo.getStringData());
		return true;
	end
end

function onMenuSelection(selection, subselection)
	if User.isHost() then
		if selection == 5 then
			User.ringBell(User.getIdentityOwner(identityname));
		elseif selection == 3 and subselection == 5 then
			User.kick(User.getIdentityOwner(identityname));
		end
	elseif User.isOwnedIdentity(identityname) then
		if selection == 3 then
			window.toggleAFK();
		elseif selection == 5 then
			User.releaseIdentity(identityname);

			local nOwned = 0;
			local aActive = User.getAllActiveIdentities();
			for k, v in pairs(aActive) do
				if User.isOwnedIdentity(v) and v ~= identityname then
					setCurrentIdentity(v);
					break;
				end
			end
		end
	end
end

function setCurrentIdentity(identityname)
	User.setCurrentIdentity(identityname);

	if CampaignRegistry and CampaignRegistry.colortables and CampaignRegistry.colortables[identityname] then
		local colortable = CampaignRegistry.colortables[identityname];
		User.setCurrentIdentityColors(colortable.color or "000000", colortable.blacktext or false);
	end
end

function bringCharacterToTop()
	local wndMain = Interface.findWindow("charsheet", "charsheet." .. identityname);
	local wndMini = Interface.findWindow("charsheetmini_top", "charsheet." .. identityname);
	if wndMain then
		wndMain.bringToFront();
	elseif wndMini then
		wndMini.bringToFront();
	else
		Interface.openWindow("charsheet", "charsheet." .. identityname);
	end
end

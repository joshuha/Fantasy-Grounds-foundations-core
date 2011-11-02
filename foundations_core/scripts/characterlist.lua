-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local aUserStates = {};

OOB_MSGTYPE_SETAFK = "setafk";

function onInit()
	-- Set callbacks for user activity
	if User.isHost() then
		User.onLogin = onLogin;
	end
	User.onUserStateChange = onUserStateChange;
	User.onIdentityActivation = onIdentityActivation;
	User.onIdentityStateChange = onIdentityStateChange;

	ChatManager.registerSlashHandler("/afk", processAFK);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_SETAFK, handleAFK);
end

function onClose()
	-- Remove holder information from shared nodes to reduce DB clutter
	if User.isHost() then
		NodeManager.removeAllWatchers("options");
		NodeManager.removeAllWatchers("combattracker");
		NodeManager.removeAllWatchers("combattracker_props");
		NodeManager.removeAllWatchers("modifiers");
		NodeManager.removeAllWatchers("effects");
	end
end

function findControlForIdentity(identity)
	return self["ctrl_" .. identity];
end

function controlSortCmp(t1, t2)
	return t1.name < t2.name;
end

function layoutControls()
	local identitylist = {};
	
	for key, val in pairs(User.getAllActiveIdentities()) do
		table.insert(identitylist, { name = val, control = findControlForIdentity(val) });
	end
	
	table.sort(identitylist, controlSortCmp);

	local n = 0;
	for key, val in pairs(identitylist) do
		val.control.sendToBack();
	end
	
	anchor.sendToBack();
end

function onLogin(username, bActivated)
	if bActivated then
		NodeManager.addWatcher("options", username);
		NodeManager.addWatcher("combattracker", username);
		NodeManager.addWatcher("combattracker_props", username);
		NodeManager.addWatcher("modifiers", username);
		NodeManager.addWatcher("effects", username);
	end
end

function onUserStateChange(sUser, sStateName, nState)
	if sUser ~= "" then
		if not aUserStates[sUser] then
			aUserStates[sUser] = "active";
		end
		
		if sStateName == "active" or sStateName == "idle" then
			if aUserStates[sUser] ~= "afk" then
				aUserStates[sUser] = sStateName;
			end
		elseif sStateName == "typing" then
			if aUserStates[sUser] == "afk" and sUser == User.getUsername() then
				aUserStates[sUser] = "typing"
				messageAFK(sUser);
			else
				aUserStates[sUser] = "typing"
			end
		end
		
		local sIdentity = User.getCurrentIdentity(sUser);
		if sIdentity then
			local ctrl = findControlForIdentity(sIdentity);
			if ctrl then
				ctrl.setActiveState(aUserStates[sUser]);
			end
		end
	end
end

function onIdentityActivation(identity, username, activated)
	if activated then
		do
			if not findControlForIdentity(identity) then
				createControl("characterlist_entry", "ctrl_" .. identity);
				
				userctrl = findControlForIdentity(identity);
				userctrl.createWidgets(identity);
				
				layoutControls();
			end
		end
		
		if not User.isHost() then
			DiceTowerManager.activate();
		end
	else
		findControlForIdentity(identity).destroy();
		layoutControls();
	end
end

function onIdentityStateChange(sIdentity, sUser, sStateName, vState)
	local ctrl = findControlForIdentity(sIdentity);
	if ctrl then
		if sStateName == "current" then
			ctrl.setCurrent(vState, sUserState);
		elseif sStateName == "label" then
			ctrl.setName(vState);
		elseif sStateName == "color" then
			ctrl.updateColor();
		end
	end
end

function toggleAFK()
	local sUser = User.getUsername();
	
	if aUserStates[sUser] == "afk" then
		aUserStates[sUser] = "active";
	else
		aUserStates[sUser] = "afk";
	end
	
	local sIdentity = User.getCurrentIdentity();
	 if sIdentity then
		local ctrl = findControlForIdentity(sIdentity);
		 if ctrl then
			ctrl.setActiveState(aUserStates[sUser]);
		end
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_SETAFK;
	msgOOB.user = sUser;
	if aUserStates[sUser] == "afk" then
		msgOOB.nState = 1;
	else
		msgOOB.nState = 0;
	end

	Comm.deliverOOBMessage(msgOOB, "");
	
	messageAFK(sUser);
end

function processAFK(params)
	toggleAFK();
end

function handleAFK(msgOOB)
	if not aUserStates[msgOOB.user] then
		aUserStates[msgOOB.user] = "active";
	end
	
	local sIdentity = User.getCurrentIdentity(msgOOB.user);
	if sIdentity then
		local ctrl = findControlForIdentity(sIdentity);
		if ctrl then
			if msgOOB.nState == "0" then
				aUserStates[msgOOB.user] = "active";
			else
				aUserStates[msgOOB.user] = "afk";
			end
			
			ctrl.setActiveState(aUserStates[msgOOB.user]);
		end
	end
end

function messageAFK(sUser)
	local msg = {font = "systemfont"};
	if aUserStates[sUser] == "afk" then
		msg.text = "User '" .. sUser .. "' has gone AFK.";
	else
		msg.text = "User '" .. sUser .. "' is back.";
	end
	Comm.deliverChatMessage(msg);
end
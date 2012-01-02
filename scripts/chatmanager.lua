-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

SPECIAL_MSGTYPE_DICETOWER = "dicetower";
SPECIAL_MSGTYPE_APPLYEFF = "applyeff";
SPECIAL_MSGTYPE_EXPIREEFF = "expireeff";
SPECIAL_MSGTYPE_ENDTURN = "endturn";
SPECIAL_MSGTYPE_REMOVECLIENTTARGET = "removeclienttarget";

-- Initialization
function onInit()
	registerSlashHandler("/die", processDie);
	registerSlashHandler("/mod", processMod);
	registerSlashHandler("/flushdb", processFlushDB);
	
	if User.isHost() then
		registerSlashHandler("/importchar", processImport);
		registerSlashHandler("/exportchar", processExport);
	end
	
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_DICETOWER, handleDiceTower);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_APPLYEFF, handleApplyEffect);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_EXPIREEFF, handleExpireEffect);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_ENDTURN, handleEndTurn);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_REMOVECLIENTTARGET, handleRemoveClientTarget);
end

-- Chat window registration for general purpose message dispatching
function registerControl(ctrl)
	control = ctrl;
end

function registerEntryControl(ctrl)
	entrycontrol = ctrl;
	ctrl.onSlashCommand = onSlashCommand;
end

function registerWindowControl(ctrl)
	windowcontrol = ctrl;
end

function DieControlThrow(type, bonus, name, custom, dice)
	if control then
		control.throwDice(type, dice, bonus, name, custom);
	end
end

-- Generic message delivery
function deliverMessage(msg, recipients)
	if control then
		control.deliverMessage(msg, recipients);
	end
end

function addMessage(msg)
	if control then
		control.addMessage(msg);
	end
end

launchmsg = {};

function registerLaunchMessage(msg)
	table.insert(launchmsg, msg);
end

function retrieveLaunchMessages()
	return launchmsg;
end


--
--
-- ROLL HANDLER
--
--

rollhandlers = {};

function registerRollHandler(sRollType, callback)
	rollhandlers[sRollType] = callback;
end

function unregisterRollHandler(sRollType, callback)
	rollhandlers[sRollType] = nil;
end

function onDiceRoll(draginfo)
	-- CHECK REGISTERED ROLL HANDLERS
	local sRollType = draginfo.getType();
	for k, v in pairs(rollhandlers) do
		if k == sRollType then
			v(draginfo);
			return true;
		end
	end
	if rollhandlers[""] then
		rollhandlers[""](draginfo);
		return true;
	end
	
	-- NO ROLL HANDLER FOUND
	return nil;
end


--
--
-- SLASH COMMAND HANDLER
--
--

slashhandlers = {};

function registerSlashHandler(command, callback)
	slashhandlers[command] = callback;
end

function unregisterSlashHandler(command, callback)
	slashhandlers[command] = nil;
end

function onSlashCommand(command, parameters)
	if string.len(command) > 1 then
		-- Check for exact match
		for c, h in pairs(slashhandlers) do
			if string.lower(c) == string.lower(command) then
				h(parameters);
				return;
			end
		end

		-- Check for unique partial match
		local fSlashCommand = nil;
		for c, h in pairs(slashhandlers) do
			if string.find(string.lower(c), string.lower(command), 1, true) == 1 then
				if fSlashCommand then
					fSlashCommand = nil;
					break;
				end
				fSlashCommand = h;
			end
		end
		if fSlashCommand then
			fSlashCommand(parameters);
			return;
		end
	end
	
	onSlashHelp();
end

function onSlashHelp()
	if User.isHost() then
		SystemMessage("SLASH COMMANDS [required] <optional>");
		SystemMessage("----------------");
		SystemMessage("BUILT-IN COMMANDS");
		SystemMessage("/console");
		SystemMessage("/day");
		SystemMessage("/emote <message>");
		SystemMessage("/mood [mood] <message>");
		SystemMessage("/mood ([multiword mood]) <message>");
		SystemMessage("/ooc <message>");
		SystemMessage("/night");
		SystemMessage("/reload");
		SystemMessage("/save");
		SystemMessage("/story <message>");
		SystemMessage("/vote <message>");
		SystemMessage("----------------");
		SystemMessage("RULESET COMMANDS");
		SystemMessage("/clear");
		SystemMessage("/die [NdN+N] <message>");
		SystemMessage("/export");
		SystemMessage("/exportchar");
		SystemMessage("/exportchar [name]");
		SystemMessage("/flushdb");
		SystemMessage("/gmid [name]");
		SystemMessage("/identity [name]");
		SystemMessage("/importchar");
		SystemMessage("/mod [N] <message>");
		SystemMessage("/reply [message]");
		SystemMessage("/whisper [character] [message]");
	else
		SystemMessage("SLASH COMMANDS [required] <optional>");
		SystemMessage("----------------");
		SystemMessage("BUILT-IN COMMANDS");
		SystemMessage("/action <message>");
		SystemMessage("/console");
		SystemMessage("/emote <message>");
		SystemMessage("/mood [mood] <message>");
		SystemMessage("/mood ([multiword mood]) <message>");
		SystemMessage("/ooc <message>");
		SystemMessage("/save");
		SystemMessage("/vote <message>");
		SystemMessage("----------------");
		SystemMessage("RULESET COMMANDS");
		SystemMessage("/die [NdN+N] <message>");
		SystemMessage("/mod [N] <message>");
		SystemMessage("/reply [message]");
		SystemMessage("/whisper GM [message]");
		SystemMessage("/whisper [character] [message]");
	end
end


--
--
-- AUTO-COMPLETE
--
--

function searchForIdentity(sSearch)
	for _, sIdentity in ipairs(User.getAllActiveIdentities()) do
		local sLabel = User.getIdentityLabel(sIdentity);
		if string.find(string.lower(sLabel), string.lower(sSearch), 1, true) == 1 then
			if User.getIdentityOwner(sIdentity) then
				return sIdentity;
			end
		end
	end

	return nil;
end

function doAutocomplete()
	local buffer = entrycontrol.getValue();
	if buffer == "" then 
		return ;
	end

	-- Parse the string, adding one chunk at a time, looking for the maximum possible match
	local sReplacement = nil;
	local nStart = 2;
	while not sReplacement do
		local nSpace = string.find(string.reverse(buffer), " ", nStart, true);

		if nSpace then
			local sSearch = string.sub(buffer, #buffer - nSpace + 2);

			if not string.match(sSearch, "^%s$") then
				local sIdentity = searchForIdentity(sSearch);
				if sIdentity then
					local sRemainder = string.sub(buffer, 1, #buffer - nSpace + 1);
					sReplacement = sRemainder .. User.getIdentityLabel(sIdentity) .. " ";
					break;
				end
			end
		else
			local sIdentity = searchForIdentity(buffer);
			if sIdentity then
				sReplacement = User.getIdentityLabel(sIdentity) .. " ";
				break;
			end
			
			return;
		end

		nStart = nSpace + 1;
	end

	if sReplacement then
		entrycontrol.setValue(sReplacement)
		entrycontrol.setCursorPosition(#sReplacement + 1)
		entrycontrol.setSelectionPosition(#sReplacement + 1)
	end
end


--
--
-- DICE AND MOD SLASH HANDLERS
--
--

function processDie(params)
	if control then
		if User.isHost() then
			if params == "reveal" then
				OptionsManager.setOption("REVL", "on");
				SystemMessage("Revealing all die rolls");
				return;
			end
			if params == "hide" then
				OptionsManager.setOption("REVL", "off");
				SystemMessage("Hiding all die rolls");
				return;
			end
		end
	
		local diestring, descriptionstring = string.match(params, "%s*(%S+)%s*(.*)");
		
		if not diestring then
			SystemMessage("Usage: /die [dice] [description]");
			return;
		end
		
		local dice, modifier = StringManager.convertStringToDice(diestring);
		
		RulesManager.dclkAction("dice", modifier, descriptionstring, nil, nil, dice, true);
	end
end

function processMod(params)
	if control then
		local modstring, descriptionstring = string.match(params, "%s*(%S+)%s*(.*)");
		
		local modifier = tonumber(modstring);
		if not modifier then
			SystemMessage("Usage: /mod [number] [description]");
			return;
		end
		
		ModifierStack.addSlot(descriptionstring, modifier);
	end
end

function processFlushDB(params)
	local rootnode = DB.findNode(".");
	if rootnode then
		rootnode.removeAllHolders(true);
	end
	SystemMessage("All client view-only access to database has been reset.");
end

function processImport(params)
	local sFile = Interface.dialogFileOpen();
	if sFile then
		DB.import(sFile, "charsheet", "character");
	end
end

function processExport(params)
	local nodeChar = nil;
	
	local sFind = StringManager.trimString(params);
	if string.len(sFind) > 0 then
		local nodeCharacters = DB.findNode("charsheet");
		if nodeCharacters then
			for kChar, vChar in pairs(nodeCharacters.getChildren()) do
				local sChar = NodeManager.get(vChar, "name", "");
				if string.len(sChar) > 0 then
					if string.lower(sFind) == string.lower(string.sub(sChar, 1, string.len(sFind))) then
						nodeChar = vChar;
						break;
					end
				end
			end
		end
		if not nodeChar then
			SystemMessage("Unable to find character requested for export. (" .. params .. ")");
			return;
		end
	end
	
	local sFile = Interface.dialogFileSave();
	if sFile then
		if nodeChar then
			DB.export(sFile, nodeChar, "character");
			SystemMessage("Exported character: " .. NodeManager.get(nodeChar, "name", ""));
		else
			DB.export(sFile, "charsheet", "character", true);
			SystemMessage("Exported all characters");
		end
	end
end

--
--
-- MESSAGES
--
--

function createBaseMessage(rSourceActor)
	-- Set up the basic message components
	local msg = {font = "systemfont", text = "", dicesecret = false};

	-- GET SOURCE ACTOR NAME
	local bShowActorName = false;
	if rSourceActor then
		local sOptionShowRoll = OptionsManager.getOption("SHRL");
		if (sOptionShowRoll == "all") or ((sOptionShowRoll == "pc") and (rSourceActor.sType == "pc")) then
			bShowActorName = true;
		end
	end
	
	-- ADD THE SOURCE ACTOR NAME TO THE OUTPUT TEXT IF AVAILABLE, 
	-- OTHERWISE SET THE ACTIVE IDENTITY AS THE SPEAKER (USUALLY A NON-ACTION)
	if bShowActorName then
		msg.text = rSourceActor.sName .. " -> " .. msg.text;
	else
		if User.isHost() then
			msg.sender = GmIdentityManager.getCurrent();
		else
			msg.sender = User.getIdentityLabel();
		end
	end
	
	-- PORTRAIT CHAT?
	if OptionsManager.isOption("PCHT", "on") then
		if User.isHost() then
			msg.icon = "portrait_gm_token";
		else
			if rSourceActor and rSourceActor.sType == "pc" and rSourceActor.nodeCreature then
				msg.icon = "portrait_" .. rSourceActor.nodeCreature.getName() .. "_chat";
			else
				local sIdentity = User.getCurrentIdentity();
				if sIdentity and sIdentity ~= "" then
					msg.icon = "portrait_" .. User.getCurrentIdentity() .. "_chat";
				end
			end
		end
	end

	-- RESULTS
	return msg;
end

-- Message: prints a message in the Chatwindow
function Message(msgtxt, broadcast, rActor)
	local msg = createBaseMessage(rActor);
	msg.text = msg.text .. msgtxt;
	if broadcast then
		deliverMessage(msg);
	else
		addMessage(msg);
	end
end

-- SystemMessage: prints a message in the Chatwindow
function SystemMessage(msgtxt)
	local msg = {font = "systemfont"};
	msg.text = msgtxt;
	addMessage(msg);
end


--
--
-- CHAT REPORTS
--
--

function reportEffect(rEffect, sTarget)
	-- VALIDATE
	if not rEffect or not rEffect.sName or not rEffect.sExpire then
		return;
	end
	
	-- Build the basic message
	local msg = {font = "systemfont", icon = "indicator_effect"};
	
	-- Add effect details
	msg.text = RulesManager.encodeEffectAsText(rEffect, sTarget);
		
	-- Add the message locally, and deliver to host, if needed
	if User.isHost() then
		addMessage(msg);
	else
		deliverMessage(msg);
	end
end

function reportModifier(mod_name, mod_bonus)
	-- Build the basic modifier message
	local msg = {font = "systemfont"};
	msg.text = mod_name;

	-- Add the save modifier as a number to make the chat entry draggable
	msg.dicesecret = true;
	msg.dice = {};
	msg.diemodifier = mod_bonus;

	-- Deliver the message
	if User.isHost() then
		addMessage(msg);
	else
		deliverMessage(msg);
	end
end


--
--
-- SPECIAL MESSAGE HANDLING
--
--

SPECIAL_MSG_TAG = "[SPECIAL]";
SPECIAL_MSG_SEP = "|||";

specialmsghandlers = {};

function registerSpecialMsgHandler(msgtype, callback)
	specialmsghandlers[msgtype] = callback;
end

function sendSpecialMessage(msgtype, params)
	-- Hosts go directly to handling the message
	if User.isHost() then
		handleSpecialMessage(msgtype, "", "", params);
	
	-- Clients build a special message to send to the host
	else
		-- Build the special message to send
		local msg = {font = "msgfont", text = ""};
		msg.sender = SPECIAL_MSG_TAG .. SPECIAL_MSG_SEP .. msgtype .. SPECIAL_MSG_SEP .. User.getUsername() .. SPECIAL_MSG_SEP .. User.getIdentityLabel() .. SPECIAL_MSG_SEP;
		for k,v in pairs(params) do
			msg.text = msg.text .. v .. SPECIAL_MSG_SEP;
		end

		-- Deliver to the host
		deliverMessage(msg, "");
	end
end

function processSpecialMessage(msg)
	-- Only the host can process special messages
	if not User.isHost() then
		return false;
	end
	
	-- Make sure the sender this is a special message
	if string.find(msg.sender, SPECIAL_MSG_TAG, 1, true) ~= 1 then
		return false;
	end

	-- Parse out the special message details
	local msg_meta = {};
	local msg_clause;
	local clause_match = "(.-)" .. SPECIAL_MSG_SEP;
	for msg_clause in string.gmatch(msg.sender, clause_match) do
		table.insert(msg_meta, msg_clause);
	end
	local msgtype = msg_meta[2];
	local msguser = msg_meta[3];
	local msgidentity = msg_meta[4];
	
	-- Parse out the special message parameters
	local msg_params = {};
	for msg_clause in string.gmatch(msg.text, clause_match) do
		table.insert(msg_params, msg_clause);
	end
	
	-- Handle the special message
	handleSpecialMessage(msgtype, msguser, msgidentity, msg_params);
	return true;
end

function handleSpecialMessage(msgtype, msguser, msgidentity, paramlist)
	for k,v in pairs(specialmsghandlers) do
		if msgtype == k then
			v(msguser, msgidentity, paramlist);
			return;
		end
	end
	
	SystemMessage("[ERROR] Unknown special message received, Type = " .. msgtype);
end


--
--
--  DICE TOWER
--
--

function handleDiceTower(msguser, msgidentity, paramlist)
	-- Get the parameters
	local droptype = paramlist[1];
	local desc = paramlist[2];
	local dicestr = paramlist[3];
	
	-- Build the description string
	local roll_desc = "[TOWER] ";
	if msgidentity ~= "" then
		roll_desc = roll_desc .. msgidentity .. " -> ";
	else
		roll_desc = roll_desc .. "GM -> ";
	end
	roll_desc = roll_desc .. desc;

	-- Roll the dice
	local dice, modifier = StringManager.convertStringToDice(dicestr);
	RulesManager.dclkAction(droptype, modifier, roll_desc, nil, nil, dice, true);
	
	-- Return a confirmation to client, if needed
	if msguser ~= "" then
		-- Build the message
		local clientmsg = {font = "chatfont", icon = "dicetower_icon", sender = "[TOWER]", text = ""};
		if desc ~= "" then
			clientmsg.text = desc .. ": ";
		end
		clientmsg.text = clientmsg.text .. dicestr;
		
		-- Deliver the message
		deliverMessage(clientmsg, msguser);
	end
end




--
--
--  APPLY EFFECT (CT FIELDS)
--
--

function handleApplyEffect(msguser, msgidentity, paramlist)
	-- Get the parameters
	local sCTEntryNode = paramlist[1];

	local rEffect = {};
	rEffect.sName = paramlist[2];
	rEffect.sExpire = paramlist[3];
	rEffect.nInit = tonumber(paramlist[4]) or 0;
	rEffect.sSource = paramlist[5];
	rEffect.nGMOnly = tonumber(paramlist[6]) or 0;
	rEffect.sApply = paramlist[7];
	
	local sEffectTargetNode = paramlist[8] or "";
	
	-- Get the combat tracker node
	local nodeCTEntry = DB.findNode(sCTEntryNode);
	if not nodeCTEntry then
		SystemMessage("[ERROR] Unable to resolve CT effect application on node = " .. sCTEntryNode);
		return;
	end
	
	-- Apply the damage
	EffectsManager.addEffect(msguser, msgidentity, nodeCTEntry, rEffect, sEffectTargetNode, true);
end

--
--
--  EXPIRE EFFECT
--
--

function handleExpireEffect(msguser, msgidentity, paramlist)
	-- Get the combat tracker node
	local nodeActor = DB.findNode(paramlist[1]);
	if not nodeActor then
		SystemMessage("[ERROR] Unable to find actor to remove effect from = " .. paramlist[1]);
		return;
	end
	
	-- Get the combat tracker node
	local nodeEffect = DB.findNode(paramlist[2]);
	if not nodeEffect then
		SystemMessage("[ERROR] Unable to find effect to remove = " .. paramlist[2]);
		return;
	end
	
	-- Get the parameters
	local nExpireType = tonumber(paramlist[3]) or 0;
	
	-- Apply the damage
	EffectsManager.expireEffect(nodeActor, nodeEffect, nExpireType);
end


--
--
--  END TURN (CT)
--
--

function handleEndTurn(msguser, msgidentity, paramlist)
	CombatCommon.endTurn(msguser);
end

--
--
--  REMOVE CLIENT TARGET
--
--

function handleRemoveClientTarget(msguser, msgidentity, paramlist)
	local sSourceName = paramlist[1];
	local sTargetNode = paramlist[2];
	TargetingManager.removeClientTarget(msguser, sSourceName, sTargetNode);
end
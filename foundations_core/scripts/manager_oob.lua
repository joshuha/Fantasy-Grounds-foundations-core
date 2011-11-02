-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_WHISPER = "whisper";

function onInit()
	ChatManager.registerSlashHandler("/whisper", processWhisper);
	ChatManager.registerSlashHandler("/w", processWhisper);
	ChatManager.registerSlashHandler("/reply", processReply);
	ChatManager.registerSlashHandler("/r", processReply);

	registerOOBMsgHandler(OOB_MSGTYPE_WHISPER, handleWhisper);
	Comm.onReceiveOOBMessage = processOOBMessage;
end

--
--
-- FRAMEWORK
--
--

aOOBMsgHandlers = {};

function registerOOBMsgHandler(sMessageType, fCallback)
	aOOBMsgHandlers[sMessageType] = fCallback;
end

function processOOBMessage(msg)
	if not msg.type then
		return;
	end
	-- Handle the special message
	for kHandlerType, fHandler in pairs(aOOBMsgHandlers) do
		if msg.type == kHandlerType then
			fHandler(msg);
			return true;
		end
	end
	
	ChatManager.SystemMessage("[ERROR] Unknown special message received, Type = " .. msg.type);
	return true;
end

--
--
-- WHISPERS
--
--

function processWhisper(sParams)
	-- Find the target user for the whisper
	local sLowerParams = string.lower(sParams);
	local sGMIdentity = "gm ";

	local sRecipient = nil;
	if string.sub(sLowerParams, 1, string.len(sGMIdentity)) == sGMIdentity then
		sRecipient = "GM";
	else
		for kID, vID in ipairs(User.getAllActiveIdentities()) do
			local sIdentity = User.getIdentityLabel(vID);

			local sIdentityMatch = string.lower(sIdentity) .. " ";
			if string.sub(sLowerParams, 1, string.len(sIdentityMatch)) == sIdentityMatch then
				if sRecipient then
					if #sRecipient < #sIdentity then
						sRecipient = sIdentity;
					end
				else
					sRecipient = sIdentity;
				end
			end
		end
	end
	
	local sMessage;
	if sRecipient then
		sMessage = string.sub(sParams, #sRecipient + 2)
	else
		sMessage = sParams;
	end
	
	processWhisperHelper(sRecipient, sMessage);
end

sLastWhisperer = nil;

function processReply(sParams)
	if not sLastWhisperer then
		ChatManager.SystemMessage("Reply target not available.");
		return;
	end
	processWhisperHelper(sLastWhisperer, sParams);
end

function processWhisperHelper(sRecipient, sMessage)
	-- Make sure we have a valid identity and valid user owning the identity
	local sUser = nil;
	local sRecipientID = nil;
	if sRecipient then
		if sRecipient == "GM" then
			sRecipientID = "";
			sUser = "";
		else
			for kID, vID in ipairs(User.getAllActiveIdentities()) do
				local sIdentity = User.getIdentityLabel(vID);
				if sIdentity == sRecipient then
					sRecipientID = vID;
					sUser = User.getIdentityOwner(vID);
				end
			end
		end
	end
	if not sRecipientID or not sUser then
		ChatManager.SystemMessage("Whisper recipient not found \rUsage: /w GM [message]\rUsage: /w [recipient] [message]");
		return;
	end
	
	-- Check for empty message
	if sMessage == "" then
		ChatManager.SystemMessage("No whisper message found \rUsage: /w GM [message]\rUsage /w [recipient] [message]");
		return;
	end
	
	-- Make sure we have a user identity
	local sSender;
	if User.isHost() then
		sSender = "";
	else
		sSender = User.getCurrentIdentity();
		if not sSender then
			ChatManager.SystemMessage("Please select an identity before whispering.");
			return;
		end
	end
	
	-- Send the whisper
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_WHISPER;
	msgOOB.sender = sSender;
	msgOOB.receiver = sRecipientID;
	msgOOB.text = sMessage;

	if User.isHost() then
		Comm.deliverOOBMessage(msgOOB, { sUser, "" });
	else
		Comm.deliverOOBMessage(msgOOB);
	end
	
	-- Show what the user whispered
	local msg = {font = "whisperfont"};
	msg.sender = "[w] -> " .. sRecipient;
	if OptionsManager.isOption("PCHT", "on") then
		if User.isHost() then
			msg.icon = "portrait_gm_token";
		elseif msgOOB.sender then
			msg.icon = "portrait_" .. msgOOB.sender .. "_chat";
		end
	end
	msg.text = sMessage;
	
	Comm.addChatMessage(msg);
end

function handleWhisper(msgOOB)
	-- Validate
	if not msgOOB.sender or not msgOOB.receiver or not msgOOB.text then
		return;
	end

	-- Check to see if GM has asked to see whispers
	if User.isHost() then
		if msgOOB.sender == "" then
			return;
		end
		if msgOOB.receiver ~= "" and OptionsManager.isOption("SHPW", "off") then
			return;
		end
		
	-- Ignore messages not targeted to this user
	else
		if msgOOB.receiver == "" then
			return;
		end
		if not User.isOwnedIdentity(msgOOB.receiver) then
			return;
		end
	end
	
	-- Get the send and receiver labels
	local sSender, sReceiver;
	if msgOOB.sender == "" then
		sSender = "GM";
	else
		sSender = User.getIdentityLabel(msgOOB.sender);
		if not sSender then
			sSender = "<unknown>";
		end
	end
	if msgOOB.receiver == "" then
		sReceiver = "GM";
	else
		sReceiver = User.getIdentityLabel(msgOOB.receiver);
		if not sReceiver then
			sReceiver = "<unknown>";
		end
	end
	
	-- Remember last whisperer
	sLastWhisperer = sSender;
	
	-- Build the message to display
	local msg = {font = "whisperfont"};
	if User.isHost() and msgOOB.receiver ~= "" then
		msg.sender = "[w] " .. sSender .. " -> " .. sReceiver;
	else
		msg.sender = "[w] " .. sSender;
	end
	if OptionsManager.isOption("PCHT", "on") then
		if msgOOB.sender == "" then
			msg.icon = "portrait_gm_token";
		else
			msg.icon = "portrait_" .. msgOOB.sender .. "_chat";
		end
	end
	msg.text = msgOOB.text;
	
	-- Show whisper message
	Comm.addChatMessage(msg);
end



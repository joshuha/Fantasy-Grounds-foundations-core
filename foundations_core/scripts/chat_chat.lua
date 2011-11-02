-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ChatManager.registerControl(self);
	
	if User.isHost() then
		Module.onActivationRequested = moduleActivationRequested;
	end

	Module.onUnloadedReference = moduleUnloadedReference;

	deliverLaunchMessage()
end

function deliverLaunchMessage()
    local msg = {sender = "", font = "emotefont", icon="portrait_ruleset_token"};
    msg.text = "Foundations Core ruleset based on 2.8"
    addMessage(msg);
    
    local launchmsg = ChatManager.retrieveLaunchMessages();
    for keyMessage, rMessage in ipairs(launchmsg) do
    	addMessage(rMessage);
    end
end

function onClose()
	ChatManager.registerControl(nil);
end

function onReceiveMessage(msg)
	-- Special handling for client-host behind the scenes communication
	if ChatManager.processSpecialMessage(msg) then
		return true;
	end
	
	-- Otherwise, let FG know to do standard processing
	return false;
end

function onDiceLanded(draginfo)
 	return ChatManager.onDiceRoll(draginfo);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("effect") then
		local rEffect = RulesManager.decodeEffectFromDrag(draginfo);
		if rEffect then
			ChatManager.reportEffect(rEffect);
		end
		return true;
	end
end

function moduleActivationRequested(module)
	local msg = {};
	msg.text = "Players have requested permission to load '" .. module .. "'";
	msg.font = "systemfont";
	msg.icon = "indicator_moduleloaded";
	addMessage(msg);
end

function moduleUnloadedReference(module)
	local msg = {};
	msg.text = "Could not open sheet with data from unloaded module '" .. module .. "'";
	msg.font = "systemfont";
	addMessage(msg);
end

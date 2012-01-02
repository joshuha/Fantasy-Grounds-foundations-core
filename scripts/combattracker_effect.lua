-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Remove Effect", "deletepointer", 3);
	registerMenuItem("Confirm Remove", "delete", 3, 3);

	local nodeTargetList = NodeManager.createChild(getDatabaseNode(), "targets");
	if nodeTargetList then
		nodeTargetList.onChildUpdate = onTargetsChanged;
		nodeTargetList.onChildAdded = onTargetsChanged;
	end
	onTargetsChanged();
end

function onMenuSelection(selection, subselection)
	if selection == 3 and subselection == 3 then
		windowlist.deleteChild(self, true);
	end
end

function onTargetsChanged()
	if target_name then
		local aTargets = {};
		for keyTarget, winTarget in pairs(targets.getWindows()) do
			local nodeTarget = DB.findNode(winTarget.noderef.getValue());
			local sTarget = NodeManager.get(nodeTarget, "name", "");
			table.insert(aTargets, sTarget);
		end
		if #aTargets > 0 then
			target_name.setValue("Targets: " .. table.concat(aTargets, ", "));
			target_name.setVisible(true);
		else
			target_name.setValue("");
			target_name.setVisible(false);
		end
	end
end

function onDrag(button, x, y, draginfo)
	local rEffect = {};
	rEffect.sName = label.getValue();
	rEffect.sExpire = expiration.getStringValue();
	rEffect.nInit = effectinit.getValue();
	rEffect.sSource = source_name.getValue();
	rEffect.nGMOnly = isgmonly.getIndex();
	rEffect.sApply = apply.getStringValue();
	return RulesManager.dragEffect(draginfo, nil, rEffect);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackerentry") then
		local nodeCTSource = draginfo.getCustomData();
		if nodeCTSource then
			if nodeCTSource.getNodeName() == windowlist.window.getDatabaseNode().getNodeName() then
				source.setSource("");
			else
				source.setSource(nodeCTSource.getNodeName());
				effectinit.setValue(NodeManager.get(nodeCTSource, "initresult", 0));
			end
		end
		return true;
	end
end

function onExpirationChanged()
	local sExpiration = expiration.getStringValue();
	if sExpiration == "endnext" or sExpiration == "start" or sExpiration == "end" then
		if source_name.getValue() == "" then
			local sourceentry = windowlist.window.windowlist.getActiveEntry();
			if sourceentry then
				effectinit.setValue(sourceentry.initresult.getValue());
			end
		end
		effectinit.setVisible(true);
		
	else
		effectinit.setValue(windowlist.window.initresult.getValue());
		effectinit.setVisible(false);
	
	end
end

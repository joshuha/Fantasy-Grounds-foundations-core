-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

localdatabasenode = nil;
id = "";

function setId(n)
	id = n;
end

function setLocalNode(node)
	localdatabasenode = node;
	
	if node then
		if node.isStatic() then
			campaign.setValue("Server character");
		else
			campaign.setValue("Local character");
			registerMenuItem("Delete character", "delete", 3);
			registerMenuItem("Confirm Delete", "delete", 3, 3);
			
			portrait.setVisible(false);
			localportrait.setVisible(true);

			local portraitfile = User.getLocalIdentityPortrait(node);
			if portraitfile then
				localportrait.setFile(portraitfile);
			end
		end
	else
		campaign.setValue("Server character");
	end
end

function requestResponse(result, identity)
	if result and identity then
		local colortable = {};
		if CampaignRegistry and CampaignRegistry.colortables and CampaignRegistry.colortables[identity] then
			colortable = CampaignRegistry.colortables[identity];
		end
		
		User.setCurrentIdentityColors(colortable.color or "000000", colortable.blacktext or false);

		windowlist.window.close();
	else
		error.setVisible(true);
	end
end

function onMenuSelection(selection, subselection)
	if localdatabasenode and selection == 3 and subselection == 3 then
		close();
		localdatabasenode.delete();
	end
end

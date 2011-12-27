-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

identitycontrols = {};

function setCurrent(name)
	local idctrl = identitycontrols[name];

	if idctrl then	
		-- Deactivate all identities
		for k, v in pairs(identitycontrols) do
			v.setCurrent(false);
		end

		-- Set active	
		idctrl.setCurrent(true);
	end
end

function addIdentity(name, isgm)
	local idctrl = identitycontrols[name];
	
	-- Create control if not found
	if not idctrl then
		createControl("identitylist_entry", "ctrl_" .. name);

		idctrl = self["ctrl_" .. name];
		identitycontrols[name] = idctrl;
		
		idctrl.createLabel(name, isgm);
	end
end

function removeIdentity(name)
	local idctrl = identitycontrols[name];

	if idctrl then
		idctrl.destroy();
		identitycontrols[name] = nil;
	end	
end

function renameGmIdentity(name)
	for k,v in pairs(identitycontrols) do
		if v.gmidentity then
			v.rename(name);
			
			identitycontrols[name] = v;
			identitycontrols[k] = nil;
			
			return;
		end
	end
end

function onInit()
	GmIdentityManager.registerIdentityList(self);
end

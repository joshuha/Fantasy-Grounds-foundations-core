-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

widgets = {};

function update()
	for k, v in ipairs(widgets) do
		v.destroy();
	end
	widgets = {};
	
	local holders = window.getViewers();
	local p = 1;

	setAnchoredWidth(#holders * portraitspacing[1]);
	setAnchoredHeight(portraitspacing[1]);
	
	for i = 1, #holders do
		local identity = User.getCurrentIdentity(holders[i]);

		if identity then
			local bitmapname = "portrait_" .. identity .. "_" .. portraitset[1];

			widgets[i] = addBitmapWidget(bitmapname);
			widgets[i].setPosition("left", portraitspacing[1] * (p-0.5), 0);
			
			p = p + 1;
		end
	end
end

function onLogin(username, activated)
	update();
end

function onInit()
	if User.isHost() then
		window.onViewersChanged = update;
		update();
	else
		setVisible(false);
	end
end
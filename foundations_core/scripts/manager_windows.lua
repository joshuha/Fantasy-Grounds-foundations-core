-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Interface.onWindowOpened = onWindowOpened;
	Interface.onWindowClosed = onWindowClosed;
end

function onWindowOpened(window)
	if window.nopositionsave then
		return;
	end
	
	if CampaignRegistry then
		local sourcename = "";
		if window.getDatabaseNode() then
			sourcename = window.getDatabaseNode().getNodeName();
		end

		if CampaignRegistry.windowpositions then
			if CampaignRegistry.windowpositions[window.getClass()] then
				if CampaignRegistry.windowpositions[window.getClass()][sourcename] then
					local pos = CampaignRegistry.windowpositions[window.getClass()][sourcename];

					window.setPosition(pos.x, pos.y);
					window.setSize(pos.w, pos.h);
					
					if window.getClass() == "imagewindow" and window.image then
						if pos.imagex and pos.imagey and pos.imagezoom then
							window.image.setViewpoint(pos.imagex, pos.imagey, pos.imagezoom);
							
							-- Workaround to force database refresh to client for viewpoint if they have the window open
							if User.isHost() then
								window.image.setGridSize(window.image.getGridSize());
							end
						end
					end
				end
			end
		end
	end
end

function onWindowClosed(window)
	if window.nopositionsave then
		return;
	end
	
	if CampaignRegistry then
		if not CampaignRegistry.windowpositions then
			CampaignRegistry.windowpositions = {};
		end

		if not CampaignRegistry.windowpositions[window.getClass()] then
			CampaignRegistry.windowpositions[window.getClass()] = {};
		end

		-- Get window data source node name
		local sourcename = "";
		if window.getDatabaseNode() then
			sourcename = window.getDatabaseNode().getNodeName();
		end

		-- Get window positioning data
		local x, y = window.getPosition();
		local w, h = window.getSize();

		-- Store positioning data
		local pos = {};
		pos.x = x;
		pos.y = y;
		pos.w = w;
		pos.h = h;
		
		if window.getClass() == "imagewindow" and window.image then
			local nImageX, nImageY, nImageZoom = window.image.getViewpoint();
			pos.imagex = nImageX;
			pos.imagey = nImageY;
			pos.imagezoom = nImageZoom;
		end

		CampaignRegistry.windowpositions[window.getClass()][sourcename] = pos;
	end
end

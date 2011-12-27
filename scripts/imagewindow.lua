-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--
synclocked = false;



function updateToolBar()

    -- determine toolbar visibilitly
	local bShowToolbar = false
	if (toolbars.getValue() > 0) then
		bShowToolbar = true;
	end

	-- if we are the host
	if (User.isHost()) then
		
		-- set visibility of the horizontal spacer 1
		h1.setVisible(bShowToolbar);
		-- if toolbar is visible
		if (bShowToolbar) then
			-- set active color
			toggle_toolbars.setColor("ffffffff");
		else
			-- set inactive color
			toggle_toolbars.setColor("60a0a0a0");
		end

		-- set visibility of the draw toolbar
		toolbar_draw.setVisibility(bShowToolbar);
		
		-- set visibility of the horizontal spacer 2
		h2.setVisible(bShowToolbar);
		
		-- set visibility of the toggle layers toolbar button
		toggle_layers.setVisible(bShowToolbar);
		
		-- determine if layers toolbar button is toggled
		local bShowLayersToggle = false;
		if (toggle_layers.getValue() > 0) then
			bShowLayersToggle = true;
		end
		
		if (bShowLayersToggle) then
			-- set active color 
			toggle_layers.setColor("ffffffff");
		else
			-- set inactive color
			toggle_layers.setColor("60a0a0a0");
		end
		
		-- set visibility of the layers toolbar
		local bShowLayersToolbar = false;
		if (bShowToolbar) then
			bShowLayersToolbar = bShowLayersToggle;
		end
		toolbar_layers.setVisibility(bShowLayersToolbar);
		
		-- set visibility of the horizontal spacer 3
		h3.setVisible(bShowToolbar);
		
		-- set visibility of the toggle grid toolbar button
		local bShowGridToggle = false;
		if (play_image.hasGrid()) then
			bShowGridToggle = bShowToolbar;
		end
		toggle_grid.setVisible(bShowGridToggle);
		
		-- determine if grid toolbar button is toggled
		local bGridToggle = false;
		if (toggle_grid.getValue() > 0) then
			bGridToggle = true;
		end
		if (bGridToggle) then
			-- set active color
			toggle_grid.setColor("ffffffff");
		else
			-- set inactive color
			toggle_grid.setColor("60a0a0a0");
		end
		
		-- set visibility of the grid toolbar
		local bShowGridToolbar = false;
		if (bGridToggle) then
			bShowGridToolbar = bShowGridToggle;
		end
		toolbar_grid.setVisibility(bShowGridToolbar);

		-- set visibility of the horizontal spacer 4
		h4.setVisible(bShowGridToggle);
		
		-- set visibility of the toggle xy coordinates toolbar button
		--toggle_xycoord.setVisible(bShowToolbar);
		
		-- set visibility of the horizontal spacer 5
		h5.setVisible(bShowToolbar);
		
		-- determine if xy coordinates toolbar button is toggled
		local bXYToggle = false;
		if (toggle_xycoord.getValue() > 0) then
			bXYToggle = true;
		end
		if (bXYToggle) then
			-- set active color
			toggle_xycoord.setColor("ffffffff");
		else
			-- set inactive color
			toggle_xycoord.setColor("60a0a0a0");
		end
		
		-- set visibility of the xy coordinates bar and xy coordinates
		local bShowXYToolbar = false;
		if (bXYToggle) then
			bShowXYToolbar = bXYToggle;
		end
		xycoordbar.setVisible(bShowXYToolbar);
		xycoordinates.setVisible(bShowXYToolbar);
	end

	-- set visibility of the targeting toolbar
	--toolbar_targeting.setVisibility(bShowToolbar);
end

function showLayer(layername)
	if layername == "play" then
		-- Enable and set visible: play (top), Disable and set visible: features (middle) and image (bottom) image
		play_image.setEnabled(true);
		play_image.setVisible(true);
		features_image.setEnabled(false);
		features_image.setVisible(true);
		image.setEnabled(false);
		image.setVisible(true);
	elseif layername == "features" then
		-- Disable and set invisible: play (top) image, Enable and set visible: features (middle) image, Disable and set visible: image (bottom) image
		play_image.setEnabled(false);
		play_image.setVisible(false);
		features_image.setEnabled(true);
		features_image.setVisible(true);
		image.setEnabled(false);
		image.setVisible(true);
	else
		-- Disable and set invisible: play (top) and features (middle) images, Enable and set visible: image (bottom) image
		play_image.setEnabled(false);
		play_image.setVisible(false);
		features_image.setEnabled(false);
		features_image.setVisible(false);
		image.setEnabled(true);
		image.setVisible(true);
	end
end

function syncToImageGrid()
	-- Determine if base image has a grid
	 if image.hasGrid() then
		-- Copy base image (bottom layer) grid to features_image (middle layer) and play_image (top layer) 
		features_image.setGridType(image.getGridType());
		features_image.setGridSize(image.getGridSize());
		features_image.setGridOffset(image.getGridOffset());
		play_image.setGridType(image.getGridType());
		play_image.setGridSize(image.getGridSize());
		play_image.setGridOffset(image.getGridOffset());
		-- Disable base image (bottom layer) grid
		image.setGridSize(0);
	end
end

function syncToPlayImageGrid()
	-- Determine if base image has a grid
	 if play_image.hasGrid() then
		-- Copy play_image (top layer) grid to features_image (middle layer) 
		features_image.setGridType(play_image.getGridType());
		features_image.setGridSize(play_image.getGridSize());
		features_image.setGridOffset(play_image.getGridOffset());
	end
end

function syncToImageMask()
	-- Determine if base image has a mask
	 if image.hasMask() then
		-- print("Mask detected");
		-- Enable play image (top layer) mask
		play_image.setMaskEnabled(true);
		-- Disable base image (bottom layer) mask
		-- 
		image.setMaskEnabled(false);
	end
end

function syncToImageViewpoint()
	if not synclocked then
		synclocked = true;
		-- Determine base image viewpoint
		local x, y, zoom = image.getViewpoint();
		if x and y and zoom then
			-- set play and feature images (top and middle layers) to identical viewpoint
			features_image.setViewpoint(x, y, zoom);
			play_image.setViewpoint(x, y, zoom);
		end
		synclocked = false;
	end
image.syncAllOverlays()
end

function syncToFeaturesImageViewpoint()
	if not synclocked then
		synclocked = true;
		-- Determine features_image viewpoint
		local x, y, zoom = features_image.getViewpoint();
		if x and y and zoom then
			-- set play and base image (top and bottom layers) to identical viewpoint
			image.setViewpoint(x, y, zoom);
			play_image.setViewpoint(x, y, zoom);
		end
		synclocked = false;
	end
	image.syncAllOverlays()
end

function syncToPlayImageViewpoint()
	if not synclocked then
		synclocked = true;
		-- Determine play_image viewpoint
		local x, y, zoom = play_image.getViewpoint();
		if x and y and zoom then
			-- set features and base image (middle and bottom layers) to identical viewpoint
			features_image.setViewpoint(x, y, zoom);
			image.setViewpoint(x, y, zoom);
		end
		synclocked = false;
	end 
	image.syncAllOverlays()
end

function syncToImageDrawingSize()
	-- Determine base image size
	local w, h = image.getImageSize();
	if w and h then
		-- set play and feature images (top and middle layers) to identical size
		features_image.setDrawingSize(w, h, 0, 0);
		play_image.setDrawingSize(w, h, 0, 0);
	end
	
end

function onClose()
	-- Determine play image viewpoint
	local x, y, zoom = play_image.getViewpoint();
	-- Set base image viewpoint
	image.setViewpoint(x, y, zoom);
end




function onInit()
	if User.isHost()  then
		-- set image scroll and zoom handlers
		image.onZoom = syncToImageViewpoint;
		--image.onZoom = syncOverlays;
		image.onScroll = syncToImageViewpoint;
		
		features_image.onZoom = syncToFeaturesImageViewpoint;
		features_image.onScroll = syncToFeaturesImageViewpoint;
		--features_image.onZoom = syncOverlays;
		play_image.onZoom = syncToPlayImageViewpoint;
		--play_image.onZoom = syncOverlays;
		play_image.onScroll = syncToPlayImageViewpoint;
		
		-- make the toolbar visible 
		toggle_toolbars.setVisible(true);
		-- synchronise all layer to base image size
		syncToImageDrawingSize();
		-- determine if base image has a grid, disable and copy it to the play image layer
		syncToImageGrid();
		-- determine if base image has a mask, disable and enable mask on play image layer
		syncToImageMask();
		-- synchronise all layers to base image viewpoint
		syncToImageViewpoint();
	else
		-- make toolbar invisible
		toggle_toolbars.setVisible(false);
		
		winscroll.setVisible(false);
	end
	-- initialise the toolbar
	updateToolBar();
	--updateDisplay();
end
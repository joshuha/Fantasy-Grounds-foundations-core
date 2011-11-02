-- This file is part of the Fantasy Grounds Open Foundation Ruleset project. 
-- For the latest information, see http://www.fantasygrounds.com/
--
-- Copyright 2008 SmiteWorks Ltd.
--
-- This file is provided under the Open Game License version 1.0a
-- Refer to the license.html file for the full license text
--
-- All producers of work derived from this material are advised to
-- familiarize themselves with the license, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.
--
-- All material submitted to the Open Foundation Ruleset project must
-- contain this notice in a manner applicable to the source file type.
local last = {};
aTokenMarkers = {}
aMapTokens = {}

function getLastCoords()
	if last.x and last.y then
		return last.x, last.y;
	else
		return 0, 0;
	end
end

function updateLastCoords(x, y) 
	last.x = x;
	last.y = y;
end


function getClosestSnapPoint(x, y)
	if hasGrid() then
		local type = getGridType();
		local size = getGridSize();

		if type == "hexrow" or type == "hexcolumn" then
			local qw, hh = getGridHexElementDimensions();
			local ox, oy = getGridOffset();

			-- The hex grid separates into a non-square grid of elements sized qw*hh, the location in which dictates corner points
			if type == "hexcolumn" then
				local col = math.floor((x - ox) / qw);
				local row = math.floor((y - oy) * 2 / size);

				local evencol = col % 2 == 0;
				local evenrow = row % 2 == 0;

				local lx = (x - ox) % qw;
				local ly = (y - oy) % hh;

				if (evenrow and evencol) or (not evenrow and not evencol) then
					-- snap to lower right and upper left
					if lx + ly * (qw/hh) < qw then
						return ox + col*qw, oy + math.floor(row*size/2);
					else
						return ox + (col+1)*qw, oy + math.floor((row+1)*size/2);
					end
				else
					-- snap to lower left and upper right
					if (qw-lx) + ly * (qw/hh) < qw then
						return ox + (col+1)*qw, oy + math.floor(row*size/2);
					else
						return ox + col*qw, oy + math.floor((row+1)*size/2);
					end
				end
			else -- "hexrow"
				local col = math.floor((x - ox) * 2 / size);
				local row = math.floor((y - oy) / qw);

				local evencol = col % 2 == 0;
				local evenrow = row % 2 == 0;

				local lx = (x - ox) % hh;
				local ly = (y - oy) % qw;

				if (evenrow and evencol) or (not evenrow and not evencol) then
					-- snap to lower right and upper left
					if lx * (qw/hh) + ly < qw then
						return ox + math.floor(col*size/2), oy + row*qw;
					else
						return ox + math.floor((col+1)*size/2), oy + (row+1)*qw;
					end
				else
					-- snap to lower left and upper right
					if (hh-lx) * (qw/hh) + ly < qw then
						return ox + math.floor((col+1)*size/2), oy + row*qw;
					else
						return ox + math.floor(col*size/2), oy + (row+1)*qw;
					end
				end
			end
		else -- if type == "square" then
			local ox, oy = getGridOffset();
			
			local basex = math.floor((x - (ox + 1))/(size/2))*(size/2) + (ox + 1);
			local basey = math.floor((y - (oy + 1))/(size/2))*(size/2) + (oy + 1);
			
			local newx = basex;
			local newy = basey;
			
			if ((x - basex) > (size / 4)) then
				newx = newx + (size / 2);
			end
			if ((y - basey) > (size / 4)) then
				newy = newy + (size / 2);
			end
			
			return newx, newy;
		end
	end
	
	return x, y;
end

function onTokenSnap(token, x, y)
	if hasGrid() then
		return getClosestSnapPoint(x, y);
	else
		return x, y;
	end
end

function onPointerSnap(startx, starty, endx, endy, pointertype)
	local newstartx = startx;
	local newstarty = starty;
	local newendx = endx;
	local newendy = endy;

	if hasGrid() then
		newstartx, newstarty = getClosestSnapPoint(startx, starty);
		newendx, newendy = getClosestSnapPoint(endx, endy);
	end

	return newstartx, newstarty, newendx, newendy;
end


function measureVector(vx, vy, gridtype, gridsize, qw, hh)
	local dist = 0;
	
	if gridtype == "hexrow" or gridtype == "hexcolumn" then
		local col, row = 0, 0;
		if gridtype == "hexcolumn" then
			col = vx / (qw*3);
			row = (vy / (hh*2)) - (col * 0.5);
		else		
			row = vy / (qw*3);
			col = (vx / (hh*2)) - (row * 0.5);
		end

		if	((row >= 0 and col >= 0) or (row < 0 and col < 0)) then
			dist = math.abs(col) + math.abs(row);
		else
			dist = math.max(math.abs(col), math.abs(row));
		end
	
	else --	if gridtype == "square" then
		local gx = math.abs(vx / gridsize);
		local gy = math.abs(vy / gridsize);
		dist = math.max(gx, gy);
	end
	
	return dist;
end

function onMeasureVector(token, vector)
	local dist = "";

	if hasGrid() then
		local gridtype = getGridType();
		local gridsize = getGridSize();

		local gridScale = 1;
		if window.getDatabaseNode().getChild("gridscale") then
			gridScale = window.getDatabaseNode().getChild("gridscale").getValue();
		end
		
		local gridUnit = "";
		if window.getDatabaseNode().getChild("gridunit") then
			gridUnit = window.getDatabaseNode().getChild("gridunit").getValue();
		end	
		
		dist = 0;
		if gridtype == "hexrow" or gridtype == "hexcolumn" then
			local qw, hh = getGridHexElementDimensions();
			for i = 1, #vector do
				local nVector = measureVector(vector[i].x, vector[i].y, gridtype, gridsize, qw, hh);
				dist = dist + nVector;
			end
		else -- if gridtype == "square" then
			for i = 1, #vector do
				local nVector = measureVector(vector[i].x, vector[i].y, gridtype, gridsize);
				dist = dist + nVector;
			end
		end
		
		dist = math.floor(dist * gridScale);
		if pointertype == "square" then
			dist = dist*2
		end
		dist = dist .. " " .. gridUnit;
		
		
	end
	
	return "" .. dist;
end

function onMeasurePointer(length, pointertype, startx, starty, endx, endy)
	local dist = "";

	if hasGrid() then
		local gridtype = getGridType();
		local gridsize = getGridSize();

		local gridScale = 1;
		if window.getDatabaseNode().getChild("gridscale") then
			gridScale = window.getDatabaseNode().getChild("gridscale").getValue();
		end

		local gridUnit = "";
		if window.getDatabaseNode().getChild("gridunit") then
			gridUnit = window.getDatabaseNode().getChild("gridunit").getValue();
		end

		if gridtype == "hexrow" or gridtype == "hexcolumn" then
			local qw, hh = getGridHexElementDimensions();
			dist = measureVector(endx - startx, endy - starty, gridtype, gridsize, qw, hh);
		else -- if gridtype == "square" then
			dist = measureVector(endx - startx, endy - starty, gridtype, gridsize);
		end

		dist = math.floor(dist * gridScale);
		if pointertype == "square" then
			dist = dist*2
		end
		dist = dist .. " " .. gridUnit;
		
	
	end
	
	return "" .. dist;
end

function gridPrefTypeChanged(valuename, value)
	if valuename == "images_hexgrid" then
		if value then
			setGridToolType("hex");
		else
			setGridToolType("square");
		end
	end
end

function onGridStateChanged(type)
	if User.isHost() then
		if type == "square" then
			setTokenOrientationCount(8);
		else
			setTokenOrientationCount(12);
		end
	end
end
function onMaskingStateChanged(tool)
	window.toolbar_draw.onValueChanged();
end

function onDrawingSizeChanged()
	 if self.getName() == "image" then
	 	window.syncToImageDrawingSize();
	 end
end

function onDrawStateChanged(tool)
	window.toolbar_draw.onValueChanged();
end

function onTokenClickRelease(token,button)
	if User.isHost() and Input.isControlPressed() and button == 1 then
		x,y = token.getPosition()
		scale = token.getScale()
		name = token.getPrototype()
		w,h = token.getImageSize()
		orientation = token.getOrientation()
		vx,vx,vzoom = getViewpoint()
		if not vzoom or vzoom == 0 then
			vzoom = 1
		end
		statenum,statemax = string.match(name,"%[(%d)o(%d)%]")
		if statenum == statemax then
			statenum = 1
		else
			statenum = statenum+1
		end
		newtokenname = string.gsub(name,"%[(%d)o(%d)%]","%["..statenum.."o%2%]")
		
		newtoken = addToken(newtokenname,x,y)
		newtoken.setOrientation(orientation)	
		newtoken.setScale(scale)
		for i,marker in ipairs(aTokenMarkers) do
			if marker.linkedtoken == token.getPrototype()..token.getId() then
				aTokenMarkers[i].linkedtoken = newtoken.getPrototype()..newtoken.getId()
				updateOverlay(newtoken)
			end
		end
		aMapTokens[newtoken.getPrototype()..newtoken.getId()] = aMapTokens[token.getPrototype()..token.getId()] 
		token.delete()
		return true;
	end
end

function onTokenContainerChanging(token)
	token.onMenuSelection = function () end;
	token.onClickRelease = function () end;
	token.onWheel = function ()  if User.isHost() and Input.isControlPressed() then return true; end; end;
	token.onContainerChanging = function () end;
	token.onScaleChanged = function () end
	token.onDelete = function () end
	token.onClickDown = function () end
end

function onTokenWheel(token, notches)
	if User.isHost() and Input.isControlPressed() then
		if Input.isShiftPressed() then
			newscale = math.floor(token.getScale() + notches);
			if newscale < 1 then
				newscale = 1;
			end
		else
			newscale = token.getScale() + (notches * 0.1);
			if newscale < 0.1 then
				newscale = 0.1;
			end
		end
		
		token.setScale(newscale);

		return true;
	end
end

function onDrop(x, y, draginfo)

	local dragtype = draginfo.getType()
	
	if dragtype == "combattrackerff" then
		-- Grab faction data from drag object
		local sFaction = draginfo.getStringData()

		-- Determine image viewpoint
		-- Handle zoom factor (>100% or <100%) and offset drop coordinates
		local vpx, vpy, vpz = getViewpoint()
		if vpz > 1 then
			x = x / vpz
			y = y / vpz
		elseif vpz < 1 then
			x = x + (x * vpz)
			y = y + (y * vpz)
		end
		
		-- If grid, then snap drop point and adjust drop spread
		local nDropSpread = 15
		if hasGrid() then
			x, y = getClosestSnapPoint(x, y)
			nDropSpread = getGridSize()
		end

		-- Get the CT window
		local ctwnd = Interface.findWindow("combattracker_window", "combattracker")
		if ctwnd then
		    -- Loop through the CT entries
			for k,v in pairs(ctwnd.list.getWindows()) do
				-- Make sure we have the right fields to work with
				if v.token and v.friendfoe then
					-- Look for entries with the same faction
					if v.friendfoe.getStringValue() == sFaction then
						-- Get the entries token image
						local tokenproto = v.token.getPrototype()
						if tokenproto then
						    -- Add it to the image at the drop coordinates 
							local addedtoken = addToken(tokenproto, x, y)

							-- Update the CT entry's token references
							v.token.replace(addedtoken)

							-- Offset drop coordinates for next token = nice spread :)
							if x >= (nDropSpread * 1.5) then
								x = x - nDropSpread
							end
							if y >= (nDropSpread * 1.5) then
								y = y - nDropSpread
							end
						end
					end
				end
			end
		end
		
		return true
	end
end


function onTokenMenuSelection(token, selection, selection2, selection3)
	if selection == 2 then
		token.setScale(1)
	elseif selection == 4 and selection2 == 1 then
		x,y = token.getPosition()
		scale = token.getScale()
		name = token.getPrototype()
		w,h = token.getImageSize()
		orientation = token.getOrientation()
		vx,vx,vzoom = getViewpoint()
		if not vzoom or vzoom == 0 then
				vzoom = 1
		end
		statenum,statemax = string.match(name,"%[(%d)o(%d)%]")
		if statenum == statemax then
			statenum = 1
		else
			statenum = statenum+1
		end
		newtokenname = string.gsub(name,"%[(%d)o(%d)%]","%["..statenum.."o%2%]")
		
		newtoken = addToken(newtokenname,x,y)
		newtoken.setOrientation(orientation)	
		newtoken.setScale(scale)
		for i,marker in ipairs(aTokenMarkers) do
			if marker.linkedtoken == token.getPrototype()..token.getId() then
				marker.linkedtoken = newtoken.getPrototype()..newtoken.getId()
				updateOverlay(newtoken)
			end
		end
		aMapTokens[newtoken.getPrototype()..newtoken.getId()] = aMapTokens[token.getPrototype()..token.getId()] 
		token.delete()
				
	elseif selection == 4 and selection2 == 4 then
		_aTokenMarkers = {}
		for i,marker in ipairs(aTokenMarkers) do
			if marker.linkedtoken == token.getPrototype()..token.getId() then
				marker.selflink.delete()
			else
				table.insert(_aTokenMarkers,marker)
			end
		end
		aTokenMarkers = _aTokenMarkers
		if aMapTokens[token.getPrototype()..token.getId()] then
			aMapTokens[token.getPrototype()..token.getId()].slot1 = false
			aMapTokens[token.getPrototype()..token.getId()].slot2 = false
			aMapTokens[token.getPrototype()..token.getId()].slot3 = false
			aMapTokens[token.getPrototype()..token.getId()].slot4 = false
			aMapTokens[token.getPrototype()..token.getId()].slot5 = false
			aMapTokens[token.getPrototype()..token.getId()].slot6 = false
			aMapTokens[token.getPrototype()..token.getId()].slot7 = false
			aMapTokens[token.getPrototype()..token.getId()].slot8 = false
		end
	elseif selection == 4 and selection2 == 3 and selection3 == 1 then
		if aMapTokens[token.getPrototype()..token.getId()] then
			deleteSlotToken(token.getPrototype()..token.getId(),1,true)
		end
	elseif selection == 4 and selection2 == 3 and selection3 == 2 then
		if aMapTokens[token.getPrototype()..token.getId()] then
			deleteSlotToken(token.getPrototype()..token.getId(),2,true)
		end
	elseif selection == 4 and selection2 == 3 and selection3 == 3 then
		if aMapTokens[token.getPrototype()..token.getId()] then
			deleteSlotToken(token.getPrototype()..token.getId(),3,true)
		end
	elseif selection == 4 and selection2 == 3 and selection3 == 4 then
		if aMapTokens[token.getPrototype()..token.getId()] then
			deleteSlotToken(token.getPrototype()..token.getId(),4,true)
		end
	elseif selection == 4 and selection2 == 3 and selection3 == 5 then
		if aMapTokens[token.getPrototype()..token.getId()] then
			deleteSlotToken(token.getPrototype()..token.getId(),5,true)
		end
	elseif selection == 4 and selection2 == 3 and selection3 == 6 then
		if aMapTokens[token.getPrototype()..token.getId()] then
			deleteSlotToken(token.getPrototype()..token.getId(),6,true)
		end
	elseif selection == 4 and selection2 == 3 and selection3 == 7 then
		if aMapTokens[token.getPrototype()..token.getId()] then
			deleteSlotToken(token.getPrototype()..token.getId(),7,true)
		end
	elseif selection == 4 and selection2 == 3 and selection3 == 8 then
		if aMapTokens[token.getPrototype()..token.getId()] then
			deleteSlotToken(token.getPrototype()..token.getId(),8,true)
		end		
	end
end

function saveTokenExtensions()
	if not CampaignRegistry.TokenExtensions then
		CampaignRegistry.TokenExtensions = {};
	end
	if not CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()] then
		CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()] = {};
	end
	for k,marker in pairs(aTokenMarkers) do
		marker.selflink = ""
	end
	CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()].aTokenMarkers = aTokenMarkers
	CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()].aMapTokens = aMapTokens
end

function onClose()
	if aTokenMarkers or aMapTokens then
		saveTokenExtensions()
	end
end

function onTokenAdded(token)
	overlaycheck = string.find(token.getPrototype(), "overlay%_")
	slotcheck = string.find(token.getPrototype(), "slot%_")
	if not overlaycheck and not slotcheck then
		if User.isHost() then
			token.registerMenuItem("Token options", "radial_effect", 4)
			token.registerMenuItem("Advance frame", "radial_heal", 4,1)
			token.registerMenuItem("Delete all overlays", "deleteallpointers", 4,4)
			token.registerMenuItem("Delete specific slot", "deletepointer", 4,3)
			token.registerMenuItem("Slot 1", "deletepointer", 4,3,1)
			token.registerMenuItem("Slot 2", "num2", 4,3,2)
			token.registerMenuItem("Slot 3", "num3", 4,3,3)
			token.registerMenuItem("Slot 4", "num4", 4,3,4)
			token.registerMenuItem("Slot 5", "num5", 4,3,5)
			token.registerMenuItem("Slot 6", "num6", 4,3,6)
			token.registerMenuItem("Slot 7", "num7", 4,3,7)
			token.registerMenuItem("Slot 8", "num8", 4,3,8)
		end
		token.onMenuSelection = onTokenMenuSelection
		token.onClickRelease = onTokenClickRelease
		token.onWheel = onTokenWheel
		token.onContainerChanging = onTokenContainerChanging
		token.onMove = updateOverlay
		token.onScaleChanged = updateOverlay
		token.onDelete = onTokenDeleted
		token.onDrop = onTokenDroppedOn
	else
		token.onDelete = onTokenDeleted
		for i,marker in ipairs(aTokenMarkers) do
			if marker.selfname == token.getPrototype()..token.getId() then
				marker.selflink = token
			end
		end
	end
	
end

function onTokenDeleted(token)
	token.onMenuSelection = function () end
	token.onClickRelease = function () end
	token.onWheel = function () end
	token.onContainerChanging = function () end
	token.onMove = function () end
	token.onScaleChanged = function () end
	token.onDelete = function () end
	token.onClickDown = function () end
	token.onDrop = function () end
	
	_aTokenMarkers = {}
	for i,marker in ipairs(aTokenMarkers) do
		if marker.selfname == token.getPrototype()..token.getId() then
			if marker.type == "slot" then
				deleteSlotToken(marker.linkedtoken,marker.slotnum,false)
			end
		elseif marker.linkedtoken == token.getPrototype()..token.getId() then
			marker.onDelete = function () end
			marker.selflink.delete()
		else
			table.insert(_aTokenMarkers,marker)
		end
	end
	aTokenMarkers = _aTokenMarkers
	
	if aMapTokens[token.getPrototype()..token.getId()] then
		aMapTokens[token.getPrototype()..token.getId()] = nil
	end

end

function onTokenDroppedOn(token,dragdata)
	overlaycheck = string.find(token.getPrototype(), "overlay%_")
	slotcheck = string.find(token.getPrototype(), "slot%_")
	if dragdata.getType() == "token" and not overlaycheck and not slotcheck then
		slotcheck = string.find(dragdata.getTokenData(), "slot%_")
		overlaycheck = string.find(dragdata.getTokenData(), "overlay%_")
		if overlaycheck then
			tokenx, tokeny = token.getPosition()
			tokenscale = token.getScale()
			tokenw,tokenh = token.getImageSize()
			
			newoverlay = {}
			newoverlay.linkedtoken = token.getPrototype()..token.getId()
			newoverlay.tokenimage = dragdata.getTokenData()
			newoverlay.type = "overlay"
						
			temptoken = addToken(newoverlay.tokenimage,-100,-100)
			newoverlay.w,newoverlay.h = temptoken.getImageSize()
			temptoken.delete()
						
			xscale = tokenw/newoverlay.h
			yscale = tokenh/newoverlay.h
			newoverlay.scale = math.max(xscale,yscale)
			newoverlay.x = tokenx
			newoverlay.y = tokeny
						
			newoverlaytoken = addToken(newoverlay.tokenimage, newoverlay.x, newoverlay.y)
			newoverlaytoken.setScale(newoverlay.scale)
			newoverlaytoken.setModifiable(false)
			newoverlaytoken.onClickDown = function () return false end
			newoverlaytoken.onClickRelease = function () return false end
			
			newoverlay.selflink = newoverlaytoken
			newoverlay.selfname = newoverlaytoken.getPrototype()..newoverlaytoken.getId()
			table.insert(aTokenMarkers, newoverlay)
		end
		if slotcheck then
			tokenx, tokeny = token.getPosition()
			tokenscale = token.getScale()
			tokenw,tokenh = token.getImageSize()
			vx,vy,vzoom = getViewpoint()
			if not vzoom or vzoom == 0 then
				vzoom = 1
			end
						
			newslot = {}
			newslot.linkedtoken = token.getPrototype()..token.getId()
			newslot.tokenimage = dragdata.getTokenData()
			newslot.type = "slot"
					
			temptoken = addToken(newslot.tokenimage,-100,-100)
			newslot.w,newslot.h = temptoken.getImageSize()
			temptoken.delete()
			
			tokenWH = (tokenw+tokenh)/2
			newslotWH = (newslot.w+newslot.h)/2
			newslot.scale = tokenWH/(newslotWH*5)
			
			slotnum = getNextSlot(token)
			newslot.slotnum = slotnum
			if slotnum == 1 then
				newslot.x = tokenx-tokenw/(2*vzoom)*tokenscale+newslot.w/(2*vzoom)*newslot.scale*tokenscale
				newslot.y = tokeny+tokenh/(2*vzoom)*tokenscale-newslot.h/(2*vzoom)*newslot.scale*tokenscale
			elseif slotnum  == 2 then
				newslot.x = tokenx-tokenw/(2*vzoom)*tokenscale+newslot.w/(2*vzoom)*newslot.scale*tokenscale*5
				newslot.y = tokeny+tokenh/(2*vzoom)*tokenscale-newslot.h/(2*vzoom)*newslot.scale*tokenscale
			elseif slotnum  == 3 then
				newslot.x = tokenx-tokenw/(2*vzoom)*tokenscale+newslot.w/(2*vzoom)*newslot.scale*tokenscale*9
				newslot.y = tokeny+tokenh/(2*vzoom)*tokenscale-newslot.h/(2*vzoom)*newslot.scale*tokenscale
			elseif slotnum  == 4 then
				newslot.x = tokenx-tokenw/(2*vzoom)*tokenscale+newslot.w/(2*vzoom)*newslot.scale*tokenscale*9
				newslot.y = tokeny+tokenh/(2*vzoom)*tokenscale-newslot.h/(2*vzoom)*newslot.scale*tokenscale*5
			elseif slotnum  == 5 then
				newslot.x = tokenx-tokenw/(2*vzoom)*tokenscale+newslot.w/(2*vzoom)*newslot.scale*tokenscale*9
				newslot.y = tokeny+tokenh/(2*vzoom)*tokenscale-newslot.h/(2*vzoom)*newslot.scale*tokenscale*9
			elseif slotnum  == 6 then
				newslot.x = tokenx-tokenw/(2*vzoom)*tokenscale+newslot.w/(2*vzoom)*newslot.scale*tokenscale*5
				newslot.y = tokeny+tokenh/(2*vzoom)*tokenscale-newslot.h/(2*vzoom)*newslot.scale*tokenscale*9
			elseif slotnum  == 7 then
				newslot.x = tokenx-tokenw/(2*vzoom)*tokenscale+newslot.w/(2*vzoom)*newslot.scale*tokenscale
				newslot.y = tokeny+tokenh/(2*vzoom)*tokenscale-newslot.h/(2*vzoom)*newslot.scale*tokenscale*9
			elseif slotnum  == 8 then
				newslot.x = tokenx-tokenw/(2*vzoom)*tokenscale+newslot.w/(2*vzoom)*newslot.scale*tokenscale
				newslot.y = tokeny+tokenh/(2*vzoom)*tokenscale-newslot.h/(2*vzoom)*newslot.scale*tokenscale*5
			end
			if slotnum >= 1 then
				newslottoken = addToken(newslot.tokenimage, newslot.x, newslot.y)
				newslottoken.setScale(newslot.scale*tokenscale)
				newslottoken.setModifiable(false)
				newslottoken.onClickDown = function () return false end
				newslottoken.onClickRelease = function () return false end
				
				newslot.selflink = newslottoken
				newslot.selfname = newslottoken.getPrototype()..newslottoken.getId()
								
				table.insert(aTokenMarkers, newslot)
				assignSlotToken(token,newslot.selfname,slotnum)
			end
		end
		return true
	end
end


function onClickDown(button, x, y)
	 if User.isHost() then 
	    -- Determine if middle mouse button is clicked
		if button==2 then
		    -- update last x, y position with current coordinates
			last.x = x;
			last.y = y;
		end
	end
end

function onDrag(button, x, y, draginfo)
	if User.isHost() then
		-- Determine if middle mouse button is clicked
		if button == 2 then
			-- Determine drag distance since initial click
		local dx = x - (last.x or 0);
		local dy = y - (last.y or 0);
			-- Determine image viewpoint
		local nx, ny, zoom = getViewpoint();
			 -- update last x, y position with current coordinates
		updateLastCoords(x,y);
			-- set the new viepoint based upon current viewpoint + drag distance
		window.image.setViewpoint(nx+dx, ny+dy, zoom);
			-- sync viewpoints for all layers
		window.syncToImageViewpoint();
		return true;
		end
	 end
end

function onHoverUpdate(x, y)
	if User.isHost() then
		-- Determine image viewpoint
		-- Handle zoom factor (>100% or <100%) and offset x, y coordinates
		local vpx, vpy, vpz = getViewpoint();
		x = x / vpz;
		y = y / vpz;
		
		-- Update x, y coordinates value in window control 
		window.xycoordinates.setValue(round(x, 0) .. "," .. round(y, 0));
	end
end

function round(value, dp)
  local result = value * (10^dp);
  result = math.floor(result + 0.5);
  return result / (10^dp);
end



function onInit()
	if CampaignRegistry then
		if CampaignRegistry.TokenExtensions then
			if CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()] then
				if CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()].aTokenMarkers then
					aTokenMarkers = CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()].aTokenMarkers
				end
				if CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()].aMapTokens then
					aMapTokens = CampaignRegistry.TokenExtensions[window.getDatabaseNode().getName()].aMapTokens
				end
			end
		end
	end

	onGridStateChanged(getGridType());

	for keyToken, refToken in pairs(getTokens()) do
		onTokenAdded(refToken);
	end

	
end


-- custom functions
function getNextSlot(token)
	if aMapTokens[token.getPrototype()..token.getId()] == nil then
		aMapTokens[token.getPrototype()..token.getId()] = {}
		aMapTokens[token.getPrototype()..token.getId()].slot1 = true
		aMapTokens[token.getPrototype()..token.getId()].slot2 = false
		aMapTokens[token.getPrototype()..token.getId()].slot3 = false
		aMapTokens[token.getPrototype()..token.getId()].slot4 = false
		aMapTokens[token.getPrototype()..token.getId()].slot5 = false
		aMapTokens[token.getPrototype()..token.getId()].slot6 = false
		aMapTokens[token.getPrototype()..token.getId()].slot7 = false
		aMapTokens[token.getPrototype()..token.getId()].slot8 = false
		slotnum = 1
	else
		if aMapTokens[token.getPrototype()..token.getId()].slot1 == false then
			aMapTokens[token.getPrototype()..token.getId()].slot1 = true
			slotnum = 1
		elseif aMapTokens[token.getPrototype()..token.getId()].slot2 == false then
			aMapTokens[token.getPrototype()..token.getId()].slot2 = true
			slotnum = 2
		elseif aMapTokens[token.getPrototype()..token.getId()].slot3 == false then
			aMapTokens[token.getPrototype()..token.getId()].slot3 = true
			slotnum = 3
		elseif aMapTokens[token.getPrototype()..token.getId()].slot4 == false then
			aMapTokens[token.getPrototype()..token.getId()].slot4 = true
			slotnum = 4
		elseif aMapTokens[token.getPrototype()..token.getId()].slot5 == false then
			aMapTokens[token.getPrototype()..token.getId()].slot5 = true
			slotnum = 5
		elseif aMapTokens[token.getPrototype()..token.getId()].slot6 == false then
			aMapTokens[token.getPrototype()..token.getId()].slot6 = true
			slotnum = 6
		elseif aMapTokens[token.getPrototype()..token.getId()].slot7 == false then
			aMapTokens[token.getPrototype()..token.getId()].slot7 = true
			slotnum = 7
		elseif aMapTokens[token.getPrototype()..token.getId()].slot8 == false then
			aMapTokens[token.getPrototype()..token.getId()].slot8 = true
			slotnum = 8
		else 
			slotnum = 0
		end
	end
	return slotnum
end

function assignSlotToken(token,newslotname,slotnum)
	if slotnum == 1 then
		aMapTokens[token.getPrototype()..token.getId()].slot1token = newslotname
	elseif slotnum == 2 then
		aMapTokens[token.getPrototype()..token.getId()].slot2token = newslotname
	elseif slotnum == 3 then
		aMapTokens[token.getPrototype()..token.getId()].slot3token = newslotname
	elseif slotnum == 4 then
		aMapTokens[token.getPrototype()..token.getId()].slot4token = newslotname
	elseif slotnum == 5 then
		aMapTokens[token.getPrototype()..token.getId()].slot5token = newslotname
	elseif slotnum == 6 then
		aMapTokens[token.getPrototype()..token.getId()].slot6token = newslotname
	elseif slotnum == 7 then
		aMapTokens[token.getPrototype()..token.getId()].slot7token = newslotname
	elseif slotnum == 8 then
		aMapTokens[token.getPrototype()..token.getId()].slot8token = newslotname
	end
end

function deleteSlotToken(tokenname,slotnum,menu)

	if slotnum == 1 then
		aMapTokens[tokenname].slot1 = false
		slotname = aMapTokens[tokenname].slot1token
		aMapTokens[tokenname].slot1token = nil
	elseif slotnum == 2 then
		aMapTokens[tokenname].slot2 = false
		slotname = aMapTokens[tokenname].slot2token
		aMapTokens[tokenname].slot2token = nil
	elseif slotnum == 3 then
		aMapTokens[tokenname].slot3 = false
		slotname = aMapTokens[tokenname].slot3token
		aMapTokens[tokenname].slot3token = nil
	elseif slotnum == 4 then
		aMapTokens[tokenname].slot4 = false
		slotname = aMapTokens[tokenname].slot4token
		aMapTokens[tokenname].slot4token = nil
	elseif slotnum == 5 then
		aMapTokens[tokenname].slot5 = false
		slotname = aMapTokens[tokenname].slot5token
		aMapTokens[tokenname].slot5token = nil
	elseif slotnum == 6 then
		aMapTokens[tokenname].slot6 = false
		slotname = aMapTokens[tokenname].slot6token
		aMapTokens[tokenname].slot6token = nil
	elseif slotnum == 7 then
		aMapTokens[tokenname].slot7 = false
		slotname = aMapTokens[tokenname].slot7token
		aMapTokens[tokenname].slot7token = nil
	elseif slotnum == 8 then
		aMapTokens[tokenname].slot8 = false
		slotname = aMapTokens[tokenname].slot8token
		aMapTokens[tokenname].slot8token = nil
	end

	if menu then
		for i,marker in ipairs(aTokenMarkers) do
			if  marker.selfname == slotname then
				 marker.selflink.delete()
			 end
		end
	end
end

function updateOverlay(token)
	tokenx, tokeny = token.getPosition()
	tokenscale = token.getScale()
	tokenw,tokenh = token.getImageSize()
	vx,vy,vzoom = getViewpoint()
	if not vzoom or vzoom == 0 then
		vzoom = 1
	end
	
	for i,marker in ipairs(aTokenMarkers) do
		if marker.linkedtoken == token.getPrototype()..token.getId() then
			if marker.type == "overlay" then
				xscale = tokenw/marker.w
				yscale = tokenh/marker.h
				marker.scale = math.max(xscale,yscale)
				
				marker.x = tokenx
				marker.y = tokeny
				marker.selflink.setPosition(tokenx,tokeny)
				marker.selflink.setScale(marker.scale)
			end
			if marker.type == "slot" then
			
				tokenWH = (tokenw+tokenh)/2
				slotWH = (marker.w+marker.h)/2
				marker.scale = tokenWH/(slotWH*5)
				marker.selflink.setScale(marker.scale*tokenscale)
				slotnum = marker.slotnum
				if slotnum == 1 then
					marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale
					marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale
				elseif slotnum  == 2 then
					marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*5
					marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale
				elseif slotnum  == 3 then
					marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*9
					marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale
				elseif slotnum  == 4 then
					marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*9
					marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*5
				elseif slotnum  == 5 then
					marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*9
					marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*9
				elseif slotnum  == 6 then
					marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*5
					marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*9
				elseif slotnum  == 7 then
					marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale
					marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*9
				elseif slotnum  == 8 then
					marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale
					marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*5
				end
				marker.selflink.setPosition(marker.x,marker.y)
			end
		end
	end
	
	
end

function syncAllOverlays()
	vx,vy,vzoom = getViewpoint()
	if not vzoom or vzoom == 0 then
		vzoom = 1
	end
	for keyToken, token in pairs(getTokens()) do
		overlaycheck = string.find(token.getPrototype(), "overlay%_")
		slotcheck = string.find(token.getPrototype(), "slot%_")
		if not overlaycheck and not slotcheck then
			tokenx, tokeny = token.getPosition()
			tokenscale = token.getScale()
			tokenw,tokenh = token.getImageSize()
			for i,marker in ipairs(aTokenMarkers) do
				if marker.type == "slot" and marker.linkedtoken == token.getPrototype()..token.getId() then
					if marker.slotnum  == 1 then
						marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale
						marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale
					elseif marker.slotnum  == 2 then
						marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*5
						marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale
					elseif marker.slotnum  == 3 then
						marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*9
						marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale
					elseif marker.slotnum  == 4 then
						marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*9
						marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*5
					elseif marker.slotnum  == 5 then
						marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*9
						marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*9
					elseif marker.slotnum  == 6 then
						marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale*5
						marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*9
					elseif marker.slotnum  == 7 then
						marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale
						marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*9
					elseif marker.slotnum  == 8 then
						marker.x = tokenx-tokenw/(2*vzoom)*tokenscale+marker.w/(2*vzoom)*marker.scale*tokenscale
						marker.y = tokeny+tokenh/(2*vzoom)*tokenscale-marker.h/(2*vzoom)*marker.scale*tokenscale*5
					end

					marker.selflink.setPosition(marker.x,marker.y)
					
					tokenWH = (tokenw+tokenh)/2
					slotWH = (marker.w+marker.h)/2
					marker.scale = tokenWH/(slotWH*5)
				
					marker.selflink.setScale(marker.scale*tokenscale)
				end
			end
		end
	end
end

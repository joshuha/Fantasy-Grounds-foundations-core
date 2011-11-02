-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

triggers = {};
currentcolor = { r = 255, g = 255, b = 255 };
blacktext = true;

function createButton(angle, size, color)
	addBitmapWidget("colorgizmo_" .. size .. "btn_base").setRadialPosition(88, angle);

	local w = addBitmapWidget("colorgizmo_" .. size .. "btn_color");
	w.setRadialPosition(88, angle);
	w.setColor(color);

	addBitmapWidget("colorgizmo_" .. size .. "btn_effects").setRadialPosition(88, angle);

	return w;
end

function registerTrigger(angle, size, method, amount)
	local trigger = {};
	
	trigger.x = math.sin((2 * math.pi * angle) / 100) * 88;
	trigger.y = -(math.cos((2 * math.pi * angle) / 100) * 88);
	
	trigger.size = size;
	
	trigger.method = method;
	trigger.amount = amount;
	
	table.insert(triggers, trigger);
end

function getCurrentColors()
	local c, b = User.getCurrentIdentityColors();
	local hextranslate = { ['0'] = 0, ['1'] = 1, ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6, ['7'] = 7,
						   ['8'] = 8, ['9'] = 9, ['a'] = 10, ['b'] = 11, ['c'] = 12, ['d'] = 13, ['e'] = 14, ['f'] = 15 };
	
	blacktext = b;
	
	currentcolor.r = hextranslate[string.sub(c, 3, 3)] * 16 + hextranslate[string.sub(c, 4, 4)];
	currentcolor.g = hextranslate[string.sub(c, 5, 5)] * 16 + hextranslate[string.sub(c, 6, 6)];
	currentcolor.b = hextranslate[string.sub(c, 7, 7)] * 16 + hextranslate[string.sub(c, 8, 8)];

	updateColors();
end

function updateColors()
	local colorstr = string.format("ff%02x%02x%02x", currentcolor.r, currentcolor.g, currentcolor.b);

	-- Local settings
	color.setColor(colorstr)
	if blacktext then
		textbg.setColor("ffffffff");
		textfg.setColor("ff000000");
	else
		textbg.setColor("ff000000");
		textfg.setColor("ffffffff");
	end

	-- System settings
	User.setCurrentIdentityColors(colorstr, blacktext);
	
	-- Save in registry
	local identity = User.getCurrentIdentity();
	if identity then
		CampaignRegistry.colortables = CampaignRegistry.colortables or {};
		CampaignRegistry.colortables[identity] = CampaignRegistry.colortables[identity] or {};

		CampaignRegistry.colortables[identity].color = colorstr;
		CampaignRegistry.colortables[identity].blacktext = blacktext;
	end
end

function onInit()
	addBitmapWidget("colorgizmo_base");
	color = addBitmapWidget("colorgizmo_color");
	addBitmapWidget("colorgizmo_effects");
	
	redbigcolor = createButton(10, "big", "ffff0000");
	redmedcolor = createButton(17, "med", "ffff0000");
	redsmlcolor = createButton(23, "sml", "ffff0000");

	greenbigcolor = createButton(64, "big", "ff00ff00");
	greenmedcolor = createButton(71, "med", "ff00ff00");
	greensmlcolor = createButton(77, "sml", "ff00ff00");

	bluebigcolor = createButton(87, "big", "ff0000ff");
	bluemedcolor = createButton(94, "med", "ff0000ff");
	bluesmlcolor = createButton(00, "sml", "ff0000ff");

	blackbigcolor = createButton(44, "big", "ff000000");
	whitebigcolor = createButton(53, "big", "ffffffff");

	addBitmapWidget("colorgizmo_bigbtn_base").setRadialPosition(88, 33);
	textbg = addBitmapWidget("colorgizmo_bigbtn_color");
	textbg.setRadialPosition(88, 33);
	textfg = addBitmapWidget("colorgizmo_bigbtn_text");
	textfg.setRadialPosition(88, 33);
	addBitmapWidget("colorgizmo_bigbtn_effects").setRadialPosition(88, 33);

	
	registerTrigger(10, 15, "red", 50);
	registerTrigger(17, 12, "red", 30);
	registerTrigger(23, 8, "red", 10);
	
	registerTrigger(64, 15, "green", 50);
	registerTrigger(71, 12, "green", 30);
	registerTrigger(77, 8, "green", 10);

	registerTrigger(87, 15, "blue", 50);
	registerTrigger(94, 12, "blue", 30);
	registerTrigger(00, 8, "blue", 10);

	registerTrigger(44, 15, "black", 20);
	registerTrigger(53, 15, "white", 20);

	registerTrigger(33, 15, "text", 20);

	getCurrentColors();
end

function onClickDown(button, x, y)
	local w, h = getSize();
	local mx, my = x - w/2, y - h/2;

	for k, v in ipairs(triggers) do
		if (mx-v.x)*(mx-v.x) + (my-v.y)*(my-v.y) <= v.size*v.size then
			
			if v.method == "red" then
				local adj = 255 - currentcolor.r;
				if adj > v.amount then
					currentcolor.r = currentcolor.r + v.amount;
				else
					currentcolor.r = 255;
					adj = v.amount - adj;
					currentcolor.g = currentcolor.g - adj;
					currentcolor.b = currentcolor.b - adj;
				end
			end
			if v.method == "green" then
				local adj = 255 - currentcolor.g;
				if adj > v.amount then
					currentcolor.g = currentcolor.g + v.amount;
				else
					currentcolor.g = 255;
					adj = v.amount - adj;
					currentcolor.r = currentcolor.r - adj;
					currentcolor.b = currentcolor.b - adj;
				end
			end
			if v.method == "blue" then
				local adj = 255 - currentcolor.b;
				if adj > v.amount then
					currentcolor.b = currentcolor.b + v.amount;
				else
					currentcolor.b = 255;
					adj = v.amount - adj;
					currentcolor.r = currentcolor.r - adj;
					currentcolor.g = currentcolor.g - adj;
				end
			end
			if v.method == "black" then
				currentcolor.r = currentcolor.r - v.amount;
				currentcolor.g = currentcolor.g - v.amount;
				currentcolor.b = currentcolor.b - v.amount;
			end
			if v.method == "white" then
				currentcolor.r = currentcolor.r + v.amount;
				currentcolor.g = currentcolor.g + v.amount;
				currentcolor.b = currentcolor.b + v.amount;
			end
			if v.method == "text" then
				blacktext = not blacktext;
			end
			
			if currentcolor.r < 0 then
				currentcolor.r = 0;
			elseif currentcolor.r > 255 then
				currentcolor.r = 255;
			end
			if currentcolor.g < 0 then
				currentcolor.g = 0;
			elseif currentcolor.g > 255 then
				currentcolor.g = 255;
			end
			if currentcolor.b < 0 then
				currentcolor.b = 0;
			elseif currentcolor.b > 255 then
				currentcolor.b = 255;
			end

			updateColors();			

			break;
		end
	end
end

function onWheel(notches)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end
	
	local amount = 10*notches;

	currentcolor.r = currentcolor.r + amount;
	currentcolor.g = currentcolor.g + amount;
	currentcolor.b = currentcolor.b + amount;

	if currentcolor.r < 0 then
		currentcolor.r = 0;
	elseif currentcolor.r > 255 then
		currentcolor.r = 255;
	end
	if currentcolor.g < 0 then
		currentcolor.g = 0;
	elseif currentcolor.g > 255 then
		currentcolor.g = 255;
	end
	if currentcolor.b < 0 then
		currentcolor.b = 0;
	elseif currentcolor.b > 255 then
		currentcolor.b = 255;
	end

	updateColors();			
	return true;
end

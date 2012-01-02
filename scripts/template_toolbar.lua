-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local nButtons = 0;
local aButtons = {};

local nButtonSize = 20;
local nButtonHorzMargin = 1;
local nButtonVertMargin = 2;

function onInit()
	if parameters then
		if parameters[1].horzmargin then
			nButtonHorzMargin = tonumber(parameters[1].horzmargin[1]) or nButtonHorzMargin;
		end
		if parameters[1].vertmargin then
			nButtonVertMargin = tonumber(parameters[1].vertmargin[1]) or nButtonVertMargin;
		end
		if parameters[1].buttonsize then
			nButtonSize = tonumber(parameters[1].buttonsize[1]) or nButtonSize;
		end
	end

	if button and type(button[1]) == "table" then
		for k, v in ipairs(button) do
			if v.id and v.icon then
				local sID = v.id[1];
				local sIcon = v.icon[1];

				local sTooltip = "";
				if v.tooltip then
					sTooltip = v.tooltip[1];
				end

				addButton(sID, sIcon, sTooltip);
			end
		end
	end
	
	if not toggle then
		highlightAll();
	end
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function addButton(sID, sIcon, sTooltip)
	local button = window.createControl("toolbar_button", "");
	if button then
		local x = nButtonHorzMargin + (nButtons * (nButtonSize + nButtonHorzMargin));
		nButtons = nButtons + 1;

		local nBarWidth = x + nButtonSize + nButtonHorzMargin;
		setAnchoredWidth(nBarWidth);
		setAnchoredHeight(nButtonSize + (2 * nButtonVertMargin));
		local w,h = getSize();

		button.setAnchor("left", getName(), "left", "absolute", x);
		button.setAnchor("top", getName(), "top", "absolute", nButtonVertMargin);
		button.setAnchoredWidth(nButtonSize);
		button.setAnchoredHeight(nButtonSize);

		button.configure(self, sID, sIcon, sTooltip);
		
		aButtons[sID] = button;

		if isVisible() then
			button.setVisible(true);
		end
	end
end

function setActive(target)
	for id, button in pairs(aButtons) do
		if id == target then
			button.highlight(true);
		else
			button.highlight(false);
		end
	end
end

function highlightAll()
	for id, button in pairs(aButtons) do
		button.highlight(true);
	end
end

function setVisibility(bVisible)
	setVisible(bVisible);
	
	for id, button in pairs(aButtons) do
		button.setVisible(bVisible);
	end
end

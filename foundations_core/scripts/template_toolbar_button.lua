-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local winParentBar = nil;
local sButtonID = "";

local sButtonHighlightColor = "ffffffff";
local sButtonNormalColor = "60a0a0a0";

function onClickDown(...)
	if winParentBar then
		return true;
	end
end

function onClickRelease(...)
	if winParentBar and winParentBar.onButtonPress then
		winParentBar.onButtonPress(sButtonID);
	end
end

function configure(win, sID, sIcon, sTooltip)
	winParentBar = win;
	sButtonID = sID;

	setIcon(sIcon);
	setColor(sButtonNormalColor);
	setTooltipText(sTooltip);
end

function highlight(bParam)
	local bHighlight = false;
	if bParam or bParam == nil then
		bHighlight = true;
	end
	
	if bHighlight then
		setColor(sButtonHighlightColor);
	else
		setColor(sButtonNormalColor);
	end
end
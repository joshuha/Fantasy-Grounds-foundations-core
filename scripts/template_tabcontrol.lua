-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local TAB_SIZE = 67
local topWidget = nil;
local tabIndex = 1;
local tabs = {};

function activateTab(index)
	index = tonumber(index);
	if index > 0 and index < #tabs+1 then
		-- Hide active tab, fade text labels
		tabs[tabIndex].widget.setColor("80ffffff");
		window[tabs[tabIndex].subwindow].setVisible(false);
		if tabs[tabIndex].scroller then
			window[tabs[tabIndex].scroller].setVisible(false);
		end 

		-- Set new index
		tabIndex = index;

		-- Move helper graphic into position
		topWidget.setPosition("topleft", 5, TAB_SIZE*(tabIndex-1)+7);
		if tabIndex == 1 then
			topWidget.setVisible(false);
		else
			topWidget.setVisible(true);
		end
		
		-- Activate text label and subwindow
		tabs[tabIndex].widget.setColor("ffffffff");

		window[tabs[tabIndex].subwindow].setVisible(true);
		for _,tab in pairs(tabs) do
			tab.widget.bringToFront();
		end
		if tabs[tabIndex].scroller then
			window[tabs[tabIndex].scroller].setVisible(true);
		end
	end
end

function onClickDown(button, x, y)
	local i = math.ceil(y/TAB_SIZE);
	
	activateTab(i);
end

function onDoubleClick(x, y)
	-- Emulate single click
	onClickDown(1, x, y);
end

function registerTab(name, icon, scroller)
	local widget = addBitmapWidget(icon);
	widget.setPosition("topleft", 7, TAB_SIZE*(#tabs)+41);
	widget.setColor("80ffffff");
	widget.bringToFront();
	tabs[#tabs+1] = {widget = widget, subwindow = name, scroller = scroller};
	
	setAnchoredHeight(22 + #tabs * TAB_SIZE);
	
	if #tabs == 1 then 
		activateTab(1);
	end
end

function onInit()
	-- Create a helper graphic widget to indicate that the selected tab is on top
	topWidget = addBitmapWidget(tabtopicon[1]);
	topWidget.setVisible(false);

	-- as we're have a merge rule set for tabs, an "empty" implementation will still have tab set to {1 = TRUE}
	if #tab > 1 or tab[1] ~= true then
		for _,t in ipairs(tab) do
			registerTab(t.subwindow[1], t.icon[1], t.scroller and t.scroller[1] or nil);
		end
	end
	
	if activate then
		activateTab(activate[1]);
	end
end

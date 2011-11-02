-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function isFiltered(wnd)
	if wnd.myfilter then
		if wnd.myfilter.getValue() == 1 then
			return true;
		end
	end

	return false;
end

function altColor()
	local alt = true;

	for i,wnd in ipairs(getWindows()) do
		if not isFiltered(wnd) then
			if alt then
				wnd.setFrame("rowshade",0,0,0,0);
			else
				wnd.setFrame(nil)
			end

			alt = not alt;
		end
	end
end

function onListRearranged(listchange)
	altColor();
end

function onFilter(w)
	local top = w.windowlist.window;
	while top.windowlist do
		top = top.windowlist.window;
	end
	if not top.filter then
		return true;
	end

	local f = string.lower(top.filter.getValue());
	if f == "" then
		w.windowlist.window.showFullHeaders(true);
		w.myfilter.setValue(0);
		return true;
	end

	w.windowlist.window.showFullHeaders(false);
	w.windowlist.setVisible(true);

	if string.find(string.lower(w.name.getValue()), f, 0, true) then
		w.myfilter.setValue(0);
		return true;
	end

	w.myfilter.setValue(1);
	return false;
end

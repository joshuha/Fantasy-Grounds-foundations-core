-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onEnter()
	local wnd = NodeManager.createWindow(window.windowlist);
	if wnd then
		wnd[getName()].setFocus();
	end
	return true;
end

function onNavigateLeft()
	local prev = window.windowlist.getPrevWindow(window);
	if prev then
		prev[getName()].setFocus();
		prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
		prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
	end
end

function onNavigateRight()
	local next = window.windowlist.getNextWindow(window);
	if next then
		next[getName()].setFocus();
		next[getName()].setCursorPosition(1);
		next[getName()].setSelectionPosition(1);
	end
end

function onDeleteUp()
	local prev = window.windowlist.getPrevWindow(window);

	if prev then
		prev[getName()].setFocus();
		prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
		prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
		
		if getValue() == "" then
			delete();
		end
	elseif getValue() == "" then
		local next = window.windowlist.getNextWindow(window);

		if next then
			next[getName()].setFocus();
			next[getName()].setCursorPosition(1);
			next[getName()].setSelectionPosition(1);
		end
		
		delete();
	end
end

function onDeleteDown()
	local next = window.windowlist.getNextWindow(window);
	
	if next then
		next[getName()].setFocus();
		next[getName()].setCursorPosition(1);
		next[getName()].setSelectionPosition(1);

		if getValue() == "" then
			delete();
		end
	elseif getValue() == "" then
		local prev = window.windowlist.getPrevWindow(window);

		if prev then
			prev[getName()].setFocus();
			prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
			prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
		end
		
		delete();
	end
end

function delete()
	if window.windowlist.deleteChild then
		window.windowlist.deleteChild(window, true);
	else
		window.getDatabaseNode().delete();
	end
end

function onGainFocus()
	window.setFrame("rowshade");
end

function onLoseFocus()
	window.setFrame(nil);
end

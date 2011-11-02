-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onIntegrityChange()
	if window.getDatabaseNode().isIntact() then
		resetMenuItems();
		integritywidget.setBitmap("indicator_record_intact");
	else
		registerMenuItem("Revert Changes", "shuffle", 8);
		integritywidget.setBitmap("indicator_record_dirty");
	end
end

function onInit()
	if window.getDatabaseNode().getModule() then
		integritywidget = addBitmapWidget("indicator_record_intact");
		integritywidget.setPosition("center", 3, 0);
		integritywidget.setVisible(true);
		
		setTooltipText(window.getDatabaseNode().getModule());
		
		window.getDatabaseNode().onIntegrityChange = onIntegrityChange;
		onIntegrityChange();
	end
end

function onMenuSelection(selection)
	if selection == 8 then
		window.getDatabaseNode().revert();
	end
end

function onDrag(button, x, y, draginfo)
	if dragging then
		return true;
	end
	
	draginfo.setType("shortcut");
	draginfo.setIcon(icon[1].normal[1]);
	draginfo.setShortcutData(getValue());
	draginfo.setDescription(getTargetDatabaseNode().getChild("name").getValue());

	dragging = true;
	return true;
end

function onDragEnd(draginfo)
	dragging = false;
end

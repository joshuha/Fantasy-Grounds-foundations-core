-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

--
-- CHARACTER SHEET MANAGER
--   - Authored by Ben Turner (phantomwhale)
--
-- This manager script allows extensions to define the "sheets" to include on the character sheet.
-- This is done by registering / deregistering sheets on start up. See the function descriptions below
-- for how to use this script.
--
-- The default behaviour is to register a single sheet called "main" - see the onInit() method.
--

-- Hash of catgeories to lists of sheets
local sheets = {};

--
-- Registers a sheet called "mainsheet", using the "main_charsheet" windowclass and the "tab_main" graphic for the tab text
-- Does this for both main and minisheet tab sets
--
function onInit()
	registerSheet("main", "mainsheet", "main_charsheet", "tab_main")
	registerSheet("mini", "mainsheet", "main_minisheet", "tab_main")
end


-- Registers a sheet for inclusion on character sheets
--
-- Params:
--   category    - category for this sheet - usually "main" or "mini"
--   name        - name of the sheet, which must be unique. Attempts to register a second sheet of the same name will remove the old sheet, taking it's place if the before parameter has not been specified
--   windowclass - the name of the windowclass or template to be created for this particular sheet
--   tabicon     - the name of the icon contained the tab image (usually text to appear over the background tab)
--   before      - if specified, tab will be added before the tab of this name. If no such tab of that name has been registered, or the parameter is not supplied, then the tab will be added to the end of the list
--
function registerSheet(category, name, windowclass, tabicon, before)
  sheets[category] = sheets[category] or {}
	local index = #sheets[category] + 1
	for key,sheet in ipairs(sheets[category]) do
		if sheet.name == name then
			table.remove(sheets[category], key)
			index = key
		end
		index = (sheet.name == before) and key or index
	end
	table.insert(sheets[category], index, {name = name, windowclass = windowclass, tabicon = tabicon})
end

--
-- Removes a sheet from the resistry
--
-- Params:
--   category    - category for this sheet - usually "main" or "mini"
--   name        - name of the sheet you wish to remove from the character sheet
--
function deregisterSheet(category, name, windowclass, tabicon, before)
	sheets[category] = sheets[category] or {}
	for key,sheet in ipairs(sheets[category]) do
		if sheet.name == name then
			table.remove(sheets.category, key)
		end
	end
end
	
-- 
-- PUBLIC FUNCTIONS
--
	
--
-- Populate the character sheet window with the registered sheets
--
-- Params:
--   category    - category for this sheet - usually "main" or "mini"
--   win         - character sheet window to be populated
--	
function populate(category, win)
	for _,sheet in ipairs(sheets[category]) do
		win.addSheet(sheet.name, sheet.windowclass, sheet.tabicon)
	end
end


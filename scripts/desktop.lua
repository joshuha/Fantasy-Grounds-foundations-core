-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if not User.isLocal() then
		if User.isHost() then
			Interface.openWindow("chat","")
			
			DesktopManager.registerStackShortcut("button_light", "button_light_down", "Lighting", "lightingselection");
			DesktopManager.registerStackShortcut("button_color", "button_color_down", "Colors", "pointerselection");
			DesktopManager.registerStackShortcut("button_characters", "button_characters_down", "Characters", "charactersheetlist", "charsheet");
			DesktopManager.registerStackShortcut("button_modules", "button_modules_down", "Modules", "moduleselection");
			DesktopManager.registerStackShortcut("button_ct", "button_ct_down", "Combat Tracker", "combattracker_window", "combattracker");
			DesktopManager.registerStackShortcut("button_modifiers", "button_modifiers_down", "Modifiers", "modifierlist", "modifiers");
			DesktopManager.registerStackShortcut("button_effects", "button_effects_down", "Effects", "effectlist", "effects");
			DesktopManager.registerStackShortcut("button_options", "button_options_down", "Options", "options");
			
			DesktopManager.registerDockShortcut("button_book", "button_book_down", "Story", "encounterlist", "encounter");
			DesktopManager.registerDockShortcut("button_maps", "button_maps_down", "Maps &\rImages", "imagelist", "image");
			DesktopManager.registerDockShortcut("button_encounter", "button_encounter_down", "Encounters", "battlelist", "battle");
			DesktopManager.registerDockShortcut("button_people", "button_people_down", "Personalities", "npclist", "npc");
			DesktopManager.registerDockShortcut("button_notes", "button_notes_down", "Notes", "notelist", "notes");
			DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
			
			DesktopManager.registerDockShortcut("button_tokencase", "button_tokencase_down", "Tokens", "tokenbag", nil, true);
		else
			DesktopManager.registerStackShortcut("button_portraits", "button_portraits_down", "Portraits", "portraitselection");
			DesktopManager.registerStackShortcut("button_color", "button_color_down", "Colors", "pointerselection");
			DesktopManager.registerStackShortcut("button_characters", "button_characters_down", "Characters", "identityselection");
			DesktopManager.registerStackShortcut("button_modules", "button_modules_down", "Modules", "moduleselection");
			DesktopManager.registerStackShortcut("button_ct", "button_ct_down", "Combat tracker", "clienttracker_window", "combattracker");
			DesktopManager.registerStackShortcut("button_options", "button_options_down", "Options", "options");
			DesktopManager.registerStackShortcut("button_modifiers", "button_modifiers_down", "Modifiers", "modifierlist", "modifiers");
			DesktopManager.registerStackShortcut("button_effects", "button_effects_down", "Effects", "effectlist", "effects");
			
			DesktopManager.registerDockShortcut("button_book", "button_book_down", "Story", "encounterlist", "encounter");
			DesktopManager.registerDockShortcut("button_maps", "button_maps_down", "Maps &\rImages", "imagelist", "image");
			DesktopManager.registerDockShortcut("button_notes", "button_notes_down", "Notes", "notelist", "notes");
			DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
			
			DesktopManager.registerDockShortcut("button_tokencase", "button_tokencase_down", "Tokens", "tokenbag", nil, true);
		end
	else
		DesktopManager.registerStackShortcut("button_characters", "button_characters_down", "Characters", "identityselection");
		DesktopManager.registerStackShortcut("button_pointer", "button_pointer_down", "Colors", "pointerselection");
		DesktopManager.registerStackShortcut("button_portraits", "button_portraits_down", "Portraits", "portraitselection");
		DesktopManager.registerStackShortcut("button_modules", "button_modules_down", "Modules", "moduleselection");

		DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
	end
end

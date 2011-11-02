-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local aCategories = {};
local bUpdatingCategories = false;

function onListRearranged(bEntriesChanged)
	if bEntriesChanged and not bUpdatingCategories then
		bUpdatingCategories = true;

		-- Close all category headings
		for k, v in pairs(aCategories) do
			v.window.close();
		end
		aCategories = {};

		-- Create new category headings
		for k, v in ipairs(getWindows()) do
			local sCategory = NodeManager.get(v.getDatabaseNode(), "categoryname", "");
			if sCategory ~= "" and not aCategories[sCategory] then
				-- Create category header
				local c = {};
				c.window = createWindowWithClass("library_booklistcategory");
				if c.window then
					c.window.name.setValue(sCategory);
				end
				
				aCategories[sCategory] = c;
			end
		end
		
		applySort();
		
		bUpdatingCategories = false;
	end
end

function onSortCompare(w1, w2)
	local bIsCategory1, bIsCategory2;
	local sCategory1, sCategory2;

	if w1.getClass() == "library_booklistentry" then
		sCategory1 = NodeManager.get(w1.getDatabaseNode(), "categoryname", "");
		bIsCategory1 = false;
	elseif w1.getClass() == "library_booklistcategory" then
		sCategory1 = w1.name.getValue();
		bIsCategory1 = true;
	end
	if w2.getClass() == "library_booklistentry" then
		sCategory2 = NodeManager.get(w2.getDatabaseNode(), "categoryname", "");
		bIsCategory2 = false;
	elseif w2.getClass() == "library_booklistcategory" then
		sCategory2 = w2.name.getValue();
		bIsCategory2 = true;
	end

	if not sCategory1 then
		sCategory1 = "";
	end
	if not sCategory2 then
		sCategory2 = "";
	end

	if sCategory1 ~= sCategory2 then
		return sCategory1 > sCategory2;
	end
	
	if bIsCategory1 then
		return false;
	elseif bIsCategory2 then
		return true;
	end
	
	local sValue1 = string.lower(w1.name.getValue());
	local sValue2 = string.lower(w2.name.getValue());
	if sValue1 ~= sValue2 then
		return sValue1 > sValue2;
	end

	return w1.getDatabaseNode().getName() > w2.getDatabaseNode().getName();
end

-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

-- Adds the username to the list of holders for the given node
function addWatcher (sNode, sUser)
	local node = DB.findNode(sNode);
	if not node then
		node = DB.createNode(sNode);
	end

	if node then
		node.addHolder(sUser);
	end	
end

-- Removes all users from the list of holders for the given node
function removeAllWatchers(sNode)
	local node = DB.findNode(sNode);
	if node then
		node.removeAllHolders(false);
	end
end

-- Copy the source node into the node tree under the destination parent node
-- Used recursively to handle node subtrees
--
-- NOTE: Node types supported are: 
-- 			number, string, image, dice, windowreference, node
function copy(nodeSource, nodeDestParent, bUseDefaultID)
    -- VALIDATE
    if not nodeSource or not nodeDestParent then
    	return nil;
    end
    
    -- NEW NODE VARIABLE
    local nodeNew = nil;
    
    -- SOURCE NODE DETAILS
    local sNodeType = nodeSource.getType();
    local sNode = nodeSource.getName();

    -- BASIC NODES
    if sNodeType == "number" or sNodeType == "string" or sNodeType == "image" or sNodeType == "dice" or sNodeType == "windowreference" then
      	nodeNew = createChild(nodeDestParent, sNode, sNodeType);
      	if nodeNew then
      		nodeNew.setValue(nodeSource.getValue());
      	end

    -- LIST NODES
    elseif sNodeType == "node" then
		if bUseDefaultID then
			nodeNew = createChild(nodeDestParent);
		else
			nodeNew = createChild(nodeDestParent, sNode);
		end
		for keyNode, nodeSub in pairs(nodeSource.getChildren()) do
			copy(nodeSub, nodeNew);
		end
	end
	
	return nodeNew;
end

-- Sets the given value into the fieldname child of sourcenode.  
-- If the fieldname child node does not exist, then it is created.
function set(nodeSource, sField, sFieldType, varInitial)
	if nodeSource and sField and sFieldType then
		nodeChild = createChild(nodeSource, sField, sFieldType);
		if nodeChild then
			nodeChild.setValue(varInitial);
			return nodeChild;
		end
	end

	return nil;
end

-- Gets the given value of the fieldname child of sourcenode.  
-- If the fieldname child node does not exist, then the defaultval is returned instead.
function get(nodeSource, sField, varDefault)
	if nodeSource then
		local nodeChild = nodeSource.getChild(sField);
		if nodeChild then
			local varReturn = nodeChild.getValue();
			if varReturn then
				return varReturn;
			end
		end
	end
	
	return varDefault;
end

--
-- SAFE NODE CREATION
--

function isReadOnly(nodeSource)
	if not nodeSource then
		return true;
	end
	
	if nodeSource.isStatic() then
		return true;
	end
	
	if User.isHost() or User.isLocal() then
		return false;
	end
	
	if nodeSource.isOwner() then
		return false;
	end
	
	return true;
end

function createChild(nodeSource, sField, sFieldType)
	if not nodeSource then
		return nil;
	end
	
	if not isReadOnly(nodeSource) then
		if sField then
			if sFieldType then
				return nodeSource.createChild(sField, sFieldType);
			else
				return nodeSource.createChild(sField);
			end
		else
			return nodeSource.createChild();
		end
	end

	if not sField then
		return nil;
	end

	return nodeSource.getChild(sField);
end

function createWindow(winList)
	if not winList then
		return nil;
	end
	
	local nodeWindowList = winList.getDatabaseNode();
	if nodeWindowList then
		if isReadOnly(nodeWindowList) then
			return nil;
		end
	end
	
	return winList.createWindow();
end

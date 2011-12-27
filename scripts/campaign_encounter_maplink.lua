-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	checkLink();
end

function onClose()
	deleteLink();
end

function tokenDeleted(tokenLinked)
	imageid.setValue(0);
end

function tokenMoved(tokenLinked)
	local x,y = tokenLinked.getPosition();
	imagex.setValue(x);
	imagey.setValue(y);
end

function deleteLink()
	if imageid.getValue() ~= 0 then
		local tokenLinked = Token.getToken(imagelink.getValue(), imageid.getValue());
		if tokenLinked then
			tokenLinked.delete();
		end
	end
end

function checkLink()
	if imagelink.getValue() == "" then
		token.setVisible(true);
		linked.setVisible(false);
	else
		token.setVisible(false);
		linked.setVisible(true);
	end
end

function setLink(tokenLinked)
	if tokenLinked then
		local nodeContainer = tokenLinked.getContainerNode();
		if nodeContainer then
			imagelink.setValue(nodeContainer.getNodeName());
			imageid.setValue(tokenLinked.getId());

			local x,y = tokenLinked.getPosition();
			imagex.setValue(x);
			imagey.setValue(y);

			tokenLinked.onDelete = tokenDeleted;
			tokenLinked.onMove = tokenMoved;
		end
	end
	
	checkLink();
end

function clearLink()
	deleteLink();

	imagelink.setValue("");
	imageid.setValue(0);
	
	checkLink();
end

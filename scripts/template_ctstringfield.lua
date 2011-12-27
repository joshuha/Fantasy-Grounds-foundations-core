-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

locked = false;
linknode = nil;

function onInit()
	if not User.isHost() then
		setReadOnly(true);
	end

	if self.update then
		self.update();
	end
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.getType() ~= "number" then
			return false;
		end

		if self.handleDrop then
			self.handleDrop(draginfo);
			return true;
		end
	end
end

function onValueChanged()
	if self.update then
		self.update();
	end

	if linknode and not isReadOnly() then
		if not locked then
			locked = true;
			linknode.setValue(getValue());
			locked = false;
		end
	end

end

function onLinkUpdated(source)
	if source then
		if not locked then
			locked = true;
			setValue(source.getValue());
			locked = false;
		end
	end

	if self.update then
		self.update();
	end
end

function setLink(dbnode, readonly)
	if dbnode then
		linknode = dbnode;
		linknode.onUpdate = onLinkUpdated;

		addBitmapWidget("indicator_linked").setPosition("bottomright", -5, -5);
		
		if readonly == true then
			setReadOnly(true);
			setFrame(nil);
		end

		onLinkUpdated(linknode);
	end
end

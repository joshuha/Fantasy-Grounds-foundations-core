-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

sources = {};
ops = {};
hasSources = false;

function sourceUpdate()
	if self.onSourceUpdate then
		self.onSourceUpdate();
	end
end

function calculateSources()
	local n = 0;

	local c = 0;
	for k, v in pairs(ops) do
		if sources[k] then
			if v == "+" then
				n = n + self.onSourceValue(sources[k], k); --sources[k].getValue();
			elseif v == "-" then
				n = n - self.onSourceValue(sources[k], k); --sources[k].getValue();
			elseif v == "*" then
				n = n * self.onSourceValue(sources[k], k); --sources[k].getValue();
			elseif v == "/" then
				n = n / self.onSourceValue(sources[k], k); --sources[k].getValue();
			elseif v == "neg+" then
				if self.onSourceValue(sources[k], k) < 0 then
					n = n + self.onSourceValue(sources[k], k); --sources[k].getValue();
				end
			end
			
			c = c+1;
		end
	end

	return n;
end

function onSourceValue(source, sourcename)
	return source.getValue();
end

function onSourceUpdate(source)
	setValue(calculateSources());
end

function addSource(name)
	local node = NodeManager.createChild(window.getDatabaseNode(), name, "number");
	if node then
		sources[name] = node;
		node.onUpdate = sourceUpdate;
		hasSources = true;
	end
end

function addSourceWithOp(name, op)
	addSource(name);
	ops[name] = op;
end

function onInit()
	if super.onInit then
		super.onInit();
	end

	if source and type(source[1]) == "table" then
		for k, v in ipairs(source) do
			if v.name and type(v.name) == "table" then
				addSource(v.name[1]);
				
				if (v.op) then
					ops[v.name[1]] = v.op[1];
				end
			end
		end
	end

	if hasSources then
		sourceUpdate();
	end
end

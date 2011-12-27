-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--


function getEffectStructures(nodeAbility)
	-- ACTOR
	local nodeChar = nil;
	if nodeAbility then
		nodeChar = nodeAbility.getChild(".......");
	end
	local rActor = CombatCommon.getActor("pc", nodeChar);

	local rEffect = {};

	rEffect.sName = EffectsManager.evalEffect(rActor, NodeManager.get(nodeAbility, "label", ""));
	rEffect.sExpire = NodeManager.get(nodeAbility, "expiration", "");
	rEffect.sApply = NodeManager.get(nodeAbility, "apply", "");
	rEffect.sTargeting = NodeManager.get(nodeAbility, "targeting", "");
	
	if rActor then
		rEffect.sSource = rActor.sCTNode;
		rEffect.nInit = NodeManager.get(rActor.nodeCT, "initresult", 0);
	else
		rEffect.sSource = "";
		rEffect.nInit = 0;
	end
	
	return rActor, rEffect;
end

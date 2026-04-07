if not Cursive.nampower then
	return
end

-- add (1) for first stack of buffs/debuffs
-- other addons already do this, avoid having to parse both formats
AURAADDEDOTHERHELPFUL = "%s gains %s (1)."
AURAADDEDOTHERHARMFUL = "%s is afflicted by %s (1)."
AURAADDEDSELFHARMFUL = "You are afflicted by %s (1)."
AURAADDEDSELFHELPFUL = "You gain %s (1)."

Cursive.core = CreateFrame("Frame", "Cursive", UIParent)

Cursive.core.tooltipScan = CreateFrame("GameTooltip", "CursiveTooltipScan", UIParent, "GameTooltipTemplate")

Cursive.core.guids = {}

Cursive.core.add = function(unit)
	local _, guid = UnitExists(unit)

	if guid and not UnitIsDead(unit) then
		Cursive.core.guids[guid] = GetTime()
	end
end

Cursive.core.addGuid = function(guid)
	if UnitExists(guid) and not UnitIsDead(guid) then
		Cursive.core.guids[guid] = GetTime()
	end
end

Cursive.core.remove = function(guid)
	Cursive.core.guids[guid] = nil
end

Cursive.core.ScanUnits = function()
	Cursive.core.add("target")
	Cursive.core.add("mouseover")
	for i = 1, 8 do
		Cursive.core.add("mark"..i)
	end
	for i = 1, 4 do
		Cursive.core.add("party"..i.."target")
	end
	for i = 1, 40 do
		Cursive.core.add("raid"..i.."target")
	end
end

Cursive.core.enable = function()
	-- unitstr
	Cursive.core:RegisterEvent("PLAYER_TARGET_CHANGED")
	Cursive.core:RegisterEvent("RAID_TARGET_UPDATE")
	-- arg1
  Cursive.core:RegisterEvent("UNIT_COMBAT_GUID") -- this can get called with player/target/raid1 etc
  Cursive.core:RegisterEvent("UNIT_MODEL_CHANGED_GUID")
end

Cursive.core.disable = function()
	Cursive.core:UnregisterEvent("PLAYER_TARGET_CHANGED")
	Cursive.core:UnregisterEvent("RAID_TARGET_UPDATE")
	Cursive.core:UnregisterEvent("UNIT_COMBAT")
	Cursive.core:UnregisterEvent("UNIT_MODEL_CHANGED")
	Cursive.core.guids = {}
end

Cursive.core:SetScript("OnEvent", function()
	if event == "PLAYER_TARGET_CHANGED" or event == "RAID_TARGET_UPDATE" then
		this.ScanUnits()
	else
		-- arg1 can be a guid or a unitid
		if arg1 and string.sub(arg1, 1, 2) == "0x" then
			this.addGuid(arg1)
		else
			this.add(arg1)
		end
	end
end)

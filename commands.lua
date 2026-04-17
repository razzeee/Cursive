local L = AceLibrary("AceLocale-2.2"):new("Cursive")
local curseCommands = L["|cffffcc00Cursive:|cffffaaaa Commands:"]
local priorityChoices = L["|cffffcc00Priority choices:"]
local curseOptions = L["|cffffcc00Options (separate with ,):"]

local commandOptions = {
	warnings = L["Display text warnings when a curse fails to cast."],
	resistsound = L["Play a sound when a curse is resisted."],
	expiringsound = L["Play a sound when a curse is about to expire."],
	allowooc = L["Allow out of combat targets to be multicursed.  Would only consider using this solo to avoid potentially griefing raids/dungeons by pulling unintended mobs."],
	priotarget = L["Always prioritize current target when choosing target for multicurse.  Does not affect 'curse' command."],
	ignoretarget = L["Ignore the current target when choosing target for multicurse.  Does not affect 'curse' command."],
	playeronly = L["Only choose players and ignore npcs when choosing target for multicurse.  Does not affect 'curse' command."],
}

local commands = {
	["curse"] = L["/cursive curse <spellName:str>|<guid?:str>|<options?:List<str>>: Casts spell if not already on target/guid"],
	["multicurse"] = L["/cursive multicurse <spellName:str>|<priority?:str>|<options?:List<str>>: Picks target based on priority and casts spell if not already on target"],
	["target"] = L["/cursive target <spellName:str>|<priority?:str>|<options?:List<str>>: Targets unit based on priority if spell in range and not already on target"],
}

local PRIORITY_HIGHEST_HP = "HIGHEST_HP"
local PRIORITY_LOWEST_HP = "LOWEST_HP"
local PRIORITY_RAID_MARK = "RAID_MARK"
local PRIORITY_RAID_MARK_SQUARE = "RAID_MARK_SQUARE"
local PRIORITY_INVERSE_RAID_MARK = "INVERSE_RAID_MARK"
local PRIORITY_HIGHEST_HP_RAID_MARK = "HIGHEST_HP_RAID_MARK"
local PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE = "HIGHEST_HP_RAID_MARK_SQUARE"
local PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK = "HIGHEST_HP_INVERSE_RAID_MARK"

local priorities = {
	[PRIORITY_HIGHEST_HP] = L["Target with the highest HP."],
	[PRIORITY_LOWEST_HP] = L["Target with the lowest HP."],
	[PRIORITY_RAID_MARK] = L["Target with the highest raid mark."],
	[PRIORITY_RAID_MARK_SQUARE] = L["Target with the highest raid mark with Cross set to -1 and Skull set to -2 (Square highest prio at 6)."],
	[PRIORITY_INVERSE_RAID_MARK] = L["Target with the lowest raid mark."],
	[PRIORITY_HIGHEST_HP_RAID_MARK] = L["Target with the highest HP and raid mark."],
	[PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE] = L["Same as HIGHEST_HP_RAID_MARK but with RAID_MARK_SQUARE mark prio."],
	[PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK] = L["Same as HIGHEST_HP_RAID_MARK but with INVERSE_RAID_MARK mark prio."]
}

local curseNoTarget = L["|cffffcc00Cursive:|cffffaaaa Couldn't find a target to curse."]

local function parseOptions(optionsStr)
	local options = {  }
	local config = Cursive.db.profile

	-- Initialize with global defaults
	for option, _ in pairs(commandOptions) do
		if config[option] ~= nil then
			options[option] = config[option]
		end
	end

	if optionsStr then
		for option, _ in pairs(commandOptions) do
			if string.find(optionsStr, option) then
				options[option] = true
			end
		end
	end

	return options
end

local function handleSlashCommands(msg, editbox)
	if not msg or msg == "" then
		DEFAULT_CHAT_FRAME:AddMessage(curseCommands)
		DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00/cursive show|R - Show the Cursive frame")
		DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00/cursive hide|R - Hide the Cursive frame")
		DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00/cursive toggle|R - Toggle the Cursive frame")
		DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00/cursive options|R - Open the options menu")
		DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00/cursive reset|R - Reset frame position")
		for cmd, description in pairs(commands) do
			DEFAULT_CHAT_FRAME:AddMessage(description)
		end
		return
	end
	-- get first word in string
	local _, _, command, args = string.find(msg, "(%w+) ?(.*)")
	if command == "show" then
		Cursive.ui.Show()
	elseif command == "hide" then
		Cursive.ui.Hide()
	elseif command == "toggle" then
		Cursive.ui.Toggle()
	elseif command == "options" then
		Cursive.ui.ToggleOptions()
	elseif command == "reset" then
		Cursive.db.profile.anchor = "CENTER"
		Cursive.db.profile.x = -100
		Cursive.db.profile.y = -100
		Cursive.ui.Setup()
	elseif command == "curse" then
		local spellName, targetedGuid, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Curse(spellName, targetedGuid, options)
	elseif command == "multicurse" then
		local spellName, priority, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Multicurse(spellName, priority, options)
	elseif command == "target" then
		local spellName, priority, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Target(spellName, priority, options)
	elseif command == "help" then
		DEFAULT_CHAT_FRAME:AddMessage(priorityChoices)
		for priority, description in pairs(priorities) do
			DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00" .. priority .. "|R: " .. description)
		end
		DEFAULT_CHAT_FRAME:AddMessage(curseOptions)
		for option, description in pairs(commandOptions) do
			DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00" .. option .. "|R: " .. description)
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["|cffffcc00Cursive:|cffffaaaa Unknown command."])
		handleSlashCommands("")
	end
end


local function GetSquarePrioRaidTargetIndex(guid)
	local index = GetRaidTargetIndex(guid)
	if index == 7 then
		return 0 -- cross becomes 0
	elseif index == 8 then
		return -1 -- skull becomes -1
	elseif index == 0 then
		return -2 -- nomark becomes -2
	end
	return index or -2
end

local function hasSpellId(guid, ignoreSpellId)
	for i = 1, 16 do
		local texture, stacks, spellSchool, spellId = UnitDebuff(guid, i);
		if not spellId then
			break
		end
		if spellId == ignoreSpellId then
			return true
		end
	end

	for i = 1, 32 do
		local texture, stacks, spellId = UnitBuff(guid, i);
		if not spellId then
			break
		end
		if spellId == ignoreSpellId then
			return true
		end
	end

	return false
end

local function hasSpellTexture(guid, ignoreTexture)
	for i = 1, 16 do
		local texture = UnitDebuff(guid, i);
		if not texture then
			break
		end
		if string.find(texture, ignoreTexture) then
			return true
		end
	end

	for i = 1, 32 do
		local texture = UnitBuff(guid, i);
		if not texture then
			break
		end
		if string.find(texture, ignoreTexture) then
			return true
		end
	end

	return false
end

local function passedOptionFilters(guid, options)
	if options["playeronly"] and not UnitIsPlayer(guid) then
		return false
	end
	return true
end

local function pickTarget(selectedPriority, lowercaseSpellNameNoRank, checkRange, options)
	-- Curse the target that best matches the selected priority
	local highestPrimaryValue = -10
	local highestSecondaryValue = -10
	local targetedGuid = nil

	if selectedPriority == PRIORITY_LOWEST_HP then
		highestPrimaryValue = 999999999999 -- should be bigger than any mob hp
	end

	local ignoreInFight = options["allowooc"]

	local _, currentTargetGuid = UnitExists("target")

	local seenRaidMark = nil -- if we have seen a raid mark

	for guid, time in pairs(Cursive.core.guids) do
		-- apply filters
		local shouldDisplay = Cursive:ShouldDisplayGuid(guid)
		-- check if target displayed
		if shouldDisplay then
			if not options["ignoretarget"] or guid ~= currentTargetGuid then
				-- check if in combat already or player is actively targeting the mob
				if ignoreInFight or Cursive.filter.infight(guid) or guid == currentTargetGuid then
					if passedOptionFilters(guid, options) then
						local passedRangeCheck = false
						if IsSpellInRange then
							local result
							if Cursive.curses.isDruid and string.find(lowercaseSpellNameNoRank, "faerie fire %(feral%)") then
								-- IsSpellInRange doesn't work with Faerie Fire (Feral), use spellid instead
								result = IsSpellInRange(17392, guid)
							else
								result = IsSpellInRange(lowercaseSpellNameNoRank, guid)
							end
							if result == -1 then
								passedRangeCheck = checkRange == false or CheckInteractDistance(guid, 4) -- fallback to old range check
							else
								-- 0 or 1
								passedRangeCheck = result == 1
							end
						else
							-- prioritize targets within 28 yards first to improve chances of being in range
							passedRangeCheck = checkRange == false or CheckInteractDistance(guid, 4)
						end
						if passedRangeCheck then
							-- check if the target has the curse
							if not Cursive.curses:HasCurse(lowercaseSpellNameNoRank, guid, 0) and not Cursive.curses:IsMobCrowdControlled(guid) then
									local primaryValue = -1
									local secondaryValue = -1
									if options["priotarget"] and guid == currentTargetGuid then
										seenRaidMark = true
										primaryValue = 999999999999 -- should be bigger than any mob hp
									elseif selectedPriority == PRIORITY_HIGHEST_HP then
										primaryValue = UnitHealth(guid) or 0
									elseif selectedPriority == PRIORITY_LOWEST_HP then
										primaryValue = UnitHealth(guid) or 999999999999
									elseif selectedPriority == PRIORITY_RAID_MARK then
										primaryValue = GetRaidTargetIndex(guid) or 0
									elseif selectedPriority == PRIORITY_RAID_MARK_SQUARE then
										primaryValue = GetSquarePrioRaidTargetIndex(guid)
									elseif selectedPriority == PRIORITY_INVERSE_RAID_MARK then
										primaryValue = -1 * (GetRaidTargetIndex(guid) or 9)
									elseif selectedPriority == PRIORITY_HIGHEST_HP_RAID_MARK then
										secondaryValue = GetRaidTargetIndex(guid) or 0
										if secondaryValue > 0 and not seenRaidMark then
											highestPrimaryValue = -10 -- reset highestPriorityValue if this is the first raid mark we've seen
											seenRaidMark = true
										end
										primaryValue = UnitHealth(guid) or 0
									elseif selectedPriority == PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE then
										secondaryValue = GetSquarePrioRaidTargetIndex(guid)
										if secondaryValue > -2 and not seenRaidMark then
											highestPrimaryValue = -10 -- reset highestPriorityValue if this is the first raid mark we've seen
											seenRaidMark = true
										end
										primaryValue = UnitHealth(guid) or 0
									elseif selectedPriority == PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK then
										secondaryValue = -1 * (GetRaidTargetIndex(guid) or 9)
										if secondaryValue > -9 and not seenRaidMark then
											highestPrimaryValue = -10 -- reset highestPriorityValue if this is the first raid mark we've seen
											seenRaidMark = true
										end
										primaryValue = UnitHealth(guid) or 0
									end

									if selectedPriority == PRIORITY_LOWEST_HP then
										if primaryValue < highestPrimaryValue then
											highestPrimaryValue = primaryValue
											targetedGuid = guid
										end
									elseif primaryValue > highestPrimaryValue then
										highestPrimaryValue = primaryValue
										highestSecondaryValue = secondaryValue
										targetedGuid = guid
									elseif primaryValue == highestPrimaryValue and secondaryValue > highestSecondaryValue then
										highestSecondaryValue = secondaryValue
										targetedGuid = guid
									end
								end
							end
						end
					end
			end
		end
	end

	-- run again if no target found ignoring range (only if IsSpellInRange is not available)
	if not targetedGuid and checkRange == true and not IsSpellInRange then
		targetedGuid = pickTarget(selectedPriority, lowercaseSpellNameNoRank, false, options)
	end

	return targetedGuid
end

local function castSpellWithOptions(spellName, lowercaseSpellNameNoRank, targetedGuid, options)
	if options["resistsound"] then
		Cursive.curses:EnableResistSound(targetedGuid)
	end
	if options["expiringsound"] then
		Cursive.curses:RequestExpiringSound(lowercaseSpellNameNoRank, targetedGuid)
	end
	CastSpellByName(spellName, targetedGuid)
end

function Cursive:Curse(spellName, targetedGuid, options)
	if not spellName or not targetedGuid then
		DEFAULT_CHAT_FRAME:AddMessage(commands["curse"])
		return false
	end

	if targetedGuid and string.sub(targetedGuid, 1, 2) ~= "0x" then
		_, targetedGuid = UnitExists(targetedGuid)

		if not targetedGuid then
			if options["warnings"] then
				DEFAULT_CHAT_FRAME:AddMessage(curseNoTarget)
			end
			return false
		end
	end

	if targetedGuid then
		-- check for options
		if not passedOptionFilters(targetedGuid, options) then
			if options["warnings"] then
				DEFAULT_CHAT_FRAME:AddMessage(curseNoTarget)
			end
			return false
		end
	end

	-- remove (Rank x) from spellName if it exists
	local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)

	if targetedGuid and not Cursive.curses:HasCurse(lowercaseSpellNameNoRank, targetedGuid, options["refreshtime"]) and not Cursive.curses:IsMobCrowdControlled(targetedGuid) then
		castSpellWithOptions(string.lower(spellName), lowercaseSpellNameNoRank, targetedGuid, options)
		return true
	elseif options["warnings"] then
		DEFAULT_CHAT_FRAME:AddMessage(curseNoTarget)
	end

	return false
end

local function getSpellTarget(spellName, priority, options)
	if not spellName then
		DEFAULT_CHAT_FRAME:AddMessage(commands["multicurse"])
		return
	end

	if priority and not priorities[priority] then
		DEFAULT_CHAT_FRAME:AddMessage(priorityChoices)
		for choice, description in pairs(priorities) do
			DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00" .. choice .. "|R: " .. description)
		end
		return
	end

	local selectedPriority = priority or PRIORITY_HIGHEST_HP

	-- remove (Rank x) from spellName if it exists
	local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)

	return pickTarget(selectedPriority, lowercaseSpellNameNoRank, true, options)
end

function Cursive:Multicurse(spellName, priority, options)
	local targetedGuid = getSpellTarget(spellName, priority, options)
	if targetedGuid then
		local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)
		castSpellWithOptions(string.lower(spellName), lowercaseSpellNameNoRank, targetedGuid, options)
		return true
	elseif options["warnings"] then
		DEFAULT_CHAT_FRAME:AddMessage(curseNoTarget)
	end
	return false
end

function Cursive:GetTarget(spellName, priority, options)
	return getSpellTarget(spellName, priority, options)
end

function Cursive:Target(spellName, priority, options)
	local targetedGuid = getSpellTarget(spellName, priority, options)
	if targetedGuid then
		TargetUnit(targetedGuid)
		return true
	end
	return false
end

SLASH_CURSIVE1 = "/cursive" --creating the slash command
SlashCmdList["CURSIVE"] = handleSlashCommands --associating the function with the slash command

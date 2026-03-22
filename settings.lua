if not Cursive.superwow then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cursive")
Cursive:RegisterDB("CursiveDB")
Cursive:RegisterDefaults("profile", {
	caption = L["Cursive"],
	anchor = "CENTER",
	x = -240,
	y = 120,

	-- editable
	enabled = true,
	clickthrough = false,
	showbackdrop = false,
	showtitle = true,
	showtargetindicator = true,
	showraidicons = true,
	showhealthbar = true,
	showunitname = true,

	shareddebuffs = {
		faeriefire = false,
	},

	alwaysshowcurrenttarget = true,

	scale = 1,
	healthwidth = 200,
	height = 22,
	bartexture = "Interface\\TargetingFrame\\UI-StatusBar",

	raidiconsize = 16,
	curseiconsize = 16,
	maxcurses = 5,
	spacing = 4,
	maxrow = 10,
	textsize = 9,
	cursetimersize = 11,

	curseordering = L["Expiring soonest -> latest"],
	curseshowdecimals = false,
	invertbars = false,
	expandupwards = false,
	compactmode = false,

	filterincombat = true,
	filterhostile = true,
	filterattackable = true,
	filterrange = false,
	filterraidmark = false,
	filterhascurse = false,
	filterignored = true,

	ignorelist = {},
	ignorelistuseregex = false,
	opacity = 1,

	-- command defaults
	warnings = false,
	resistsound = false,
	expiringsound = false,
	allowooc = false,
	minhp = 0,
	refreshtime = 0,
	priotarget = false,
	ignoretarget = false,
	playeronly = false,
	name = "",
	ignorespellid = 0,
	ignorespelltexture = "",
})

local function splitString(str, delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(str, delimiter, from)
	while delim_from do
		table.insert(result, string.sub(str, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(str, delimiter, from)
	end
	table.insert(result, string.sub(str, from))
	return result
end

local commandDefaults = {
	["warnings"] = {
		type = "toggle",
		name = L["Display text warnings when a curse fails to cast."],
		desc = L["Display text warnings when a curse fails to cast."],
		order = 1,
		get = function()
			return Cursive.db.profile.warnings
		end,
		set = function(v)
			Cursive.db.profile.warnings = v
		end,
	},
	["resistsound"] = {
		type = "toggle",
		name = L["Play a sound when a curse is resisted."],
		desc = L["Play a sound when a curse is resisted."],
		order = 2,
		get = function()
			return Cursive.db.profile.resistsound
		end,
		set = function(v)
			Cursive.db.profile.resistsound = v
		end,
	},
	["expiringsound"] = {
		type = "toggle",
		name = L["Play a sound when a curse is about to expire."],
		desc = L["Play a sound when a curse is about to expire."],
		order = 3,
		get = function()
			return Cursive.db.profile.expiringsound
		end,
		set = function(v)
			Cursive.db.profile.expiringsound = v
		end,
	},
	["allowooc"] = {
		type = "toggle",
		name = L["Allow out of combat targets to be multicursed.  Would only consider using this solo to avoid potentially griefing raids/dungeons by pulling unintended mobs."],
		desc = L["Allow out of combat targets to be multicursed.  Would only consider using this solo to avoid potentially griefing raids/dungeons by pulling unintended mobs."],
		order = 4,
		get = function()
			return Cursive.db.profile.allowooc
		end,
		set = function(v)
			Cursive.db.profile.allowooc = v
		end,
	},
	["priotarget"] = {
		type = "toggle",
		name = L["Always prioritize current target when choosing target for multicurse.  Does not affect 'curse' command."],
		desc = L["Always prioritize current target when choosing target for multicurse.  Does not affect 'curse' command."],
		order = 5,
		get = function()
			return Cursive.db.profile.priotarget
		end,
		set = function(v)
			Cursive.db.profile.priotarget = v
		end,
	},
	["minhp"] = {
		type = "range",
		name = L["Minimum HP for a target to be considered.  Example usage minhp=10000. "],
		desc = L["Minimum HP for a target to be considered.  Example usage minhp=10000. "],
		order = 6,
		min = 0,
		max = 2000000,
		step = 100,
		get = function()
			return Cursive.db.profile.minhp
		end,
		set = function(v)
			Cursive.db.profile.minhp = v
		end,
	},
	["refreshtime"] = {
		type = "range",
		name = L["Time threshold at which to allow refreshing a curse.  Default is 0 seconds."],
		desc = L["Time threshold at which to allow refreshing a curse.  Default is 0 seconds."],
		order = 7,
		min = 0,
		max = 30,
		step = 1,
		get = function()
			return Cursive.db.profile.refreshtime
		end,
		set = function(v)
			Cursive.db.profile.refreshtime = v
		end,
	},
	["ignoretarget"] = {
		type = "toggle",
		name = L["Ignore the current target when choosing target for multicurse.  Does not affect 'curse' command."],
		desc = L["Ignore the current target when choosing target for multicurse.  Does not affect 'curse' command."],
		order = 8,
		get = function()
			return Cursive.db.profile.ignoretarget
		end,
		set = function(v)
			Cursive.db.profile.ignoretarget = v
		end,
	},
	["playeronly"] = {
		type = "toggle",
		name = L["Only choose players and ignore npcs when choosing target for multicurse.  Does not affect 'curse' command."],
		desc = L["Only choose players and ignore npcs when choosing target for multicurse.  Does not affect 'curse' command."],
		order = 9,
		get = function()
			return Cursive.db.profile.playeronly
		end,
		set = function(v)
			Cursive.db.profile.playeronly = v
		end,
	},
	["name"] = {
		type = "text",
		name = L["Filter targets by name. Can be a partial match.  If no match is found, the command will do nothing."],
		desc = L["Filter targets by name. Can be a partial match.  If no match is found, the command will do nothing."],
		order = 10,
		get = function()
			return Cursive.db.profile.name
		end,
		set = function(v)
			Cursive.db.profile.name = v
		end,
	},
	["ignorespellid"] = {
		type = "range",
		name = L["Ignore targets with the specified spell id already on them. Useful for ignoring targets that already have a shared debuff."],
		desc = L["Ignore targets with the specified spell id already on them. Useful for ignoring targets that already have a shared debuff."],
		order = 11,
		min = 0,
		max = 60000,
		step = 1,
		get = function()
			return Cursive.db.profile.ignorespellid
		end,
		set = function(v)
			Cursive.db.profile.ignorespellid = v
		end,
	},
	["ignorespelltexture"] = {
		type = "text",
		name = L["Ignore targets with the specified spell texture already on them. Useful for ignoring targets that already have a shared debuff."],
		desc = L["Ignore targets with the specified spell texture already on them. Useful for ignoring targets that already have a shared debuff."],
		order = 12,
		get = function()
			return Cursive.db.profile.ignorespelltexture
		end,
		set = function(v)
			Cursive.db.profile.ignorespelltexture = v
		end,
	},
}

local barOptions = {
	["invertbars"] = {
		type = "toggle",
		name = "Invert Bar Display",
		desc = "Show sections in order 3-2-1 and reverse element order in sections 1 and 3",
		order = 1,
		get = function()
			return Cursive.db.profile.invertbars
		end,
		set = function(v)
			Cursive.db.profile.invertbars = v
			Cursive.UpdateFramesFromConfig()
		end,
	},
	["expandupwards"] = {
		type = "toggle",
		name = "Expand Bars Upwards",
		desc = "Make bars expand upwards instead of downwards",
		order = 2,
		get = function()
			return Cursive.db.profile.expandupwards
		end,
		set = function(v)
			Cursive.db.profile.expandupwards = v
			Cursive.UpdateFramesFromConfig()
		end,
	},
	["compactmode"] = {
		type = "toggle",
		name = L["Compact Mode"],
		desc = L["Moves curse icons onto the health bar and reduces button height."],
		order = 3,
		get = function()
			return Cursive.db.profile.compactmode
		end,
		set = function(v)
			Cursive.db.profile.compactmode = v
			Cursive.UpdateFramesFromConfig()
		end,
	},
	["spacer1"] = {
		type = "header",
		name = "Section Display",
		order = 5,
	},
	["alwaysshowcurrenttarget"] = {
		type = "toggle",
		name = "Always Show Current Target",
		desc = "Always show current target at the bottom of the mob list if it is not already shown",
		order = 30,
		get = function()
			return Cursive.db.profile.alwaysshowcurrenttarget
		end,
		set = function(v)
			Cursive.db.profile.alwaysshowcurrenttarget = v
		end,
	},
	["spacer2"] = {
		type = "header",
		name = "Size & Appearance",
		order = 35,
	},
	["barheight"] = {
		type = "range",
		name = L["Health Bar/Unit Name Height"],
		desc = L["Health Bar/Unit Name Height"],
		order = 50,
		min = 8,
		max = 50,
		step = 2,
		get = function()
			return Cursive.db.profile.height
		end,
		set = function(v)
			if v ~= Cursive.db.profile.height then
				Cursive.db.profile.height = v
				Cursive.UpdateFramesFromConfig()
			end
		end,
	},
	["curseordering"] = {
		type = "text",
		name = L["Curse Ordering"],
		desc = L["Curse Ordering"],
		order = 72,
		get = function()
			return Cursive.db.profile.curseordering
		end,
		validate = { L["Order applied"], L["Expiring soonest -> latest"], L["Expiring latest -> soonest"] },
		set = function(v)
			Cursive.db.profile.curseordering = v
		end,
	},
	["curseshowdecimals"] = {
		type = "toggle",
		name = L["Decimal Duration"],
		desc = L["Decimal Duration Desc"],
		order = 74,
		get = function()
			return Cursive.db.profile.curseshowdecimals
		end,
		set = function(v)
			Cursive.db.profile.curseshowdecimals = v
			Cursive.UpdateFramesFromConfig()
		end,
	},
	["spacing"] = {
		type = "range",
		name = L["Spacing"],
		desc = L["Spacing"],
		order = 80,
		min = 0,
		max = 10,
		step = 1,
		get = function()
			return Cursive.db.profile.spacing
		end,
		set = function(v)
			if v ~= Cursive.db.profile.spacing then
				Cursive.db.profile.spacing = v
				Cursive.UpdateFramesFromConfig()
			end
		end,
	},
	["textsize"] = {
		type = "range",
		name = L["Name/Hp Text Size"],
		desc = L["Name/Hp Text Size"],
		order = 90,
		min = 8,
		max = 20,
		step = 1,
		get = function()
			return Cursive.db.profile.textsize
		end,
		set = function(v)
			if v ~= Cursive.db.profile.textsize then
				Cursive.db.profile.textsize = v
				Cursive.UpdateFramesFromConfig()
			end
		end,
	},
	["cursetimersize"] = {
		type = "range",
		name = L["Curse Timer Text Size"],
		desc = L["Curse Timer Text Size"],
		order = 95,
		min = 6,
		max = 20,
		step = 1,
		get = function()
			return Cursive.db.profile.cursetimersize
		end,
		set = function(v)
			if v ~= Cursive.db.profile.cursetimersize then
				Cursive.db.profile.cursetimersize = v
				Cursive.UpdateFramesFromConfig()
			end
		end,
	},
	["scale"] = {
		type = "range",
		name = L["Scale"],
		desc = L["Scale"],
		order = 100,
		min = 0.5,
		max = 2,
		step = 0.1,
		get = function()
			return Cursive.db.profile.scale
		end,
		set = function(v)
			if v ~= Cursive.db.profile.scale then
				Cursive.db.profile.scale = v
				Cursive.UpdateFramesFromConfig()
			end
		end,
	},
}

local mobFilters = {
	["incombat"] = {
		type = "toggle",
		name = L["In Combat"],
		desc = L["In Combat"],
		order = 1,
		get = function()
			return Cursive.db.profile.filterincombat
		end,
		set = function(v)
			Cursive.db.profile.filterincombat = v
		end,
	},
	["hostile"] = {
		type = "toggle",
		name = L["Hostile"],
		desc = L["Hostile"],
		order = 11,
		get = function()
			return Cursive.db.profile.filterhostile
		end,
		set = function(v)
			Cursive.db.profile.filterhostile = v
		end,
	},
	["attackable"] = {
		type = "toggle",
		name = L["Attackable"],
		desc = L["Attackable"],
		order = 22,
		get = function()
			return Cursive.db.profile.filterattackable
		end,
		set = function(v)
			Cursive.db.profile.filterattackable = v
		end,
	},
	["player"] = {
		type = "toggle",
		name = L["Player"],
		desc = L["Player Desc"],
		order = 33,
		get = function()
			return Cursive.db.profile.filterplayer
		end,
		set = function(v)
			Cursive.db.profile.filterplayer = v
		end,
	},
	["notplayer"] = {
		type = "toggle",
		name = L["Not Player"],
		desc = L["Not Player Desc"],
		order = 33,
		get = function()
			return Cursive.db.profile.filternotplayer
		end,
		set = function(v)
			Cursive.db.profile.filternotplayer = v
		end,
	},
	["range"] = {
		type = "toggle",
		name = IsSpellInRange and L["Within 45 Range"] or L["Within 28 Range"],
		desc = IsSpellInRange and L["Within 45 Range"] or L["Within 28 Range"],
		order = 44,
		get = function()
			return Cursive.db.profile.filterrange
		end,
		set = function(v)
			Cursive.db.profile.filterrange = v
		end,
	},
	["raidmark"] = {
		type = "toggle",
		name = L["Has Raid Mark"],
		desc = L["Has Raid Mark"],
		order = 55,
		get = function()
			return Cursive.db.profile.filterraidmark
		end,
		set = function(v)
			Cursive.db.profile.filterraidmark = v
		end,
	},
	["hascurse"] = {
		type = "toggle",
		name = L["Has Curse"],
		desc = L["Only show units you have cursed"],
		order = 66,
		get = function()
			return Cursive.db.profile.filterhascurse
		end,
		set = function(v)
			Cursive.db.profile.filterhascurse = v
		end,
	},
	["notignored"] = {
		type = "toggle",
		name = L["Not ignored"],
		desc = L["Not ignored"],
		order = 67,
		get = function()
			return Cursive.db.profile.filterignored
		end,
		set = function(v)
			Cursive.db.profile.filterignored = v
		end,
	},
	["ignorelist"] = {
		type = "text",
		name = L["Ignored Mobs List (Enter to save)"],
		desc = L["Ignored Mobs Desc"],
		usage = "whelp, black dragonkin, player3",
		order = 68,
		get = function()
			if Cursive.db.profile.ignorelist and table.getn(Cursive.db.profile.ignorelist) > 0 then
				return table.concat(Cursive.db.profile.ignorelist, ",") or ""
			end
			return ""
		end,
		set = function(v)
			if not v or v == "" then
				Cursive.db.profile.ignorelist = {}
			else
				Cursive.db.profile.ignorelist = splitString(v, ",");
			end
			-- check for common lua regex patterns
			Cursive.db.profile.ignorelistuseregex = string.find(v, "[*+%%?]") ~= nil
		end,
	},
}

local sharedDebuffs = {
	["sharedFaerieFire"] = {
		type = "toggle",
		name = L["Shared Faerie Fire"],
		desc = L["This will show other player's Faerie Fires and avoid trying to cast Faerie Fire on those mobs"],
		order = 10,
		get = function()
			return Cursive.db.profile.shareddebuffs.faeriefire
		end,
		set = function(v)
			Cursive.db.profile.shareddebuffs.faeriefire = v
			Cursive.UpdateFramesFromConfig()
		end,
	},
}

Cursive.cmdtable = {
	type = "group",
	handler = Cursive,
	args = {
		["enabled"] = {
			type = "toggle",
			name = L["Enabled"],
			desc = L["Enable/Disable Cursive"],
			order = 1,
			get = function()
				return Cursive.db.profile.enabled
			end,
			set = function(v)
				Cursive.db.profile.enabled = v
				if v == true then
					Cursive.core.enable()
				else
					Cursive.core.disable()
				end
			end,
		},
		["clickthrough"] = {
			type = "toggle",
			name = L["Allow clickthrough"],
			desc = L["This will allow you to click through the frame to target mobs behind it, but prevents dragging the frame."],
			order = 5,
			get = function()
				return Cursive.db.profile.clickthrough
			end,
			set = function(v)
				Cursive.db.profile.clickthrough = v
				Cursive.UpdateFramesFromConfig()
			end,
		},
		["resetframe"] = {
			type = "execute",
			name = L["Reset Frame"],
			desc = L["Move the frame back to the default position"],
			order = 9,
			func = function()
				Cursive.db.profile.anchor = "CENTER"
				Cursive.db.profile.x = -100
				Cursive.db.profile.y = -100
				Cursive.UpdateFramesFromConfig()
			end,
		},
		["spacer"] = {
			type = "header",
			name = " ",
			order = 11,
		},
		["bardisplay"] = {
			type = "group",
			name = L["Bar Display Settings"],
			desc = L["Bar Display Settings"],
			order = 13,
			args = barOptions
		},
		["filters"] = {
			type = "group",
			name = L["Mob filters"],
			desc = L["Target and Raid Marks always shown"],
			order = 19,
			args = mobFilters
		},
		["shareddebuffs"] = {
			type = "group",
			name = L["Shared Debuffs"],
			desc = L["Shared Debuffs"],
			order = 20,
			args = sharedDebuffs
		},
		["commanddefaults"] = {
			type = "group",
			name = "Command Defaults",
			desc = "Default settings for /cursive commands",
			order = 21,
			args = commandDefaults
		},
		["spacer2"] = {
			type = "header",
			name = " ",
			order = 21,
		},
		["maxcurses"] = {
			type = "range",
			name = L["Max Curses"],
			desc = L["Max Curses"],
			order = 22,
			min = 1,
			max = 8,
			step = 1,
			get = function()
				return Cursive.db.profile.maxcurses
			end,
			set = function(v)
				if v ~= Cursive.db.profile.maxcurses then
					Cursive.db.profile.maxcurses = v
					Cursive.UpdateFramesFromConfig()
				end
			end,
		},
		["maxrow"] = {
			type = "range",
			name = L["Max Rows"],
			desc = L["Max Rows"],
			order = 30,
			min = 1,
			max = 20,
			step = 1,
			get = function()
				return Cursive.db.profile.maxrow
			end,
			set = function(v)
				if v ~= Cursive.db.profile.maxrow then
					Cursive.db.profile.maxrow = v
					Cursive.UpdateFramesFromConfig()
				end
			end,
		},
	}
}

local deuce = Cursive:NewModule("Options Menu")
deuce.hasFuBar = IsAddOnLoaded("FuBar") and FuBar
deuce.consoleCmd = not deuce.hasFuBar

CursiveOptions = AceLibrary("AceAddon-2.0"):new("AceDB-2.0", "FuBarPlugin-2.0")
CursiveOptions.name = "FuBar - Cursive"
CursiveOptions:RegisterDB("CursiveDB")
CursiveOptions.hasIcon = "Interface\\Icons\\spell_shadow_deathcoil"
CursiveOptions.defaultMinimapPosition = 180
CursiveOptions.independentProfile = true
CursiveOptions.hideWithoutStandby = false

-- XXX total hack
CursiveOptions.OnMenuRequest = Cursive.cmdtable
local args = AceLibrary("FuBarPlugin-2.0"):GetAceOptionsDataTable(CursiveOptions)
for k, v in pairs(args) do
	if CursiveOptions.OnMenuRequest.args[k] == nil then
		CursiveOptions.OnMenuRequest.args[k] = v
	end
end
-- XXX end hack

local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getSharedDebuffs()
	return {
		faeriefire = {
			[770] = { name = L["faerie fire"], rank = 1, duration = 40 },
			[778] = { name = L["faerie fire"], rank = 2, duration = 40 },
			[9749] = { name = L["faerie fire"], rank = 3, duration = 40 },
			[9907] = { name = L["faerie fire"], rank = 4, duration = 40 },

			[16855] = { name = L["faerie fire"], rank = 1, duration = 40 }, -- use faerie fire instead of (bear) version so they block each other
			[17387] = { name = L["faerie fire"], rank = 2, duration = 40 },
			[17388] = { name = L["faerie fire"], rank = 3, duration = 40 },
			[17389] = { name = L["faerie fire"], rank = 4, duration = 40 },

			[16857] = { name = L["faerie fire"], rank = 1, duration = 40 }, -- use faerie fire instead of (feral) version so they block each other
			[17390] = { name = L["faerie fire"], rank = 2, duration = 40 },
			[17391] = { name = L["faerie fire"], rank = 3, duration = 40 },
			[17392] = { name = L["faerie fire"], rank = 4, duration = 40 },
		},
		cc = {
			-- polymorph
			[118] = { name = L["polymorph"], rank = 1, duration = 20 },
			[12824] = { name = L["polymorph"], rank = 2, duration = 30 },
			[12825] = { name = L["polymorph"], rank = 3, duration = 40 },
			[12826] = { name = L["polymorph"], rank = 4, duration = 50 },
			[28270] = { name = L["polymorph: cow"], rank = 1, duration = 50 },
			[28271] = { name = L["polymorph: turtle"], rank = 1, duration = 50 },
			[28272] = { name = L["polymorph: pig"], rank = 1, duration = 50 },
			-- banish
			[710] = { name = L["banish"], rank = 1, duration = 20 },
			[18647] = { name = L["banish"], rank = 2, duration = 30 },
			-- fear
			[5782] = { name = L["fear"], rank = 1, duration = 10 },
			[6213] = { name = L["fear"], rank = 2, duration = 15 },
			[6215] = { name = L["fear"], rank = 3, duration = 20 },
			-- shackle undead
			[9484] = { name = L["shackle undead"], rank = 1, duration = 30 },
			[9485] = { name = L["shackle undead"], rank = 2, duration = 40 },
			[10955] = { name = L["shackle undead"], rank = 3, duration = 50 },
			[1425] = { name = L["shackle undead"], rank = 1, duration = 30 },
			[9486] = { name = L["shackle undead"], rank = 2, duration = 40 },
			[10956] = { name = L["shackle undead"], rank = 3, duration = 50 },
			-- hibernate
			[2637] = { name = L["hibernate"], rank = 1, duration = 20 },
			[18657] = { name = L["hibernate"], rank = 2, duration = 30 },
			[18658] = { name = L["hibernate"], rank = 3, duration = 40 },
			-- sleep
			[700] = { name = L["sleep"], rank = 1, duration = 20 },
			[1090] = { name = L["sleep"], rank = 2, duration = 30 },
			[2937] = { name = L["sleep"], rank = 3, duration = 40 },
			-- entangling roots
			[339] = { name = L["entangling roots"], rank = 1, duration = 12 },
			[1062] = { name = L["entangling roots"], rank = 2, duration = 15 },
			[5195] = { name = L["entangling roots"], rank = 3, duration = 18 },
			[5196] = { name = L["entangling roots"], rank = 4, duration = 21 },
			[9852] = { name = L["entangling roots"], rank = 5, duration = 24 },
			[9853] = { name = L["entangling roots"], rank = 6, duration = 27 },
			-- freezing trap
			[3355] = { name = L["freezing trap"], rank = 1, duration = 10 },
			[14308] = { name = L["freezing trap"], rank = 2, duration = 15 },
			[14309] = { name = L["freezing trap"], rank = 3, duration = 20 },
			-- wyvern sting
			[19386] = { name = L["wyvern sting"], rank = 1, duration = 12 },
			[24132] = { name = L["wyvern sting"], rank = 2, duration = 12 },
			[24133] = { name = L["wyvern sting"], rank = 3, duration = 12 },
			-- sap
			[6770] = { name = L["sap"], rank = 1, duration = 25 },
			[2070] = { name = L["sap"], rank = 2, duration = 35 },
			[11297] = { name = L["sap"], rank = 3, duration = 45 },
			-- blind
			[2094] = { name = L["blind"], rank = 1, duration = 10 },
			[21060] = { name = L["blind"], rank = 1, duration = 10 },
			-- gouge
			[1776] = { name = L["gouge"], rank = 1, duration = 4 },
			[1777] = { name = L["gouge"], rank = 2, duration = 4 },
			[8629] = { name = L["gouge"], rank = 3, duration = 4 },
			[11285] = { name = L["gouge"], rank = 4, duration = 4 },
			[11286] = { name = L["gouge"], rank = 5, duration = 4 },
			-- turn undead
			[2878] = { name = L["turn undead"], rank = 1, duration = 10 },
			[5627] = { name = L["turn undead"], rank = 2, duration = 15 },
			[10326] = { name = L["turn undead"], rank = 3, duration = 20 },
		}
	}
end

if not Cursive.nampower then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cursive")

local utils = Cursive.utils
local filter = Cursive.filter

local ui = {}
Cursive.ui = ui

ui.border = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

ui.background = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true, tileSize = 16, edgeSize = 8,
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

ui.rootBarFrame = nil
ui.targetIndicatorSize = 8
ui.padding = 2

ui.row = 1
ui.col = 1
ui.maxBarsDisplayed = false
ui.numDisplayed = 0

local function GetBarFirstSectionWidth()
	local config = Cursive.db.profile

	local size = 1
	if config.showraidicons then
		size = size + config.raidiconsize
	end
	if config.showtargetindicator then
		size = size + ui.targetIndicatorSize
	end
	if size > 0 then
		size = size + ui.padding
	end

	return size
end

local function GetBarSecondSectionWidth()
	local config = Cursive.db.profile

	if config.showhealthbar == false and config.showunitname == false then
		return 1
	end

	return config.healthwidth + ui.padding
end

local function GetBarThirdSectionWidth()
	local config = Cursive.db.profile

	return config.maxcurses * (config.curseiconsize + ui.padding)
end

local function GetBarWidth()
	return GetBarFirstSectionWidth() +
			GetBarSecondSectionWidth() +
			GetBarThirdSectionWidth()
end

local function UpdateRootBarFrame()
	local config = Cursive.db.profile

	if config.showbackdrop then
		ui.rootBarFrame:SetBackdrop(ui.background)
	else
		ui.rootBarFrame:SetBackdrop(nil)
	end

	ui.rootBarFrame:EnableMouse(not config.clickthrough)

	ui.rootBarFrame.pos = config.anchor .. config.x .. config.y .. config.scale
	ui.rootBarFrame:ClearAllPoints()
	ui.rootBarFrame:SetPoint(config.anchor, config.x, config.y)

	ui.rootBarFrame:SetScale(config.scale)

	ui.rootBarFrame.caption:SetFont(STANDARD_TEXT_FONT, Cursive.db.profile.textsize, "THINOUTLINE")
	ui.rootBarFrame.caption:SetText(Cursive.db.profile.caption)
	if Cursive.db.profile.showtitle then
		ui.rootBarFrame.caption:Show()
	else
		ui.rootBarFrame.caption:Hide()
	end

	ui.rootBarFrame:SetWidth(config.maxcol * GetBarWidth())
	-- Calculate height: title area + all rows + extra spacing
	local title_size = 12 + config.spacing
	local total_height = title_size + (config.maxrow * (config.height + config.spacing)) + config.spacing
	ui.rootBarFrame:SetHeight(total_height)
end

local function CreateRoot()
	local frame = CreateFrame("Frame", Cursive.db.profile.caption, UIParent)
	ui.rootBarFrame = frame

	frame.id = Cursive.db.profile.caption

	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	frame:SetScript("OnDragStart", function()
		this.lock = true
		this:StartMoving()
	end)

	frame:SetScript("OnDragStop", function()
		-- convert to best anchor depending on position
		local new_anchor = utils.GetBestAnchor(this)
		local anchor, x, y = utils.ConvertFrameAnchor(this, new_anchor)
		this:ClearAllPoints()
		this:SetPoint(anchor, UIParent, anchor, x, y)

		-- save new position
		anchor, _, _, x, y = this:GetPoint()
		Cursive.db.profile.anchor, Cursive.db.profile.x, Cursive.db.profile.y = anchor, x, y

		-- stop drag
		this:StopMovingOrSizing()
		this.lock = false

		this:ClearAllPoints()
		this:SetPoint(anchor, x, y)
	end)

	-- create title text
	frame.caption = frame:CreateFontString(nil, "HIGH", "GameFontWhite")
	frame.caption:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -2)
	frame.caption:SetTextColor(1, 1, 1, 1)

	UpdateRootBarFrame()

	frame:Show()

	return frame
end

ui.unitFrames = {} -- holds all unitFrames for all columns/rows

Cursive.UpdateFramesFromConfig = function()
	for col, rows in pairs(ui.unitFrames) do
		for row, unitFrame in pairs(rows) do
			if unitFrame and unitFrame:IsShown() then
				unitFrame:Hide()
			end
		end
	end

	if ui.rootBarFrame then
		UpdateRootBarFrame()
	end

	-- after 3 seconds reset the unit frames so all changes are applied
	Cursive:ScheduleEvent("resetUnitFrames", Cursive.ResetUnitFrames, 3)
end

Cursive.ResetUnitFrames = function()
	-- hide all existing unit frames
	for col, rows in pairs(ui.unitFrames) do
		for row, unitFrame in pairs(rows) do
			if unitFrame and unitFrame:IsShown() then
				unitFrame:Hide()
			end
		end
	end
	-- clear cached frames so they are recreated
	ui.unitFrames = {}
end

ui.BarEnter = function()
	if this.parent.healthBar then
		this.parent.healthBar.border:SetBackdropBorderColor(1, 1, 1, 1)
	end
	this.parent.hover = true

  SetMouseoverUnit(this.parent.guid)
	GameTooltip_SetDefaultAnchor(GameTooltip, this)
	GameTooltip:SetUnit(this.parent.guid)
	GameTooltip:Show()
end

ui.BarLeave = function()
	this.parent.hover = false
  SetMouseoverUnit()
	GameTooltip:Hide()
end

ui.BarUpdate = function()
	if not this.guid or this.guid == 0 then
		this:Hide()
		return
	end

	if (this.tick or 1) > GetTime() then
		return
	else
		this.tick = GetTime() + 0.05
	end

	-- update statusbar values if it exists
	if this.healthBar then
		this.healthBar:SetMinMaxValues(0, UnitHealthMax(this.guid))
		this.healthBar:SetValue(UnitHealth(this.guid))

		-- update health bar color
		local hex, r, g, b, a = utils.GetUnitColor(this.guid)
		this.healthBar:SetStatusBarColor(r, g, b, a)

		-- update health bar border
		if this.healthBar.border then
			if this.hover then
				this.healthBar.border:SetBackdropBorderColor(1, 1, 1, 1)
			elseif UnitAffectingCombat(this.guid) then
				this.healthBar.border:SetBackdropBorderColor(.8, .2, .2, 1)
			else
				this.healthBar.border:SetBackdropBorderColor(.2, .2, .2, 1)
			end
		end
	end

	-- update caption text
	local name = UnitName(this.guid)
	if name and this.nameText then
		this.nameText:SetText(name)
	end

	if this.hpText then
		local hp = UnitHealth(this.guid)
		if GetLocale() == "zhCN" then
			if hp then
				if hp >= 10000 then
					hp = math.floor(hp / 1000) / 10 .. "万"
					-- elseif hp >= 1000 then
					-- 	hp = math.floor(hp / 100) / 10 .. "k"
				end
			end
		else
			-- convert hp to k if > 1000
			if hp then
				if hp >= 1000000 then
					hp = math.floor(hp / 100000) / 10 .. "m"
				elseif hp >= 1000 then
					hp = math.floor(hp / 100) / 10 .. "k"
				end
			end
		end

		if hp then
			this.hpText:SetText(hp)
		end
	end

	-- show raid icon if existing
	if this.icon then
		if GetRaidTargetIndex(this.guid) and Cursive.filter.alive(this.guid) then
			SetRaidTargetIconTexture(this.icon, GetRaidTargetIndex(this.guid))
			this.icon:Show()
		else
			this.icon:Hide()
		end
	end

	-- update target indicator
	if this.target_left then
		if UnitIsUnit("target", this.guid) then
			this.target_left:Show()
		else
			this.target_left:Hide()
		end
	end
end

ui.BarClick = function()
	if arg1 == "LeftButton" then
		TargetUnit(this.parent.guid)
	elseif arg1 == "RightButton" then
		TargetUnit(this.parent.guid)
		if (not PlayerFrame.inCombat) then
			AttackTarget()
		end
	end
end

local function CreateBarFirstSection(unitFrame, guid)
	local config = Cursive.db.profile
	local firstSection = CreateFrame("Frame", "Cursive1stSection", unitFrame)

	if config.invertbars then
		-- When inverted, position relative to second section (rightmost)
		firstSection:SetPoint("LEFT", unitFrame.secondSection, "RIGHT", 0, 0)
	else
		-- Normal positioning (leftmost)
		firstSection:SetPoint("LEFT", unitFrame, "LEFT", 0, 0)
	end
	
	firstSection:SetWidth(GetBarFirstSectionWidth())
	firstSection:SetHeight(config.height)
	firstSection:EnableMouse(false)
	unitFrame.firstSection = firstSection

	-- create target indicator
	if config.showtargetindicator then
		local targetLeft = firstSection:CreateTexture(nil, "OVERLAY")
		targetLeft:SetWidth(ui.targetIndicatorSize)
		targetLeft:SetHeight(8)
		if config.invertbars then
			targetLeft:SetPoint("RIGHT", firstSection, "RIGHT", 0, 0)
			targetLeft:SetTexture("Interface\\AddOns\\Cursive\\img\\target-right")
		else
			targetLeft:SetPoint("LEFT", unitFrame, "LEFT", 0, 0)
			targetLeft:SetTexture("Interface\\AddOns\\Cursive\\img\\target-left")
		end
		targetLeft:Hide()
		unitFrame.target_left = targetLeft
	end

	-- create raid icon textures
	if config.showraidicons then
		local icon = firstSection:CreateTexture(nil, "OVERLAY")
		icon:SetWidth(config.raidiconsize)
		icon:SetHeight(config.raidiconsize)
		if config.invertbars then
			icon:SetPoint("LEFT", firstSection, "LEFT", 0, 0)
		else
			icon:SetPoint("RIGHT", firstSection, "RIGHT", 0, 0)
		end
		icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		icon:Hide()
		unitFrame.icon = icon
	end
end

local function CreateBarSecondSection(unitFrame, guid)
	local config = Cursive.db.profile
	local secondSection = CreateFrame("Button", "Cursive2ndSection", unitFrame)

	if config.invertbars then
		-- When inverted, position relative to third section (which is created first)
		secondSection:SetPoint("LEFT", unitFrame.thirdSection, "RIGHT", 0, 0)
	else
		-- Normal positioning relative to first section
		secondSection:SetPoint("LEFT", unitFrame.firstSection, "RIGHT", 0, 0)
	end
	
	secondSection:SetWidth(GetBarSecondSectionWidth())
	secondSection:SetHeight(config.height)
	unitFrame.secondSection = secondSection
	secondSection.parent = unitFrame

	secondSection:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	secondSection:SetScript("OnClick", ui.BarClick)
	secondSection:SetScript("OnEnter", ui.BarEnter)
	secondSection:SetScript("OnLeave", ui.BarLeave)

	-- create health bar
	if config.showhealthbar then
		local healthBar = CreateFrame("StatusBar", "CursiveHealthBar", secondSection)
		healthBar:SetStatusBarTexture(config.bartexture)
		healthBar:SetStatusBarColor(1, .8, .2, 1)
		healthBar:SetMinMaxValues(0, 100)
		healthBar:SetValue(20)
		healthBar:SetPoint("LEFT", secondSection, "LEFT", ui.padding, 0)
		healthBar:SetWidth(config.healthwidth)
		healthBar:SetHeight(config.height)
		unitFrame.healthBar = healthBar

		local hp = healthBar:CreateFontString(nil, "HIGH", "GameFontWhite")
		hp:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", -2, -2)
		hp:SetWidth(30)
		hp:SetHeight(config.height - 4)
		hp:SetFont(STANDARD_TEXT_FONT, config.textsize, "THINOUTLINE")
		hp:SetJustifyH("RIGHT")
		unitFrame.hpText = hp

		if config.showunitname then
			local name = healthBar:CreateFontString(nil, "HIGH", "GameFontWhite")
			name:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 2, -2)
			name:SetPoint("BOTTOMRIGHT", hp, "BOTTOMLEFT", 2, 0)
			name:SetFont(STANDARD_TEXT_FONT, config.textsize, "THINOUTLINE")
			name:SetJustifyH("LEFT")
			unitFrame.nameText = name
		end

		-- create health bar backdrops
		if pfUI and pfUI.uf then
			pfUI.api.CreateBackdrop(healthBar)
			healthBar.border = healthBar.backdrop
		else
			healthBar:SetBackdrop(ui.background)
			healthBar:SetBackdropColor(0, 0, 0, 1)

			local border = CreateFrame("Frame", "CursiveBorder", healthBar.bar)
			border:SetBackdrop(ui.border)
			border:SetBackdropColor(.2, .2, .2, 1)
			border:SetPoint("TOPLEFT", healthBar.bar, "TOPLEFT", -2, 2)
			border:SetPoint("BOTTOMRIGHT", healthBar.bar, "BOTTOMRIGHT", 2, -2)
			healthBar.border = border
		end
	else
		if config.showunitname then
			local name = secondSection:CreateFontString(nil, "HIGH", "GameFontWhite")
			name:SetPoint("TOPLEFT", secondSection, "TOPLEFT", 2, -2)
			name:SetPoint("BOTTOMRIGHT", secondSection, "BOTTOMRIGHT", 2, 0)
			name:SetFont(STANDARD_TEXT_FONT, config.textsize, "THINOUTLINE")
			name:SetWidth(config.healthwidth)
			name:SetHeight(config.height - 4)
			name:SetJustifyH("LEFT")
			unitFrame.nameText = name
		end
	end
end

local function CreateBarThirdSection(unitFrame, guid)
	local config = Cursive.db.profile

	local thirdSection = CreateFrame("Frame", "Cursive3rdSection", unitFrame)

	if config.invertbars then
		-- When inverted, this is positioned first (leftmost)
		thirdSection:SetPoint("LEFT", unitFrame, "LEFT", 0, 0)
	else
		-- Normal positioning relative to second section
		thirdSection:SetPoint("LEFT", unitFrame.secondSection, "RIGHT", 0, 0)
	end
	
	thirdSection:SetWidth(GetBarThirdSectionWidth())
	thirdSection:SetHeight(config.height)
	thirdSection:EnableMouse(false)
	unitFrame.thirdSection = thirdSection

	-- display up to maxcurses curses
	for i = 1, config.maxcurses do
		local curse = thirdSection:CreateTexture(nil, "OVERLAY")
		curse:SetWidth(config.curseiconsize)
		curse:SetHeight(config.curseiconsize)

		if config.invertbars then
			-- When inverted, position from right to left
			local rightOffset = i * ui.padding + ((i - 1) * config.curseiconsize)
			curse:SetPoint("RIGHT", thirdSection, "RIGHT", -rightOffset, 0)
		else
			-- Normal positioning from left to right
			curse:SetPoint("LEFT", thirdSection, "LEFT", i * ui.padding + ((i - 1) * config.curseiconsize), 0)
		end

		curse.timer = thirdSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		curse.timer:SetFontObject(GameFontHighlight)
		curse.timer:SetFont(STANDARD_TEXT_FONT, config.cursetimersize, "OUTLINE")
		curse.timer:SetTextColor(1, 1, 1)
		curse.timer:SetAllPoints(curse)

		curse.timer:Hide()
		curse:Hide()
		unitFrame["curse" .. i] = curse
	end
end

local function CreateBar(row, col, guid)
	local unitFrame = CreateFrame("Frame", "CursiveUnitFrame", ui.rootBarFrame)
	unitFrame.guid = guid

	unitFrame:SetScript("OnUpdate", ui.BarUpdate)

	local config = Cursive.db.profile
	local width = GetBarWidth()
	unitFrame:SetWidth(width)
	unitFrame:SetHeight(config.height)

	local config = Cursive.db.profile
	if config.invertbars then
		-- Create sections in reverse order: 3 -> 2 -> 1
		CreateBarThirdSection(unitFrame, guid)
		CreateBarSecondSection(unitFrame, guid)
		CreateBarFirstSection(unitFrame, guid)
	else
		-- Normal order: 1 -> 2 -> 3
		CreateBarFirstSection(unitFrame, guid)
		CreateBarSecondSection(unitFrame, guid)
		CreateBarThirdSection(unitFrame, guid)
	end

	ui.unitFrames[col][row] = unitFrame
	return unitFrame
end

local function GetBarCords(row, col)
	local config = Cursive.db.profile
	local x = (col - 1) * GetBarWidth()
	local y
	if config.expandupwards then
		-- For upward expansion: start from bottom with spacing, then go up
		y = config.spacing + ((row - 1) * (config.height + config.spacing))
	else
		-- For downward expansion: use original logic (don't subtract 1 to account for header)
		y = -(row * (config.height + config.spacing))
	end
	return x, y
end

local function hasAnySpellId(guid, spellIds)
	local auras = GetUnitField(guid, "aura")
	for i, spellId in pairs(auras) do
		if spellIds[spellId] then
			return spellId
		end
	end
	return nil
end

ui.unitButtons = {}
ui.maxButtons = 20
ui.lastCleanup = 0

local function GetSortedCurses(guidCurses)
	-- Collect keys
	local curseNames = {}
	for key in pairs(guidCurses) do
		table.insert(curseNames, key)
	end

	if Cursive.db.profile.curseordering == L["Order applied"] then
		table.sort(curseNames, function(a, b)
			return guidCurses[a].start < guidCurses[b].start
		end)
	elseif Cursive.db.profile.curseordering == L["Expiring soonest -> latest"] then
		table.sort(curseNames, function(a, b)
			return Cursive.curses:TimeRemaining(guidCurses[a]) < Cursive.curses:TimeRemaining(guidCurses[b])
		end)
	elseif Cursive.db.profile.curseordering == L["Expiring latest -> soonest"] then
		table.sort(curseNames, function(a, b)
			return Cursive.curses:TimeRemaining(guidCurses[a]) > Cursive.curses:TimeRemaining(guidCurses[b])
		end)
	end

	local i = 0
	return function()
		i = i + 1
		local key = curseNames[i]
		if key then
			return key, guidCurses[key]
		end
	end
end

function ui.Setup()
    ui.UpdateScale()
    if CursiveFrame then
        CursiveFrame:SetAlpha(Cursive.db.profile.opacity or 1)
        CursiveFrame:ClearAllPoints()
        CursiveFrame:SetPoint(Cursive.db.profile.anchor, Cursive.db.profile.x, Cursive.db.profile.y)
    end

    ui.UpdateHeader()
    ui.UpdateBackdrop()
    ui.UpdateLock()

    if CursiveUnitsFrame then
        for i = 1, ui.maxButtons do
            local name = "CursiveUnitButton"..i
            local btn = getglobal(name)
            if not btn then
                btn = CreateFrame("Button", name, CursiveUnitsFrame, "CursiveUnitButtonTemplate")
                btn:SetID(i)
            end
            ui.unitButtons[i] = btn
        end
    end

    ui.UpdateInvert()
    ui.UpdateLayout()
end

function ui.UpdateHeader()
    if not CursiveFrame then return end
    local config = Cursive.db.profile
    if config.showtitle then
        CursiveFrameTitle:Show()
        CursiveFrameBackground:Show()
        CursiveFrameHitRect:Show()

        local width = config.healthwidth or 220
        CursiveFrameBackground:SetWidth(width)
        CursiveFrameHitRect:SetWidth(width)
        CursiveFrame:SetWidth(width + 10)
    else
        CursiveFrameTitle:Hide()
        CursiveFrameBackground:Hide()
        CursiveFrameHitRect:Hide()
    end
    ui.UpdateBackdrop()
end

function ui.UpdateBackdrop()
    if not CursiveFrame then return end

    if IsAddOnLoaded("pfUI") then
        -- pfUI Skinning
        CursiveFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        CursiveFrame:SetBackdropColor(0, 0, 0, 0.7)
        CursiveFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        if CursiveOptionsFrame then
            CursiveOptionsFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false, tileSize = 0, edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            CursiveOptionsFrame:SetBackdropColor(0, 0, 0, 0.9)
            CursiveOptionsFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        end
    elseif Cursive.db.profile.showbackdrop then
        local top = Cursive.db.profile.showtitle and 5 or 0
        CursiveFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 5, right = 5, top = top, bottom = 5 }
        })
        CursiveFrame:SetBackdropColor(0, 0, 0, 0.5)
    else
        CursiveFrame:SetBackdrop(nil)
    end
end

function ui.UpdateLock()
    if not CursiveFrame then return end
    CursiveFrame:SetMovable(not Cursive.db.profile.clickthrough) -- In Cursive, clickthrough means locked
    CursiveFrame:EnableMouse(not Cursive.db.profile.clickthrough)
end

function ui.UpdateInvert()
    ui.UpdateLayout()
end

function ui.UpdateLayout()
    if not CursiveFrame or not CursiveUnitsFrame then return end
    local config = Cursive.db.profile
    CursiveUnitsFrame:ClearAllPoints()

    if config.expandupwards then
        CursiveUnitsFrame:SetPoint("BOTTOM", CursiveFrame, "BOTTOM", 0, 5)
    else
        if config.showtitle then
            CursiveUnitsFrame:SetPoint("TOP", CursiveFrame, "TOP", 0, -35)
        else
            CursiveUnitsFrame:SetPoint("TOP", CursiveFrame, "TOP", 0, -5)
        end
    end

    local spacing = config.spacing or 4
    local btnWidth = config.healthwidth or 220
    local btnHeight = config.compactmode and (config.height or 22) or 48

    -- Adjust main frame height based on num buttons (always draw a box that fits max rows)
    local titleSize = (config.showtitle or IsAddOnLoaded("pfUI")) and 40 or 10
    local num = config.maxrow
    local entriesHeight = (num * btnHeight) + ((num > 0 and num - 1 or 0) * spacing)
    local padding = 15
    CursiveFrame:SetWidth(btnWidth + 10)
    CursiveFrame:SetHeight(titleSize + entriesHeight + padding)
    local barHeight = config.height or 22
    local raidSize = config.raidiconsize or 18
    local curseSize = config.curseiconsize or (config.compactmode and (barHeight - 4) or 20)

    CursiveUnitsFrame:SetWidth(btnWidth)

    for i = 1, ui.maxButtons do
        local btn = ui.unitButtons[i]
        if not btn then break end
        btn:ClearAllPoints()
        btn:SetWidth(btnWidth)
        btn:SetHeight(btnHeight)

        if i == 1 then
            if config.expandupwards then
                btn:SetPoint("BOTTOM", CursiveUnitsFrame, "BOTTOM", 0, 0)
            else
                btn:SetPoint("TOP", CursiveUnitsFrame, "TOP", 0, 0)
            end
        else
            if config.expandupwards then
                btn:SetPoint("BOTTOM", ui.unitButtons[i-1], "TOP", 0, spacing)
            else
                btn:SetPoint("TOP", ui.unitButtons[i-1], "BOTTOM", 0, -spacing)
            end
        end

        -- Layout components
        local healthBar = getglobal(btn:GetName().."HealthBar")

        if IsAddOnLoaded("pfUI") then
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false, tileSize = 0, edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            btn:SetBackdropColor(0, 0, 0, 0.4)
            btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

            local selection = getglobal(btn:GetName().."Selection")
            selection:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false, tileSize = 0, edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            selection:SetBackdropBorderColor(1, 1, 1, 1)
        end
        local nameText = getglobal(btn:GetName().."HealthBarName")
        local hpText = getglobal(btn:GetName().."HealthBarHPText")
        local targetInd = getglobal(btn:GetName().."HealthBarTargetIndicator")
        local raidIcon = getglobal(btn:GetName().."HealthBarRaidIcon")
        local dots = getglobal(btn:GetName().."Dots")

        healthBar:ClearAllPoints()
        nameText:ClearAllPoints()
        hpText:ClearAllPoints()
        targetInd:ClearAllPoints()
        raidIcon:ClearAllPoints()
        dots:ClearAllPoints()

        healthBar:SetWidth(btnWidth)
        healthBar:SetHeight(barHeight)
        healthBar:SetPoint("TOP", btn, "TOP", 0, 0)

        if config.showhealthbar then
            healthBar:Show()
        else
            healthBar:Hide()
        end

        raidIcon:SetWidth(raidSize)
        raidIcon:SetHeight(raidSize)
        targetInd:SetWidth(raidSize / 1.8)
        targetInd:SetHeight(raidSize * 1.1)

        if config.showunitname then
            nameText:Show()
        else
            nameText:Hide()
        end

        dots:SetWidth(btnWidth)
        dots:SetHeight(config.compactmode and barHeight or 20)

        if config.compactmode then
            dots:SetPoint("TOP", btn, "TOP", 0, 0)
        else
            dots:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
        end

        nameText:SetHeight(barHeight)
        hpText:SetHeight(barHeight)

        local raidReserved = config.showraidicons and raidSize or 0
        local targetReserved = config.showtargetindicator and (raidSize / 1.8) or 0
        local extraPadding = (raidReserved > 0 or targetReserved > 0) and 10 or 5

        if config.compactmode then
            -- Reserve space for 3 curses (curseSize + 4 padding each) + HP text (approx 50)
            -- If more than 3 curses, they will overlap the name or be hidden.
            local reserved = 50 + (curseSize * 3) + 15
            nameText:SetWidth(btnWidth - raidReserved - targetReserved - reserved - extraPadding)
        else
            nameText:SetWidth(btnWidth - raidReserved - targetReserved - 70)
        end

        -- Text settings (Move from OnUpdate for performance)
        local font, _, flags = nameText:GetFont()
        nameText:SetFont(font or "Fonts\\FRIZQT__.TTF", config.textsize or 12, flags)

        local hpFont, _, hpFlags = hpText:GetFont()
        hpText:SetFont(hpFont or "Fonts\\FRIZQT__.TTF", config.textsize or 9, hpFlags)

        for j = 1, 5 do
            local timer = getglobal(dots:GetName().."Curse"..j.."Timer")
            local tFont, _, tFlags = timer:GetFont()
            timer:SetFont(tFont or "Fonts\\FRIZQT__.TTF", config.cursetimersize or 11, tFlags)
        end

        healthBar:SetStatusBarTexture(config.bartexture or "Interface\\TargetingFrame\\UI-StatusBar")

        if config.invertbars then
            targetInd:SetPoint("RIGHT", healthBar, "RIGHT", -5, 0)
            targetInd:SetTexture("Interface\\AddOns\\Cursive\\img\\target-right")
            raidIcon:SetPoint("RIGHT", targetInd, "LEFT", -2, 0)

            nameText:SetPoint("RIGHT", raidIcon, "LEFT", -5, 0)
            nameText:SetJustifyH("RIGHT")
            hpText:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
            hpText:SetJustifyH("LEFT")
        else
            targetInd:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
            targetInd:SetTexture("Interface\\AddOns\\Cursive\\img\\target-left")
            raidIcon:SetPoint("LEFT", targetInd, "RIGHT", 2, 0)

            nameText:SetPoint("LEFT", raidIcon, "RIGHT", 5, 0)
            nameText:SetJustifyH("LEFT")
            hpText:SetPoint("RIGHT", healthBar, "RIGHT", -5, 0)
            hpText:SetJustifyH("RIGHT")
        end

        -- Update curses icons layout
        for j = 1, 5 do
            local curse = getglobal(dots:GetName().."Curse"..j)
            local curseBorder = getglobal(dots:GetName().."Curse"..j.."Border")
            curse:ClearAllPoints()
            curse:SetWidth(curseSize)
            curse:SetHeight(curseSize)
            curseBorder:SetWidth(curseSize * 1.1)
            curseBorder:SetHeight(curseSize * 1.1)

            if config.invertbars then
                if j == 1 then
                    if config.compactmode then
                        -- In compact mode, anchor next to HP text (which is on the LEFT)
                        curse:SetPoint("LEFT", hpText, "RIGHT", 5, 0)
                    else
                        curse:SetPoint("RIGHT", dots, "RIGHT", -3, 0)
                    end
                else
                    if config.compactmode then
                        curse:SetPoint("LEFT", getglobal(dots:GetName().."Curse"..(j-1)), "RIGHT", 4, 0)
                    else
                        curse:SetPoint("RIGHT", getglobal(dots:GetName().."Curse"..(j-1)), "LEFT", -4, 0)
                    end
                end
            else
                if j == 1 then
                    if config.compactmode then
                        -- In compact mode, anchor next to HP text (which is on the RIGHT)
                        curse:SetPoint("RIGHT", hpText, "LEFT", -5, 0)
                    else
                        curse:SetPoint("LEFT", dots, "LEFT", 3, 0)
                    end
                else
                    if config.compactmode then
                        curse:SetPoint("RIGHT", getglobal(dots:GetName().."Curse"..(j-1)), "LEFT", -4, 0)
                    else
                        curse:SetPoint("LEFT", getglobal(dots:GetName().."Curse"..(j-1)), "RIGHT", 4, 0)
                    end
                end
            end
        end
    end
end

function ui.ToggleOptions()
    if CursiveOptionsFrame:IsShown() then
        CursiveOptionsFrame:Hide()
    else
        local config = Cursive.db.profile
        CursiveOptionsFrameScaleSlider:SetValue(config.scale)
        CursiveOptionsFrameOpacitySlider:SetValue(config.opacity or 1)
        CursiveOptionsFrameLock:SetChecked(config.clickthrough)
        CursiveOptionsFrameInvert:SetChecked(config.invertbars)
        CursiveOptionsFrameExpandUpwards:SetChecked(config.expandupwards)
        CursiveOptionsFrameAlwaysShowTarget:SetChecked(config.alwaysshowcurrenttarget)
        CursiveOptionsFrameCompactMode:SetChecked(config.compactmode)
        CursiveOptionsFrameWarnings:SetChecked(config.warnings)
        CursiveOptionsFrameResistSound:SetChecked(config.resistsound)
        CursiveOptionsFrameExpiringSound:SetChecked(config.expiringsound)
        CursiveOptionsFrameAllowOOC:SetChecked(config.allowooc)
        CursiveOptionsFramePrioTarget:SetChecked(config.priotarget)
        CursiveOptionsFrameIgnoreTarget:SetChecked(config.ignoretarget)
        CursiveOptionsFramePlayerOnly:SetChecked(config.playeronly)
        CursiveOptionsFrameBarHeightSlider:SetValue(config.height)
        CursiveOptionsFrameMaxRowSlider:SetValue(config.maxrow)

        -- Update labels
        CursiveOptionsFrameScaleSliderText:SetText("Scale ("..(math.floor(config.scale * 100)/100)..")")
        CursiveOptionsFrameOpacitySliderText:SetText("Opacity ("..(math.floor((config.opacity or 1) * 100)/100)..")")
        CursiveOptionsFrameBarHeightSliderText:SetText(L["Health Bar/Unit Name Height"].." ("..config.height..")")
        CursiveOptionsFrameMaxRowSliderText:SetText("Max Rows ("..config.maxrow..")")

        CursiveOptionsFrame:Show()
    end
end

-- Option callbacks
function ui.UpdateScale()
    if not CursiveFrame then return end
    local scale = Cursive.db.profile.scale or 1
    CursiveFrame:SetScale(scale)
end

function ui.ScaleChanged(val)
    val = math.floor(val * 100) / 100
    Cursive.db.profile.scale = val
    ui.UpdateScale()
    CursiveOptionsFrameScaleSliderText:SetText("Scale ("..val..")")
end

function ui.OpacityChanged(val)
    if not CursiveFrame then return end
    val = math.floor(val * 100) / 100
    Cursive.db.profile.opacity = val
    CursiveFrame:SetAlpha(val)
    CursiveOptionsFrameOpacitySliderText:SetText("Opacity ("..val..")")
end

function ui.ToggleLock(val)
    Cursive.db.profile.clickthrough = val
    ui.UpdateLock()
end

function ui.ToggleInvert(val)
    Cursive.db.profile.invertbars = val
    ui.UpdateLayout()
end

function ui.ToggleExpandUpwards(val)
    Cursive.db.profile.expandupwards = val
    ui.UpdateLayout()
end

function ui.ToggleShowBackdrop(val)
    Cursive.db.profile.showbackdrop = val
    ui.UpdateBackdrop()
end

function ui.ToggleShowTitle(val)
    Cursive.db.profile.showtitle = val
    ui.UpdateHeader()
    ui.UpdateLayout()
end

function ui.ToggleAlwaysShowTarget(val)
    Cursive.db.profile.alwaysshowcurrenttarget = val
end

function ui.ToggleCompactMode(val)
    Cursive.db.profile.compactmode = val
    ui.UpdateLayout()
end

function ui.ToggleWarnings(val)
    Cursive.db.profile.warnings = val
end

function ui.ToggleResistSound(val)
    Cursive.db.profile.resistsound = val
end

function ui.ToggleExpiringSound(val)
    Cursive.db.profile.expiringsound = val
end

function ui.ToggleAllowOOC(val)
    Cursive.db.profile.allowooc = val
end

function ui.TogglePrioTarget(val)
    Cursive.db.profile.priotarget = val
end

function ui.ToggleIgnoreTarget(val)
    Cursive.db.profile.ignoretarget = val
end

function ui.TogglePlayerOnly(val)
    Cursive.db.profile.playeronly = val
end

function ui.BarHeightChanged(val)
    val = math.floor(val)
    Cursive.db.profile.height = val
    ui.UpdateLayout()
    CursiveOptionsFrameBarHeightSliderText:SetText(L["Health Bar/Unit Name Height"].." ("..val..")")
end

function ui.MaxRowChanged(val)
    val = math.floor(val)
    Cursive.db.profile.maxrow = val
    CursiveOptionsFrameMaxRowSliderText:SetText("Max Rows ("..val..")")
end

function ui.Show()
    if not CursiveFrame then return end
    Cursive.db.profile.enabled = true
    CursiveFrame:Show()
    CursiveUnitsFrame:Show()
    Cursive.core.enable()
end

function ui.Hide()
    if not CursiveFrame then return end
    Cursive.db.profile.enabled = false
    CursiveFrame:Hide()
    CursiveUnitsFrame:Hide()
    Cursive.core.disable()
end

function ui.Toggle()
    if Cursive.db.profile.enabled then
        ui.Hide()
    else
        ui.Show()
    end
end

-- Bar functions used by templates
function ui.BarClick()
    if not this.guid then return end
    if arg1 == "LeftButton" then
        TargetUnit(this.guid)
    elseif arg1 == "RightButton" then
        TargetUnit(this.guid)
        if (not PlayerFrame.inCombat) then
            AttackTarget()
        end
    end
end

function ui.BarEnter()
    if not this.guid then return end

    if this.guid then
        GameTooltip_SetDefaultAnchor(GameTooltip, this)
        GameTooltip:SetUnit(this.guid)
        GameTooltip:Show()
    end
end

function ui.BarLeave()
    GameTooltip:Hide()
end

function ui.CheckForCleanup()
    local now = GetTime()
    if (now - ui.lastCleanup < 5) then return end
    ui.lastCleanup = now

    for guid, _ in pairs(Cursive.core.guids) do
        if (not UnitExists(guid) or UnitIsDead(guid)) then
            Cursive.core.guids[guid] = nil
            if Cursive.curses.guids[guid] then
                Cursive.curses.guids[guid] = nil
            end
        end
    end
end

-- The main update loop (moved from the anonymous function in original ui.lua)
ui.tick = 0
function ui.OnUpdate()
    local elapsed = arg1 or 0
    local config = Cursive.db.profile
    if not config.enabled then
        for i = 1, ui.maxButtons do
            local btn = ui.unitButtons[i]
            if btn then btn:Hide() end
        end
        return
    end

    ui.CheckForCleanup()

    ui.tick = ui.tick + elapsed
    if ui.tick < 0.1 then return end
    ui.tick = 0

    -- Logic for choosing which GUIDs to show
    local guidList = {}

    local allPotential = {}
    for guid, _ in pairs(Cursive.core.guids) do
        if Cursive:ShouldDisplayGuid(guid) then
            table.insert(allPotential, guid)
        end
    end

    -- Stable Sort: Raid Mark priority first (Skull/Cross first), then Max HP
    table.sort(allPotential, function(a, b)
        local markA = GetRaidTargetIndex(a) or 0
        local markB = GetRaidTargetIndex(b) or 0

        -- Special case for Skull (8) and Cross (7)
        local weightA = (markA == 8 or markA == 7) and (markA + 10) or markA
        local weightB = (markB == 8 or markB == 7) and (markB + 10) or markB

        if weightA ~= weightB then
            return weightA > weightB
        end
        return UnitHealthMax(a) > UnitHealthMax(b)
    end)

    for i = 1, math.min(table.getn(allPotential), config.maxrow) do
        table.insert(guidList, allPotential[i])
    end

    -- Now update the buttons
    local numToShow = table.getn(guidList)

    for i = 1, ui.maxButtons do
        local btn = ui.unitButtons[i]
        if not btn then break end
        if i <= numToShow and i <= config.maxrow then
            local guid = guidList[i]
            btn.guid = guid

            local name = UnitName(guid)
            local healthBar = getglobal(btn:GetName().."HealthBar")
            local nameText = getglobal(btn:GetName().."HealthBarName")
            local hpText = getglobal(btn:GetName().."HealthBarHPText")
            local targetInd = getglobal(btn:GetName().."HealthBarTargetIndicator")
            local raidIcon = getglobal(btn:GetName().."HealthBarRaidIcon")
            local dots = getglobal(btn:GetName().."Dots")

            nameText:SetText(name)
            nameText:SetTextColor(1, 1, 1) -- Use white for better contrast against health bar

            local hp = UnitHealth(guid)
            local hpMax = UnitHealthMax(guid)
            healthBar:SetMinMaxValues(0, hpMax)
            healthBar:SetValue(hp)

            local _, r, g, b = utils.GetUnitColor(guid)
            healthBar:SetStatusBarColor(r, g, b)
            getglobal(healthBar:GetName().."Background"):SetAlpha(0.8)

            -- HP text formatting
            local hpStr = hp
            if hp >= 1000000 then hpStr = math.floor(hp/100000)/10 .. "m"
            elseif hp >= 1000 then hpStr = math.floor(hp/100)/10 .. "k" end
            hpText:SetText(hpStr)

            -- Target indicator and Selection border
            if guid and UnitIsUnit("target", guid) then
                if config.showtargetindicator then
                    targetInd:Show()
                else
                    targetInd:Hide()
                end
                getglobal(btn:GetName().."Selection"):Show()
            else
                targetInd:Hide()
                getglobal(btn:GetName().."Selection"):Hide()
            end

            -- Raid icon
            local raidIndex = guid and GetRaidTargetIndex(guid)
            if raidIndex and config.showraidicons then
                SetRaidTargetIconTexture(raidIcon, raidIndex)
                raidIcon:Show()
            else
                raidIcon:Hide()
            end

            -- Curses
            local guidCurses = guid and Cursive.curses.guids[guid]
            local curseIdx = 1
            if guidCurses then
                -- Sort curses
                for curseName, curseData in GetSortedCurses(guidCurses) do
                    if curseIdx > 5 then break end
                    local remaining = Cursive.curses:TimeRemaining(curseData)
                    if remaining >= 0 then
                        local curseTex = getglobal(dots:GetName().."Curse"..curseIdx)
                        local curseBorder = getglobal(dots:GetName().."Curse"..curseIdx.."Border")
                        local curseTimer = getglobal(dots:GetName().."Curse"..curseIdx.."Timer")
                        curseTex:SetTexture(Cursive.curses.trackedCurseIds[curseData.spellID].texture)
                        curseTex:SetDesaturated(not curseData.currentPlayer)
                        curseTex:Show()
                        curseBorder:Show()
                        curseTimer:SetText(remaining)
                        curseTimer:Show()
                        curseIdx = curseIdx + 1
                    end
                end
            end
            for j = curseIdx, 5 do
                getglobal(dots:GetName().."Curse"..j):Hide()
                getglobal(dots:GetName().."Curse"..j.."Border"):Hide()
                getglobal(dots:GetName().."Curse"..j.."Timer"):Hide()
            end

            btn:Show()
        else
            btn:Hide()
            btn.guid = nil
        end
    end

end

-- Initialize the UI
function ui.Initialize()
    ui.Setup()
    if CursiveFrame then
        CursiveFrame:SetScript("OnUpdate", ui.OnUpdate)
        ui.OnUpdate() -- Initial update to set height
        if Cursive.db.profile.enabled then
            CursiveFrame:Show()
            CursiveUnitsFrame:Show()
        else
            CursiveFrame:Hide()
            CursiveUnitsFrame:Hide()
        end
    end
end

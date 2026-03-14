if not Cursive.superwow then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cursive")

local utils = Cursive.utils
local filter = Cursive.filter

local ui = {}
Cursive.ui = ui

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
    if Cursive.db.profile.showbackdrop then
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

        raidIcon:SetWidth(raidSize)
        raidIcon:SetHeight(raidSize)
        targetInd:SetWidth(raidSize / 1.8)
        targetInd:SetHeight(raidSize * 1.1)

        dots:SetWidth(btnWidth)
        dots:SetHeight(config.compactmode and barHeight or 20)

        if config.compactmode then
            dots:SetPoint("TOP", btn, "TOP", 0, 0)
        else
            dots:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
        end

        nameText:SetHeight(barHeight)
        hpText:SetHeight(barHeight)

        if config.compactmode then
            -- Reserve space for 5 curses (curseSize + 4 padding each) + HP text (approx 50)
            local reserved = 50 + (curseSize * 5) + 20
            nameText:SetWidth(btnWidth - raidSize - (raidSize / 1.8) - reserved)
        else
            nameText:SetWidth(btnWidth - raidSize - (raidSize / 1.8) - 65)
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
            raidIcon:SetPoint("RIGHT", healthBar, "RIGHT", -5, 0)
            targetInd:SetPoint("RIGHT", raidIcon, "LEFT", -2, 0)
            targetInd:SetTexture("Interface\\AddOns\\Cursive\\img\\target-right")

            nameText:SetPoint("RIGHT", targetInd, "LEFT", -5, 0)
            nameText:SetJustifyH("RIGHT")
            hpText:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
            hpText:SetJustifyH("LEFT")
        else
            raidIcon:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
            targetInd:SetPoint("LEFT", raidIcon, "RIGHT", 2, 0)
            targetInd:SetTexture("Interface\\AddOns\\Cursive\\img\\target-left")

            nameText:SetPoint("LEFT", targetInd, "RIGHT", 5, 0)
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
        CursiveOptionsFrameShowBackdrop:SetChecked(config.showbackdrop)
        CursiveOptionsFrameShowTitle:SetChecked(config.showtitle)
        CursiveOptionsFrameAlwaysShowTarget:SetChecked(config.alwaysshowcurrenttarget)
        CursiveOptionsFrameCompactMode:SetChecked(config.compactmode)
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
                targetInd:Show()
                getglobal(btn:GetName().."Selection"):Show()
            else
                targetInd:Hide()
                getglobal(btn:GetName().."Selection"):Hide()
            end

            -- Raid icon
            local raidIndex = guid and GetRaidTargetIndex(guid)
            if raidIndex then
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

    -- Adjust main frame height based on num buttons (always draw a box that fits max rows)
    if CursiveFrame then
        local titleSize = config.showtitle and 40 or 10
        local spacing = config.spacing or 4
        local num = config.maxrow
        local btnHeight = config.compactmode and (config.height or 22) or 48
        local entriesHeight = (num * btnHeight) + ((num > 0 and num - 1 or 0) * spacing)
        local padding = 15
        CursiveFrame:SetWidth((config.healthwidth or 220) + 10)
        CursiveFrame:SetHeight(titleSize + entriesHeight + padding)
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

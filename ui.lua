if not Cursive.superwow then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cursive")

local utils = Cursive.utils
local filter = Cursive.filter

local ui = {}
Cursive.ui = ui

ui.unitButtons = {}
ui.maxButtons = 15

function ui.Setup()
    ui.UpdateScale()
    CursiveFrame:SetAlpha(Cursive.db.profile.opacity or 1)
    CursiveFrame:ClearAllPoints()
    CursiveFrame:SetPoint(Cursive.db.profile.anchor, Cursive.db.profile.x, Cursive.db.profile.y)

    ui.UpdateHeader()
    ui.UpdateBackdrop()
    ui.UpdateLock()

    for i = 1, ui.maxButtons do
        local btn = CreateFrame("Button", "CursiveUnitButton"..i, CursiveUnitsFrame, "CursiveUnitButtonTemplate")
        btn:SetID(i)
        ui.unitButtons[i] = btn
    end

    ui.UpdateInvert()
    ui.UpdateLayout()
end

function ui.UpdateHeader()
    if Cursive.db.profile.showtitle then
        CursiveFrameTitle:Show()
        CursiveFrameBackground:Show()
        CursiveFrameHitRect:Show()
    else
        CursiveFrameTitle:Hide()
        CursiveFrameBackground:Hide()
        CursiveFrameHitRect:Hide()
    end
end

function ui.UpdateBackdrop()
    if Cursive.db.profile.showbackdrop then
        CursiveFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
    else
        CursiveFrame:SetBackdrop(nil)
    end
end

function ui.UpdateLock()
    CursiveFrame:SetMovable(not Cursive.db.profile.clickthrough) -- In Cursive, clickthrough means locked
    CursiveFrame:EnableMouse(not Cursive.db.profile.clickthrough)
end

function ui.UpdateInvert()
    ui.UpdateLayout()
end

function ui.UpdateLayout()
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

    for i = 1, ui.maxButtons do
        local btn = ui.unitButtons[i]
        if not btn then break end
        btn:ClearAllPoints()
        if i == 1 then
            if config.expandupwards then
                btn:SetPoint("BOTTOM", CursiveUnitsFrame, "BOTTOM")
            else
                btn:SetPoint("TOP", CursiveUnitsFrame, "TOP")
            end
        else
            if config.expandupwards then
                btn:SetPoint("BOTTOM", ui.unitButtons[i-1], "TOP")
            else
                btn:SetPoint("TOP", ui.unitButtons[i-1], "BOTTOM")
            end
        end

        -- Invert internal button layout if needed
        local healthBar = getglobal(btn:GetName().."HealthBar")
        local nameText = getglobal(btn:GetName().."HealthBarName")
        local hpText = getglobal(btn:GetName().."HealthBarHPText")
        local targetInd = getglobal(btn:GetName().."TargetIndicator")
        local raidIcon = getglobal(btn:GetName().."RaidIcon")

        healthBar:ClearAllPoints()
        nameText:ClearAllPoints()
        hpText:ClearAllPoints()
        targetInd:ClearAllPoints()
        raidIcon:ClearAllPoints()

        if config.invertbars then
            healthBar:SetPoint("TOP", btn, "TOP", 0, -1)
            nameText:SetPoint("RIGHT", healthBar, "RIGHT", -5, 0)
            nameText:SetJustifyH("RIGHT")
            hpText:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
            hpText:SetJustifyH("LEFT")
            targetInd:SetPoint("LEFT", healthBar, "RIGHT", 2, 0)
            targetInd:SetTexture("Interface\\AddOns\\Cursive\\img\\target-left")
            raidIcon:SetPoint("CENTER", healthBar, "TOPLEFT", 5, 0)
        else
            healthBar:SetPoint("TOP", btn, "TOP", 0, -1)
            nameText:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
            nameText:SetJustifyH("LEFT")
            hpText:SetPoint("RIGHT", healthBar, "RIGHT", -5, 0)
            hpText:SetJustifyH("RIGHT")
            targetInd:SetPoint("RIGHT", healthBar, "LEFT", -2, 0)
            targetInd:SetTexture("Interface\\AddOns\\Cursive\\img\\target-right")
            raidIcon:SetPoint("CENTER", healthBar, "TOPRIGHT", -5, 0)
        end

        -- Update curses icons layout (below health bar)
        for j = 1, 5 do
            local curse = getglobal(btn:GetName().."Curse"..j)
            curse:ClearAllPoints()
            if config.invertbars then
                if j == 1 then
                    curse:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -15, -20)
                else
                    curse:SetPoint("RIGHT", getglobal(btn:GetName().."Curse"..(j-1)), "LEFT", -2, 0)
                end
            else
                if j == 1 then
                    curse:SetPoint("TOPLEFT", btn, "TOPLEFT", 15, -20)
                else
                    curse:SetPoint("LEFT", getglobal(btn:GetName().."Curse"..(j-1)), "RIGHT", 2, 0)
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
        CursiveOptionsFrameShowHealthBar:SetChecked(config.showhealthbar)
        CursiveOptionsFrameAlwaysShowTarget:SetChecked(config.alwaysshowcurrenttarget)
        CursiveOptionsFrameMaxRowSlider:SetValue(config.maxrow)

        -- Update labels
        CursiveOptionsFrameScaleSliderText:SetText("Scale ("..(math.floor(config.scale * 100)/100)..")")
        CursiveOptionsFrameOpacitySliderText:SetText("Opacity ("..(math.floor((config.opacity or 1) * 100)/100)..")")
        CursiveOptionsFrameMaxRowSliderText:SetText("Max Rows ("..config.maxrow..")")

        CursiveOptionsFrame:Show()
    end
end

-- Option callbacks
function ui.UpdateScale()
    local scale = Cursive.db.profile.scale or 1
    CursiveFrame:SetScale(scale)
    CursiveUnitsFrame:SetScale(scale)
end

function ui.ScaleChanged(val)
    val = math.floor(val * 100) / 100
    Cursive.db.profile.scale = val
    ui.UpdateScale()
    CursiveOptionsFrameScaleSliderText:SetText("Scale ("..val..")")
end

function ui.OpacityChanged(val)
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

function ui.ToggleShowHealthBar(val)
    Cursive.db.profile.showhealthbar = val
    ui.UpdateLayout()
end

function ui.ToggleAlwaysShowTarget(val)
    Cursive.db.profile.alwaysshowcurrenttarget = val
end

function ui.MaxRowChanged(val)
    val = math.floor(val)
    Cursive.db.profile.maxrow = val
    CursiveOptionsFrameMaxRowSliderText:SetText("Max Rows ("..val..")")
end

function ui.Show()
    Cursive.db.profile.enabled = true
    CursiveFrame:Show()
    CursiveUnitsFrame:Show()
    Cursive.core.enable()
end

function ui.Hide()
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
    this.hover = true
    if not this.guid then
        local healthBar = getglobal(this:GetName().."HealthBar")
        healthBar:SetBackdropBorderColor(1, 1, 1, 1)
        return
    end

    if this.guid then
        GameTooltip_SetDefaultAnchor(GameTooltip, this)
        GameTooltip:SetUnit(this.guid)
        GameTooltip:Show()
    end
end

function ui.BarLeave()
    this.hover = false
    GameTooltip:Hide()
end

-- The main update loop (moved from the anonymous function in original ui.lua)
ui.tick = 0
function ui.OnUpdate()
    local elapsed = arg1 or 0
    local config = Cursive.db.profile
    if not config.enabled then
        for i = 1, ui.maxButtons do ui.unitButtons[i]:Hide() end
        return
    end

    ui.tick = ui.tick + elapsed
    if ui.tick < 0.1 then return end
    ui.tick = 0

    -- Logic for choosing which GUIDs to show (reusing existing Cursive logic)
    local displayedGuids = {}
    local guidList = {}

    -- (Simplified for this conversion, but should follow Cursive's priority)
    -- 1. Raid marks
    for i = 8, 1, -1 do
        local _, guid = UnitExists("mark" .. i)
        if guid and Cursive:ShouldDisplayGuid(guid) then
            if not displayedGuids[guid] then
                table.insert(guidList, guid)
                displayedGuids[guid] = true
            end
        end
    end

    -- 2. Current target
    local _, targetGuid = UnitExists("target")
    if targetGuid and Cursive:ShouldDisplayGuid(targetGuid) and config.alwaysshowcurrenttarget then
        if not displayedGuids[targetGuid] then
            table.insert(guidList, targetGuid)
            displayedGuids[targetGuid] = true
        end
    end

    -- 3. Top HP mobs and others
    -- Collect all potential guids
    local potential = {}
    for guid, _ in pairs(Cursive.core.guids) do
        if not displayedGuids[guid] and Cursive:ShouldDisplayGuid(guid) then
            table.insert(potential, guid)
        end
    end
    -- Sort potential by max HP
    table.sort(potential, function(a, b)
        return UnitHealthMax(a) > UnitHealthMax(b)
    end)
    for _, guid in ipairs(potential) do
        if table.getn(guidList) >= config.maxrow * config.maxcol then break end
        table.insert(guidList, guid)
        displayedGuids[guid] = true
    end

    -- Now update the buttons
    local numToShow = table.getn(guidList)
    for i = 1, ui.maxButtons do
        local btn = ui.unitButtons[i]
        if i <= numToShow and i <= config.maxrow then
            local guid = guidList[i]
            btn.guid = guid

            local name = UnitName(guid)
            local healthBar = getglobal(btn:GetName().."HealthBar")
            local nameText = getglobal(btn:GetName().."HealthBarName")
            local hpText = getglobal(btn:GetName().."HealthBarHPText")
            local targetInd = getglobal(btn:GetName().."TargetIndicator")
            local raidIcon = getglobal(btn:GetName().."RaidIcon")

            nameText:SetText(name)
            local _, r, g, b = utils.GetUnitColor(guid)
            nameText:SetTextColor(r, g, b)

            local hp = UnitHealth(guid)
            local hpMax = UnitHealthMax(guid)
            healthBar:SetMinMaxValues(0, hpMax)
            healthBar:SetValue(hp)
            healthBar:SetStatusBarColor(r, g, b)
            if config.showhealthbar then
                healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                getglobal(healthBar:GetName().."Background"):SetAlpha(0.8)
            else
                healthBar:SetStatusBarTexture(nil)
                getglobal(healthBar:GetName().."Background"):SetAlpha(0)
            end

            -- HP text formatting
            local hpStr = hp
            if hp >= 1000000 then hpStr = math.floor(hp/100000)/10 .. "m"
            elseif hp >= 1000 then hpStr = math.floor(hp/100)/10 .. "k" end
            hpText:SetText(hpStr)

            -- Target indicator
            if UnitIsUnit("target", guid) then targetInd:Show() else targetInd:Hide() end

            -- Raid icon
            local raidIndex = GetRaidTargetIndex(guid)
            if raidIndex then
                SetRaidTargetIconTexture(raidIcon, raidIndex)
                raidIcon:Show()
            else
                raidIcon:Hide()
            end

            -- Curses
            local guidCurses = Cursive.curses.guids[guid]
            local curseIdx = 1
            if guidCurses then
                -- Sort curses (reusing logic from displayGuid if possible, but let's just use first 5)
                for curseName, curseData in pairs(guidCurses) do
                    if curseIdx > 5 then break end
                    local remaining = Cursive.curses:TimeRemaining(curseData)
                    if remaining >= 0 then
                        local curseTex = getglobal(btn:GetName().."Curse"..curseIdx)
                        local curseBorder = getglobal(btn:GetName().."Curse"..curseIdx.."Border")
                        curseTex:SetTexture(Cursive.curses.trackedCurseIds[curseData.spellID].texture)
                        curseTex:SetDesaturated(not curseData.currentPlayer)
                        curseTex:Show()
                        curseBorder:Show()
                        curseIdx = curseIdx + 1
                    end
                end
            end
            for j = curseIdx, 5 do
                getglobal(btn:GetName().."Curse"..j):Hide()
                getglobal(btn:GetName().."Curse"..j.."Border"):Hide()
            end

            btn:Show()
        else
            btn:Hide()
            btn.guid = nil
        end
    end

    -- Adjust main frame height based on num buttons
    local titleSize = config.showtitle and 40 or 10
    CursiveFrame:SetHeight(titleSize + (math.min(numToShow, config.maxrow) * 42))
end

-- Initialize the UI
function ui.Initialize()
    ui.Setup()
    CursiveFrame:SetScript("OnUpdate", ui.OnUpdate)
    if Cursive.db.profile.enabled then
        CursiveFrame:Show()
        CursiveUnitsFrame:Show()
    else
        CursiveFrame:Hide()
        CursiveUnitsFrame:Hide()
    end
end

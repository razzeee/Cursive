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
    CursiveFrame:SetScale(Cursive.db.profile.scale)
    CursiveFrame:SetAlpha(Cursive.db.profile.opacity or 1)
    CursiveFrame:ClearAllPoints()
    CursiveFrame:SetPoint(Cursive.db.profile.anchor, Cursive.db.profile.x, Cursive.db.profile.y)

    ui.UpdateHeader()
    ui.UpdateBackdrop()
    ui.UpdateLock()
    ui.UpdateInvert()

    for i = 1, ui.maxButtons do
        local btn = CreateFrame("Button", "CursiveUnitButton"..i, CursiveUnitsFrame, "CursiveUnitButtonTemplate")
        btn:SetID(i)
        ui.unitButtons[i] = btn
    end
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
        local icon = getglobal(btn:GetName().."Icon")
        local player = getglobal(btn:GetName().."Player")
        local hp = getglobal(btn:GetName().."HP")
        local healthBar = getglobal(btn:GetName().."HealthBar")

        icon:ClearAllPoints()
        player:ClearAllPoints()
        hp:ClearAllPoints()
        healthBar:ClearAllPoints()

        if config.invertbars then
            icon:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
            player:SetPoint("TOPRIGHT", icon, "TOPLEFT", -5, 3)
            player:SetJustifyH("RIGHT")
            hp:SetPoint("TOPLEFT", btn, "TOPLEFT", 5, 3)
            hp:SetJustifyH("LEFT")
            healthBar:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -10, 2)
        else
            icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
            player:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, 3)
            player:SetJustifyH("LEFT")
            hp:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -5, 3)
            hp:SetJustifyH("RIGHT")
            healthBar:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 10, 2)
        end

        -- Update curses icons layout
        for j = 1, 5 do
            local curse = getglobal(btn:GetName().."Curse"..j)
            curse:ClearAllPoints()
            if config.invertbars then
                if j == 1 then
                    curse:SetPoint("BOTTOMRIGHT", icon, "BOTTOMLEFT", -5, 0)
                else
                    curse:SetPoint("RIGHT", getglobal(btn:GetName().."Curse"..(j-1)), "LEFT", -2, 0)
                end
            else
                if j == 1 then
                    curse:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 5, 0)
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
        CursiveOptionsFrameScaleSlider:SetValue(Cursive.db.profile.scale)
        CursiveOptionsFrameOpacitySlider:SetValue(Cursive.db.profile.opacity or 1)
        CursiveOptionsFrameLock:SetChecked(Cursive.db.profile.clickthrough)
        CursiveOptionsFrameInvert:SetChecked(Cursive.db.profile.invertbars)
        CursiveOptionsFrameExpandUpwards:SetChecked(Cursive.db.profile.expandupwards)
        CursiveOptionsFrameShowBackdrop:SetChecked(Cursive.db.profile.showbackdrop)
        CursiveOptionsFrameShowTitle:SetChecked(Cursive.db.profile.showtitle)
        CursiveOptionsFrame:Show()
    end
end

-- Option callbacks
function ui.ScaleChanged(val)
    Cursive.db.profile.scale = val
    CursiveFrame:SetScale(val)
end

function ui.OpacityChanged(val)
    Cursive.db.profile.opacity = val
    CursiveFrame:SetAlpha(val)
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
function ui.OnUpdate(elapsed)
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
            local playerText = getglobal(btn:GetName().."Player")
            local hpText = getglobal(btn:GetName().."HP")
            local healthBar = getglobal(btn:GetName().."HealthBar")
            local icon = getglobal(btn:GetName().."Icon")
            local targetInd = getglobal(btn:GetName().."TargetIndicator")
            local raidIcon = getglobal(btn:GetName().."RaidIcon")

            playerText:SetText(name)
            local _, r, g, b = utils.GetUnitColor(guid)
            playerText:SetTextColor(r, g, b)

            local hp = UnitHealth(guid)
            local hpMax = UnitHealthMax(guid)
            healthBar:SetMinMaxValues(0, hpMax)
            healthBar:SetValue(hp)
            healthBar:SetStatusBarColor(r, g, b)

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
                        curseTex:SetTexture(Cursive.curses.trackedCurseIds[curseData.spellID].texture)
                        curseTex:SetDesaturated(not curseData.currentPlayer)
                        curseTex:Show()
                        curseIdx = curseIdx + 1
                    end
                end
            end
            for j = curseIdx, 5 do getglobal(btn:GetName().."Curse"..j):Hide() end

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
Cursive:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    ui.Setup()
    CursiveFrame:SetScript("OnUpdate", ui.OnUpdate)
end)

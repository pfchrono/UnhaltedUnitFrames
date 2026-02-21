local _, UUF = ...

-- Class colour mapping from oUF
local ClassColours = {
    DEATHKNIGHT = {0.77, 0.12, 0.23},
    DEMONHUNTER = {0.64, 0.19, 0.79},
    DRUID = {1.0, 0.49, 0.04},
    HUNTER = {0.67, 0.83, 0.45},
    MAGE = {0.41, 0.8, 0.94},
    MONK = {0.0, 1.0, 0.59},
    PALADIN = {1.0, 0.96, 0.41},
    PRIEST = {1.0, 1.0, 1.0},
    ROGUE = {1.0, 0.96, 0.41},
    SHAMAN = {0.0, 0.44, 0.87},
    WARLOCK = {0.58, 0.51, 0.79},
    WARRIOR = {0.78, 0.61, 0.43},
}

local function GetClassColour(unit)
    if not unit then return nil end
    local _, class = UnitClass(unit)
    if class and ClassColours[class] then
        local c = ClassColours[class]
        return {c[1], c[2], c[3], 1.0}
    end
    return nil
end

local function ConfigureOverlayBar(bar, colour, overlayOpacity, textureName)
    local alpha = (colour[4] or 1) * (overlayOpacity or 0.75)

    local LSM = LibStub("LibSharedMedia-3.0")
    local textureFile = UUF.Media.Foreground or "Interface\\TargetingFrame\\UI-StatusBar"
    
    if textureName and LSM then
        local lsmTexture = LSM:Fetch("statusbar", textureName)
        if lsmTexture then
            textureFile = lsmTexture
        end
    end

    -- Set texture first
    bar:SetStatusBarTexture(textureFile)
    
    -- Apply color (this needs to happen AFTER texture is set)
    bar:SetStatusBarColor(colour[1], colour[2], colour[3], alpha)
    
    -- Set min/max and value
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    
    -- Configure texture layer
    local texture = bar:GetStatusBarTexture()
    if texture then
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetDrawLayer("ARTWORK", 1)
    end
end

local function ConfigureSolidBar(bar, colour)
    bar:SetStatusBarTexture(UUF.Media.Foreground)
    bar:SetStatusBarColor(colour[1], colour[2], colour[3], colour[4] or 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
end

local function PositionPredictionBar(bar, unitFrame, position, height, reverseRight, anchorTexture)
    local anchorFrame = anchorTexture or unitFrame.Health
    local healthFrameWidth = unitFrame.Health:GetWidth() or 200
    
    bar:ClearAllPoints()

    if position == "RIGHT" then
        bar:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", 0, 0)
        bar:SetHeight(height)
        bar:SetReverseFill(reverseRight)
        bar:SetWidth(healthFrameWidth)
    elseif position == "ATTACH" then
        -- For ATTACH, put incoming heals on the side after the filled health (right side for normal, left for reversed)
        unitFrame.Health:SetClipsChildren(true)
        local isReversed = unitFrame.Health:GetReverseFill()
        
        if isReversed then
            -- For reversed bars, incoming heals go on the LEFT
            bar:SetPoint("TOPLEFT", anchorTexture or unitFrame.Health:GetStatusBarTexture(), "TOPLEFT", 0, 0)
            bar:SetPoint("BOTTOMLEFT", anchorTexture or unitFrame.Health:GetStatusBarTexture(), "BOTTOMLEFT", 0, 0)
            bar:SetReverseFill(true)
        else
            -- For normal bars, incoming heals go on the RIGHT
            bar:SetPoint("TOPRIGHT", anchorTexture or unitFrame.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
            bar:SetPoint("BOTTOMRIGHT", anchorTexture or unitFrame.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
            bar:SetReverseFill(false)
        end
        bar:SetHeight(height)
        bar:SetWidth(healthFrameWidth)
    else
        bar:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMLEFT", 0, 0)
        bar:SetHeight(height)
        bar:SetReverseFill(false)
        bar:SetWidth(healthFrameWidth)
    end
end

local function AnchorOverAbsorbGlow(glow, unitFrame, side)
    local healthFrame = unitFrame.Health
    local healthHeight = healthFrame:GetHeight() or 20
    
    glow:ClearAllPoints()
    glow:SetPoint("TOP", healthFrame, "TOP", 0, 0)
    glow:SetPoint("BOTTOM", healthFrame, "BOTTOM", 0, 0)
    
    if side == "RIGHT" then
        glow:SetPoint("RIGHT", healthFrame, "RIGHT", 7, 0)
    else
        glow:SetPoint("LEFT", healthFrame, "LEFT", -7, 0)
    end
    
    -- Update glow size to match health bar height
    glow:SetSize(16, healthHeight)
end

local function CreateValueDisplay(parentFrame, frameName)
    local fontString = parentFrame:CreateFontString(frameName, "OVERLAY")
    local font, size = GameFontNormal:GetFont()
    fontString:SetFont(font, size - 3)
    fontString:SetTextColor(1, 1, 1, 1)
    fontString:SetJustifyH("CENTER")
    fontString:SetJustifyV("MIDDLE")
    fontString:SetWidth(60)
    fontString:SetHeight(16)
    fontString:SetWordWrap(false)
    return fontString
end

local function IsSecretValue(value)
    if type(issecretvalue) == "function" then
        return issecretvalue(value)
    end
    return UUF.Architecture.IsSecretValue(value)
end

local function GetBarShown(bar)
    local ok, shown = UUF.Architecture.SafeValue(bar.IsShown, bar)
    if ok then return shown end
    return true
end

local function UpdateValueDisplay(bar)
    if not bar or not bar.ValueDisplay then return end

    local okValue, value = pcall(bar.GetValue, bar)
    local okMinMax, minValue, maxValue = pcall(bar.GetMinMaxValues, bar)

    if not okValue or not okMinMax then
        bar.ValueDisplay:Hide()
        return
    end

    if not value then
        bar.ValueDisplay:Hide()
        return
    end

    if not GetBarShown(bar) then
        bar.ValueDisplay:Hide()
        return
    end

    local valueIsSecret = IsSecretValue(value)
    local maxIsSecret = IsSecretValue(maxValue)

    if not valueIsSecret and not maxIsSecret and maxValue and maxValue > 0 and value > 0 then
        local formattedValue = UUF.Utilities and UUF.Utilities.FormatNumber and UUF.Utilities.FormatNumber(value) or tostring(value)
        local percent = math.floor((value / maxValue) * 100)
        local displayText = string.format("%s (%d%%)", formattedValue, percent)
        
        print("[HealPrediction] Value: " .. tostring(value) .. " / " .. tostring(maxValue) .. " (" .. tostring(percent) .. "%) => " .. displayText)
        
        bar.ValueDisplay:SetText(displayText)
        bar.ValueDisplay:Show()
        return
    end

    bar.ValueDisplay:Hide()
end

local function AttachValueHooks(bar)
    if not bar or bar.UUFValueHooked then return end
    bar:HookScript("OnValueChanged", UpdateValueDisplay)
    bar:HookScript("OnMinMaxChanged", UpdateValueDisplay)
    bar.UUFValueHooked = true
    UpdateValueDisplay(bar)
end

local function HealPredictionPostUpdate(element, unit)
    UpdateValueDisplay(element.damageAbsorb)
    UpdateValueDisplay(element.healAbsorb)
    UpdateValueDisplay(element.healingAll)
    UpdateValueDisplay(element.healingPlayer)
    UpdateValueDisplay(element.healingOther)
end

local function CreateUnitAbsorbs(unitFrame, unit)
    local AbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.Absorbs
    if not unitFrame.Health then return end
    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)

    local AbsorbBar = CreateFrame("StatusBar", frameName .. "_AbsorbBar", unitFrame.Health)
    ConfigureOverlayBar(AbsorbBar, AbsorbDB.Colour, AbsorbDB.OverlayOpacity or 0.5, AbsorbDB.Texture or "Blizzard")
    PositionPredictionBar(AbsorbBar, unitFrame, AbsorbDB.Position, AbsorbDB.Height, true)
    AbsorbBar:SetFrameLevel(unitFrame.Health:GetFrameLevel())
    
    -- Create value display
    local valueFont = CreateValueDisplay(AbsorbBar, frameName .. "_AbsorbValue")
    valueFont:ClearAllPoints()
    valueFont:SetPoint("CENTER", AbsorbBar, "CENTER", 0, 0)
    valueFont:SetPoint("LEFT", AbsorbBar, "CENTER", 3, 0)
    AbsorbBar.ValueDisplay = valueFont
    AttachValueHooks(AbsorbBar)
    
    AbsorbBar:Show()

    return AbsorbBar
end

local function CreateUnitHealAbsorbs(unitFrame, unit)
    local HealAbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.HealAbsorbs
    if not unitFrame.Health then return end
    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)

    local HealAbsorbBar = CreateFrame("StatusBar", frameName .. "_HealAbsorbBar", unitFrame.Health)
    ConfigureOverlayBar(HealAbsorbBar, HealAbsorbDB.Colour, HealAbsorbDB.OverlayOpacity or 0.5, HealAbsorbDB.Texture or "Blizzard")
    PositionPredictionBar(HealAbsorbBar, unitFrame, HealAbsorbDB.Position, HealAbsorbDB.Height, true)
    HealAbsorbBar:SetFrameLevel(unitFrame.Health:GetFrameLevel())
    
    -- Create value display
    local valueFont = CreateValueDisplay(HealAbsorbBar, frameName .. "_HealAbsorbValue")
    valueFont:ClearAllPoints()
    valueFont:SetPoint("CENTER", HealAbsorbBar, "CENTER", 0, 0)
    valueFont:SetPoint("LEFT", HealAbsorbBar, "CENTER", 3, 0)
    HealAbsorbBar.ValueDisplay = valueFont
    AttachValueHooks(HealAbsorbBar)
    
    HealAbsorbBar:Show()

    return HealAbsorbBar
end

local function CreateIncomingHealBar(unitFrame, unit, suffix)
    if not unitFrame.Health then return end

    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)
    local bar = CreateFrame("StatusBar", frameName .. suffix, unitFrame.Health)
    bar:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 1)
    
    -- Create value display
    local valueFont = CreateValueDisplay(bar, frameName .. suffix .. "_Value")
    valueFont:ClearAllPoints()
    valueFont:SetPoint("CENTER", bar, "CENTER", 0, 0)
    valueFont:SetPoint("LEFT", bar, "CENTER", 3, 0)
    bar.ValueDisplay = valueFont
    AttachValueHooks(bar)

    return bar
end

function UUF:CreateUnitHealPrediction(unitFrame, unit)
    local AbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.Absorbs
    local HealAbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.HealAbsorbs

    local IncomingHealsDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.IncomingHeals
    local damageAbsorbBar = AbsorbDB.Enabled and CreateUnitAbsorbs(unitFrame, unit)
    local healAbsorbBar = HealAbsorbDB.Enabled and CreateUnitHealAbsorbs(unitFrame, unit)
    local healingAllBar
    local healingPlayerBar
    local healingOtherBar
    local overDamageAbsorbGlow
    local overHealAbsorbGlow

    if AbsorbDB.ShowGlow ~= false then
        local healthHeight = unitFrame.Health:GetHeight() or 20
        overDamageAbsorbGlow = unitFrame.Health:CreateTexture(nil, "ARTWORK", nil, 2)
        overDamageAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
        overDamageAbsorbGlow:SetBlendMode("ADD")
        overDamageAbsorbGlow:SetSize(16, healthHeight)
        -- Anchor immediately
        overDamageAbsorbGlow:SetPoint("TOP", unitFrame.Health, "TOP", 0, 0)
        overDamageAbsorbGlow:SetPoint("BOTTOM", unitFrame.Health, "BOTTOM", 0, 0)
        overDamageAbsorbGlow:SetPoint("LEFT", unitFrame.Health, "LEFT", -7, 0)
        overDamageAbsorbGlow:Hide()
    end

    if HealAbsorbDB.ShowGlow ~= false then
        local healthHeight = unitFrame.Health:GetHeight() or 20
        overHealAbsorbGlow = unitFrame.Health:CreateTexture(nil, "ARTWORK", nil, 2)
        overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
        overHealAbsorbGlow:SetBlendMode("ADD")
        overHealAbsorbGlow:SetSize(16, healthHeight)
        -- Anchor immediately
        overHealAbsorbGlow:SetPoint("TOP", unitFrame.Health, "TOP", 0, 0)
        overHealAbsorbGlow:SetPoint("BOTTOM", unitFrame.Health, "BOTTOM", 0, 0)
        overHealAbsorbGlow:SetPoint("RIGHT", unitFrame.Health, "RIGHT", 7, 0)
        overHealAbsorbGlow:Hide()
    end

    if IncomingHealsDB and IncomingHealsDB.Enabled then
        if IncomingHealsDB.Split then
            healingPlayerBar = CreateIncomingHealBar(unitFrame, unit, "_IncomingHealPlayer")
            healingOtherBar = CreateIncomingHealBar(unitFrame, unit, "_IncomingHealOther")
        else
            healingAllBar = CreateIncomingHealBar(unitFrame, unit, "_IncomingHealAll")
        end
    end

    unitFrame.HealthPrediction = {
        healingAll = healingAllBar,
        healingPlayer = healingPlayerBar,
        healingOther = healingOtherBar,
        damageAbsorb = damageAbsorbBar,
        damageAbsorbClampMode = 2,
        overDamageAbsorbIndicator = overDamageAbsorbGlow,
        healAbsorb = healAbsorbBar,
        healAbsorbClampMode = 1,
        healAbsorbMode = 1,
        overHealAbsorbIndicator = overHealAbsorbGlow,
        incomingHealOverflow = IncomingHealsDB and IncomingHealsDB.Overflow or 1.05,
        PostUpdate = HealPredictionPostUpdate,
    }
end

function UUF:UpdateUnitHealPrediction(unitFrame, unit)
    local AbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.Absorbs
    local HealAbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.HealAbsorbs
    local IncomingHealsDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.IncomingHeals

    -- Get class colour for absorbs
    local classColour = GetClassColour(unit)
    local absorbColour = classColour or AbsorbDB.Colour
    
    if unitFrame.HealthPrediction then
        if AbsorbDB.Enabled then
            unitFrame.HealthPrediction.damageAbsorb = unitFrame.HealthPrediction.damageAbsorb or CreateUnitAbsorbs(unitFrame, unit)
            unitFrame.HealthPrediction.damageAbsorbClampMode = 2
            unitFrame.HealthPrediction.damageAbsorb:Show()
            ConfigureOverlayBar(unitFrame.HealthPrediction.damageAbsorb, absorbColour, AbsorbDB.OverlayOpacity or 0.5, AbsorbDB.Texture or "Blizzard")
            PositionPredictionBar(unitFrame.HealthPrediction.damageAbsorb, unitFrame, AbsorbDB.Position, AbsorbDB.Height, true)
            unitFrame.HealthPrediction.damageAbsorb:SetValue(unitFrame.HealthPrediction.damageAbsorb:GetValue() or 0)

            if AbsorbDB.ShowGlow ~= false then
                if not unitFrame.HealthPrediction.overDamageAbsorbIndicator then
                    local healthHeight = unitFrame.Health:GetHeight() or 20
                    unitFrame.HealthPrediction.overDamageAbsorbIndicator = unitFrame.Health:CreateTexture(nil, "ARTWORK", nil, 2)
                    unitFrame.HealthPrediction.overDamageAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
                    unitFrame.HealthPrediction.overDamageAbsorbIndicator:SetBlendMode("ADD")
                    unitFrame.HealthPrediction.overDamageAbsorbIndicator:SetSize(16, healthHeight)
                end
                AnchorOverAbsorbGlow(unitFrame.HealthPrediction.overDamageAbsorbIndicator, unitFrame, "LEFT")
                -- Use bright white for glow visibility instead of absorb colour
                unitFrame.HealthPrediction.overDamageAbsorbIndicator:SetVertexColor(1.0, 1.0, 1.0, (AbsorbDB.GlowOpacity or 1.0))
                unitFrame.HealthPrediction.overDamageAbsorbIndicator:Show()
            elseif unitFrame.HealthPrediction.overDamageAbsorbIndicator then
                unitFrame.HealthPrediction.overDamageAbsorbIndicator:Hide()
            end

            unitFrame.HealthPrediction:ForceUpdate()
            AttachValueHooks(unitFrame.HealthPrediction.damageAbsorb)
        else
            if unitFrame.HealthPrediction.damageAbsorb then
                unitFrame.HealthPrediction.damageAbsorb:Hide()
            end
            if unitFrame.HealthPrediction.overDamageAbsorbIndicator then
                unitFrame.HealthPrediction.overDamageAbsorbIndicator:Hide()
            end
        end
        if HealAbsorbDB.Enabled then
            unitFrame.HealthPrediction.healAbsorb = unitFrame.HealthPrediction.healAbsorb or CreateUnitHealAbsorbs(unitFrame, unit)
            unitFrame.HealthPrediction.healAbsorbClampMode = 1
            unitFrame.HealthPrediction.healAbsorb:Show()
            ConfigureOverlayBar(unitFrame.HealthPrediction.healAbsorb, HealAbsorbDB.Colour, HealAbsorbDB.OverlayOpacity or 0.5, HealAbsorbDB.Texture or "Blizzard")
            PositionPredictionBar(unitFrame.HealthPrediction.healAbsorb, unitFrame, HealAbsorbDB.Position, HealAbsorbDB.Height, true)
            unitFrame.HealthPrediction.healAbsorb:SetValue(unitFrame.HealthPrediction.healAbsorb:GetValue() or 0)

            if HealAbsorbDB.ShowGlow ~= false then
                if not unitFrame.HealthPrediction.overHealAbsorbIndicator then
                    local healthHeight = unitFrame.Health:GetHeight() or 20
                    unitFrame.HealthPrediction.overHealAbsorbIndicator = unitFrame.Health:CreateTexture(nil, "ARTWORK", nil, 2)
                    unitFrame.HealthPrediction.overHealAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
                    unitFrame.HealthPrediction.overHealAbsorbIndicator:SetBlendMode("ADD")
                    unitFrame.HealthPrediction.overHealAbsorbIndicator:SetSize(16, healthHeight)
                end
                AnchorOverAbsorbGlow(unitFrame.HealthPrediction.overHealAbsorbIndicator, unitFrame, "RIGHT")
                -- Use bright white for glow visibility instead of heal absorb colour
                unitFrame.HealthPrediction.overHealAbsorbIndicator:SetVertexColor(1.0, 1.0, 1.0, (HealAbsorbDB.GlowOpacity or 1.0))
                unitFrame.HealthPrediction.overHealAbsorbIndicator:Show()
            elseif unitFrame.HealthPrediction.overHealAbsorbIndicator then
                unitFrame.HealthPrediction.overHealAbsorbIndicator:Hide()
            end

            unitFrame.HealthPrediction:ForceUpdate()
            AttachValueHooks(unitFrame.HealthPrediction.healAbsorb)
        else
            if unitFrame.HealthPrediction.healAbsorb then
                unitFrame.HealthPrediction.healAbsorb:Hide()
            end
            if unitFrame.HealthPrediction.overHealAbsorbIndicator then
                unitFrame.HealthPrediction.overHealAbsorbIndicator:Hide()
            end
        end

        if IncomingHealsDB and IncomingHealsDB.Enabled then
            unitFrame.HealthPrediction.incomingHealOverflow = IncomingHealsDB.Overflow or 1.05

            if IncomingHealsDB.Split then
                unitFrame.HealthPrediction.healingPlayer = unitFrame.HealthPrediction.healingPlayer or CreateIncomingHealBar(unitFrame, unit, "_IncomingHealPlayer")
                unitFrame.HealthPrediction.healingOther = unitFrame.HealthPrediction.healingOther or CreateIncomingHealBar(unitFrame, unit, "_IncomingHealOther")
                if unitFrame.HealthPrediction.healingAll then
                    unitFrame.HealthPrediction.healingAll:Hide()
                end

                ConfigureSolidBar(unitFrame.HealthPrediction.healingPlayer, IncomingHealsDB.ColourPlayer)
                ConfigureSolidBar(unitFrame.HealthPrediction.healingOther, IncomingHealsDB.ColourOther)

                PositionPredictionBar(unitFrame.HealthPrediction.healingPlayer, unitFrame, IncomingHealsDB.Position, IncomingHealsDB.Height, false)
                PositionPredictionBar(
                    unitFrame.HealthPrediction.healingOther,
                    unitFrame,
                    IncomingHealsDB.Position,
                    IncomingHealsDB.Height,
                    false,
                    unitFrame.HealthPrediction.healingPlayer:GetStatusBarTexture()
                )

                unitFrame.HealthPrediction.healingPlayer:Show()
                unitFrame.HealthPrediction.healingOther:Show()
            else
                unitFrame.HealthPrediction.healingAll = unitFrame.HealthPrediction.healingAll or CreateIncomingHealBar(unitFrame, unit, "_IncomingHealAll")
                if unitFrame.HealthPrediction.healingPlayer then
                    unitFrame.HealthPrediction.healingPlayer:Hide()
                end
                if unitFrame.HealthPrediction.healingOther then
                    unitFrame.HealthPrediction.healingOther:Hide()
                end

                ConfigureSolidBar(unitFrame.HealthPrediction.healingAll, IncomingHealsDB.ColourAll)
                PositionPredictionBar(unitFrame.HealthPrediction.healingAll, unitFrame, IncomingHealsDB.Position, IncomingHealsDB.Height, false)
                
                unitFrame.HealthPrediction.healingAll:Show()
            end

            unitFrame.HealthPrediction:ForceUpdate()
            AttachValueHooks(unitFrame.HealthPrediction.healingAll)
            AttachValueHooks(unitFrame.HealthPrediction.healingPlayer)
            AttachValueHooks(unitFrame.HealthPrediction.healingOther)
        else
            if unitFrame.HealthPrediction.healingAll then
                unitFrame.HealthPrediction.healingAll:Hide()
            end
            if unitFrame.HealthPrediction.healingPlayer then
                unitFrame.HealthPrediction.healingPlayer:Hide()
            end
            if unitFrame.HealthPrediction.healingOther then
                unitFrame.HealthPrediction.healingOther:Hide()
            end

            unitFrame.HealthPrediction.healingAll = nil
            unitFrame.HealthPrediction.healingPlayer = nil
            unitFrame.HealthPrediction.healingOther = nil
        end
    else
        UUF:CreateUnitHealPrediction(unitFrame, unit)
    end
end
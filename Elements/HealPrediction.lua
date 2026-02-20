local _, UUF = ...

local function ConfigureOverlayBar(bar, colour, overlayOpacity)
    local alpha = (colour[4] or 1) * (overlayOpacity or 1)

    bar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Overlay")
    bar:SetStatusBarColor(colour[1], colour[2], colour[3], alpha)

    local texture = bar:GetStatusBarTexture()
    texture:SetTexture("Interface\\RaidFrame\\Shield-Overlay", "REPEAT", "REPEAT")
    texture:SetHorizTile(true)
    texture:SetVertTile(true)
    texture:SetDrawLayer("ARTWORK", 1)
end

local function ConfigureSolidBar(bar, colour)
    bar:SetStatusBarTexture(UUF.Media.Foreground)
    bar:SetStatusBarColor(colour[1], colour[2], colour[3], colour[4] or 1)
end

local function PositionPredictionBar(bar, unitFrame, position, height, reverseRight, anchorTexture)
    local anchorFrame = anchorTexture or unitFrame.Health
    bar:ClearAllPoints()

    if position == "RIGHT" then
        bar:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", 0, 0)
        bar:SetHeight(height)
        bar:SetReverseFill(reverseRight)
    elseif position == "ATTACH" then
        unitFrame.Health:SetClipsChildren(true)
        if unitFrame.Health:GetReverseFill() then
            bar:SetPoint("TOPRIGHT", anchorTexture or unitFrame.Health:GetStatusBarTexture(), "TOPLEFT", 0, 0)
            bar:SetReverseFill(true)
        else
            bar:SetPoint("TOPLEFT", anchorTexture or unitFrame.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
            bar:SetReverseFill(false)
        end
        bar:SetHeight(height)
    else
        bar:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, 0)
        bar:SetHeight(height)
        bar:SetReverseFill(false)
    end
end

local function AnchorOverAbsorbGlow(glow, bar, side)
    local texture = bar:GetStatusBarTexture()

    glow:ClearAllPoints()
    glow:SetPoint("TOP", texture, "TOP", 0, 0)
    glow:SetPoint("BOTTOM", texture, "BOTTOM", 0, 0)

    if side == "RIGHT" then
        glow:SetPoint("RIGHT", texture, "RIGHT", 7, 0)
    else
        glow:SetPoint("LEFT", texture, "LEFT", -7, 0)
    end
end

local function CreateUnitAbsorbs(unitFrame, unit)
    local AbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.Absorbs
    if not unitFrame.Health then return end
    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)

    local AbsorbBar = CreateFrame("StatusBar", frameName .. "_AbsorbBar", unitFrame.Health)
    ConfigureOverlayBar(AbsorbBar, AbsorbDB.Colour, AbsorbDB.OverlayOpacity or 0.5)
    UUF:QueueOrRun(function()
        PositionPredictionBar(AbsorbBar, unitFrame, AbsorbDB.Position, AbsorbDB.Height, true)
        AbsorbBar:SetFrameLevel(unitFrame.Health:GetFrameLevel())
        AbsorbBar:Show()
    end)

    return AbsorbBar
end

local function CreateUnitHealAbsorbs(unitFrame, unit)
    local HealAbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.HealAbsorbs
    if not unitFrame.Health then return end
    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)

    local HealAbsorbBar = CreateFrame("StatusBar", frameName .. "_HealAbsorbBar", unitFrame.Health)
    ConfigureOverlayBar(HealAbsorbBar, HealAbsorbDB.Colour, HealAbsorbDB.OverlayOpacity or 0.5)
    UUF:QueueOrRun(function()
        PositionPredictionBar(HealAbsorbBar, unitFrame, HealAbsorbDB.Position, HealAbsorbDB.Height, true)
        HealAbsorbBar:SetFrameLevel(unitFrame.Health:GetFrameLevel())
        HealAbsorbBar:Show()
    end)

    return HealAbsorbBar
end

local function CreateIncomingHealBar(unitFrame, unit, suffix)
    if not unitFrame.Health then return end

    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)
    local bar = CreateFrame("StatusBar", frameName .. suffix, unitFrame.Health)
    bar:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 1)

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
        overDamageAbsorbGlow = unitFrame.Health:CreateTexture(nil, "ARTWORK", nil, 2)
        overDamageAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
        overDamageAbsorbGlow:SetBlendMode("ADD")
        overDamageAbsorbGlow:SetSize(16, 0)
        overDamageAbsorbGlow:Hide()
    end

    if HealAbsorbDB.ShowGlow ~= false then
        overHealAbsorbGlow = unitFrame.Health:CreateTexture(nil, "ARTWORK", nil, 2)
        overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
        overHealAbsorbGlow:SetBlendMode("ADD")
        overHealAbsorbGlow:SetSize(16, 0)
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
    }
end

function UUF:UpdateUnitHealPrediction(unitFrame, unit)
    local AbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.Absorbs
    local HealAbsorbDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.HealAbsorbs
    local IncomingHealsDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealPrediction.IncomingHeals

    if unitFrame.HealthPrediction then
        if AbsorbDB.Enabled then
            unitFrame.HealthPrediction.damageAbsorb = unitFrame.HealthPrediction.damageAbsorb or CreateUnitAbsorbs(unitFrame, unit)
            unitFrame.HealthPrediction.damageAbsorbClampMode = 2
            unitFrame.HealthPrediction.damageAbsorb:Show()
            ConfigureOverlayBar(unitFrame.HealthPrediction.damageAbsorb, AbsorbDB.Colour, AbsorbDB.OverlayOpacity or 0.5)
            PositionPredictionBar(unitFrame.HealthPrediction.damageAbsorb, unitFrame, AbsorbDB.Position, AbsorbDB.Height, true)

            if AbsorbDB.ShowGlow ~= false then
                if not unitFrame.HealthPrediction.overDamageAbsorbIndicator then
                    unitFrame.HealthPrediction.overDamageAbsorbIndicator = unitFrame.Health:CreateTexture(nil, "ARTWORK", nil, 2)
                    unitFrame.HealthPrediction.overDamageAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
                    unitFrame.HealthPrediction.overDamageAbsorbIndicator:SetBlendMode("ADD")
                    unitFrame.HealthPrediction.overDamageAbsorbIndicator:SetSize(16, 0)
                end
                AnchorOverAbsorbGlow(unitFrame.HealthPrediction.overDamageAbsorbIndicator, unitFrame.HealthPrediction.damageAbsorb, "LEFT")
                unitFrame.HealthPrediction.overDamageAbsorbIndicator:Show()
            elseif unitFrame.HealthPrediction.overDamageAbsorbIndicator then
                unitFrame.HealthPrediction.overDamageAbsorbIndicator:Hide()
            end

            unitFrame.HealthPrediction:ForceUpdate()
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
            ConfigureOverlayBar(unitFrame.HealthPrediction.healAbsorb, HealAbsorbDB.Colour, HealAbsorbDB.OverlayOpacity or 0.5)
            PositionPredictionBar(unitFrame.HealthPrediction.healAbsorb, unitFrame, HealAbsorbDB.Position, HealAbsorbDB.Height, true)

            if HealAbsorbDB.ShowGlow ~= false then
                if not unitFrame.HealthPrediction.overHealAbsorbIndicator then
                    unitFrame.HealthPrediction.overHealAbsorbIndicator = unitFrame.Health:CreateTexture(nil, "ARTWORK", nil, 2)
                    unitFrame.HealthPrediction.overHealAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
                    unitFrame.HealthPrediction.overHealAbsorbIndicator:SetBlendMode("ADD")
                    unitFrame.HealthPrediction.overHealAbsorbIndicator:SetSize(16, 0)
                end
                AnchorOverAbsorbGlow(unitFrame.HealthPrediction.overHealAbsorbIndicator, unitFrame.HealthPrediction.healAbsorb, "RIGHT")
                unitFrame.HealthPrediction.overHealAbsorbIndicator:Show()
            elseif unitFrame.HealthPrediction.overHealAbsorbIndicator then
                unitFrame.HealthPrediction.overHealAbsorbIndicator:Hide()
            end

            unitFrame.HealthPrediction:ForceUpdate()
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
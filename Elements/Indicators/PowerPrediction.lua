local _, UUF = ...
local function GetPowerPredictionDB(unit)
    local unitDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)]
    return unitDB and unitDB.Indicators and unitDB.Indicators.PowerPrediction
end

local function EnsurePredictionBar(unitFrame, unit, db)
    if not unitFrame or not unitFrame.Power then return nil end

    local bar = unitFrame._uufPowerPredictionBar
    if not bar then
        local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)
        bar = CreateFrame("StatusBar", frameName .. "_PowerPrediction", unitFrame)
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(bar)
        bg:SetTexture(UUF.Media.Background or "Interface\\ChatFrame\\ChatFrameBackground")
        bar.Background = bg
        unitFrame._uufPowerPredictionBar = bar
    end

    bar:SetStatusBarTexture(UUF.Media.Foreground or "Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetFrameStrata(db.FrameStrata or "MEDIUM")
    bar:SetSize(db.Width or 100, db.Height or 3)
    UUF:SetPointIfChanged(bar, db.Layout[1], unitFrame, db.Layout[2], db.Layout[3], db.Layout[4])

    local color = db.Colour or { 1, 1, 0 }
    bar:SetStatusBarColor(color[1], color[2], color[3], db.Opacity or 0.7)
    if bar.Background then
        bar.Background:SetVertexColor(0.1, 0.1, 0.1, db.BackgroundOpacity or 0.5)
    end
    bar:SetReverseFill(unitFrame.Power:GetReverseFill() == true)

    return bar
end

local function RefreshPowerElementBinding(unitFrame, shouldEnable)
    if not unitFrame or not unitFrame.Power then return end
    if unitFrame.Power._uufPredictionBound == shouldEnable then return end

    unitFrame.Power._uufPredictionBound = shouldEnable
    if unitFrame:IsElementEnabled("Power") then
        unitFrame:DisableElement("Power")
        unitFrame:EnableElement("Power")
    end
end

function UUF:CreateUnitPowerPrediction(unitFrame, unit)
    if not unitFrame then return end
    UUF:UpdateUnitPowerPrediction(unitFrame, unit)
end

function UUF:UpdateUnitPowerPrediction(unitFrame, unit)
    if not unitFrame then return end

    local db = GetPowerPredictionDB(unit)
    local enabled = db and db.Enabled and unitFrame.Power ~= nil

    if not enabled then
        if unitFrame.Power then
            unitFrame.Power.CostPrediction = nil
        end
        if unitFrame._uufPowerPredictionBar then
            unitFrame._uufPowerPredictionBar:Hide()
        end
        RefreshPowerElementBinding(unitFrame, false)
        return
    end

    local bar = EnsurePredictionBar(unitFrame, unit, db)
    if not bar then
        RefreshPowerElementBinding(unitFrame, false)
        return
    end

    unitFrame.Power.CostPrediction = bar
    bar:Show()
    RefreshPowerElementBinding(unitFrame, true)

    if unitFrame.Power.ForceUpdate then
        unitFrame.Power:ForceUpdate()
    end
end

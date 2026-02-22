local _, UUF = ...
local oUF = UUF.oUF

function UUF:CreateUnitThreatIndicator(unitFrame, unit)
    if not unitFrame then return end
    
    local ThreatDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.ThreatIndicator
    if not ThreatDB or not ThreatDB.Enabled then return end
    
    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)
    local threatIndicator = unitFrame:CreateTexture(frameName .. "_ThreatIndicator", "OVERLAY")
    threatIndicator:SetTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Glow.tga")
    threatIndicator:SetSize(ThreatDB.Size, ThreatDB.Size)
    threatIndicator:SetVertexColor(ThreatDB.Colour[1], ThreatDB.Colour[2], ThreatDB.Colour[3], ThreatDB.Opacity)
    UUF:QueueOrRun(function()
        threatIndicator:ClearAllPoints()
        threatIndicator:SetPoint(ThreatDB.Layout[1], unitFrame, ThreatDB.Layout[2], ThreatDB.Layout[3], ThreatDB.Layout[4])
    end)
    threatIndicator:Hide()

    unitFrame.ThreatIndicator = threatIndicator

end

function UUF:UpdateUnitThreatIndicator(unitFrame, unit)
    if not unitFrame then return end
    
    local ThreatDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.ThreatIndicator
    if not ThreatDB or not ThreatDB.Enabled then
        if unitFrame.ThreatIndicator then
            UUF:QueueOrRun(function()
                unitFrame.ThreatIndicator:Hide()
            end)
        end
        return
    end
    
    if not unitFrame.ThreatIndicator then
        UUF:CreateUnitThreatIndicator(unitFrame, unit)
    end

    if unitFrame.ThreatIndicator and not unitFrame:IsElementEnabled("ThreatIndicator") then
        unitFrame:EnableElement("ThreatIndicator")
    end
    
    if unitFrame.ThreatIndicator then
        UUF:QueueOrRun(function()
            unitFrame.ThreatIndicator:SetSize(ThreatDB.Size, ThreatDB.Size)
            UUF:SetPointIfChanged(unitFrame.ThreatIndicator, ThreatDB.Layout[1], unitFrame, ThreatDB.Layout[2], ThreatDB.Layout[3], ThreatDB.Layout[4])
            unitFrame.ThreatIndicator:SetVertexColor(ThreatDB.Colour[1], ThreatDB.Colour[2], ThreatDB.Colour[3], ThreatDB.Opacity)
        end)
    end
end

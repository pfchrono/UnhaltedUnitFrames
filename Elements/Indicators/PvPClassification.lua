local _, UUF = ...

function UUF:CreateUnitPvPClassificationIndicator(unitFrame, unit)
    if not unitFrame then return end

    local PvPDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.PvPClassification
    if not PvPDB or not PvPDB.Enabled then return end

    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)
    local pvpClassificationIndicator = unitFrame:CreateTexture(frameName .. "_PvPClassification", "OVERLAY")
    pvpClassificationIndicator:SetSize(PvPDB.Size, PvPDB.Size)
    UUF:QueueOrRun(function()
        pvpClassificationIndicator:ClearAllPoints()
        pvpClassificationIndicator:SetPoint(PvPDB.Layout[1], unitFrame, PvPDB.Layout[2], PvPDB.Layout[3], PvPDB.Layout[4])
    end)
    pvpClassificationIndicator:Hide()

    unitFrame.PvPClassificationIndicator = pvpClassificationIndicator

end

function UUF:UpdateUnitPvPClassificationIndicator(unitFrame, unit)
    if not unitFrame then return end

    local PvPDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.PvPClassification
    if not PvPDB or not PvPDB.Enabled then
        if unitFrame.PvPClassificationIndicator then
            UUF:QueueOrRun(function()
                unitFrame.PvPClassificationIndicator:Hide()
            end)
        end
        return
    end

    if not unitFrame.PvPClassificationIndicator then
        UUF:CreateUnitPvPClassificationIndicator(unitFrame, unit)
    end

    if unitFrame.PvPClassificationIndicator and not unitFrame:IsElementEnabled("PvPClassificationIndicator") then
        unitFrame:EnableElement("PvPClassificationIndicator")
    end

    if unitFrame.PvPClassificationIndicator then
        UUF:QueueOrRun(function()
            unitFrame.PvPClassificationIndicator:SetSize(PvPDB.Size, PvPDB.Size)
            UUF:SetPointIfChanged(unitFrame.PvPClassificationIndicator, PvPDB.Layout[1], unitFrame, PvPDB.Layout[2], PvPDB.Layout[3], PvPDB.Layout[4])
        end)
    end
end

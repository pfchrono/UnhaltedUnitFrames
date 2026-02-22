local _, UUF = ...

function UUF:CreateUnitSummonIndicator(unitFrame, unit)
    if not unitFrame then return end

    local SummonDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.SummonIndicator
    if not SummonDB or not SummonDB.Enabled then return end

    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)
    local summonIndicator = unitFrame:CreateTexture(frameName .. "_SummonIndicator", "OVERLAY")
    summonIndicator:SetSize(SummonDB.Size, SummonDB.Size)
    UUF:QueueOrRun(function()
        summonIndicator:ClearAllPoints()
        summonIndicator:SetPoint(SummonDB.Layout[1], unitFrame, SummonDB.Layout[2], SummonDB.Layout[3], SummonDB.Layout[4])
    end)
    summonIndicator:Hide()

    unitFrame.SummonIndicator = summonIndicator

end

function UUF:UpdateUnitSummonIndicator(unitFrame, unit)
    if not unitFrame then return end

    local SummonDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.SummonIndicator
    if not SummonDB or not SummonDB.Enabled then
        if unitFrame.SummonIndicator then
            UUF:QueueOrRun(function()
                unitFrame.SummonIndicator:Hide()
            end)
        end
        return
    end

    if not unitFrame.SummonIndicator then
        UUF:CreateUnitSummonIndicator(unitFrame, unit)
    end

    if unitFrame.SummonIndicator and not unitFrame:IsElementEnabled("SummonIndicator") then
        unitFrame:EnableElement("SummonIndicator")
    end

    if unitFrame.SummonIndicator then
        UUF:QueueOrRun(function()
            unitFrame.SummonIndicator:SetSize(SummonDB.Size, SummonDB.Size)
            UUF:SetPointIfChanged(unitFrame.SummonIndicator, SummonDB.Layout[1], unitFrame, SummonDB.Layout[2], SummonDB.Layout[3], SummonDB.Layout[4])
        end)
    end
end

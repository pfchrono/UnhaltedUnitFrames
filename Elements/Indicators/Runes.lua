local _, UUF = ...
local oUF = UUF.oUF

function UUF:CreateUnitRunes(unitFrame, unit)
    if unit ~= "player" then return end
    
    local RunesDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.Runes
    if not RunesDB or not RunesDB.Enabled then return end
    local runeWidth = RunesDB.Width or RunesDB.Size or 24
    local runeHeight = RunesDB.Height or RunesDB.Size or 24
    
    local frameName = unitFrame:GetName() or UUF:FetchFrameName(unit)
    local runeContainer = CreateFrame("Frame", frameName .. "_RunesContainer", unitFrame)
    
    runeContainer:SetSize(runeWidth, runeHeight)
    UUF:QueueOrRun(function()
        runeContainer:SetPoint(RunesDB.Layout[1], unitFrame, RunesDB.Layout[2], RunesDB.Layout[3], RunesDB.Layout[4])
    end)
    runeContainer:SetFrameStrata(RunesDB.FrameStrata)
    
    unitFrame.Runes = runeContainer
    
end

function UUF:UpdateUnitRunes(unitFrame, unit)
    if unit ~= "player" then return end
    if not unitFrame then return end
    
    local RunesDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.Runes
    if not RunesDB or not RunesDB.Enabled then
        if unitFrame.Runes then
            UUF:QueueOrRun(function()
                unitFrame.Runes:Hide()
            end)
        end
        return
    end
    local runeWidth = RunesDB.Width or RunesDB.Size or 24
    local runeHeight = RunesDB.Height or RunesDB.Size or 24
    if not unitFrame.Runes then
        UUF:CreateUnitRunes(unitFrame, unit)
    end

    if unitFrame.Runes and not unitFrame:IsElementEnabled("Runes") then
        unitFrame:EnableElement("Runes")
    end
    
    if unitFrame.Runes then
        UUF:QueueOrRun(function()
            unitFrame.Runes:SetSize(runeWidth, runeHeight)
            UUF:SetPointIfChanged(unitFrame.Runes, RunesDB.Layout[1], unitFrame, RunesDB.Layout[2], RunesDB.Layout[3], RunesDB.Layout[4])
            unitFrame.Runes:SetFrameStrata(RunesDB.FrameStrata)
            unitFrame.Runes:Show()
        end)
    end
end

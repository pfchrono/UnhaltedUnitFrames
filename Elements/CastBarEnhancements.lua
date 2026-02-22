local _, UUF = ...

-- =========================================================================
-- ENHANCED CASTBAR MODULE
-- =========================================================================
-- Provides advanced castbar features:
-- 1. Timer direction indicators (shows if cast left-to-right or right-to-left)
-- 2. Channel tick markers (visual ticks for channel abilities)
-- 3. Empower stage visuals (stage indicators for empowered abilities)
-- 4. Latency/interrupt feedback (shows player latency and interrupt window)
-- 5. Performance fallback (simplified bar for large groups)

local UnitCastingInfo, UnitChannelInfo  = UnitCastingInfo, UnitChannelInfo
local GetNetStats = GetNetStats
local select, type, pairs = select, type, pairs
local GetTime = GetTime
local math_max = math.max
local IsSecretValue = issecretvalue or function() return false end

local CastBarEnhancements = {}
UUF.CastBarEnhancements = CastBarEnhancements

local function HideEnhancementElements(castBar)
    if castBar._TimerDirection then castBar._TimerDirection:Hide() end
    if castBar._ChannelTicks then
        for _, tick in pairs(castBar._ChannelTicks) do
            if tick then tick:Hide() end
        end
    end
    if castBar._EmpowerStages then
        for _, stage in pairs(castBar._EmpowerStages) do
            if stage then stage:Hide() end
        end
    end
    if castBar._LatencyIndicator then
        castBar._LatencyIndicator:SetText("")
        castBar._LatencyIndicator:Hide()
    end
end

-- TIMER ARROW TEXTURE (Simple drawn arrow pointing left or right)
local function CreateArrowTexture(frame, direction, colour)
    -- Create a simple colored square that we'll position as arrow
    local arrow = frame:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(10, 10)
    arrow:SetColorTexture(colour[1], colour[2], colour[3], colour[4])
    return arrow
end

-- =========================================================================
-- TIMER DIRECTION INDICATOR
-- =========================================================================
function CastBarEnhancements:CreateTimerDirection(castBar, castBarDB)
    if not castBarDB.TimerDirection.Enabled then
        if castBar._TimerDirection then
            castBar._TimerDirection:Hide()
        end
        return
    end
    
    local container = castBar:GetParent()
    if not container then return end
    
    -- Create direction indicator frame
    if not castBar._TimerDirection then
        castBar._TimerDirection = CreateFrame("Frame", nil, castBar)
    end
    
    local timerDir = castBar._TimerDirection
    local db = castBarDB.TimerDirection
    
    -- Size and position
    timerDir:SetSize(db.Size or 12, db.Size or 12)
    timerDir:ClearAllPoints()
    timerDir:SetPoint(db.Layout[1] or "BOTTOM", castBar, db.Layout[2] or "CENTER", db.Layout[3] or 0, db.Layout[4] or -8)
    
    if db.Type == "ARROW" then
        -- Create left/right arrow
        if not timerDir._arrow then
            timerDir._arrow = CreateArrowTexture(timerDir, "RIGHT", db.Colour)
            timerDir._arrow:SetPoint("CENTER", timerDir, "CENTER")
        end
        timerDir._arrow:SetColorTexture(db.Colour[1], db.Colour[2], db.Colour[3], db.Colour[4])
        timerDir._arrow:Show()
    elseif db.Type == "TEXT" then
        -- Create directional text indicator
        if not timerDir._text then
            timerDir._text = timerDir:CreateFontString(nil, "OVERLAY")
            timerDir._text:SetAllPoints()
            timerDir._text:SetFont(UUF.Media.Font or "Fonts\\FRIZQT__.TTF", math.max(8, (db.Size or 12) - 2), "OUTLINE")
        end
        timerDir._text:SetTextColor(db.Colour[1], db.Colour[2], db.Colour[3], db.Colour[4])
        timerDir._text:SetJustifyH("CENTER")
        timerDir._text:SetJustifyV("MIDDLE")
        timerDir._text:Show()
    elseif db.Type == "BAR" then
        -- Visual bar texture
        if not timerDir._bar then
            timerDir._bar = timerDir:CreateTexture(nil, "OVERLAY")
            timerDir._bar:SetSize(2, db.Size or 12)
            timerDir._bar:SetPoint("CENTER", timerDir, "CENTER")
        end
        timerDir._bar:SetColorTexture(db.Colour[1], db.Colour[2], db.Colour[3], db.Colour[4])
        timerDir._bar:Show()
    end
    
    timerDir:Show()
    castBar._TimerDirection = timerDir
end

-- Update timer direction visual based on cast progress
function CastBarEnhancements:UpdateTimerDirection(castBar, castBarDB, unit)
    if not castBarDB.TimerDirection.Enabled then return end
    if not castBar._TimerDirection then return end
    
    local timerDir = castBar._TimerDirection
    local db = castBarDB.TimerDirection
    
    -- Determine cast direction based on bar fill
    local name, _, _, startTime, endTime = UnitCastingInfo(unit)
    if not name then
        name, _, _, startTime, endTime = UnitChannelInfo(unit)
    end
    if not name or not startTime or not endTime then return end
    if IsSecretValue(name) or IsSecretValue(startTime) or IsSecretValue(endTime) then return end
    
    local nowMs = GetTime() * 1000  -- UnitCastingInfo/UnitChannelInfo timestamps are in ms.
    
    -- Ensure valid time range
    if endTime <= startTime then return end
    local progress = (nowMs - startTime) / (endTime - startTime)
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end
    local isReverseFill = castBar:GetReverseFill()
    
    -- Update TEXT indicator to show direction
    if db.Type == "TEXT" and timerDir._text then
        if isReverseFill then
            timerDir._text:SetText("◄")  -- Left arrow
        else
            timerDir._text:SetText("►")  -- Right arrow
        end
    end
    
    timerDir:Show()
end

-- =========================================================================
-- CHANNEL TICK MARKERS
-- =========================================================================
function CastBarEnhancements:CreateChannelTicks(castBar, castBarDB)
    if not castBarDB.ChannelTicks.Enabled then
        if castBar._ChannelTicks then
            for _, tick in pairs(castBar._ChannelTicks) do
                if tick and tick:IsObjectType("Texture") then
                    tick:Hide()
                end
            end
        end
        return
    end
    
    local container = castBar:GetParent()
    if not container then return end
    
    if not castBar._ChannelTicks then
        castBar._ChannelTicks = {}
    end
end

-- Update channel ticks based on spell info
function CastBarEnhancements:UpdateChannelTicks(castBar, castBarDB, unit)
    if not castBarDB.ChannelTicks.Enabled then return end

    -- Check if the cast is an empowered cast and skip updating channel ticks
    local _, _, _, _, _, _, _, _, isEmpowered = UnitChannelInfo(unit)
    if isEmpowered then
        if castBar._ChannelTicks then
            for _, tick in pairs(castBar._ChannelTicks) do
                if tick then tick:Hide() end
            end
        end
        return
    end

    local _, _, _, startTime, endTime, _, _, spellID = UnitChannelInfo(unit)
    if IsSecretValue(startTime) or IsSecretValue(endTime) or IsSecretValue(spellID) then
        if castBar._ChannelTicks then
            for _, tick in pairs(castBar._ChannelTicks) do
                if tick then tick:Hide() end
            end
        end
        return
    end
    if not spellID or not startTime then
        if castBar._ChannelTicks then
            for _, tick in pairs(castBar._ChannelTicks) do
                tick:Hide()
            end
        end
        return
    end

    local ticks = UUF:GetChannelTicks(spellID)
    if not ticks or #ticks == 0 then
        if castBar._ChannelTicks then
            for _, tick in pairs(castBar._ChannelTicks) do
                tick:Hide()
            end
        end
        return
    end

    local db = castBarDB.ChannelTicks
    local tickMarkers = castBar._ChannelTicks or {}
    local barWidth = castBar:GetWidth()
    local barHeight = castBar:GetHeight()
    local duration = (endTime - startTime) -- UnitChannelInfo returns ms
    if not duration or duration <= 0 then
        for _, tick in pairs(tickMarkers) do
            if tick then tick:Hide() end
        end
        return
    end

    -- Calculate evenly spaced tick positions
    local tickInterval = duration / (#ticks + 1)

    for i = 1, #ticks do
        if not tickMarkers[i] then
            tickMarkers[i] = castBar:CreateTexture(nil, "OVERLAY")
        end

        local tick = tickMarkers[i]
        local tickTime = tickInterval * i
        local progress = tickTime / duration
        local tickWidth = (db.Width or db.Thickness or 8) / 2
        local tickHeight = db.Height or (barHeight - 5)
        local tickTexture = db.Texture or "Interface\\CastingBar\\UI-CastingBar-Tick"

        tick:SetSize(tickWidth, tickHeight)
        if tickTexture and tickTexture ~= "" then
            tick:SetTexture(tickTexture)
            tick:SetVertexColor(db.Colour[1], db.Colour[2], db.Colour[3], db.Opacity or 0.8)
        else
            tick:SetColorTexture(db.Colour[1], db.Colour[2], db.Colour[3], db.Opacity or 0.8)
        end
        tick:ClearAllPoints()

        if castBar:GetReverseFill() then
            tick:SetPoint("CENTER", castBar, "TOPRIGHT", -barWidth * progress, -5) -- Lower the tick by 5px
        else
            tick:SetPoint("CENTER", castBar, "TOPLEFT", barWidth * progress, -5) -- Lower the tick by 5px
        end
        tick:Show()
    end

    -- Hide unused ticks
    for i = #ticks + 1, #tickMarkers do
        tickMarkers[i]:Hide()
    end

    castBar._ChannelTicks = tickMarkers
end

-- =========================================================================
-- EMPOWER STAGE VISUALS
-- =========================================================================
function CastBarEnhancements:CreateEmpowerStages(castBar, castBarDB)
    if not castBarDB.EmpowerStages.Enabled then
        if castBar._EmpowerStages then
            for _, stage in pairs(castBar._EmpowerStages) do
                if stage and stage:IsObjectType("Texture") then
                    stage:Hide()
                end
            end
        end
        return
    end

    local container = castBar:GetParent()
    if not container then return end

    if not castBar._EmpowerStages then
        castBar._EmpowerStages = {}
    end
end

-- Update empower stages based on spell info
-- Empower stages only update during active casts 
function CastBarEnhancements:UpdateEmpowerStages(castBar, castBarDB, unit)
    if not castBarDB.EmpowerStages.Enabled then
        if castBar._EmpowerStages then
            for _, stage in pairs(castBar._EmpowerStages) do
                if stage then stage:Hide() end
            end
        end
        return
    end

    if not GetUnitEmpowerStageDuration then
        if castBar._EmpowerStages then
            for _, stage in pairs(castBar._EmpowerStages) do
                if stage then stage:Hide() end
            end
        end
        return
    end

    local channelName, _, _, startTime, _, _, _, _, isEmpowered, numStages = UnitChannelInfo(unit)
    if IsSecretValue(channelName) or IsSecretValue(startTime) or IsSecretValue(isEmpowered) or IsSecretValue(numStages) then
        if castBar._EmpowerStages then
            for _, stage in pairs(castBar._EmpowerStages) do
                if stage then stage:Hide() end
            end
        end
        return
    end
    if not channelName or not isEmpowered or not numStages or numStages <= 0 then
        if castBar._EmpowerStages then
            for _, stage in pairs(castBar._EmpowerStages) do
                if stage then stage:Hide() end
            end
        end
        return
    end

    local db = castBarDB.EmpowerStages
    local stages = castBar._EmpowerStages or {}
    local barWidth = castBar:GetWidth()
    local barHeight = castBar:GetHeight()

    -- Ensure we have valid dimensions
    if barWidth <= 0 or barHeight <= 0 then return end

    -- Calculate elapsed time in milliseconds
    local currentTimeMs = GetTime() * 1000
    local elapsedMs = currentTimeMs - startTime
    if elapsedMs < 0 then elapsedMs = 0 end

    -- Build cumulative stage end times
    local stageEnds = {}
    local totalMs = 0
    for stageIdx = 0, numStages - 1 do
        local stageDurationMs = GetUnitEmpowerStageDuration(unit, stageIdx)
        if stageDurationMs and stageDurationMs > 0 then
            totalMs = totalMs + stageDurationMs
            stageEnds[stageIdx + 1] = totalMs
        end
    end

    -- Determine current stage (how many full stages completed)
    local currentStage = 0
    for i = 1, #stageEnds do
        if elapsedMs >= stageEnds[i] then
            currentStage = i
        else
            break
        end
    end

    local stageSize = db.Width or db.Thickness or 12
    local stageHeight = db.Height or (barHeight * 0.8)
    local stagePadding = db.Padding or 1
    local totalWidth = (stageSize * numStages) + (stagePadding * (numStages - 1))
    local startX = (barWidth - totalWidth) * 0.5

    -- Update stage visuals
    for i = 1, numStages do
        if not stages[i] then
            stages[i] = castBar:CreateTexture(nil, "OVERLAY")
        end

        local stage = stages[i]
        local xOffset = startX + ((i - 1) * (stageSize + stagePadding)) + (stageSize * 0.5)

        stage:SetSize(stageSize, stageHeight)
        stage:ClearAllPoints()
        stage:SetPoint("CENTER", castBar, "LEFT", xOffset, 0)

        -- Option A: Sequential lighting (all stages up to current are lit)
        if i <= currentStage then
            -- Stage is completed/active - bright
            stage:SetColorTexture(db.Colour[1], db.Colour[2], db.Colour[3], db.Colour[4] or 0.9)
        else
            -- Stage not yet reached - dim
            stage:SetColorTexture(db.Colour[1], db.Colour[2], db.Colour[3], 0.25)
        end

        stage:Show()
    end

    -- Hide unused stages
    for i = numStages + 1, #stages do
        stages[i]:Hide()
    end

    castBar._EmpowerStages = stages
end

-- =========================================================================
-- LATENCY & INTERRUPT FEEDBACK
-- =========================================================================
function CastBarEnhancements:CreateLatencyIndicator(castBar, castBarDB)
    if not castBarDB.LatencyIndicator.Enabled then
        if castBar._LatencyIndicator then
            castBar._LatencyIndicator:Hide()
        end
        return
    end
    
    if not castBar._LatencyIndicator then
        castBar._LatencyIndicator = castBar:CreateFontString(nil, "OVERLAY")
        local db = castBarDB.LatencyIndicator
        local fontSize = math.max(8, castBar:GetHeight() - 4)
        castBar._LatencyIndicator:SetFont(UUF.Media.Font or "Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        castBar._LatencyIndicator:SetPoint("CENTER", castBar, "BOTTOMRIGHT", -5, 2)
    end
    
    castBar._LatencyIndicator:Show()
end

function CastBarEnhancements:UpdateLatencyIndicator(castBar, castBarDB, unit)
    if not castBarDB.LatencyIndicator.Enabled then return end
    if not castBar._LatencyIndicator then return end
    
    local db = castBarDB.LatencyIndicator
    local _, _, _, startTime = UnitCastingInfo(unit)
    if IsSecretValue(startTime) then
        castBar._LatencyIndicator:SetText("")
        castBar._LatencyIndicator:Hide()
        return
    end
    if not startTime then
        castBar._LatencyIndicator:SetText("")
        castBar._LatencyIndicator:Hide()
        return
    end
    
    -- Calculate latency in milliseconds (home latency, not world)
    local latency = (select(1, GetNetStats()) or 0)
    
    if db.ShowValue then
        castBar._LatencyIndicator:SetText(latency .. "ms")
    else
        castBar._LatencyIndicator:SetText("")
    end
    
    -- Color by latency threshold
    local colour = latency > (db.HighLatencyThreshold or 150) and (db.HighLatencyColour or db.Colour) or db.Colour
    castBar._LatencyIndicator:SetTextColor(colour[1], colour[2], colour[3], colour[4] or 1.0)
end

-- =========================================================================
-- INTERRUPT FEEDBACK (via NotInterruptibleOverlay - already in CastBar.lua)
-- =========================================================================
-- This is already handled by the existing NotInterruptibleOverlay in CastBar.lua
-- We just ensure it's properly configured via the InterruptFeedback settings

-- =========================================================================
-- PERFORMANCE FALLBACK
-- =========================================================================
function CastBarEnhancements:ShouldSimplify(unit)
    -- Check group size and performance settings
    local unitNorm = UUF:GetNormalizedUnit(unit)
    local castBarDB = UUF.db.profile.Units[unitNorm].CastBar
    
    if not castBarDB.Performance.SimplifyForLargeGroups then
        return false
    end
    
    local threshold = castBarDB.Performance.GroupSizeThreshold or 15
    local groupSize = GetNumGroupMembers()
    if groupSize == 0 then groupSize = 1 end  -- Solo player
    
    return groupSize >= threshold
end

-- =========================================================================
-- PUBLIC API
-- =========================================================================
function UUF:EnhanceCastBar(castBar, castBarDB, unit)
    if not castBar or not castBarDB then return end
    
    -- Skip enhancements for simplified mode (large groups)
    if CastBarEnhancements:ShouldSimplify(unit) then
        return
    end
    
    -- Create all enhancement elements
    CastBarEnhancements:CreateTimerDirection(castBar, castBarDB)
    CastBarEnhancements:CreateChannelTicks(castBar, castBarDB)
    CastBarEnhancements:CreateEmpowerStages(castBar, castBarDB)
    CastBarEnhancements:CreateLatencyIndicator(castBar, castBarDB)
end

function UUF:UpdateCastBarEnhancements(castBar, castBarDB, unit)
    if not castBar or not castBarDB or not unit then return end
    
    -- Skip if castbar not visible or invalid
    if not castBar:IsVisible() then return end
    
    -- Skip enhancements for simplified mode
    if CastBarEnhancements:ShouldSimplify(unit) then
        return
    end
    
    -- Trust oUF cast state flags to avoid secret-value hazards from extra API probing.
    if not (castBar.casting or castBar.channeling or castBar.empowering) then
        HideEnhancementElements(castBar)
        return
    end
    
    -- Update all enhancement elements
    CastBarEnhancements:UpdateTimerDirection(castBar, castBarDB, unit)
    CastBarEnhancements:UpdateChannelTicks(castBar, castBarDB, unit)
    CastBarEnhancements:UpdateEmpowerStages(castBar, castBarDB, unit)
    CastBarEnhancements:UpdateLatencyIndicator(castBar, castBarDB, unit)
end


local _, UUF = ...

-- LibDataBroker support for minimap icon
local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

local function ToggleConfig()
    if UUF.ConfigWindow and UUF.ConfigWindow:IsVisible() then
        UUF.ConfigWindow:Hide()
    else
        UUF:CreateGUI()
    end
end

local function TogglePerformanceDashboard()
    if UUF.PerformanceDashboard then
        UUF.PerformanceDashboard:Toggle()
    end
end

local function ToggleDebugConsole()
    if UUF.DebugPanel then
        UUF.DebugPanel:Toggle()
    elseif SlashCmdList and SlashCmdList["UUFDEBUG"] then
        SlashCmdList["UUFDEBUG"]("")
    end
end

local function ToggleFrameLock()
    if UUF.ToggleFrameMover then
        UUF:ToggleFrameMover()
    end
end

local function ShowMinimapContextMenu(anchorFrame)
    local frameMoverLabel = (UUF.GetFrameMoverLabel and UUF:GetFrameMoverLabel()) or "Unlock Frames"
    local menu = {
        { text = UUF.PRETTY_ADDON_NAME or "UnhaltedUnitFrames", isTitle = true, notCheckable = true },
        { text = "Open Config", notCheckable = true, func = ToggleConfig },
        { text = "Toggle UUFPerf", notCheckable = true, func = TogglePerformanceDashboard },
        { text = "Toggle UUFDebug", notCheckable = true, func = ToggleDebugConsole },
        { text = frameMoverLabel, notCheckable = true, func = ToggleFrameLock },
    }

    UUF:ShowContextMenu(menu, anchorFrame, "LDB")
end

local dataObject = ldb:NewDataObject(
    "UnhaltedUnitFrames",
    {
        type = "data source",
        text = "UUF",
        icon = "Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Logo.tga",
        OnClick = function(frame, button)
            if button == "LeftButton" then
                ToggleConfig()
            elseif button == "RightButton" then
                ShowMinimapContextMenu(frame)
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip then return end
            tooltip:AddLine(UUF.PRETTY_ADDON_NAME)
            tooltip:AddLine("Version " .. UUF.ADDON_VERSION, 0.7, 0.7, 0.7)
            tooltip:AddLine(" ")
            
            -- Count active frames
            local frameCount = 0
            if UUF.PLAYER then frameCount = frameCount + 1 end
            if UUF.TARGET then frameCount = frameCount + 1 end
            if UUF.TARGETTARGET then frameCount = frameCount + 1 end
            if UUF.FOCUS then frameCount = frameCount + 1 end
            if UUF.FOCUSTARGET then frameCount = frameCount + 1 end
            if UUF.PET then frameCount = frameCount + 1 end
            
            for i = 1, UUF.MAX_PARTY_MEMBERS do
                if UUF["PARTY" .. i] then frameCount = frameCount + 1 end
            end
            
            for i = 1, UUF.MAX_BOSS_FRAMES do
                if UUF["BOSS" .. i] then frameCount = frameCount + 1 end
            end
            
            tooltip:AddLine("Frames: " .. frameCount, 1, 1, 1)
            tooltip:AddLine("Left Click: Toggle Config", 0.7, 0.7, 0.7)
            tooltip:AddLine("Right Click: Context Menu", 0.7, 0.7, 0.7)
        end,
    }
)

-- Register with broker plugins if available
local LDB_Icon = LibStub:GetLibrary("DBIcon-1.0", true)
if LDB_Icon then
    LDB_Icon:Register("UnhaltedUnitFrames", dataObject, UUF.db.profile.General.LDB or {})
end

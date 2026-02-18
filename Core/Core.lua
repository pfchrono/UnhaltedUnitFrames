local _, UUF = ...
local UnhaltedUnitFrames = LibStub("AceAddon-3.0"):NewAddon("UnhaltedUnitFrames", "AceConsole-3.0", "AceTimer-3.0", "AceBucket-3.0")

function UnhaltedUnitFrames:OnInitialize()
    UUF.db = LibStub("AceDB-3.0"):New("UUFDB", UUF:GetDefaultDB(), true)
    UUF.LDS:EnhanceDatabase(UUF.db, "UnhaltedUnitFrames")
    for k, v in pairs(UUF:GetDefaultDB()) do
        if UUF.db.profile[k] == nil then
            UUF.db.profile[k] = v
        end
    end
    UUF.TAG_UPDATE_INTERVAL = UUF.db.profile.General.TagUpdateInterval or 0.25
    UUF.SEPARATOR = UUF.db.profile.General.Separator or "||"
    UUF.TOT_SEPARATOR = UUF.db.profile.General.ToTSeparator or "»"
    if UUF.db.global.UseGlobalProfile then UUF.db:SetProfile(UUF.db.global.GlobalProfile or "Default") end
    UUF.db.RegisterCallback(UUF, "OnProfileChanged", function() UUF:UpdateAllUnitFrames() end)
    UUF.db.RegisterCallback(UUF, "OnProfileCopied", function() UUF:UpdateAllUnitFrames() end)
    UUF.db.RegisterCallback(UUF, "OnProfileReset", function() UUF:UpdateAllUnitFrames() end)

    -- Detect AbstractFramework (initialized in GUIBridge.lua)
    if UUF.HasAbstractFramework then
        print("|cFF8080FFUnhalted|rUnitFrames: AbstractFramework detected - Enhanced GUI features enabled")
    end

    local playerSpecalizationChangedEventFrame = CreateFrame("Frame")
    playerSpecalizationChangedEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    playerSpecalizationChangedEventFrame:SetScript("OnEvent", function(_, event, ...) if event == "PLAYER_SPECIALIZATION_CHANGED" then local unit = ... if unit == "player" then UUF:UpdateAllUnitFrames() end end end)

    -- Batched event bucket for guardian/pet updates (threshold 0.25s)
    UnhaltedUnitFrames:RegisterBucketEvent({"PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED", "COMPANION_UPDATE", "UNIT_PET", "UNIT_SPELLCAST_SUCCEEDED"}, 0.25, "OnPetUpdate")
    
    -- Batched event bucket for group updates (threshold 0.5s)
    UnhaltedUnitFrames:RegisterBucketEvent({"GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED"}, 0.5, "OnGroupUpdate")
    
    -- Safe-queue for deferred protected calls during combat lockdown
    UUF._safeQueue = UUF._safeQueue or {}
    local safeQueueFrame = CreateFrame("Frame")
    safeQueueFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    safeQueueFrame:SetScript("OnEvent", function()
        if not UUF._safeQueue or #UUF._safeQueue == 0 then return end
        for i = 1, #UUF._safeQueue do
            local ok, err = pcall(UUF._safeQueue[i])
            if not ok then
                print("UnhaltedUnitFrames: error flushing safe queue - ", err)
            end
        end
        UUF._safeQueue = {}
    end)
end

function UUF:SetupEditModeHooks()
    if UUF._editModeHooked then return end
    if not EditModeManagerFrame then return end
    UUF._editModeHooked = true
    EditModeManagerFrame:HookScript("OnShow", function() UUF:ApplyFrameMovers() end)
    EditModeManagerFrame:HookScript("OnHide", function() UUF:ApplyFrameMovers() end)
    EditModeManagerFrame:HookScript("OnShow", function() UUF:ApplyEditModeLayout() end)
    EditModeManagerFrame:HookScript("OnHide", function() UUF:ApplyEditModeLayout() end)
end

function UnhaltedUnitFrames:OnEnable()
    UUF:Init()
    UUF:SetupEditModeHooks()
    UUF:CreatePositionController()
    UUF:SpawnUnitFrame("player")
    UUF:SpawnUnitFrame("target")
    UUF:SpawnUnitFrame("targettarget")
    UUF:SpawnUnitFrame("focus")
    UUF:SpawnUnitFrame("focustarget")
    UUF:SpawnUnitFrame("pet")
    UUF:SpawnUnitFrame("party")
    UUF:SpawnUnitFrame("boss")
end

function UnhaltedUnitFrames:OnPetUpdate()
    if UUF.PET then
        UUF:UpdateUnitFrame(UUF.PET, "pet")
    end
end

function UnhaltedUnitFrames:OnGroupUpdate()
    if UUF.db.profile.Units.party.SortOrder == "ROLE" then
        UUF:CreateTestPartyFrames()
    end
end

function UUF:GetUnitConfig(unit)
    local normalizedUnit = UUF:GetNormalizedUnit(unit)
    local unitConfig = UUF.db.profile.Units[normalizedUnit]
    return unitConfig
end

function UUF:GetUnitIndicatorConfig(unit, indicatorType)
    local unitConfig = UUF:GetUnitConfig(unit)
    if not unitConfig or not unitConfig.Indicators then
        return nil
    end
    return unitConfig.Indicators[indicatorType]
end

function UUF:QueueOrRun(fn)
    if type(fn) ~= "function" then return end
    if InCombatLockdown() then
        UUF._safeQueue = UUF._safeQueue or {}
        UUF._safeQueue[#UUF._safeQueue + 1] = fn
    else
        fn()
    end
end

-- Timer management via AceTimer-3.0
function UUF:ScheduleTimer(timername, delay, func, ...)
    return UnhaltedUnitFrames:ScheduleTimer(func, delay, ...)
end

function UUF:CancelTimer(handle)
    if handle then
        UnhaltedUnitFrames:CancelTimer(handle, true)
    end
end

local minimapPingFrame = CreateFrame("Frame")
do
    local ok = pcall(minimapPingFrame.RegisterEvent, minimapPingFrame, "MINIMAP_PING")
    if ok then
        minimapPingFrame:SetScript("OnEvent", function(_, _, unit)
            UUF:ShowPingOnUnit(unit)
        end)
    end
end

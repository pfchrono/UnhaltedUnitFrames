local _, UUF = ...

local CreateFrame = CreateFrame
local type = type

local function EnsureFallbackMenu()
    if UUF._contextMenuFallbackFrame then
        return UUF._contextMenuFallbackFrame
    end

    local frame = CreateFrame("Frame", "UUF_MinimapContextMenuFallback", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)

    UUF._contextMenuFallbackButtons = {}
    UUF._contextMenuFallbackTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UUF._contextMenuFallbackTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
    UUF._contextMenuFallbackTitle:SetJustifyH("LEFT")
    UUF._contextMenuFallbackFrame = frame

    return frame
end

local function ShowFallbackMenu(menu)
    local frame = EnsureFallbackMenu()
    local buttons = UUF._contextMenuFallbackButtons
    local titleFS = UUF._contextMenuFallbackTitle

    for i = 1, #buttons do
        buttons[i]:Hide()
    end

    local row = 0
    local width = 190
    local function AcquireButton(index)
        if buttons[index] then
            return buttons[index]
        end
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetSize(width - 20, 20)
        buttons[index] = btn
        return btn
    end

    local titleText = "UnhaltedUnitFrames"
    if type(menu) == "table" and type(menu[1]) == "table" and menu[1].isTitle then
        titleText = menu[1].text or titleText
    end
    titleFS:SetText(titleText)

    for i = 1, #menu do
        local item = menu[i]
        if item and not item.isTitle then
            row = row + 1
            local btn = AcquireButton(row)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10 - (row * 22))
            btn:SetText(item.text or "")
            btn:SetScript("OnClick", function()
                frame:Hide()
                if type(item.func) == "function" then
                    item.func()
                end
            end)
            btn:Show()
        end
    end

    local height = 16 + (row * 22) + 12
    frame:SetSize(width, height)

    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (cursorX / scale) + 8, (cursorY / scale) - 8)
    frame:Show()
end

function UUF:ShowContextMenu(menu, anchorFrame, sourceTag)
    local menuUtil = MenuUtil or _G.MenuUtil
    if menuUtil and type(menuUtil.CreateContextMenu) == "function" then
        menuUtil.CreateContextMenu(anchorFrame or UIParent, function(_, rootDescription)
            for i = 1, #menu do
                local item = menu[i]
                if item then
                    if item.isTitle then
                        rootDescription:CreateTitle(item.text or "")
                    else
                        rootDescription:CreateButton(item.text or "", function()
                            if type(item.func) == "function" then
                                item.func()
                            end
                        end)
                    end
                end
            end
        end)
        return true
    end

    if UUF.DebugOutput then
        UUF._contextMenuFallbackNotice = UUF._contextMenuFallbackNotice or {}
        if not UUF._contextMenuFallbackNotice[sourceTag or "ContextMenu"] then
            UUF._contextMenuFallbackNotice[sourceTag or "ContextMenu"] = true
            UUF.DebugOutput:Output(
                sourceTag or "ContextMenu",
                "MenuUtil unavailable; using internal minimap context menu fallback.",
                UUF.DebugOutput.TIER_INFO
            )
        end
    end

    ShowFallbackMenu(menu)
    return true
end

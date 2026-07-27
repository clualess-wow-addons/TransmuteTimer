-- TransmuteTimer: Alchemy transmute cooldown display + one-click craft.
local ADDON_NAME = ...

-- Classic Era alchemy transmute spell IDs (all share the same cooldown).
local TRANSMUTE_SPELLS = {
    11479, -- Transmute: Iron to Gold
    11480, -- Transmute: Mithril to Truesilver
    17187, -- Transmute: Arcanite
    17559, -- Transmute: Air to Fire
    17560, -- Transmute: Fire to Earth
    17561, -- Transmute: Earth to Water
    17562, -- Transmute: Water to Air
    17563, -- Transmute: Undeath to Water
    17564, -- Transmute: Water to Undeath
    17565, -- Transmute: Life to Earth
    17566, -- Transmute: Earth to Life
    25146, -- Transmute: Elemental Fire (Heart of Fire -> Elemental Fire)
}

-- Map each transmute spell to the item ID of its result so we can show the
-- correct item icon (spell icons are often the *source* essence, not the result).
local TRANSMUTE_RESULT_ITEM = {
    [11479] = 3577,  -- Gold Bar
    [11480] = 6037,  -- Truesilver Bar
    [17187] = 12360, -- Arcanite Bar
    [17559] = 7078,  -- Essence of Fire
    [17560] = 7076,  -- Essence of Earth
    [17561] = 7080,  -- Essence of Water
    [17562] = 7082,  -- Essence of Air
    [17563] = 7080,  -- Essence of Water
    [17564] = 12808, -- Essence of Undeath
    [17565] = 7076,  -- Essence of Earth
    [17566] = 12803, -- Living Essence
    [25146] = 7068,  -- Elemental Fire
}

local function GetTransmuteIcon(spellID)
    local itemID = TRANSMUTE_RESULT_ITEM[spellID]
    if itemID then
        local tex = GetItemIcon(itemID)
        if tex then return tex end
    end
    return GetSpellTexture(spellID)
end

local DEFAULTS = {
    point = "CENTER",
    relPoint = "CENTER",
    x = 0,
    y = 200,
    shown = true,
    selectedSpellID = nil,
}

local frame
local text
local icon
local dropdown
local updateAccum = 0

local function FormatRemaining(secs)
    if secs <= 0 then return nil end
    local days = math.floor(secs / 86400)
    local hours = math.floor((secs % 86400) / 3600)
    local mins = math.floor((secs % 3600) / 60)
    local s = math.floor(secs % 60)
    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, mins)
    else
        return string.format("%dm %ds", mins, s)
    end
end

local function IsTransmuteKnown(id)
    return (IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id)) or false
end

local function FindKnownTransmute()
    for _, id in ipairs(TRANSMUTE_SPELLS) do
        if IsTransmuteKnown(id) then
            return id
        end
    end
    return nil
end

local function CurrentSpellID()
    return TransmuteTimerDB.selectedSpellID or FindKnownTransmute() or TRANSMUTE_SPELLS[1]
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    TransmuteTimerDB.point = point
    TransmuteTimerDB.relPoint = relPoint
    TransmuteTimerDB.x = x
    TransmuteTimerDB.y = y
end

local function ApplyPosition()
    frame:ClearAllPoints()
    frame:SetPoint(
        TransmuteTimerDB.point or DEFAULTS.point,
        UIParent,
        TransmuteTimerDB.relPoint or DEFAULTS.relPoint,
        TransmuteTimerDB.x or DEFAULTS.x,
        TransmuteTimerDB.y or DEFAULTS.y
    )
end

local UpdateDisplay -- forward declaration

local function RefreshVisibility()
    if not TransmuteTimerDB.shown then
        frame:Hide()
        return
    end
    frame:Show()
    UpdateDisplay()
end

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FONT_TIMER_SIZE = 14
local FONT_READY_SIZE = 11

local function ShowReady()
    text:SetFont(FONT_PATH, FONT_READY_SIZE, "OUTLINE")
    text:SetText("Click to Transmute")
    text:SetTextColor(0.2, 1, 0.2)
end

local function ShowTimer(label)
    text:SetFont(FONT_PATH, FONT_TIMER_SIZE, "OUTLINE")
    text:SetText(label)
    text:SetTextColor(1, 0.2, 0.2)
end

UpdateDisplay = function()
    local id = CurrentSpellID()
    if not id then return end
    if icon then
        local tex = GetTransmuteIcon(id)
        if tex then icon:SetTexture(tex) end
    end
    local start, duration = GetSpellCooldown(id)
    if not start or not duration or duration <= 1.5 then
        ShowReady()
        return
    end
    local remaining = (start + duration) - GetTime()
    local label = FormatRemaining(remaining)
    if not label then
        ShowReady()
    else
        ShowTimer(label)
    end
end

local function OnUpdate(_, elapsed)
    updateAccum = updateAccum + elapsed
    if updateAccum < 1 then return end
    updateAccum = 0
    UpdateDisplay()
end

local function SetSelectedTransmute(spellID)
    TransmuteTimerDB.selectedSpellID = spellID
    UpdateDisplay()
end

-- TSM-style direct trade-skill craft. Requires the Alchemy window to be open.
local function CraftTransmute(spellID)
    local targetName = GetSpellInfo(spellID)
    if not targetName then
        print("|cff33ff99TransmuteTimer|r: unknown spell.")
        return
    end
    if not GetNumTradeSkills or GetNumTradeSkills() == 0 then
        print("|cff33ff99TransmuteTimer|r: open your Alchemy window first, then click again to craft " .. targetName .. ".")
        return
    end
    for i = 1, GetNumTradeSkills() do
        local n = GetTradeSkillInfo(i)
        if n == targetName then
            DoTradeSkill(i, 1)
            return
        end
    end
    print("|cff33ff99TransmuteTimer|r: '" .. targetName .. "' not found in your Alchemy recipe list. Are you sure it's learned?")
end

local function InitDropdown(_, level)
    if not level then return end
    local current = TransmuteTimerDB.selectedSpellID
    for _, id in ipairs(TRANSMUTE_SPELLS) do
        local name = GetSpellInfo(id) or ("Spell " .. id)
        local known = IsTransmuteKnown(id)
        local info = UIDropDownMenu_CreateInfo()
        info.text = known and name or (name .. "  |cff808080(not learned)|r")
        info.icon = GetTransmuteIcon(id)
        info.checked = (current == id)
        info.func = function() SetSelectedTransmute(id) end
        UIDropDownMenu_AddButton(info, level)
    end
end

local function CreateFrame_TT()
    local templates = (BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame = CreateFrame("Button", "TransmuteTimerFrame", UIParent, templates)
    frame:SetSize(160, 32)
    frame:SetFrameStrata("LOW")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0, 0, 0, 0.7)
    else
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 3, -3)
        bg:SetPoint("BOTTOMRIGHT", -3, 3)
        bg:SetColorTexture(0, 0, 0, 0.7)
    end

    icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", frame, "LEFT", 8, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- crops Blizzard's icon border

    text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    text:SetPoint("RIGHT", frame, "RIGHT", -6, 0)
    text:SetJustifyH("CENTER")
    text:SetText("Transmute")
    text:SetTextColor(1, 0.82, 0)

    -- Drag with left-click; bare click (no movement) still casts.
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    frame:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ToggleDropDownMenu(1, nil, dropdown, self, 0, 0)
        elseif button == "LeftButton" then
            local id = CurrentSpellID()
            if id then CraftTransmute(id) end
        end
    end)

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local id = CurrentSpellID()
        local name = id and GetSpellInfo(id) or "(none)"
        GameTooltip:AddLine("TransmuteTimer")
        GameTooltip:AddLine("Selected: " .. name, 1, 1, 1)
        GameTooltip:AddLine("Left-click: craft", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: choose transmute", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag: move", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame:SetScript("OnUpdate", OnUpdate)

    dropdown = CreateFrame("Frame", "TransmuteTimerDropdown", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(dropdown, InitDropdown, "MENU")
end

local function HandleSlash(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "reset" then
        TransmuteTimerDB.point = DEFAULTS.point
        TransmuteTimerDB.relPoint = DEFAULTS.relPoint
        TransmuteTimerDB.x = DEFAULTS.x
        TransmuteTimerDB.y = DEFAULTS.y
        ApplyPosition()
        print("|cff33ff99TransmuteTimer|r: position reset.")
        return
    end
    TransmuteTimerDB.shown = not TransmuteTimerDB.shown
    RefreshVisibility()
    print("|cff33ff99TransmuteTimer|r: " .. (TransmuteTimerDB.shown and "shown" or "hidden") .. ". Use '/tmt reset' to reset position.")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("SPELLS_CHANGED")
loader:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        TransmuteTimerDB = TransmuteTimerDB or {}
        for k, v in pairs(DEFAULTS) do
            if TransmuteTimerDB[k] == nil then TransmuteTimerDB[k] = v end
        end
        CreateFrame_TT()
        ApplyPosition()
    elseif event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED" then
        if not TransmuteTimerDB.selectedSpellID then
            TransmuteTimerDB.selectedSpellID = FindKnownTransmute()
        end
        RefreshVisibility()
    end
end)

SLASH_TRANSMUTETIMER1 = "/tmt"
SLASH_TRANSMUTETIMER2 = "/transmutetimer"
SlashCmdList["TRANSMUTETIMER"] = HandleSlash

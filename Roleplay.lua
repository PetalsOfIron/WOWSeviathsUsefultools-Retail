-- SeviathsUsefulTools - the Roleplay (OC) page: the original character of each of your characters, saved for the whole account, shown on your tooltip,
-- with the character sheet window and the import from Total RP 3 / XRP / MyRolePlay (RPBridge.lua). Its own tab of the menu.

local _, SFP = ...
local K = SFP.MenuKit
if not K then return end

local CY = "|c" .. (SFP.CYAN_HEX or "ffffd100")   -- CYAN_HEX already starts with the alpha (ff)

local function charKey()
    local n = UnitName("player")
    return type(n) == "string" and n or "?"
end

-- the character's two names (first name and surname; the game gives the surname where other games have the realm)
local function fullName()
    local n, s = UnitName("player")
    if type(n) ~= "string" then return "?" end
    if type(s) == "string" and s ~= "" and not s:find("Realm") and not s:find("CAMWOW") then return n .. " " .. s end
    return n
end

---------------------------------------------------------------------------
-- Roleplay: the OC (original character) of each of your characters, saved for the whole account
---------------------------------------------------------------------------
-- the fields of the roleplay addons (Total RP, MyRolePlay, XRP): the long texts on the left, the short facts on the right; { key, label, lines, column }
local RP_FIELDS = {
    { "title", "Title or role", 1, 1 }, { "looks", "Looks (physical description)", 3, 1 }, { "traits", "Personality", 3, 1 },
    { "story", "Backstory (history)", 5, 1 }, { "notes", "Notes and plans (private)", 3, 1 },
    { "age", "Age", 1, 2 }, { "height", "Height and build", 1, 2 }, { "eyes", "Eyes and hair", 1, 2 }, { "residence", "Residence", 1, 2 },
    { "birthplace", "Birthplace", 1, 2 }, { "motto", "Motto", 1, 2 }, { "currently", "Currently (what my character is doing)", 2, 2 },
    { "ooc", "Out of character info", 2, 2 },
}

local function rpData() SFP.db.rp = SFP.db.rp or { chars = {} }; return SFP.db.rp end
local function rpOf(key) local d = rpData(); d.chars[key] = d.chars[key] or {}; return d.chars[key] end

local rpSelected
local buildRoleplay = K.simplePage("Roleplay",
    "Type who each of your characters is (your OC; the character's own name is its name): title, looks, personality and backstory. It is saved for the whole account, so every character shows the same data of all of them. " ..
    "Your title, looks, personality and backstory show on the tooltip of your character (notes and plans stay private).",
    function(pane, y)
        -- every character of the account: the key is "Name-Realm", the same as the Alt Overview uses
        local function rpKey()
            return (UnitName("player") or "?") .. "-" .. ((GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName() or "?"):gsub("[%s%-']", ""))
        end
        local function migrate()
            -- an older profile was saved under the first name only: it moves to the full key of this character
            local d = rpData().chars
            local first, full = charKey(), rpKey()
            if d[first] and not d[full] then d[full] = d[first]; d[first] = nil end
        end
        migrate()
        rpSelected = rpSelected or rpKey()
        if not rpData().chars[rpSelected] then rpSelected = rpKey() end
        rpOf(rpKey())
        local charButtons = {}
        local editors = {}
        local function load()
            local rec = rpOf(rpSelected)
            for _, e in ipairs(editors) do
                if not e.box:HasFocus() then e.box:SetText(rec[e.key] or ""); e.box:SetCursorPosition(0) end
            end
        end
        local function rebuildButtons()
            -- all the characters the addon knows on this account (the Alt Overview list and the profiles saved so far), yours first
            local keys, seen = {}, {}
            local function add(k) if type(k) == "string" and not seen[k] then seen[k] = true; keys[#keys + 1] = k end end
            for k in pairs(SFP.db.alts or {}) do add(k) end
            for k in pairs(rpData().chars) do add(k) end
            add(rpKey())
            table.sort(keys, function(a, b)
                if (a == rpKey()) ~= (b == rpKey()) then return a == rpKey() end
                return a < b
            end)
            local x, row = 12, 0
            for i, k in ipairs(keys) do
                local b = charButtons[i]
                if not b then
                    b = K.mkButton(pane, k, 112, function(self) rpSelected = self.key; SFP:Safe("rp", pane.refresh) end)
                    charButtons[i] = b
                end
                b.key = k
                -- both names of the character: saved when that character logged in (the surname is only known to the character itself)
                local nm = k:match("^(.-)%-") or k
                local rec = rpData().chars[k]
                b.text:SetText(k == rpKey() and fullName() or (type(rec) == "table" and rec.full) or nm)
                b.text:SetTextColor(k == rpSelected and 1 or 0.8, k == rpSelected and 0.82 or 0.8, k == rpSelected and 0 or 0.8)
                -- the button is as wide as the name
                local w = math.max(70, math.ceil(b.text:GetStringWidth()) + 28)
                b:SetWidth(w)
                if x + w > 640 then x, row = 12, row + 1 end
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", x, y - row * 26)
                x = x + w + 6
                b:Show()
            end
            for i = #keys + 1, #charButtons do charButtons[i]:Hide() end
        end
        local top1 = y - 112   -- room for three rows of characters and the status button
        local top2 = top1
        -- in character / out of character, like the roleplay addons have
        -- copy the profile of an installed roleplay addon (Total RP 3, XRP, MyRolePlay) into these fields
        local importBtn
        if SFP.RPBridge and SFP.RPBridge.Which() then
            importBtn = K.mkButton(pane, "Import from " .. SFP.RPBridge.Which(), 230, function()
                local mine = SFP.RPBridge.MyProfile()
                if not mine then SFP:Print("No profile found in " .. SFP.RPBridge.Which() .. " yet.") return end
                local r = rpOf(rpSelected)
                for k, v in pairs(mine) do if k ~= "name" and v and v ~= "" then r[k] = v end end
                SFP:Safe("rp", pane.refresh)
            end, "Copies your own profile of the roleplay addon into this page (only for the character you are playing).")
            importBtn:SetPoint("TOPLEFT", 252, y - 84)
        end
        local statusBtn
        statusBtn = K.mkButton(pane, "", 230, function()
            local r = rpOf(rpSelected)
            r.status = (r.status == "OOC") and "IC" or "OOC"
            statusBtn.text:SetText(r.status == "OOC" and "Out of character (OOC)" or "In character (IC)")
        end, "In character or out of character: shown on the tooltip of your character.")
        statusBtn:SetPoint("TOPLEFT", 12, y - 84)
        for _, f in ipairs(RP_FIELDS) do
            local col = f[4] or 1
            local top = col == 1 and top1 or top2
            local colX, colW = (col == 1) and 12 or 500, (col == 1) and 470 or 230
            K.mkText(pane, f[2], colX, top, colW, "GameFontNormalSmall")
            -- a visible box (dark with a gold edge) to type in
            local h = f[3] * 13 + 10
            local holder = CreateFrame("Frame", nil, pane, "BackdropTemplate")
            holder:SetPoint("TOPLEFT", colX, top - 14)
            holder:SetSize(colW, h)
            holder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 } })
            holder:SetBackdropColor(0.04, 0.04, 0.05, 0.9)
            holder:SetBackdropBorderColor(0.7, 0.58, 0.3, 1)
            local box = CreateFrame("EditBox", nil, holder)
            box:SetPoint("TOPLEFT", 7, -6)
            box:SetPoint("BOTTOMRIGHT", -7, 6)
            box:SetMultiLine(f[3] > 1)
            box:SetAutoFocus(false)
            box:SetFontObject("GameFontHighlightSmall")
            box:SetMaxLetters(f[3] > 1 and 1500 or 60)
            holder:EnableMouse(true)
            holder:SetScript("OnMouseDown", function() box:SetFocus() end)
            local function save(self) rpOf(rpSelected)[f[1]] = strtrim(self:GetText() or "") end
            box:SetScript("OnEditFocusLost", save)
            -- saved as you type (no Enter needed): the tooltip shows it at once
            box:SetScript("OnTextChanged", function(self, byUser) if byUser then save(self) end end)
            box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            if f[3] == 1 then box:SetScript("OnEnterPressed", function(self) save(self); self:ClearFocus() end) end
            editors[#editors + 1] = { key = f[1], box = box }
            if col == 1 then top1 = top1 - h - 17 else top2 = top2 - h - 17 end
        end
        local baseLoad = load
        return function() rebuildButtons(); baseLoad(); statusBtn.text:SetText(rpOf(rpSelected).status == "OOC" and "Out of character (OOC)" or "In character (IC)") end
    end)

-- your OC on the tooltip of your character
if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, function(tt)
        if tt ~= GameTooltip then return end
        local okU, _, unit = pcall(tt.GetUnit, tt)
        if not okU or not unit or (issecretvalue and issecretvalue(unit)) then return end
        local okS, isMe = pcall(UnitIsUnit, unit, "player")
        if not okS or (issecretvalue and issecretvalue(isMe)) or not isMe then return end
        local rpk = (UnitName("player") or "?") .. "-" .. ((GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName() or "?"):gsub("[%s%-']", ""))
        local rec = SFP.db and SFP.db.rp and SFP.db.rp.chars and (SFP.db.rp.chars[rpk] or SFP.db.rp.chars[charKey()])
        if rec then
            local title = (rec.title or "") ~= "" and rec.title or nil
            if title or (rec.looks or "") ~= "" or (rec.traits or "") ~= "" or (rec.story or "") ~= "" then tt:AddLine(CY .. fullName() .. "|r") end
            if title then tt:AddLine(title, 1, 1, 1) end
            if (rec.looks or "") ~= "" then tt:AddLine(rec.looks:sub(1, 160), 0.8, 0.8, 0.8, true) end
            if (rec.traits or "") ~= "" then tt:AddLine("|cffffd100Personality:|r " .. rec.traits:sub(1, 120), 0.8, 0.8, 0.8, true) end
            if (rec.story or "") ~= "" then tt:AddLine("|cffffd100Backstory:|r " .. rec.story:sub(1, 240), 0.8, 0.8, 0.8, true) end
            if (rec.age or "") ~= "" then tt:AddLine("|cffffd100Age:|r " .. rec.age:sub(1, 40), 0.8, 0.8, 0.8) end
            if (rec.height or "") ~= "" then tt:AddLine("|cffffd100Height:|r " .. rec.height:sub(1, 60), 0.8, 0.8, 0.8) end
            if (rec.residence or "") ~= "" then tt:AddLine("|cffffd100Residence:|r " .. rec.residence:sub(1, 80), 0.8, 0.8, 0.8) end
            if (rec.motto or "") ~= "" then tt:AddLine("\"" .. rec.motto:sub(1, 100) .. "\"", 0.9, 0.8, 0.5, true) end
            if (rec.currently or "") ~= "" then tt:AddLine("|cffffd100Currently:|r " .. rec.currently:sub(1, 120), 0.8, 0.8, 0.8, true) end
            local any = false
            for _, k in ipairs({ "title", "looks", "traits", "story", "age", "height", "residence", "motto", "currently" }) do if (rec[k] or "") ~= "" then any = true end end
            if any then tt:AddLine(rec.status == "OOC" and "|cffff6060Out of character|r" or "|cff40ff40In character|r") end
            tt:Show()
        end
    end)
end

---------------------------------------------------------------------------
-- every character notes its own full name (first name and surname) at login, so the Roleplay page can show both names of all of them
SFP:OnLogin(function()
    C_Timer.After(2, function()
        if not SFP.db then return end
        local key = (UnitName("player") or "?") .. "-" .. ((GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName() or "?"):gsub("[%s%-']", ""))
        local d = rpData().chars
        local first = charKey()
        if d[first] and not d[key] then d[key] = d[first]; d[first] = nil end
        d[key] = d[key] or {}
        d[key].full = fullName()
    end)
end)

-- the character sheet: a window with just what the player wrote for the character, read only, with the snake of the addon
local rpCard
function SFP:ShowRoleplayCard()
    if not rpCard then
        rpCard = SFP.MakeToolWindow("SeviathsUsefulToolsRoleplayCard", "", 470, 600)
        local snake = rpCard:CreateTexture(nil, "BACKGROUND", nil, 3)
        snake:SetTexture("Interface\\AddOns\\SeviathsUsefulTools\\Media\\snake_tile.tga")
        snake:SetSize(250, 250)
        snake:SetPoint("TOPRIGHT", rpCard, "TOPRIGHT", -12, -30)
        snake:SetVertexColor(0.95, 0.2, 0.18)
        snake:SetAlpha(0.45)
        local edit = K.mkButton(rpCard, "Edit", 80, function() SFP:ToggleMenu("roleplay") end)
        edit:SetPoint("TOPRIGHT", rpCard, "TOPRIGHT", -34, 1)
    end
    local n, s = UnitName("player")
    local full = (type(s) == "string" and s ~= "" and not s:find("Realm") and not s:find("CAMWOW")) and (n .. " " .. s) or tostring(n)
    local key = (UnitName("player") or "?") .. "-" .. ((GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName() or "?"):gsub("[%s%-']", ""))
    local rec = (SFP.db.rp and SFP.db.rp.chars and (SFP.db.rp.chars[key] or SFP.db.rp.chars[UnitName("player") or "?"])) or {}
    local lines = { CY .. full .. "|r" }
    -- every field of the Roleplay page is listed; an empty one stays an empty section
    local function add(label, v, long)
        v = (type(v) == "string") and v or ""
        if long then lines[#lines + 1] = "\n" .. CY .. label .. "|r\n" .. v else lines[#lines + 1] = CY .. label .. ":|r " .. v end
    end
    local race, class = UnitRace("player"), UnitClass("player")
    lines[#lines + 1] = "|cff808080" .. tostring(race or "") .. " " .. tostring(class or "") .. ", level " .. tostring(UnitLevel("player")) .. "|r"
    lines[#lines + 1] = rec.status == "OOC" and "|cffff6060Out of character|r" or "|cff40ff40In character|r"
    lines[#lines + 1] = ""
    add("Title or role", rec.title); add("Age", rec.age); add("Height and build", rec.height); add("Eyes and hair", rec.eyes)
    add("Residence", rec.residence); add("Birthplace", rec.birthplace); add("Motto", rec.motto)
    add("Looks (physical description)", rec.looks, true); add("Personality", rec.traits, true); add("Backstory (history)", rec.story, true)
    add("Currently (what my character is doing)", rec.currently, true); add("Out of character info", rec.ooc, true)
    rpCard.title:SetText("Character")
    rpCard:SetContent(table.concat(lines, "\n"))
    rpCard:Show()
end

-- clicking on your own portrait (or yourself in the world): the menu has an entry that opens the character sheet
if Menu and Menu.ModifyMenu then
    for _, tag in ipairs({ "MENU_UNIT_SELF" }) do
        pcall(Menu.ModifyMenu, tag, function(owner, root)
            root:CreateDivider()
            root:CreateButton("Roleplay information (OC)", function() SFP:ShowRoleplayCard() end)
        end)
    end
end


---------------------------------------------------------------------------
-- the menu entry: a new tab of its own, after the Alt Overview
---------------------------------------------------------------------------
do
    local at = #K.sections + 1
    for i, s in ipairs(K.sections) do if s.key == "alts" then at = i + 1 end end
    table.insert(K.sections, at, { key = "roleplay", label = "Roleplay" })
    K.builders.roleplay = buildRoleplay
end

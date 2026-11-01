-- SeviathsUsefulTools - material search on the world map
--
-- A button at the top of the world map opens a big window (not movable, it opens and closes with the map): on the left every expansion
-- from Classic to Midnight with its zones; the zone you pick shows ONLY the loot of that zone on the right - the materials, pets and
-- gear you can farm from monsters there - and for each item the monsters that drop it. Click a monster: a waypoint is set on it and
-- the map opens at that zone. The search bar looks through all zones at once.

local _, SFP = ...

local ROW_H = 20
local TREE_W = 190
local SECTIONS = {
    { key = "mat",   title = "Materials",   color = "|cff40ff40" },
    { key = "pet",   title = "Battle pets", color = "|cffffd100" },
    { key = "boe",   title = "BoE gear",    color = "|cff0070dd" },
    { key = "other", title = "Other",       color = "|cffa335ee" },
}
local PET_KINDS = { pet = true }
local OTHER_KINDS = { mount = true, toy = true, recipe = true }

local win, tree, list, search
local selected          -- map ID of the zone shown
local collapsed = {}    -- [expansion key] = true

local function sectionOf(id)
    local info = SFP.Items[id]
    local k = info and info.kind
    if k == "boe" then return "boe" end
    if PET_KINDS[k] then return "pet" end
    if OTHER_KINDS[k] then return "other" end
    return "mat"
end

---------------------------------------------------------------------------
-- rows (one pool per side)
---------------------------------------------------------------------------
local function rowOf(side, i)
    local r = side.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, side.content)
    r:SetHeight(ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(16, 16)
    r.right = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.right:SetPoint("RIGHT", -6, 0)
    r.right:SetJustifyH("RIGHT")
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.text:SetJustifyH("LEFT")
    r.hl = r:CreateTexture(nil, "HIGHLIGHT")
    r.hl:SetAllPoints()
    r.hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
    r.hl:SetBlendMode("ADD")
    r:SetScript("OnEnter", function(self)
        if self.item then
            local t = SFP.Tip()
            t:SetOwner(self, "ANCHOR_RIGHT")
            t:SetItemByID(self.item)
            t:Show()
        elseif self.hint then
            local t = SFP.Tip()
            t:SetOwner(self, "ANCHOR_RIGHT")
            t:AddLine(self.hint, 1, 1, 1, true)
            t:Show()
        end
    end)
    r:SetScript("OnLeave", function() SFP.Tip():Hide() end)
    r:SetScript("OnClick", function(self) if self.click then self.click() end end)
    side.rows[i] = r
    return r
end

local function place(side, r, n, indent)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", side.content, "TOPLEFT", 0, -(n - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", side.content, "TOPRIGHT", 0, -(n - 1) * ROW_H)
    r.icon:ClearAllPoints()
    r.icon:SetPoint("LEFT", 4 + indent, 0)
    r.text:ClearAllPoints()
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 4, 0)
    r.text:SetPoint("RIGHT", r.right, "LEFT", -4, 0)
    r.item, r.click, r.hint = nil, nil, nil
    r.right:SetText("")
    r.bg:SetColorTexture(0, 0, 0, 0)
    r.hl:Show()
    r:Show()
end

local function finish(side, n)
    for i = n + 1, #side.rows do side.rows[i]:Hide() end
    side.content:SetHeight(math.max(n * ROW_H, 1))
end

---------------------------------------------------------------------------
-- the loot of one zone: item -> monsters that drop it
---------------------------------------------------------------------------
-- Data/SpawnsWowhead.lua: [map] = { { npc, name, pts, drop = { [item] = percent } } } for every crafting reagent monsters drop
local function guideList(map)
    return SFP.SpawnsWowhead and SFP.SpawnsWowhead[map] or {}
end

local function monstersFor(map, id)
    local out = {}
    local zone = SFP.zoneByMap[map]
    for _, sp in ipairs(zone and zone.spawns or {}) do
        for _, it in ipairs(sp.items or {}) do
            if it == id then out[#out + 1] = sp break end
        end
    end
    local have = {}
    for _, sp in ipairs(out) do have[sp.name or ""] = true end
    local extra = {}
    for _, w in ipairs(guideList(map)) do
        if w.drop and w.drop[id] and not have[w.name] then extra[#extra + 1] = w end
    end
    table.sort(extra, function(a, c) return a.drop[id] > c.drop[id] end)
    for _, w in ipairs(extra) do out[#out + 1] = w end
    return out
end

local function zoneItems(map)
    local ids, seen = {}, {}
    local zone = SFP.zoneByMap[map]
    for _, id in ipairs(zone and zone.items or {}) do
        if not seen[id] and SFP.Items[id] then seen[id] = true; ids[#ids + 1] = id end
    end
    for _, w in ipairs(guideList(map)) do
        for id in pairs(w.drop or {}) do
            if not seen[id] then seen[id] = true; ids[#ids + 1] = id end
        end
    end
    return ids
end

-- the zones of an expansion: its farm zones and every map the Wowhead data puts reagent monsters on
local zonesCache = {}
local function zonesOf(exp)
    local c = zonesCache[exp.key]
    if c then return c end
    local seen, out = {}, {}
    for _, z in ipairs(exp.zones or {}) do
        if not seen[z.map] then seen[z.map] = true; out[#out + 1] = z.map end
    end
    for map in pairs(SFP.SpawnsWowhead or {}) do
        if not seen[map] then
            local e = SFP:ExpansionForMap(map)
            if e == exp then seen[map] = true; out[#out + 1] = map end
        end
    end
    table.sort(out, function(a, c2) return SFP:ZoneName(a) < SFP:ZoneName(c2) end)
    zonesCache[exp.key] = out
    return out
end

local function goToMonster(mapID, sp)
    local x, y = sp.hx, sp.hy
    if not x then local p = sp.points and sp.points[1]; if p then x, y = p[1], p[2] end end
    if not x and sp.pts then
        local px, py = sp.pts:match("([%d%.]+),([%d%.]+)")
        if px then x, y = tonumber(px) / 100, tonumber(py) / 100 end
    end
    if not x then return end
    -- the map shows that zone and the waypoint sits on the monster (set again, never removed by a second click)
    if WorldMapFrame:GetMapID() ~= mapID then WorldMapFrame:SetMapID(mapID) end
    if C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapID) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
    end
    SFP:Print(string.format("Waypoint set: %s, %s %.1f, %.1f", tostring(sp.name), SFP:ZoneName(mapID), x * 100, y * 100))
end

-- add the rows of one item (its line and one line per monster); returns the new row count
local function addItem(n, mapID, id, withZone)
    n = n + 1
    local r = rowOf(list, n)
    place(list, r, n, 8)
    r.icon:SetTexture(SFP:ItemIcon(id))
    r.text:SetText(SFP:ItemName(id) .. (withZone and ("  |cff808080" .. SFP:ZoneName(mapID) .. "|r") or ""))
    local price = SFP:GetPrice(id)
    r.right:SetText(price and SFP:FormatPrice(price) or "")
    r.item = id
    local mons = monstersFor(mapID, id)
    if #mons == 0 then
        n = n + 1
        local m = rowOf(list, n)
        place(list, m, n, 30)
        m.icon:SetTexture(nil)
        m.text:SetText("|cff808080monsters of the zone (no spot known yet)|r")
        m.hl:Hide()
    end
    for _, sp in ipairs(mons) do
        n = n + 1
        local m = rowOf(list, n)
        place(list, m, n, 30)
        m.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
        m.text:SetText("|cff00e5ff" .. tostring(sp.name) .. "|r")
        local drops = sp.counts and sp.counts[id] and sp.kills and sp.kills > 0
        local wpct = sp.drop and sp.drop[id]
        if drops or wpct then
            local pct = drops and (100 * sp.counts[id] / sp.kills) or wpct
            m.right:SetText(string.format("|cffffd100%s%%|r  |cff808080waypoint|r", pct >= 10 and string.format("%.0f", pct) or string.format("%.1f", pct)))
        else
            m.right:SetText("|cff808080click: waypoint|r")
        end
        m.hint = "Click: set a waypoint on " .. tostring(sp.name) .. " and open the map there"
        m.click = function() goToMonster(mapID, sp) end
    end
    return n
end

local function renderZone()
    local n = 0
    if not selected then
        finish(list, 0)
        win.title:SetText("Pick a zone on the left, or search for a material")
        return
    end
    win.title:SetText("|cff33e6ff" .. SFP:ZoneName(selected) .. "|r")
    local ids = zoneItems(selected)
    for _, sec in ipairs(SECTIONS) do
        local mine = {}
        for _, id in ipairs(ids) do if sectionOf(id) == sec.key then mine[#mine + 1] = id end end
        table.sort(mine, function(a, b) return SFP:ItemName(a):gsub("|c%x%x%x%x%x%x%x%x", "") < SFP:ItemName(b):gsub("|c%x%x%x%x%x%x%x%x", "") end)
        if #mine > 0 then
            n = n + 1
            local h = rowOf(list, n)
            place(list, h, n, 0)
            h.icon:SetTexture(nil)
            h.text:SetText(sec.color .. sec.title .. "|r  |cff808080" .. #mine .. "|r")
            h.bg:SetColorTexture(1, 1, 1, 0.06)
            h.hl:Hide()
            for _, id in ipairs(mine) do n = addItem(n, selected, id, false) end
        end
    end
    if n == 0 then
        n = 1
        local h = rowOf(list, 1)
        place(list, h, 1, 0)
        h.icon:SetTexture(nil)
        h.text:SetText("|cff808080Nothing farmable recorded for this zone yet|r")
        h.hl:Hide()
    end
    finish(list, n)
end

local function renderSearch(q)
    local n = 0
    win.title:SetText("Search: |cffffd100" .. q .. "|r")
    local ql = q:lower()
    for _, exp in ipairs(SFP.Expansions) do
        for _, map in ipairs(zonesOf(exp)) do
            for _, id in ipairs(zoneItems(map)) do
                local nm = (SFP:ItemName(id) or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
                if nm:find(ql, 1, true) and n < 600 then n = addItem(n, map, id, true) end
            end
        end
    end
    if n == 0 then
        n = 1
        local h = rowOf(list, 1)
        place(list, h, 1, 0)
        h.icon:SetTexture(nil)
        h.text:SetText("|cff808080Nothing found|r")
        h.hl:Hide()
    end
    finish(list, n)
end

local function renderList()
    if not win then return end
    local q = strtrim(search:GetText() or "")
    if #q >= 2 then renderSearch(q) else renderZone() end
end

---------------------------------------------------------------------------
-- the tree of expansions and zones
---------------------------------------------------------------------------
local function renderTree()
    local n = 0
    for _, exp in ipairs(SFP.Expansions) do
        if #zonesOf(exp) > 0 then
            n = n + 1
            local r = rowOf(tree, n)
            place(tree, r, n, 0)
            local open = not collapsed[exp.key]
            r.icon:SetTexture(nil)
            r.text:SetText("|cffffd100" .. (open and "[-] " or "[+] ") .. exp.name .. "|r")
            r.bg:SetColorTexture(1, 1, 1, 0.06)
            r.click = function() collapsed[exp.key] = open or nil; renderTree() end
            if open then
                for _, map in ipairs(zonesOf(exp)) do
                    n = n + 1
                    local z = rowOf(tree, n)
                    place(tree, z, n, 12)
                    z.icon:SetTexture(nil)
                    z.text:SetText((selected == map and "|cff33e6ff" or "|cffffffff") .. SFP:ZoneName(map) .. "|r")
                    if selected == map then z.bg:SetColorTexture(0, 0.9, 1, 0.15) end
                    z.click = function()
                        selected = map
                        search:SetText("")
                        renderTree()
                        renderList()
                    end
                end
            end
        end
    end
    finish(tree, n)
end

---------------------------------------------------------------------------
-- the window
---------------------------------------------------------------------------
local function scrollSide(parent, x, y, w)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", x, y)
    sf:SetPoint("BOTTOMLEFT", x, 8)
    sf:SetWidth(w)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(w, 1)
    sf:SetScrollChild(content)
    return { scroll = sf, content = content, rows = {} }
end

local function build()
    local sc = WorldMapFrame.ScrollContainer
    win = CreateFrame("Frame", "SeviathsUsefulToolsMaterialGuide", sc, "BackdropTemplate")
    win:SetFrameStrata("DIALOG")
    -- big: most of the map, with a margin; it is not movable
    -- docked at the bottom right of the map so the map itself stays in view; big, but not over the whole map
    win:SetPoint("BOTTOMRIGHT", sc, "BOTTOMRIGHT", -8, 8)
    local function fit()
        local w, h = sc:GetWidth(), sc:GetHeight()
        if w and w > 0 then win:SetSize(math.max(520, w * 0.46), math.max(360, h * 0.62)) end
    end
    fit()
    sc:HookScript("OnSizeChanged", fit)
    win:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    win:SetBackdropColor(0.02, 0.03, 0.05, 0.96)
    win:SetBackdropBorderColor(0, 0.9, 1, 0.9)
    win:EnableMouse(true)
    win:Hide()

    win.header = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    win.header:SetPoint("TOPLEFT", 12, -10)
    win.header:SetText("|c" .. SFP.CYAN_HEX .. "Material search|r")

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    search = CreateFrame("EditBox", nil, win, "SearchBoxTemplate")
    search:SetSize(260, 22)
    search:SetPoint("TOPRIGHT", close, "TOPLEFT", -8, -5)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end
        renderList()
    end)

    win.title = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    win.title:SetPoint("TOPLEFT", TREE_W + 34, -40)

    tree = scrollSide(win, 10, -64, TREE_W)
    list = scrollSide(win, TREE_W + 34, -64, 10)
    list.scroll:SetPoint("BOTTOMRIGHT", -30, 8)
    list.content:SetWidth(list.scroll:GetWidth())
    win:SetScript("OnSizeChanged", function()
        list.content:SetWidth(math.max(list.scroll:GetWidth(), 100))
    end)
    win:SetScript("OnShow", function()
        list.content:SetWidth(math.max(list.scroll:GetWidth(), 100))
        if not selected then
            local m = WorldMapFrame:GetMapID()
            if m and (SFP.zoneByMap[m] or SFP.SpawnsWowhead and SFP.SpawnsWowhead[m]) then selected = m end
        end
        renderTree()
        renderList()
    end)
end

SFP:OnLogin(function()
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer then return end
    local sc = WorldMapFrame.ScrollContainer
    local button = CreateFrame("Button", "SeviathsUsefulToolsMaterialButton", sc, "UIPanelButtonTemplate")
    button:SetSize(150, 28)
    button:SetPoint("TOPLEFT", sc, "TOPLEFT", 40, -6)
    button:SetFrameStrata("HIGH")
    button:SetText("Material search")
    button:SetScript("OnClick", function()
        if not win then build() end
        win:SetShown(not win:IsShown())
    end)
    button:SetScript("OnEnter", function(self)
        SFP.Tip():SetOwner(self, "ANCHOR_BOTTOM")
        SFP.Tip():AddLine("|c" .. SFP.CYAN_HEX .. "Material search|r")
        SFP.Tip():AddLine("Every zone from Classic to Midnight: what you can farm there and which monsters drop it. Click a monster for a waypoint.", 1, 1, 1, true)
        SFP.Tip():Show()
    end)
    button:SetScript("OnLeave", function() SFP.Tip():Hide() end)
    WorldMapFrame:HookScript("OnHide", function() if win then win:Hide() end end)
end)

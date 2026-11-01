-- SeviathsUsefulTools - material search on the world map
--
-- A button at the top of the world map opens a big window (not movable, it opens and closes with the map): on the left every expansion
-- from Classic to Midnight with its zones; the zone you pick shows ONLY the loot of that zone on the right - the materials, pets and
-- gear you can farm from monsters there - and for each item the monsters that drop it. Click a monster: a waypoint is set on it and
-- the map opens at that zone. The search bar looks through all zones at once.

local _, SFP = ...

local ROW_H = 30
local TREE_W = 190
local SECTIONS = {
    { key = "mat",   title = "Materials",   color = "|cff40ff40" },
    { key = "pet",   title = "Battle pets", color = "|cffffd100" },
    { key = "boe",   title = "BoE gear",    color = "|cff0070dd" },
    { key = "other", title = "Other",       color = "|cffa335ee" },
}
local PET_KINDS = { pet = true }
local OTHER_KINDS = { mount = true, toy = true, recipe = true }

-- an item name that is never "item 12345": the game's own name when it has loaded, else the name the addon has stored for it; the window
-- redraws when the game delivers more names
local function iname(id)
    local n = SFP:ItemName(id)
    if n:find("item ", 1, true) and n:find("|cff808080", 1, true) == 1 then
        local k = SFP.db and SFP.db.knownItems and SFP.db.knownItems[id]
        local nm = (type(k) == "table" and k.n) or (SFP.AuctionItems and SFP.AuctionItems[id] and SFP.AuctionItems[id][2])
            or (SFP.db and SFP.db.ahNames and SFP.db.ahNames[id])
        if type(nm) == "string" and nm ~= "" then return nm end
    end
    return n
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
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
    r.right = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.right:SetPoint("RIGHT", -6, 0)
    r.right:SetJustifyH("RIGHT")
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.text:SetJustifyH("LEFT")
    r.text:SetWordWrap(false)   -- one line per row: a long name is cut instead of running into the next row
    r.text:SetMaxLines(1)
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
    r:EnableMouse(true)
    r.right:SetText("")
    r.bg:SetColorTexture(0, 0, 0, 0)
    r.hl:Show()
    r:Show()
end

-- the list is cut into pages that fit the window (Previous / Next below it); the tree on the left just scrolls
local mode = "mat"          -- "mat", "mount", "hunter", "pet", "farm", "rare" or "top"
local matTab = "monsters"   -- the Material search has two tabs: "monsters" and "gather"
local gatherExp = "zone"   -- what the gathering tab shows: "zone" (the zone on the map), "all" or an expansion key
local expSel = "all"        -- expansion key / family shown in the mount, hunter and pet lists
local listPage, listSig = 1, nil
local function finish(side, n)
    for i = n + 1, #side.rows do side.rows[i]:Hide() end
    if side ~= list then
        side.content:SetHeight(math.max(n * ROW_H, 1))
        return
    end
    local per = math.max(6, math.floor((list.scroll:GetHeight() or 300) / ROW_H))
    local sig = tostring(mode) .. "|" .. tostring(matTab) .. "|" .. tostring(gatherExp) .. "|" .. tostring(selected) .. "|" .. tostring(expSel) .. "|" .. (search and search:GetText() or "")
    if sig ~= listSig then listSig, listPage = sig, 1 end
    local pages = math.max(1, math.ceil(n / per))
    listPage = math.min(math.max(listPage, 1), pages)
    local first = (listPage - 1) * per
    for i = 1, n do
        local r = side.rows[i]
        if i > first and i <= first + per then
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", side.content, "TOPLEFT", 0, -(i - first - 1) * ROW_H)
            r:SetPoint("TOPRIGHT", side.content, "TOPRIGHT", 0, -(i - first - 1) * ROW_H)
            r:Show()
        else
            r:Hide()
        end
    end
    side.content:SetHeight(math.max(math.min(n - first, per) * ROW_H, 1))
    if win and win.pager then
        win.pager.text:SetText("Page " .. listPage .. " / " .. pages .. "   |cff808080" .. n .. " rows|r")
        win.pager.prev:SetEnabled(listPage > 1)
        win.pager.next:SetEnabled(listPage < pages)
        win.pager:SetShown(pages > 1)
    end
end

-- an empty row: the space after each item
local function spacer(n)
    n = n + 1
    local r = rowOf(list, n)
    place(list, r, n, 0)
    r.icon:SetTexture(nil)
    r.text:SetText("")
    r.hl:Hide()
    return n
end

---------------------------------------------------------------------------
-- the loot of one zone: item -> monsters that drop it
---------------------------------------------------------------------------
-- the monsters that drop crafting reagents, by map: what the addon has collected (kills with loot, skinning; the shipped data too) and
-- Data/SpawnsWowhead.lua when it has anything. Built when the window opens and dropped when it closes.
local guideIndex
local function isReagent(id)
    local a = SFP.AuctionItems and SFP.AuctionItems[id]
    if a and a[1] == 7 then return true end
    local info = SFP.Items[id]
    if info and (info.kind == "cloth" or info.kind == "leather" or info.kind == "meat" or info.kind == "element" or info.kind == "enchant") then return true end
    local k = SFP.db and SFP.db.knownItems and SFP.db.knownItems[id]
    return type(k) == "table" and k.c == 7
end

local function buildGuideIndex()
    local out = {}
    local walk = SeviathsAllPairs or pairs
    for npcID, rec in walk(SFP.db and SFP.db.npcs or {}) do
        if type(rec) == "table" and type(rec.m) == "table" and (rec.d or rec.s) and rec.n then
            local kills = rec.k or 0
            local drop
            for _, src in ipairs({ rec.d or {}, rec.s or {} }) do
                for id, q in pairs(src) do
                    if type(q) == "number" and isReagent(id) then
                        drop = drop or {}
                        local pct = kills >= 3 and math.min(100, math.floor(q / kills * 1000) / 10) or 0
                        drop[id] = math.max(drop[id] or 0, pct)
                    end
                end
            end
            if drop then
                for map, pts in pairs(rec.m) do
                    local p = type(pts) == "table" and pts[1]
                    if p and p[1] and p[2] then
                        local l = out[map]
                        if not l then l = {}; out[map] = l end
                        l[#l + 1] = { npc = npcID, name = rec.n, pts = string.format("%.1f,%.1f", p[1] * 100, p[2] * 100), drop = drop }
                    end
                end
            end
        end
    end
    for map, list in pairs(SFP.SpawnsWowhead or {}) do
        local l = out[map]
        if not l then l = {}; out[map] = l end
        for _, w in ipairs(list) do l[#l + 1] = w end
    end
    return out
end

local function guideMaps()
    if not guideIndex then guideIndex = buildGuideIndex() end
    return guideIndex
end

local function guideList(map)
    return guideMaps()[map] or {}
end

local function monstersFor(map, id)
    local out = {}
    local zone = SFP.zoneByMap[map]
    for _, sp in ipairs(zone and zone.spawns or {}) do
        if not (sp.rare or sp.special or sp.hunter or sp.gather) then
            for _, it in ipairs(sp.items or {}) do
                if it == id then out[#out + 1] = sp break end
            end
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
    for map in pairs(guideMaps()) do
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
    local placed = false
    if C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapID) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        placed = true
    end
    if placed then
        SFP:Print(string.format("Waypoint set: %s, %s %.1f, %.1f", tostring(sp.name), SFP:ZoneName(mapID), x * 100, y * 100))
    else
        SFP:Print(string.format("%s: the game does not allow a waypoint on %s - the spot %.1f, %.1f is pinged on the map.", tostring(sp.name), SFP:ZoneName(mapID), x * 100, y * 100))
    end
    if SFP.PingSpot then SFP.PingSpot(mapID, x, y) end
end

-- add the rows of one item (its line and one line per monster); returns the new row count
local function addItem(n, mapID, id, withZone)
    n = n + 1
    local r = rowOf(list, n)
    place(list, r, n, 8)
    r.icon:SetTexture(SFP:ItemIcon(id))
    r.text:SetText(iname(id) .. (withZone and ("  |cff808080" .. SFP:ZoneName(mapID) .. "|r") or ""))
    local price = SFP:GetPrice(id)
    r.right:SetText(price and SFP:FormatPrice(price) or "")
    r.item = id
    local mons = monstersFor(mapID, id)
    if mons[1] then r.click = function() goToMonster(mapID, mons[1]) end end
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
        local iconId = id
        if sp.drop then
            local top = -1
            for did, pct in pairs(sp.drop) do if pct > top then top, iconId = pct, did end end
        elseif sp.items and sp.items[1] then iconId = sp.items[1] end
        m.icon:SetTexture(SFP:ItemIcon(iconId))
        m.text:SetText("|cff00e5ff" .. tostring(sp.name) .. "|r")
        local drops = sp.counts and sp.counts[id] and sp.kills and sp.kills > 0
        local wpct = sp.drop and sp.drop[id]
        if wpct == 0 then wpct = nil end
        if drops or wpct then
            local pct = drops and (100 * sp.counts[id] / sp.kills) or wpct
            m.right:SetText(string.format("|cffffd100%s%%|r  |cffff3030WAYPOINT|r", pct >= 10 and string.format("%.0f", pct) or string.format("%.1f", pct)))
        else
            m.right:SetText("|cffff3030WAYPOINT|r")
        end
        m.hint = "Click: set a waypoint on " .. tostring(sp.name) .. " and open the map there"
        m.click = function() goToMonster(mapID, sp) end
    end
    return spacer(n)
end

---------------------------------------------------------------------------
-- Gathering reagents: every ore and herb (and what your own gathering found), with where to gather it. The exact spots your own
-- gathering recorded come first (the area name and the coordinates), then the zones where the item spawns with the number of nodes.
---------------------------------------------------------------------------
local GATHER_SECTIONS = {
    { key = "ore",  title = "Mining",      color = "|cffffb366" },
    { key = "herb", title = "Herbalism",   color = "|cff4dff8c" },
    { key = "other", title = "Other gathering", color = "|cffa335ee" },
}

-- the exact spots recorded from your own gathering (and the shipped ones): [item] = { { map, x, y, area, name } }
local function learnedGatherSpots()
    local out = {}
    local objects = SFP.db and SFP.db.objects
    if not objects then return out end
    local walk = SeviathsAllPairs or pairs
    for _, rec in walk(objects) do
        if type(rec) == "table" and rec.d and rec.m and SFP:ObjectKind(rec) then
            for id in pairs(rec.d) do
                local info = SFP.Items[id]
                local k = SFP.ClassifyItem and SFP:ClassifyItem(id) or (info and info.kind)
                if k == "ore" or k == "herb" or k == "element" or k == "enchant" then
                    local l = out[id]
                    if not l then l = {}; out[id] = l end
                    for map, pts in pairs(rec.m) do
                        for _, p in ipairs(pts) do
                            l[#l + 1] = { map = map, x = p[1], y = p[2], area = p[3], name = rec.n }
                        end
                    end
                end
            end
        end
    end
    return out
end

local function gatherItems()
    local ids, seen = {}, {}
    for _, g in ipairs(SFP.Gather or {}) do
        if not seen[g.item] then seen[g.item] = true; ids[#ids + 1] = g.item end
    end
    for id in pairs(SFP.GatherZones or {}) do
        if not seen[id] then seen[id] = true; ids[#ids + 1] = id end
    end
    for id in pairs(learnedGatherSpots()) do
        if not seen[id] then seen[id] = true; ids[#ids + 1] = id end
    end
    return ids
end

local function gatherKind(id)
    local k = SFP.Items[id] and SFP.Items[id].kind
    if k == "ore" or k == "herb" then return k end
    return "other"
end

local function openSpot(map, x, y, label)
    if WorldMapFrame:GetMapID() ~= map then WorldMapFrame:SetMapID(map) end
    if x and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(map) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        SFP:Print(string.format("Waypoint set: %s, %s %.1f, %.1f", tostring(label), SFP:ZoneName(map), x * 100, y * 100))
        if SFP.PingSpot then SFP.PingSpot(map, x, y) end
    end
end

local learnedCache
local function addGatherItem(n, id, withKind)
    n = n + 1
    local r = rowOf(list, n)
    place(list, r, n, 8)
    r.icon:SetTexture(SFP:ItemIcon(id))
    r.text:SetText(iname(id))
    local price = SFP:GetPrice(id)
    r.right:SetText(price and SFP:FormatPrice(price) or "")
    r.item = id
    -- exact spots from gathering, nearest to one area name once each
    local seenSpot = {}
    local shown = 0
    for _, s in ipairs(learnedCache and learnedCache[id] or {}) do
        local key = s.map .. "|" .. tostring(s.area or (math.floor(s.x * 100) .. "," .. math.floor(s.y * 100)))
        if not seenSpot[key] and shown < 12 then
            seenSpot[key] = true
            shown = shown + 1
            n = n + 1
            local m = rowOf(list, n)
            place(list, m, n, 30)
            m.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
            m.text:SetText("|cff00e5ff" .. (s.area and (s.area .. " - ") or "") .. SFP:ZoneName(s.map) .. "|r  |cff808080" ..
                string.format("%.1f, %.1f", s.x * 100, s.y * 100) .. "|r")
            m.right:SetText("|cffff3030WAYPOINT|r")
            m.hint = "A spot where gathering was recorded. Click: set a waypoint there and open the map"
            m.click = function() openSpot(s.map, s.x, s.y, tostring(s.name or iname(id))) end
            if shown == 1 then r.click = m.click end   -- the name of the material goes to the first spot
        end
    end
    -- the zones it spawns in, most nodes first
    local zones = {}
    for map, count in pairs(SFP.GatherZones and SFP.GatherZones[id] or {}) do zones[#zones + 1] = { map = map, count = count } end
    table.sort(zones, function(a, c) return a.count > c.count end)
    for i, z in ipairs(zones) do
        if i > 8 then break end
        n = n + 1
        local m = rowOf(list, n)
        place(list, m, n, 30)
        m.icon:SetTexture(nil)
        m.text:SetText("|cffffffff" .. SFP:ZoneName(z.map) .. "|r")
        m.right:SetText("|cffffd100" .. z.count .. " nodes|r  |cffff3030WAYPOINT|r")
        m.hint = "Click: open the map of " .. SFP:ZoneName(z.map) .. " with a waypoint on the best spot there"
        m.click = function()
            local x, y
            for _, g in ipairs(SFP.Gather or {}) do
                if g.item == id and g.map == z.map and g.pts then
                    local px, py = g.pts:match("([%d%.]+),([%d%.]+)")
                    if px then x, y = tonumber(px) / 100, tonumber(py) / 100 end
                    break
                end
            end
            openSpot(z.map, x, y, iname(id))
        end
        if i == 1 and not r.click then r.click = m.click end
    end
    if shown == 0 and #zones == 0 then
        n = n + 1
        local m = rowOf(list, n)
        place(list, m, n, 30)
        m.icon:SetTexture(nil)
        m.text:SetText("|cff808080no gathering spot recorded yet|r")
        m.hl:Hide()
    end
    return spacer(n)
end


local function renderGather(q)
    local n = 0
    local ql = q and q:lower() or nil
    win.title:SetText("|cff33e6ffGathering|r" .. (ql and ("  |cffffd100" .. q .. "|r") or ""))
    learnedCache = learnedGatherSpots()
    local ids = gatherItems()
    local zoneMap = (gatherExp == "zone" and not ql) and WorldMapFrame:GetMapID() or nil
    if zoneMap then
        local here, keep = {}, {}
        for _, g in ipairs(SFP.Gather or {}) do if g.map == zoneMap then here[g.item] = true end end
        for id, zones in pairs(SFP.GatherZones or {}) do if zones[zoneMap] then here[id] = true end end
        for id, spots in pairs(learnedCache) do
            for _, s in ipairs(spots) do if s.map == zoneMap then here[id] = true break end end
        end
        for _, id in ipairs(ids) do if here[id] then keep[#keep + 1] = id end end
        ids = keep
        win.title:SetText("|cff33e6ff" .. SFP:ZoneName(zoneMap) .. "|r  |cffaaaaaaMining & Herbalism|r")
    end
    local expOf = {}
    for _, g in ipairs(SFP.Gather or {}) do expOf[g.item] = expOf[g.item] or g.exp end
    local groups = {}
    for _, exp in ipairs(SFP.Expansions) do groups[#groups + 1] = { key = exp.key, name = exp.name } end
    groups[#groups + 1] = { key = "other", name = "Other" }
    for _, grp in ipairs(groups) do
        if ql or zoneMap or gatherExp == "all" or gatherExp == grp.key then
            for _, sec in ipairs(GATHER_SECTIONS) do
                local mine = {}
                for _, id in ipairs(ids) do
                    local e = expOf[id] or "other"
                    if e == grp.key and gatherKind(id) == sec.key
                        and (not ql or plain(iname(id)):lower():find(ql, 1, true)) then mine[#mine + 1] = id end
                end
                table.sort(mine, function(a, c) return plain(iname(a)) < plain(iname(c)) end)
                if #mine > 0 then
                    n = n + 1
                    local h = rowOf(list, n)
                    place(list, h, n, 0)
                    h.icon:SetTexture(nil)
                    h.text:SetText(sec.color .. grp.name .. " - " .. sec.title .. "|r  |cff808080" .. #mine .. "|r")
                    h.bg:SetColorTexture(1, 1, 1, 0.06)
                    h.hl:Hide()
                    for _, id in ipairs(mine) do n = addGatherItem(n, id) end
                end
            end
        end
    end
    if n == 0 then
        n = 1
        local h = rowOf(list, 1)
        place(list, h, 1, 0)
        h.icon:SetTexture(nil)
        h.text:SetText("|cff808080" .. (zoneMap and "No ore or herb recorded for this zone yet" or "No gathering data for this expansion yet") .. "|r")
        h.hl:Hide()
    end
    finish(list, n)
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
        table.sort(mine, function(a, b) return iname(a):gsub("|c%x%x%x%x%x%x%x%x", "") < iname(b):gsub("|c%x%x%x%x%x%x%x%x", "") end)
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
                local nm = (iname(id) or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
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

---------------------------------------------------------------------------
-- Mount search and Hunter search: the same window with another list. The left side picks an expansion (or all), the right side lists
-- every mount / hunter pet with a waypoint on where to get it; the search box filters by name.
---------------------------------------------------------------------------
local entriesCache

local function firstPoint(pts)
    local x, y = tostring(pts or ""):match("([%d%.]+),([%d%.]+)")
    if x then return tonumber(x) / 100, tonumber(y) / 100 end
end

-- every mount: { item, exp, sources = { { text, map, x, y } } }
local function mountEntries()
    local byItem, order = {}, {}
    local function add(id, expKey, src)
        local e = byItem[id]
        if not e then e = { item = id, exp = expKey, sources = {} }; byItem[id] = e; order[#order + 1] = e end
        e.sources[#e.sources + 1] = src
    end
    for _, exp in ipairs(SFP.Expansions) do
        for _, inst in ipairs(exp.instances or {}) do
            for _, id in ipairs(inst.items or {}) do
                local info = SFP.Items[id]
                if info and info.kind == "mount" then
                    local en = SFP:FindEntrance(inst)
                    add(id, exp.key, { text = (inst.kind == "raid" and "Raid: " or "Dungeon: ") .. inst.name .. (info.drop and ("  |cffffd100" .. info.drop .. "|r") or ""),
                        map = en and en.map, x = en and en.x, y = en and en.y })
                end
            end
        end
    end
    for map, list in pairs(SFP.Rares or {}) do
        for _, sp in ipairs(list) do
            for _, id in ipairs(sp.items or {}) do
                local info = SFP.Items[id]
                if info and info.kind == "mount" then
                    local x, y = firstPoint(sp.pts)
                    add(id, list.exp, { text = "Rare: " .. tostring(sp.name), zone = SFP:ZoneName(map), map = map, x = x, y = y })
                end
            end
        end
    end
    return order
end

-- every hunter pet: { name, exp, map, x, y, kind }
local function hunterEntries()
    local out, seen = {}, {}
    for map, list in pairs(SFP.Rares or {}) do
        for _, sp in ipairs(list) do
            if sp.hunter then
                local x, y = firstPoint(sp.pts)
                seen[sp.name .. "@" .. map] = true
                out[#out + 1] = { name = sp.name, exp = list.exp, map = map, x = x, y = y,
                    kind = sp.hunter == "spirit" and "spirit beast" or "unique look" }
            end
        end
    end
    -- tameable beasts seen in the game (recorded and shipped by the Codex)
    local beasts = _G.SeviathsCodexDB and _G.SeviathsCodexDB.beasts
    for _, b in (SeviathsAllPairs or pairs)(beasts or {}) do
        if type(b) == "table" and b.n and b.m and not seen[b.n .. "@" .. b.m] then
            seen[b.n .. "@" .. b.m] = true
            local e = SFP:ExpansionForMap(b.m)
            out[#out + 1] = { name = b.n, exp = e and e.key, map = b.m, x = b.x, y = b.y, kind = (b.f or "beast") .. (b.r and " (rare)" or "") }
        end
    end
    return out
end

local function expOrder(key)
    for i, e in ipairs(SFP.Expansions) do if e.key == key then return i end end
    return 99
end

local renderPetTree   -- defined below (the battle pets list)
local function renderModeTree()
    if mode == "pet" then return renderPetTree() end
    local n = 1
    local function row(i, text, key, indent, header)
        local r = rowOf(tree, i)
        place(tree, r, i, indent)
        r.icon:SetTexture(nil)
        r.text:SetText((expSel == key and "|cff33e6ff" or "|cffffffff") .. text .. "|r")
        r.bg:SetColorTexture(0, 0.9, 1, expSel == key and 0.15 or 0.06)
        r.click = function()
            expSel = key
            search:SetText("")
            renderModeTree()
            win.refreshList()
        end
    end
    row(1, "All expansions", "all", 0)
    for _, exp in ipairs(SFP.Expansions) do
        n = n + 1
        row(n, exp.name, exp.key, 12)
    end
    finish(tree, n)
end

local headerRow, openWaypoint   -- defined below
-- Battle pets: every pet species of the game with its auction price (own realm's last scan); the families on the left filter the list
local function petPrices()
    local all = SFP.db and SFP.db.petPrices
    if type(all) ~= "table" then return {} end
    local own = all[SFP:RealmKey()]
    if own and next(own) then return own end
    for _, t in pairs(all) do if type(t) == "table" and next(t) then return t end end
    return {}
end

-- where a pet's source is: the vendor ("Vendor: Name") or the monster ("Drop: Name") that its source text names, found in the collected
-- vendors and monsters: { map, x, y }
local zoneIndex
local function mapOfZone(name)
    if not zoneIndex then
        zoneIndex = {}
        local list = C_Map.GetMapChildrenInfo and C_Map.GetMapChildrenInfo(946, nil, true) or {}
        for _, m in ipairs(list) do
            if m.name and not zoneIndex[m.name] then zoneIndex[m.name] = m.mapID end
        end
        for _, exp in ipairs(SFP.Expansions) do
            for _, z in ipairs(exp.zones or {}) do
                local nm = SFP:ZoneName(z.map)
                if nm and not zoneIndex[nm] then zoneIndex[nm] = z.map end
            end
        end
    end
    return zoneIndex[name]
end

local function petSpots(entries)
    local need = {}
    for _, e in ipairs(entries) do
        local src = plain(e.source or "")
        e.vendorName = src:match("Vendor:%s*([^\n]+)")
        e.dropName = src:match("Drop:%s*([^\n]+)")
        if e.vendorName then need[e.vendorName] = true end
        if e.dropName then need[e.dropName] = true end
    end
    for _, e in ipairs(entries) do
        local zn = plain(e.source or ""):match("Zone:%s*([^\n]+)")
        if zn then
            e.zoneName = zn
            e.zoneMap = mapOfZone(zn)
        end
    end
    if next(need) == nil then return end
    local found = {}
    local vendors = _G.SeviathsCodexDB and _G.SeviathsCodexDB.vendors
    for key, v in (SeviathsAllPairs or pairs)(vendors or {}) do
        if type(v) == "table" and v.m and v.x then
            local name = v.n or tostring(key):match("^(.-)@")
            if name and need[name] and not found[name] then found[name] = { map = v.m, x = v.x, y = v.y } end
        end
    end
    for _, rec in (SeviathsAllPairs or pairs)(SFP.db and SFP.db.npcs or {}) do
        if type(rec) == "table" and rec.n and need[rec.n] and not found[rec.n] and type(rec.m) == "table" then
            for map, pts in pairs(rec.m) do
                local p = type(pts) == "table" and pts[1]
                if p and p[1] and p[2] then found[rec.n] = { map = map, x = p[1], y = p[2] } break end
            end
        end
    end
    for _, e in ipairs(entries) do
        local s = (e.vendorName and found[e.vendorName]) or (e.dropName and found[e.dropName])
        if s then e.map, e.x, e.y = s.map, s.x, s.y end
    end
    -- a pet that is a drop: the monsters that drop its item (farm spots, and every monster the addon has seen drop it) give the waypoint
    local byName = {}
    for _, e in ipairs(entries) do byName[e.name] = e end
    local function petOf(itemId)
        if not (C_PetJournal and C_PetJournal.GetPetInfoByItemID) then return nil end
        local ok, nm = pcall(C_PetJournal.GetPetInfoByItemID, itemId)
        return ok and type(nm) == "string" and byName[nm] or nil
    end
    local checked = {}
    for mapID, zone in pairs(SFP.zoneByMap) do
        for _, sp in ipairs(zone.spawns or {}) do
            for _, id in ipairs(sp.items or {}) do
                local info = SFP.Items[id]
                if info and info.kind == "pet" then
                    local e = petOf(id)
                    if e and not e.map and sp.hx then e.map, e.x, e.y, e.who = mapID, sp.hx, sp.hy, "Drop " .. tostring(sp.name) end
                end
            end
        end
    end
    for _, rec in (SeviathsAllPairs or pairs)(SFP.db and SFP.db.npcs or {}) do
        if type(rec) == "table" and rec.n and type(rec.d) == "table" and type(rec.m) == "table" then
            for id in pairs(rec.d) do
                if checked[id] == nil then checked[id] = petOf(id) or false end
                local e = checked[id]
                if e and not e.map then
                    for map, pts in pairs(rec.m) do
                        local p = type(pts) == "table" and pts[1]
                        if p and p[1] and p[2] then e.map, e.x, e.y, e.who = map, p[1], p[2], "Drop " .. rec.n break end
                    end
                end
            end
        end
    end
    for _, e in ipairs(entries) do
        e.who = e.who or e.vendorName and ("Vendor " .. e.vendorName) or (e.dropName and ("Drop " .. e.dropName)) or nil
    end
end

local function petEntries()
    local out = {}
    if not (C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID) then return out end
    local prices = petPrices()
    for i = 1, 6000 do
        local ok, name, icon, petType, _, source, _, _, canBattle, tradeable = pcall(C_PetJournal.GetPetInfoBySpeciesID, i)
        if ok and type(name) == "string" and name ~= "" then
            out[#out + 1] = { species = i, name = name, icon = icon, petType = petType, source = source, tradeable = tradeable,
                canBattle = canBattle, price = prices[i] }
        end
    end
    petSpots(out)
    return out
end

renderPetTree = function()
    local n = 0
    local function row(text, key)
        n = n + 1
        local r = rowOf(tree, n)
        place(tree, r, n, key == "all" and 0 or 12)
        r.icon:SetTexture(nil)
        r.text:SetText((expSel == key and "|cff33e6ff" or "|cffffffff") .. text .. "|r")
        r.bg:SetColorTexture(0, 0.9, 1, expSel == key and 0.15 or 0.06)
        r.click = function()
            expSel = key
            search:SetText("")
            renderPetTree()
            win.refreshList()
        end
    end
    row("All battle pets", "all")
    row("With an auction price", "priced")
    for t = 1, 10 do row(_G["BATTLE_PET_NAME_" .. t] or ("Family " .. t), t) end
    finish(tree, n)
end

local function renderPets(q)
    local ql = q and q:lower() or ""
    win.title:SetText("|cffffd100Battle pets|r" .. (#ql > 0 and ("  |cffffd100" .. q .. "|r") or ""))
    entriesCache = entriesCache or petEntries()
    local entries = {}
    for _, e in ipairs(entriesCache) do
        local ok
        if #ql >= 2 then ok = e.name:lower():find(ql, 1, true)
        elseif expSel == "all" then ok = true
        elseif expSel == "priced" then ok = e.price
        else ok = e.petType == expSel end
        if ok then entries[#entries + 1] = e end
    end
    table.sort(entries, function(a, c)
        if (a.price and 1 or 0) ~= (c.price and 1 or 0) then return a.price ~= nil end
        if a.price and a.price ~= c.price then return a.price > c.price end
        return a.name < c.name
    end)
    local n = 0
    for _, e in ipairs(entries) do
        if n >= 800 then break end
        n = n + 1
        local r = rowOf(list, n)
        place(list, r, n, 8)
        r.icon:SetTexture(e.icon)
        local where = (e.who and (e.who .. (e.zoneName and " - " or "")) or "") .. (e.zoneName or "")
        r.text:SetText(e.name .. "  |cff808080" .. (_G["BATTLE_PET_NAME_" .. tostring(e.petType)] or "") .. "|r" ..
            (where ~= "" and ("  |cffffd100" .. where .. "|r") or ""))
        r.right:SetText((e.map and "|cffff3030WAYPOINT|r   " or "") ..
            (e.price and SFP:FormatPrice(e.price) or "|cff808080no price yet|r"))
        r.hint = plain(e.source or "") .. (e.tradeable and "" or "\n|cffff8080Not tradeable|r") .. (e.map and "\n|cff33e6ffClick: waypoint at the place and open the map there|r" or "")
        if e.map then r.click = function() openWaypoint(e.map, e.x, e.y, e.vendorName or e.dropName or e.name) end end
    end
    if n == 0 then n = headerRow(0, "|cff808080Nothing found|r") end
    finish(list, n)
end

openWaypoint = function(map, x, y, label)
    if not map then return end
    if WorldMapFrame:GetMapID() ~= map then WorldMapFrame:SetMapID(map) end
    if x and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(map) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        SFP:Print(string.format("Waypoint set: %s, %s %.1f, %.1f", tostring(label), SFP:ZoneName(map), x * 100, y * 100))
        if SFP.PingSpot then SFP.PingSpot(map, x, y) end
    end
end

headerRow = function(n, text)
    n = n + 1
    local h = rowOf(list, n)
    place(list, h, n, 0)
    h.icon:SetTexture(nil)
    h.text:SetText(text)
    h.bg:SetColorTexture(1, 1, 1, 0.06)
    h.hl:Hide()
    return n
end

local function renderMounts(q)
    local ql = q and q:lower() or ""
    local n = 0
    win.title:SetText("|cffa335eeMounts|r" .. (#ql > 0 and ("  |cffffd100" .. q .. "|r") or ""))
    entriesCache = entriesCache or mountEntries()
    local entries = {}
    for _, e in ipairs(entriesCache) do
        local nm = plain(iname(e.item)):lower()
        if (#ql >= 2 and nm:find(ql, 1, true)) or (#ql < 2 and (expSel == "all" or e.exp == expSel)) then entries[#entries + 1] = e end
    end
    table.sort(entries, function(a, c)
        if expOrder(a.exp) ~= expOrder(c.exp) then return expOrder(a.exp) < expOrder(c.exp) end
        return plain(iname(a.item)) < plain(iname(c.item))
    end)
    local lastExp
    for _, e in ipairs(entries) do
        if e.exp ~= lastExp then
            lastExp = e.exp
            local en
            for _, x in ipairs(SFP.Expansions) do if x.key == e.exp then en = x.name end end
            n = headerRow(n, "|cffffd100" .. (en or "Other") .. "|r")
        end
        n = n + 1
        local r = rowOf(list, n)
        place(list, r, n, 8)
        r.icon:SetTexture(SFP:ItemIcon(e.item))
        r.text:SetText(iname(e.item))
        local price = SFP:GetPrice(e.item)
        r.right:SetText(price and SFP:FormatPrice(price) or "")
        r.item = e.item
        -- the name bar is a waypoint too: it goes to the first source that has a spot
        for _, s in ipairs(e.sources) do
            if s.map then
                r.click = function() openWaypoint(s.map, s.x, s.y, plain(iname(e.item))) end
                break
            end
        end
        for _, s in ipairs(e.sources) do
            n = n + 1
            local m = rowOf(list, n)
            place(list, m, n, 30)
            m.icon:SetTexture(nil)
            m.text:SetText("|cff00e5ff" .. s.text .. "|r")
            m.right:SetText(s.zone and ("|cffff3030WAYPOINT|r   |cff808080" .. s.zone .. "|r") or (s.map and "|cffff3030WAYPOINT|r" or "|cff808080no map spot|r"))
            m.hint = s.map and "Click: set a waypoint and open the map there" or nil
            if s.map then m.click = function() openWaypoint(s.map, s.x, s.y, plain(iname(e.item))) end end
        end
        n = spacer(n)
    end
    if n == 0 then n = headerRow(0, "|cff808080Nothing found|r") end
    finish(list, n)
end

local function renderHunters(q)
    local ql = q and q:lower() or ""
    local n = 0
    win.title:SetText("|cffabd473Hunter pets|r" .. (#ql > 0 and ("  |cffffd100" .. q .. "|r") or ""))
    entriesCache = entriesCache or hunterEntries()
    local entries = {}
    for _, e in ipairs(entriesCache) do
        local nm = tostring(e.name):lower()
        if (#ql >= 2 and (nm:find(ql, 1, true) or tostring(e.kind):lower():find(ql, 1, true)))
            or (#ql < 2 and (expSel == "all" or e.exp == expSel)) then
            entries[#entries + 1] = e
        end
    end
    table.sort(entries, function(a, c)
        if expOrder(a.exp) ~= expOrder(c.exp) then return expOrder(a.exp) < expOrder(c.exp) end
        if a.map ~= c.map then return SFP:ZoneName(a.map) < SFP:ZoneName(c.map) end
        return tostring(a.name) < tostring(c.name)
    end)
    local lastExp
    for _, e in ipairs(entries) do
        if e.exp ~= lastExp then
            lastExp = e.exp
            local en
            for _, x in ipairs(SFP.Expansions) do if x.key == e.exp then en = x.name end end
            n = headerRow(n, "|cffffd100" .. (en or "Other") .. "|r")
        end
        n = n + 1
        local r = rowOf(list, n)
        place(list, r, n, 8)
        r.icon:SetTexture("Interface\\Icons\\ClassIcon_Hunter")
        r.text:SetText("|cff00e5ff" .. tostring(e.name) .. "|r")
        r.right:SetText("|cffff3030WAYPOINT|r   |cff808080" .. SFP:ZoneName(e.map) .. "|r   |cffabd473" .. e.kind .. "|r")
        r.hint = (e.x and "Click: set a waypoint and open the map there") or "Click: open the map"
        r.click = function() openWaypoint(e.map, e.x, e.y, tostring(e.name)) end
    end
    if n == 0 then n = headerRow(0, "|cff808080Nothing found|r") end
    finish(list, n)
end

local function setMode(m)
    mode = m
    if win and win.tabs then
        win.tabs.monsters:SetShown(m == "mat")
        win.tabs.gather:SetShown(m == "mat")
        if win.curBtn then win.curBtn:SetShown(m == "farm" or m == "rare") end
        if win.topBtn then win.topBtn:SetShown(m == "farm" or m == "rare" or m == "top") end
        if win.curBtn then win.curBtn:SetShown(m == "farm" or m == "rare" or m == "top") end
    end
    entriesCache = nil
    expSel = "all"
    if win then
        search:SetText("")
        win.header:SetText("|c" .. SFP.CYAN_HEX .. (m == "top" and "Best 15 spots" or m == "mount" and "Mount search" or m == "hunter" and "Hunter search" or m == "pet" and "Battle pets" or m == "farm" and "Farm spots" or m == "rare" and "Rares" or "Material search") .. "|r")
    end
end

-- the monsters the addon has collected (kills and loot, with positions), by map: normal monsters (elites too) for Farm spots, rares for
-- Rares; no bosses, no monster that drops a battle pet (those are under Battle pets). Built when first needed, dropped with the window.
local monsterIndex
local function collectedMonsters(map, group)
    if not monsterIndex then
        monsterIndex = {}
        for npcID, rec in (SeviathsAllPairs or pairs)(SFP.db and SFP.db.npcs or {}) do
            if type(rec) == "table" and rec.n and type(rec.m) == "table" and (rec.d or rec.s) and not rec.boss then
                local cls = rec.c
                local g = (cls == "rare" or cls == "rareelite") and "rare" or ((cls == nil or cls == "normal" or cls == "elite") and "farm" or nil)
                if g then
                    local pet = false
                    for _, src in ipairs({ rec.d or {}, rec.s or {} }) do
                        for id in pairs(src) do
                            local info = SFP.Items[id]
                            if info and info.kind == "pet" then pet = true break end
                        end
                    end
                    if not pet then
                        for m, pts in pairs(rec.m) do
                            local p = type(pts) == "table" and pts[1]
                            if p and p[1] and p[2] then
                                local byMap = monsterIndex[m]
                                if not byMap then byMap = { farm = {}, rare = {} }; monsterIndex[m] = byMap end
                                local list = byMap[g]
                                list[#list + 1] = { name = rec.n, npc = npcID, hx = p[1], hy = p[2], items = {}, kills = rec.k or 0 }
                            end
                        end
                    end
                end
            end
        end
        for _, byMap in pairs(monsterIndex) do
            for _, list in pairs(byMap) do table.sort(list, function(a, c) return a.name < c.name end) end
        end
    end
    local byMap = monsterIndex[map]
    return byMap and byMap[group] or {}
end

-- Farm spots and Rares: the same window - the zones on the left, and for the zone picked a block per monster: its name and a red
-- WAYPOINT, its place, everything it drops (grey items too) with how often and the price, and a space before the next one
-- the monsters of a zone for Farm spots / Rares: the addon's farm data and the collected monsters, each name once
local function farmSpotsFor(map, group)
    local spots = (map and SFP.FarmSpotsOf) and SFP.FarmSpotsOf(map, group) or {}
    if not map then return spots end
    local have, merged = {}, {}
    for _, s in ipairs(spots) do have[tostring(s.name):lower()] = true; merged[#merged + 1] = s end
    for _, s in ipairs(collectedMonsters(map, group)) do
        if not have[s.name:lower()] then have[s.name:lower()] = true; merged[#merged + 1] = s end
    end
    return merged
end

-- the blocks of some monsters of one map: name and red WAYPOINT, place, all the loot (grey items too), a space after each
local function renderBlocks(n, map, spots)
    for _, s in ipairs(spots) do
        local loot, kills = SFP.MonsterLoot(s)
        local x0, y0 = s.hx, s.hy
        local top = loot[1] and loot[1].id or (s.items and s.items[1])
        n = n + 1
        local r = rowOf(list, n)
        place(list, r, n, 8)
        r.icon:SetTexture(top and SFP:ItemIcon(top) or "Interface\\Icons\\INV_Misc_QuestionMark")
        r.text:SetText((s.rank and ("|cffffd100" .. s.rank .. ".|r  ") or "") .. "|cff00e5ff" .. tostring(s.name) .. "|r")
        r.right:SetText("|cffff3030WAYPOINT|r")
        r.hint = "Click: set a waypoint on " .. tostring(s.name) .. " and open the map there"
        r.click = function() goToMonster(map, s) end
        n = n + 1
        local p = rowOf(list, n)
        place(list, p, n, 30)
        p.icon:SetTexture(nil)
        p.text:SetText("|cffffd100" .. SFP:ZoneName(map) .. "|r  |cffaaaaaa" .. SFP.AreaAt(map, x0, y0) .. "|r  |cff808080" ..
            (x0 and string.format("%.1f, %.1f", x0 * 100, y0 * 100) or "") .. "|r" .. (s.valueText or ""))
        p.hint = "Click: set a waypoint on " .. tostring(s.name) .. " and open the map there"
        p.click = function() goToMonster(map, s) end
        for _, d in ipairs(loot) do
            n = n + 1
            local l = rowOf(list, n)
            place(list, l, n, 30)
            l.icon:SetTexture(SFP:ItemIcon(d.id))
            l.text:SetText(iname(d.id))
            local price = SFP:GetPrice(d.id)
            local pct = (kills >= 3 and d.q > 0) and ("|cffffd100" .. math.min(100, math.floor(d.q / kills * 1000) / 10) .. "%|r  ") or ""
            l.right:SetText(pct .. (price and SFP:FormatPrice(price) or ""))
            -- the materials are plain text here: no highlight, no tooltip, nothing under the mouse
            l:EnableMouse(false)
            l.hl:Hide()
        end
        if #loot == 0 then
            n = n + 1
            local l = rowOf(list, n)
            place(list, l, n, 30)
            l.icon:SetTexture(nil)
            l.text:SetText("|cff808080no loot recorded yet|r")
            l.hl:Hide()
        end
        n = spacer(n)
    end
    return n
end

-- does a zone have monsters for the list (for the zone tree on the left)
local function zoneHasMonsters(map, group)
    return #farmSpotsFor(map, group == "rare" and "rare" or "farm") > 0
end

-- the 15 best farm spots of the whole database: the value of what a monster drops per kill (the chance of each item times its auction
-- price), over the monsters with at least 3 kills recorded
local function renderTop()
    local n = 0
    win.title:SetText("|c" .. SFP.CYAN_HEX .. "Best 15 farm spots|r  |cffaaaaaathis week|r")
    collectedMonsters(0, "farm")
    local function valueOf(s)
        local loot, kills = SFP.MonsterLoot(s)
        if kills < 3 then return 0 end
        local val = 0
        for _, d in ipairs(loot) do
            local price = SFP:GetPrice(d.id)
            if price and d.q > 0 then val = val + price * d.q / kills end
        end
        return val
    end
    -- the ranking is made once a week, at the weekly reset (with that day's prices), and kept for the week; a spot learned later is in
    -- the database and the search at once, and can be in the next week's ranking
    local resetIn = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
    local weekKey = resetIn and math.floor((time() + resetIn) / 3600) or nil
    local saved = SFP.db.topSpots
    if not (saved and weekKey and saved.week == weekKey and saved.list and #saved.list > 0) then
        local maps, seenMap = {}, {}
        for map in pairs(SFP.zoneByMap) do if not seenMap[map] then seenMap[map] = true; maps[#maps + 1] = map end end
        for map in pairs(monsterIndex or {}) do if not seenMap[map] then seenMap[map] = true; maps[#maps + 1] = map end end
        local ranked = {}
        for _, map in ipairs(maps) do
            for _, s in ipairs(farmSpotsFor(map, "farm")) do
                local val = valueOf(s)
                if val > 0 then ranked[#ranked + 1] = { map = map, name = tostring(s.name), npc = s.npc, val = val } end
            end
        end
        table.sort(ranked, function(a, c) return a.val > c.val end)
        local keep = {}
        for k = 1, math.min(15, #ranked) do keep[k] = { map = ranked[k].map, name = ranked[k].name, npc = ranked[k].npc } end
        saved = { week = weekKey, list = keep }
        if weekKey and #keep > 0 then SFP.db.topSpots = saved end
    end
    for k, e in ipairs(saved.list) do
        for _, s in ipairs(farmSpotsFor(e.map, "farm")) do
            if (e.npc and s.npc == e.npc) or (not e.npc and tostring(s.name) == e.name) then
                local val = valueOf(s)
                s.rank = k
                s.valueText = "   |cff40ff40" .. (val > 0 and (SFP:FormatPrice(math.floor(val)) .. " per kill") or "no price now") .. "|r"
                n = renderBlocks(n, e.map, { s })
                break
            end
        end
    end
    if n == 0 then n = headerRow(0, "|cff808080No monster has enough kills and prices recorded yet|r") end
    finish(list, n)
end

local function renderFarmList(group)
    local n = 0
    local label = group == "rare" and "|cffff8000Rares|r" or ("|c" .. SFP.CYAN_HEX .. "Farm spots|r")
    local q = strtrim(search and search:GetText() or "")
    if #q >= 2 then
        -- a search: the monsters of that name in every zone
        win.title:SetText(label .. "  |cffffd100" .. q .. "|r")
        local ql, found = q:lower(), 0
        collectedMonsters(0, group)   -- builds the index of collected monsters
        local maps, seenMap = {}, {}
        for map in pairs(SFP.zoneByMap) do if not seenMap[map] then seenMap[map] = true; maps[#maps + 1] = map end end
        for map in pairs(monsterIndex or {}) do if not seenMap[map] then seenMap[map] = true; maps[#maps + 1] = map end end
        table.sort(maps, function(a, c) return SFP:ZoneName(a) < SFP:ZoneName(c) end)
        for _, map in ipairs(maps) do
            local mine = {}
            for _, s in ipairs(farmSpotsFor(map, group)) do
                if tostring(s.name):lower():find(ql, 1, true) then mine[#mine + 1] = s end
            end
            if #mine > 0 and found < 80 then
                found = found + #mine
                n = renderBlocks(n, map, mine)
            end
        end
    else
        local map = selected
        if type(map) ~= "number" then map = WorldMapFrame:GetMapID() end
        win.title:SetText(label .. "  |cffaaaaaa" .. (map and SFP:ZoneName(map) or "") .. "|r")
        if map then n = renderBlocks(n, map, farmSpotsFor(map, group)) end
    end
    if n == 0 then n = headerRow(0, "|cff808080Nothing recorded|r") end
    finish(list, n)
end

local function renderList()
    if not win then return end
    local q = strtrim(search:GetText() or "")
    if mode == "mount" then return renderMounts(q) end
    if mode == "hunter" then return renderHunters(q) end
    if mode == "pet" then return renderPets(q) end
    if mode == "farm" then return renderFarmList("farm") end
    if mode == "top" then return renderTop() end
    if mode == "rare" then return renderFarmList("rare") end
    if matTab == "gather" then return renderGather(#q >= 2 and q or nil) end
    if #q >= 2 then renderSearch(q) else renderZone() end
end

---------------------------------------------------------------------------
-- the tree of expansions and zones
---------------------------------------------------------------------------
local renderTree
local function renderTreeMat()
    local n = 0
    local monsterMode = (mode == "farm" or mode == "rare" or mode == "top")
    local zq = monsterMode and strtrim(search and search:GetText() or "") or ""
    if monsterMode then
        local cur = WorldMapFrame:GetMapID()
        n = 1
        local r = rowOf(tree, 1)
        place(tree, r, 1, 0)
        r.icon:SetTexture(nil)
        r.text:SetText("|cff33e6ffCurrent zone|r" .. (cur and ("  |cffaaaaaa" .. SFP:ZoneName(cur) .. "|r") or ""))
        r.bg:SetColorTexture(0, 0.9, 1, 0.18)
        r.click = function()
            selected = WorldMapFrame:GetMapID()
            search:SetText("")
            renderTree()
            renderList()
        end
    end
    if mode == "mat" and matTab == "gather" then
        local function sub(text, key, indent)
            n = n + 1
            local r = rowOf(tree, n)
            place(tree, r, n, indent)
            r.icon:SetTexture(nil)
            r.text:SetText((gatherExp == key and "|cff33e6ff" or "|cffffffff") .. text .. "|r")
            r.bg:SetColorTexture(0, 0.9, 1, gatherExp == key and 0.15 or 0.06)
            r.click = function() gatherExp = key; search:SetText(""); renderTree(); renderList() end
        end
        local cur = WorldMapFrame:GetMapID()
        sub("Current zone" .. (cur and (": " .. SFP:ZoneName(cur)) or ""), "zone", 0)
        sub("All expansions", "all", 0)
        for _, exp in ipairs(SFP.Expansions) do sub(exp.name, exp.key, 12) end
        finish(tree, n)
        return
    end
    for _, exp in ipairs(SFP.Expansions) do
        local zoneList = zonesOf(exp)
        if monsterMode then
            local keep = {}
            for _, map in ipairs(zoneList) do
                if (#zq < 2 or SFP:ZoneName(map):lower():find(zq:lower(), 1, true)) and zoneHasMonsters(map, mode) then keep[#keep + 1] = map end
            end
            zoneList = keep
        end
        if #zoneList > 0 then
            n = n + 1
            local r = rowOf(tree, n)
            place(tree, r, n, 0)
            local open = not collapsed[exp.key] or #zq >= 2
            r.icon:SetTexture(nil)
            r.text:SetText("|cffffd100" .. (open and "[-] " or "[+] ") .. exp.name .. "|r")
            r.bg:SetColorTexture(1, 1, 1, 0.06)
            r.click = function() collapsed[exp.key] = open or nil; renderTree() end
            if open then
                for _, map in ipairs(zoneList) do
                    n = n + 1
                    local z = rowOf(tree, n)
                    place(tree, z, n, 12)
                    z.icon:SetTexture(nil)
                    z.text:SetText((selected == map and "|cff33e6ff" or "|cffffffff") .. SFP:ZoneName(map) .. "|r")
                    if selected == map then z.bg:SetColorTexture(0, 0.9, 1, 0.15) end
                    z.click = function()
                        if mode == "top" then setMode("farm") end
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

renderTree = function()
    if mode == "mat" or mode == "farm" or mode == "rare" or mode == "top" then renderTreeMat() else renderModeTree() end
end

local function setTab(t)
    matTab = t
    search:SetText("")
    if win.tabs then
        win.tabs.monsters:SetEnabled(t ~= "monsters")
        win.tabs.gather:SetEnabled(t ~= "gather")
    end
    renderTree()
    renderList()
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
    win = CreateFrame("Frame", "SeviathsUsefulToolsMaterialGuide", WorldMapFrame, "BackdropTemplate")
    win:SetFrameStrata("DIALOG")
    -- it is not movable. The map cannot be moved either, so the window uses the empty screen to the right of it, as tall as the map;
    -- when the map leaves no room there (a maximized map) it sits at the bottom right of the map instead
    local function fit()
        win:ClearAllPoints()
        local mr, ms = WorldMapFrame:GetRight(), WorldMapFrame:GetEffectiveScale()
        local ur, us = UIParent:GetRight(), UIParent:GetEffectiveScale()
        local ws = win:GetEffectiveScale()
        local space = (mr and ur and ws > 0) and ((ur * us - mr * ms) / ws) or 0
        if space >= 520 then
            win:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 48, 0)   -- clear of the map's side tabs
            win:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMRIGHT", 48, 0)
            win:SetWidth(math.min(space - 52, 820))
        else
            win:SetPoint("BOTTOMRIGHT", sc, "BOTTOMRIGHT", -8, 8)
            local w, h = sc:GetWidth(), sc:GetHeight()
            if w and w > 0 then win:SetSize(math.max(520, w * 0.46), math.max(360, h * 0.62)) end
        end
    end
    fit()
    win.fit = fit
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
        if mode == "farm" or mode == "rare" then renderTree() end
        renderList()
    end)

    win.title = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    win.title:SetPoint("TOPLEFT", TREE_W + 34, -40)

    tree = scrollSide(win, 10, -64, TREE_W)
    tree.scroll:ClearAllPoints()
    tree.scroll:SetPoint("TOPLEFT", win, "TOPLEFT", 10, -64)
    tree.scroll:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 10, 40)
    tree.scroll:SetWidth(TREE_W)
    -- Top 10 best spots: always at the bottom of the Farm spots / Rares window
    win.topBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    win.topBtn:SetSize(TREE_W, 26)
    win.topBtn:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 10, 8)
    win.topBtn:SetText("Top 15 best spots")
    win.topBtn:SetScript("OnClick", function()
        setMode("top")
        win.curBtn:Show()
        renderTree()
        renderList()
    end)
    win.topBtn:Hide()
    list = scrollSide(win, TREE_W + 34, -64, 10)
    list.scroll:ClearAllPoints()
    list.scroll:SetPoint("TOPLEFT", win, "TOPLEFT", TREE_W + 34, -64)
    list.scroll:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -30, 40)
    -- the pages: Previous / Next under the list
    local pg = CreateFrame("Frame", nil, win)
    pg:SetHeight(26)
    pg:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", TREE_W + 34, 8)
    pg:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -30, 8)
    pg.prev = CreateFrame("Button", nil, pg, "UIPanelButtonTemplate")
    pg.prev:SetSize(90, 24)
    pg.prev:SetPoint("LEFT", 0, 0)
    pg.prev:SetText("Previous")
    pg.next = CreateFrame("Button", nil, pg, "UIPanelButtonTemplate")
    pg.next:SetSize(90, 24)
    pg.next:SetPoint("RIGHT", 0, 0)
    pg.next:SetText("Next")
    pg.text = pg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pg.text:SetPoint("CENTER")
    pg.prev:SetScript("OnClick", function() listPage = listPage - 1; win.refreshList() end)
    pg.next:SetScript("OnClick", function() listPage = listPage + 1; win.refreshList() end)
    win.pager = pg
    list.content:SetWidth(list.scroll:GetWidth())
    win:SetScript("OnSizeChanged", function()
        list.content:SetWidth(math.max(list.scroll:GetWidth(), 100))
    end)
    win.refreshList = renderList
    win.curBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    win.curBtn:SetSize(170, 24)
    win.curBtn:SetPoint("TOPLEFT", win, "TOPLEFT", 200, -8)
    win.curBtn:SetText("Show current zone")
    win.curBtn:SetScript("OnClick", function()
        selected = WorldMapFrame:GetMapID()
        search:SetText("")
        renderTree()
        renderList()
    end)
    win.curBtn:Hide()
    win.tabs = {}
    for k, def in ipairs({ { "monsters", "Monsters" }, { "gather", "Mining & Herbalism" } }) do
        local key, text = def[1], def[2]
        local tb = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
        tb:SetSize(k == 1 and 90 or 150, 24)
        tb:SetPoint("TOPLEFT", win, "TOPLEFT", 200 + (k - 1) * 94, -8)
        tb:SetText(text)
        tb:SetScript("OnClick", function() setTab(key) end)
        win.tabs[key] = tb
    end
    win.tabs.monsters:SetEnabled(matTab ~= "monsters")
    win.tabs.gather:SetEnabled(matTab ~= "gather")
    win:SetScript("OnHide", function()
        guideIndex = nil
        monsterIndex = nil
        zonesCache = {}
    end)
    win:SetScript("OnShow", function()
        fit()
        list.content:SetWidth(math.max(list.scroll:GetWidth(), 100))
        if not selected then
            local m = WorldMapFrame:GetMapID()
            if m and (SFP.zoneByMap[m] or guideMaps()[m]) then selected = m end
        end
        renderTree()
        renderList()
    end)
end

---------------------------------------------------------------------------
-- The line of buttons below the world map, at the right: Farm spots, Collectables, Material search and, last, Mining & Herbalism. Each
-- is a button like "Material search"; the side lists open above their button, one at a time.
---------------------------------------------------------------------------
local row
local rowBtns = {}

local function openMode(m)
    if not win then build() end
    if win:IsShown() and mode == m then win:Hide() return end
    SFP.db.spotsCollapsed, SFP.db.gatherCollapsed, SFP.db.collCollapsed, SFP.db.raresCollapsed = true, true, true, true
    SFP.RefreshWorldMap()
    setMode(m)
    if m == "farm" or m == "rare" then selected = WorldMapFrame:GetMapID() end
    win:Show()
    renderTree()
    renderList()
end
local function openGuide() openMode("mat") end
local function openGather()
    if not win then build() end
    if win:IsShown() and mode == "mat" and matTab == "gather" then win:Hide() return end
    SFP.db.spotsCollapsed, SFP.db.gatherCollapsed, SFP.db.collCollapsed, SFP.db.raresCollapsed = true, true, true, true
    SFP.RefreshWorldMap()
    setMode("mat")
    gatherExp = "zone"
    win:Show()
    setTab("gather")
end

-- which list a button opens: its collapsed flag in the saved settings (one open at a time)
local FLAGS = { spots = "spotsCollapsed", rares = "raresCollapsed", coll = "collCollapsed", gather = "gatherCollapsed" }
local function openOnly(key)
    if win and win:IsShown() then win:Hide() end
    local wasOpen = SFP.db[FLAGS[key]] == false
    for k, flag in pairs(FLAGS) do SFP.db[flag] = true end
    if not wasOpen then SFP.db[FLAGS[key]] = false end
    SFP.RefreshWorldMap()
end

local function makeButton(key, text, tip, onClick)
    local b = CreateFrame("Button", "SeviathsUsefulToolsRow" .. key, row, "UIPanelButtonTemplate")
    b:SetHeight(26)
    b:SetText(text)
    b:SetWidth(b:GetTextWidth() + 28)
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self)
        SFP.Tip():SetOwner(self, "ANCHOR_TOP")
        SFP.Tip():AddLine(text)
        SFP.Tip():AddLine(tip, 1, 1, 1, true)
        SFP.Tip():Show()
    end)
    b:SetScript("OnLeave", function() SFP.Tip():Hide() end)
    rowBtns[key] = b
    return b
end

local function refreshRow()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then if row then row:Hide() end return end
    if not row then
        row = CreateFrame("Frame", "SeviathsUsefulToolsButtonRow", WorldMapFrame)
        row:SetFrameStrata("HIGH")
        row:SetHeight(28)
        row:SetPoint("TOPRIGHT", WorldMapFrame, "BOTTOMRIGHT", -2, 2)
        makeButton("spots", "Farm spots", "The farm spots of this zone, with a checkbox each", function() openMode("farm") end)
        makeButton("coll", "Collectables", "Mounts of the dungeons and raids here, and the hunter pets of the zone", function() openOnly("coll") end)
        makeButton("rares", "Rares", "The rare monsters of this zone with a waypoint each", function() openMode("rare") end)
        makeButton("search", "Material search", "Every zone from Classic to Midnight: what you can farm there and which monsters drop it. Click a monster for a waypoint.", openGuide)
        makeButton("mount", "Mount search", "Every mount with where to get it, Classic to Midnight. Click a source for a waypoint.", function() openMode("mount") end)
        makeButton("hunter", "Hunter search", "Every hunter pet (spirit beasts, unique looks and the tameable beasts seen so far) with a waypoint", function() openMode("hunter") end)
        makeButton("pet", "Battle pets", "Every battle pet with its auction price - search by name, or pick a family", function() openMode("pet") end)
        makeButton("gather", "Mining & Herbalism", "The ores and herbs of this zone and the best zone for each", openGather)
    end
    local map = WorldMapFrame:GetMapID()
    local zone = map and SFP.zoneByMap[map]
    local hasFarm, hasRares = false, false
    if map and SFP.HasFarmLists then hasFarm, hasRares = SFP.HasFarmLists(map) end
    local show = {
        spots = true,   -- the window has its own zone list and search, so these two are always there
        rares = true,
        coll = false,   -- Collectables is covered by Mount search and Hunter search
        search = true,
        mount = true,
        hunter = true,
        pet = true,
        gather = SFP.db.showGatherList and map and (zone or SFP.GatherHere) and #SFP.GatherHere(map) > 0,
    }
    local x = 0
    -- right to left: the last of the line is Mining & Herbalism
    for _, key in ipairs({ "gather", "pet", "hunter", "mount", "search", "coll", "rares", "spots" }) do
        local b = rowBtns[key]
        b:ClearAllPoints()
        if show[key] then
            b:SetPoint("RIGHT", row, "RIGHT", -x, 0)
            x = x + b:GetWidth() + 4
            b:Show()
        else
            b:Hide()
        end
    end
    row:SetWidth(math.max(x, 10))
    row:Show()
    if SFP.DockPanels then SFP.DockPanels() end
end

local nameWait
local nameFrame = CreateFrame("Frame")
nameFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
nameFrame:SetScript("OnEvent", function(_, _, itemID)
    if itemID and SFP.StoreIcon then SFP:StoreIcon(itemID) end   -- a delivered item: its icon is kept too
    if nameWait or not (win and win:IsShown()) then return end
    nameWait = true
    C_Timer.After(0.5, function()
        nameWait = nil
        if win and win:IsShown() and win.refreshList then pcall(win.refreshList) end
    end)
end)

SFP:OnLogin(function()
    -- once: the side lists start closed (they are opened with the buttons below the map); older saved settings had the Farm spots list open
    if SFP.db and not SFP.db.panelsClosedV2 then
        SFP.db.panelsClosedV2 = true
        SFP.db.spotsCollapsed, SFP.db.gatherCollapsed, SFP.db.collCollapsed, SFP.db.raresCollapsed = true, true, true, true
    end
    -- the icons of all crafting reagents are stored a little after login (the game knows an item's icon without asking the server), a few
    -- hundred per frame, so the Material search shows the right icon for every material
    C_Timer.After(12, function()
        local ids = {}
        for id, a2 in pairs(SFP.AuctionItems or {}) do if a2[1] == 7 then ids[#ids + 1] = id end end
        for id, info in pairs(SFP.Items or {}) do if info.kind and info.kind ~= "mount" then ids[#ids + 1] = id end end
        local i = 1
        local function step()
            local last = math.min(i + 400, #ids)
            for k = i, last do pcall(SFP.StoreIcon, SFP, ids[k]) end
            i = last + 1
            if i <= #ids then C_Timer.After(0, step) end
        end
        step()
    end)
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer then return end
    WorldMapFrame:HookScript("OnHide", function()
        if win then win:Hide() end
        if row then row:Hide() end
    end)
    WorldMapFrame:HookScript("OnShow", function() pcall(refreshRow) end)
    SFP:OnRefresh(function() pcall(refreshRow) end)
end)

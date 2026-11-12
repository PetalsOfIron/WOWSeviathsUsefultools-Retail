-- SeviathsUsefulTools - Questing Zone Planner (a page of its own in the menu, the same as in the WoW Forever version)
-- The zones you still need for your level and where to head next. A zone is taken off the list when you mark it done (the button on its row).

local _, SFP = ...
local K = SFP.MenuKit
if not K then return end

local CY = "|c" .. (SFP.CYAN_HEX or "ffffd100")

-- The zones and their level ranges come from the game itself (the same levels the world map shows on hover: C_Map.GetMapLevels). The seeds below are zones
-- of the leveling expansions; every zone of the same continent is listed too. The numbers after a seed are only used when the game gives no level for it.
local SEEDS = {
    { 2022, 60, 64 }, { 2023, 62, 66 }, { 2024, 64, 68 }, { 2025, 66, 70 }, { 2151, 60, 70 }, { 2133, 70, 70 }, { 2200, 70, 70 },
    { 2248, 70, 73 }, { 2214, 72, 76 }, { 2215, 75, 79 }, { 2255, 78, 80 }, { 2346, 80, 80 }, { 2371, 80, 80 },
    { 2395, 80, 83 }, { 2437, 82, 86 }, { 2413, 85, 89 }, { 2405, 88, 90 },
}
local ZONES, zonesAt = {}, 0

local function levelsOf(map)
    if not (C_Map and C_Map.GetMapLevels) then return nil end
    local ok, lo, hi = pcall(C_Map.GetMapLevels, map)
    if ok and type(lo) == "number" and type(hi) == "number" and not (issecretvalue and (issecretvalue(lo) or issecretvalue(hi))) and lo > 0 and hi >= lo then return lo, hi end
    return nil
end

local function buildZones()
    local list, seen = {}, {}
    local function add(map, fbLo, fbHi, expansion)
        if seen[map] then return end
        local lo, hi = levelsOf(map)
        lo, hi = lo or fbLo, hi or fbHi
        if not (lo and hi) then return end
        seen[map] = true
        list[#list + 1] = { map, expansion, lo, hi }
    end
    local zoneType = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
    for _, sd in ipairs(SEEDS) do
        local okI, info = pcall(C_Map.GetMapInfo, sd[1])
        local parent = okI and type(info) == "table" and info.parentMapID
        local pname
        if parent and parent > 0 then
            local okP, pinfo = pcall(C_Map.GetMapInfo, parent)
            pname = okP and type(pinfo) == "table" and pinfo.name or nil
            if not seen["c" .. parent] then
                seen["c" .. parent] = true
                local okC, kids = pcall(C_Map.GetMapChildrenInfo, parent, zoneType)
                for _, k in ipairs(okC and type(kids) == "table" and kids or {}) do
                    if type(k) == "table" and k.mapID and k.mapType == zoneType then add(k.mapID, nil, nil, pname) end
                end
            end
        end
        add(sd[1], sd[2], sd[3], pname)
    end
    return list
end

local function myLevel() local l = UnitLevel("player"); return type(l) == "number" and l or 1 end

local function zoneName(map)
    local okI, info = pcall(C_Map.GetMapInfo, map)
    if okI and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then return info.name end
    local ok, n = pcall(function() return SFP:ZoneName(map) end)
    return ok and n or ("zone " .. map)
end

local function charKey()
    return (UnitName("player") or "?") .. "-" .. ((GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName() or "?"):gsub("[%s%-']", ""))
end

local function distance(lvl, lo, hi)
    if lvl >= lo and lvl <= hi then return 0 end
    return lvl < lo and (lo - lvl) or (lvl - hi)
end

local function done()
    SFP.db.zoneDone = SFP.db.zoneDone or {}
    local d = SFP.db.zoneDone[charKey()]
    if not d then d = {}; SFP.db.zoneDone[charKey()] = d end
    return d
end

local function openMap(map)
    if OpenWorldMap then OpenWorldMap(map) return end
    if WorldMapFrame then
        if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
        WorldMapFrame:SetMapID(map)
    end
end

local buildQuests = K.simplePage("Questing Zone Planner",
    "The zones you still need for your level, and where to head next. Map opens the world map on the zone; Done takes a zone off the list for this character once you have finished its quests.",
    function(pane, y)
        local head = K.mkText(pane, "", 12, y - 6, 480, "GameFontNormal")
        local list = SFP.MakeRowList(pane, 8, y - 34, 500, 380, 22)
        local showAll = false
        local allBtn = K.mkButton(pane, "Show finished zones", 150, function(self)
            showAll = not showAll
            self.text:SetText(showAll and "Hide finished zones" or "Show finished zones")
            SFP:Safe("quest planner", pane.refresh)
        end)
        allBtn:SetPoint("TOPLEFT", 340, y - 4)
        return function()
            local lvl = myLevel()
            local d = done()
            local rows = {}
            if #ZONES == 0 or GetTime() - zonesAt > 600 then ZONES = buildZones(); zonesAt = GetTime() end
            for _, z in ipairs(ZONES) do
                local isDone = d[z[1]] and true or false
                local dist = distance(lvl, z[3], z[4])
                -- what you need: zones that fit your level or are up to 6 levels ahead, and that you have not marked done
                if showAll or (not isDone and z[4] >= lvl and z[3] - lvl <= 6) then rows[#rows + 1] = { z = z, dist = dist, done = isDone } end
            end
            table.sort(rows, function(a, b)
                if a.done ~= b.done then return not a.done end
                if a.dist ~= b.dist then return a.dist < b.dist end
                return a.z[4] > b.z[4]   -- of the zones that fit, the one with the higher range first: it leads further on
            end)
            local first = rows[1] and not rows[1].done and rows[1].z
            if first then
                head:SetText(("%sHead to %s next|r  |cffffd100(level %d-%d)|r"):format(CY, zoneName(first[1]), first[3], first[4]))
            elseif lvl < 60 then
                head:SetText(("%sLevel %d|r  -  pick an expansion with Chromie (Stormwind or Orgrimmar): its zones scale to your level"):format(CY, lvl))
            else
                head:SetText(("%sLevel %d|r  -  no zone left for your level in the list"):format(CY, lvl))
            end
            local items = {}
            local here = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            for i, r in ipairs(rows) do
                local z = r.z
                items[i] = {
                    text = ("%s%s|r  |cff808080%s level %d-%d%s|r"):format(r.done and "|cff808080" or "|cffffffff", zoneName(z[1]), z[2] or "", z[3], z[4], here == z[1] and "  (you are here)" or ""),
                    buttons = {
                        { r.done and "Undo" or "Done", 52, function() d[z[1]] = (not r.done) or nil; SFP:Safe("quest planner", pane.refresh) end },
                        { "Map", 46, function() openMap(z[1]) end },
                    },
                }
            end
            list:Set(items)
        end
    end)

-- the page is a tab of its own, right after the Achievement Planner
do
    local at = #K.sections + 1
    for i, s in ipairs(K.sections) do if s.key == "ach" then at = i + 1 break end end
    table.insert(K.sections, at, { key = "qzone", label = "Questing Zone Planner" })
    K.builders.qzone = buildQuests
end

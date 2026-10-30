-- SeviathsUsefulTools - spots on the minimap
--
-- The same farm spots, rares, hunter tames, special materials and gathering nodes as on the world
-- map, drawn on the minimap around you. Only the spots near you are drawn.
-- With HereBeDragons-Pins (the library Questie, RareScanner and others share) it follows rotation,
-- zoom and any minimap shape set by Leatrix, BasicMinimap and similar addons. Without it the spots
-- are placed here, from the map size, the minimap zoom and the minimap rotation.
--

local ADDON, SFP = ...

local RANGE = 0.12          -- map units around the player (about the minimap view)
local MAXPINS = 90
local TEX = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

local HBD
local pool, shown = {}, {}
local currentMap

local function safe(fn, ...)
    local ok, a = pcall(fn, ...)
    if ok then return a end
end

local function getHBD()
    if HBD then return HBD end
    if LibStub then HBD = LibStub("HereBeDragons-Pins-2.0", true) end
    return HBD
end

local function color(s)
    if SFP.SpotColor then return SFP.SpotColor(s) end
    return SFP.CYAN
end

local function acquire()
    local f = table.remove(pool)
    if f then return f end
    f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(12, 12)
    f.outer = f:CreateTexture(nil, "BACKGROUND")
    f.outer:SetAllPoints()
    f.outer:SetTexture(TEX)
    f.outer:SetBlendMode("ADD")
    f.inner = f:CreateTexture(nil, "ARTWORK")
    f.inner:SetSize(5, 5)
    f.inner:SetPoint("CENTER")
    f.inner:SetTexture(TEX)
    f.inner:SetBlendMode("ADD")
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        local s = self.spot
        if not s then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(s.name or "?", color(s).r, color(s).g, color(s).b)
        local tag = s.gather and ("best zone for " .. (s.gather == "ore" and "ore" or "herbs"))
            or (s.hunter and "hunter tame") or (s.rare and "rare") or (s.special and "special material") or "farm spot"
        GameTooltip:AddLine(tag, 0.8, 0.8, 0.8)
        for i, id in ipairs(s.items or {}) do
            if i > 5 then break end
            GameTooltip:AddLine("|T" .. SFP:ItemIcon(id) .. ":12|t " .. SFP:ItemName(id))
        end
        if s.note and s.note ~= "" then GameTooltip:AddLine(s.note, 0.6, 0.6, 0.6, true) end
        GameTooltip:AddLine(string.format("%.1f, %.1f", self.px * 100, self.py * 100), 1, 0.82, 0)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return f
end

local function release(key)
    local f = shown[key]
    if not f then return end
    local h = getHBD()
    if h then pcall(h.RemoveMinimapIcon, h, SFP, f) end
    f:Hide()
    f.spot = nil
    pool[#pool + 1] = f
    shown[key] = nil
end

---------------------------------------------------------------------------
-- without HereBeDragons: place the spots on the minimap ourselves
---------------------------------------------------------------------------
-- minimap diameter in yards per zoom level (outdoors)
local OUTDOOR = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }

local mapSize = {}   -- [mapID] = { width yards, height yards } or false
local function sizeOf(mapID)
    local s = mapSize[mapID]
    if s ~= nil then return s end
    s = false
    if C_Map.GetWorldPosFromMapPos and CreateVector2D then
        local _, a = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
        local _, bx = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 0))
        local _, by = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 1))
        if a and bx and by then
            local w = math.sqrt((bx.x - a.x) ^ 2 + (bx.y - a.y) ^ 2)
            local h = math.sqrt((by.x - a.x) ^ 2 + (by.y - a.y) ^ 2)
            if w > 0 and h > 0 then s = { w, h } end
        end
    end
    mapSize[mapID] = s
    return s
end

local function viewRadius()
    if C_Minimap and C_Minimap.GetViewRadius then
        local r = C_Minimap.GetViewRadius()
        if type(r) == "number" and r > 0 then return r end
    end
    return (OUTDOOR[Minimap:GetZoom() or 0] or OUTDOOR[3]) / 2
end

-- move every drawn spot to where it belongs around the minimap centre
local function placeOwn()
    if getHBD() or not next(shown) then return end
    local size = currentMap and sizeOf(currentMap)
    local pos = currentMap and C_Map.GetPlayerMapPosition(currentMap, "player")
    local px, py
    if pos and pos.GetXY then px, py = pos:GetXY() end
    if issecretvalue and (issecretvalue(px) or issecretvalue(py)) then px, py = nil, nil end
    if not size or not px or px <= 0 then
        for _, f in pairs(shown) do f:Hide() end
        return
    end
    local rotate = (C_CVar and C_CVar.GetCVar or GetCVar)("rotateMinimap") == "1"
    local face = rotate and GetPlayerFacing() or 0
    local cs, sn = math.cos(face), math.sin(face)
    local radius = viewRadius()
    local scale = (Minimap:GetWidth() / 2) / radius
    for _, f in pairs(shown) do
        local ex = (f.px - px) * size[1]     -- yards east
        local ny = -(f.py - py) * size[2]    -- yards north
        local x, y = ex * cs + ny * sn, -ex * sn + ny * cs
        if x * x + y * y > radius * radius * 0.96 then
            f:Hide()
        else
            f:ClearAllPoints()
            f:SetPoint("CENTER", Minimap, "CENTER", x * scale, y * scale)
            f:Show()
        end
    end
end

local function clearAll()
    for key in pairs(shown) do release(key) end
end

local function update()
    local h = getHBD()
    if not SFP.db or not SFP.db.minimapSpots or not SFP.db.mapOverlay or not SFP.zoneByMap then
        clearAll()
        return
    end
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    local px, py
    if pos and pos.GetXY then px, py = pos:GetXY() end
    if issecretvalue and (issecretvalue(px) or issecretvalue(py)) then px, py = nil, nil end
    local zone = mapID and SFP.zoneByMap[mapID]
    if not zone or not px or px <= 0 or not zone.spawns then
        clearAll()
        return
    end
    if currentMap ~= mapID then clearAll(); currentMap = mapID end

    local wanted, n = {}, 0
    for si, s in ipairs(zone.spawns) do
        if s.points and SFP.ShowSpot and SFP.ShowSpot(s) then
            for pi, p in ipairs(s.points) do
                local dx, dy = p[1] - px, p[2] - py
                if dx * dx + dy * dy < RANGE * RANGE then
                    n = n + 1
                    if n > MAXPINS then break end
                    wanted[si .. ":" .. pi] = { s, p }
                end
            end
        end
        if n > MAXPINS then break end
    end
    for key in pairs(shown) do
        if not wanted[key] then release(key) end
    end
    for key, e in pairs(wanted) do
        if not shown[key] then
            local s, p = e[1], e[2]
            local f = acquire()
            local c = color(s)
            f.spot, f.px, f.py = s, p[1], p[2]
            f.outer:SetVertexColor(c.r, c.g, c.b, 0.75)
            f.inner:SetVertexColor(1, 1, 1, 0.95)
            if h then
                f:Show()
                local ok = pcall(h.AddMinimapIconMap, h, SFP, f, mapID, p[1], p[2], false, false)
                if ok then shown[key] = f else f:Hide(); pool[#pool + 1] = f end
            elseif sizeOf(mapID) then
                f:SetParent(Minimap)
                f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
                shown[key] = f   -- placeOwn() puts it on the minimap
            else
                pool[#pool + 1] = f
            end
        end
    end
    if not h then placeOwn() end
end

local ticker
SFP:OnLogin(function()
    local f = CreateFrame("Frame")
    local acc = 0
    f:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 1 then return end
        acc = 0
        SFP:Safe("minimap spots", update)
    end)
    SFP:OnRefresh(function() currentMap = nil end)
    -- no HereBeDragons: keep the spots on the move with the player
    local move = CreateFrame("Frame")
    local acc2 = 0
    move:SetScript("OnUpdate", function(_, dt)
        acc2 = acc2 + dt
        if acc2 < 0.05 then return end
        acc2 = 0
        if next(shown) then SFP:Safe("minimap spots move", placeOwn) end
    end)
end)

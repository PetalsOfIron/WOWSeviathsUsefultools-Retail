-- SeviathsUsefulTools - treasures on the world map
--
-- Every treasure chest, cache or skull you open is recorded with what it gave (Collector.lua: SFP.db.objects). Here each of them is a very small box on the world
-- map at the place you opened it; hover the box to see the loot, each item with its chance (the same lines as the tooltip of the chest itself).

local _, SFP = ...

local SIZE = 6            -- screen pixels of the box
local pins, used = {}, 0
local byMap = {}          -- [map] = list of { id, rec, x, y }: made when a map is asked for, dropped when the loot changes
local layer

local function canvas()
    local sc = WorldMapFrame and WorldMapFrame.ScrollContainer
    return sc and sc.Child
end

local function canvasScale()
    local sc = WorldMapFrame and WorldMapFrame.ScrollContainer
    return (sc and sc.GetCanvasScale and sc:GetCanvasScale()) or 1
end

-- the treasures recorded on one map: objects that gave something and are not gathering nodes (ore, herbs ...)
local function treasuresOf(map)
    local list = byMap[map]
    if list then return list end
    list = {}
    local objects = SFP.db and SFP.db.objects
    if objects then
        for id, rec in (SeviathsAllPairs or pairs)(objects) do
            if type(id) == "number" and type(rec) == "table" and type(rec.d) == "table" and next(rec.d) and type(rec.m) == "table"
                and (rec.k or 0) >= 1 and not (SFP.ObjectKind and SFP:ObjectKind(rec)) then
                local pts = rec.m[map]
                if type(pts) == "table" then
                    for _, p in ipairs(pts) do
                        if p[1] and p[2] then list[#list + 1] = { id = id, rec = rec, x = p[1], y = p[2] } end
                    end
                end
            end
        end
    end
    byMap[map] = list
    return list
end

local function getPin()
    used = used + 1
    local p = pins[used]
    if not p then
        p = CreateFrame("Button", nil, layer)
        p.edge = p:CreateTexture(nil, "BACKGROUND")
        p.edge:SetAllPoints()
        p.edge:SetColorTexture(0, 0, 0, 0.9)
        p.fill = p:CreateTexture(nil, "ARTWORK")
        p.fill:SetPoint("TOPLEFT", 1, -1)
        p.fill:SetPoint("BOTTOMRIGHT", -1, 1)
        p.fill:SetColorTexture(1, 0.82, 0.1, 1)
        p:SetScript("OnEnter", function(self)
            local t = SFP.Tip and SFP.Tip() or GameTooltip
            t:SetOwner(self, "ANCHOR_RIGHT")
            t:ClearLines()
            t:AddLine(tostring(self.rec.n or ("Treasure " .. tostring(self.id))), 1, 0.82, 0.1)
            if SFP.ObjectLootLines then SFP.ObjectLootLines(t, self.rec) end
            t:Show()
        end)
        p:SetScript("OnLeave", function() (SFP.Tip and SFP.Tip() or GameTooltip):Hide() end)
        pins[used] = p
    end
    p:Show()
    return p
end

local function update()
    if not layer then return end
    for i = 1, #pins do pins[i]:Hide() end
    used = 0
    if not (WorldMapFrame and WorldMapFrame:IsShown()) or not (SFP.db and SFP.db.showTreasures ~= false) then return end
    local c = canvas()
    local map = WorldMapFrame:GetMapID()
    if not (c and map) then return end
    local w, h = c:GetWidth(), c:GetHeight()
    if not w or w <= 0 then return end
    local size = math.max(SIZE / canvasScale(), 3)
    for _, t in ipairs(treasuresOf(map)) do
        local p = getPin()
        p:SetSize(size, size)
        p:ClearAllPoints()
        p:SetPoint("CENTER", c, "TOPLEFT", t.x * w, -t.y * h)
        p.id, p.rec = t.id, t.rec
    end
end

-- the same boxes on the minimap: around the player, placed by the distance in yards (the size of the zone) and the minimap's view radius; they turn with the
-- minimap when it rotates
local mpins, mused = {}, 0
local function minimapRadius()
    if C_Minimap and C_Minimap.GetViewRadius then
        local ok, r = pcall(C_Minimap.GetViewRadius)
        if ok and type(r) == "number" and r > 0 then return r end
    end
    local zoom = Minimap:GetZoom() or 0
    local indoors = GetCVar and GetCVar("minimapZoom") ~= GetCVar("minimapInsideZoom")
    local out = { [0] = 233, 200, 167, 133, 100, 67 }
    local inn = { [0] = 150, 120, 90, 60, 40, 25 }
    return (indoors and inn or out)[zoom] or 133
end

local function getMiniPin()
    mused = mused + 1
    local p = mpins[mused]
    if not p then
        p = CreateFrame("Button", nil, Minimap)
        p:SetFrameLevel(Minimap:GetFrameLevel() + 6)
        p:SetSize(SIZE, SIZE)
        p.edge = p:CreateTexture(nil, "BACKGROUND")
        p.edge:SetAllPoints()
        p.edge:SetColorTexture(0, 0, 0, 0.9)
        p.fill = p:CreateTexture(nil, "ARTWORK")
        p.fill:SetPoint("TOPLEFT", 1, -1)
        p.fill:SetPoint("BOTTOMRIGHT", -1, 1)
        p.fill:SetColorTexture(1, 0.82, 0.1, 1)
        p:SetScript("OnEnter", function(self)
            local t = SFP.Tip and SFP.Tip() or GameTooltip
            t:SetOwner(self, "ANCHOR_LEFT")
            t:ClearLines()
            t:AddLine(tostring(self.rec.n or ("Treasure " .. tostring(self.id))), 1, 0.82, 0.1)
            if SFP.ObjectLootLines then SFP.ObjectLootLines(t, self.rec) end
            t:Show()
        end)
        p:SetScript("OnLeave", function() (SFP.Tip and SFP.Tip() or GameTooltip):Hide() end)
        mpins[mused] = p
    end
    p:Show()
    return p
end

local function updateMinimap()
    for i = 1, #mpins do mpins[i]:Hide() end
    mused = 0
    if not (SFP.db and SFP.db.showTreasures ~= false) or not Minimap:IsShown() then return end
    local map = C_Map.GetBestMapForUnit("player")
    if not map then return end
    local pos = C_Map.GetPlayerMapPosition(map, "player")
    if not pos then return end
    local px, py = pos:GetXY()
    if not px or (issecretvalue and (issecretvalue(px) or issecretvalue(py))) or px <= 0 then return end
    local list = treasuresOf(map)
    if #list == 0 then return end
    local okS, wy, hy = pcall(C_Map.GetMapWorldSize, map)
    if not okS or type(wy) ~= "number" or wy <= 0 then return end
    local radius = minimapRadius()
    local half = Minimap:GetWidth() / 2
    local rotate = GetCVar and GetCVar("rotateMinimap") == "1"
    local facing = rotate and GetPlayerFacing and GetPlayerFacing() or 0
    local cs, sn = math.cos(facing), math.sin(facing)
    for _, t in ipairs(list) do
        local dx, dy = (t.x - px) * wy, (t.y - py) * hy   -- yards: east and south
        if rotate and facing then dx, dy = dx * cs - dy * sn, dx * sn + dy * cs end
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= radius * 0.95 then
            local p = getMiniPin()
            p:ClearAllPoints()
            p:SetPoint("CENTER", Minimap, "CENTER", dx / radius * half, -dy / radius * half)
            p.id, p.rec = t.id, t.rec
        end
    end
end

SFP:OnLogin(function()
    if not (WorldMapFrame and WorldMapFrame.ScrollContainer) then return end
    local c = canvas()
    if not c then return end
    layer = CreateFrame("Frame", nil, c)
    layer:SetAllPoints(c)
    layer:SetFrameLevel((c:GetFrameLevel() or 0) + 6)
    layer:EnableMouse(false)   -- only the little boxes take the mouse
    if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", update) end
    WorldMapFrame:HookScript("OnShow", update)
    if WorldMapFrame.ScrollContainer.HookScript then pcall(WorldMapFrame.ScrollContainer.HookScript, WorldMapFrame.ScrollContainer, "OnMouseWheel", function() C_Timer.After(0.05, update) end) end
    -- the minimap boxes follow the player: a few times a second
    local acc = 0
    local mf = CreateFrame("Frame")
    mf:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 0.2 then return end
        acc = 0
        SFP:Safe("treasures minimap", updateMinimap)
    end)
    -- a treasure opened now: the boxes are made again after the loot is recorded
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("LOOT_CLOSED")
    ev:SetScript("OnEvent", function()
        C_Timer.After(1, function()
            wipe(byMap)
            if WorldMapFrame:IsShown() then SFP:Safe("treasures", update) end
        end)
    end)
end)

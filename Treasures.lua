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

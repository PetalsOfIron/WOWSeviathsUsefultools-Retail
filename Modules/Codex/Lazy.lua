-- Seviath's Codex - pages built only for the group that is open.
--
-- The item pages (about 55,000) and the quest pages (about 37,000) made from the collected data are the biggest part of the Codex's memory.
-- Here nothing of them is built when the Codex opens. When the Items or Quests section is opened, a short pass over the data only counts
-- the pages of each group (an expansion: "The War Within", "Midnight" ...) and remembers their IDs; the list shows the groups with their
-- counts. The pages of ONE group are made when that group is expanded (a few thousand, about 2 seconds, in the background) and taken out
-- again when it is collapsed, another section is opened, or the Codex is closed. A search builds everything.

local ADDON, ns = SFP_Module("Codex")
local SFP = _G.SeviathsUsefulTools

local function budgetLoop(total, perFrameMs, fn, done)
    local i = 1
    local function step()
        local t0 = debugprofilestop()
        while i <= total and debugprofilestop() - t0 < perFrameMs do
            fn(i)
            i = i + 1
        end
        if i <= total then C_Timer.After(0, step) elseif done then done() end
    end
    step()
end

ns.lazy = {
    item = { groups = {}, built = {}, state = nil },    -- state: nil = not indexed, "indexing", "ready"
    quest = { groups = {}, built = {}, state = nil },
}

------------------------------------------------------------------------
-- indexing: which group each record belongs to (IDs only)
------------------------------------------------------------------------
local scanners = {}

scanners.quest = function(done)
    local db = ns.db
    local ids = {}
    for id in SeviathsAllPairs(db.quests or {}) do ids[#ids + 1] = id end
    local lz = ns.lazy.quest
    budgetLoop(#ids, 6, function(n)
        local id = ids[n]
        local q = db.quests[id]
        if type(q) == "table" and q.t and not ns:Get("quest:" .. id) then
            local g = (q.x and _G["EXPANSION_NAME" .. q.x]) or "Other"
            local list = lz.groups[g]
            if not list then list = {}; lz.groups[g] = list end
            list[#list + 1] = id
        end
    end, done)
end

scanners.item = function(done)
    local db = SFP and SFP.db
    if not db then if done then done() end return end
    local ids = {}
    for id in pairs(db.ahItems or {}) do ids[#ids + 1] = id end
    for id in SeviathsAllPairs(db.knownItems or {}) do ids[#ids + 1] = id end
    local lz = ns.lazy.item
    budgetLoop(#ids, 6, function(n)
        local id = ids[n]
        local r = db.knownItems and db.knownItems[id]
        local g
        if type(r) == "table" and r.n then
            if r.c == 7 then
                if ns.MaybeMaterial then pcall(ns.MaybeMaterial, ns, id, r.n) end   -- materials are few: made at once
            elseif not ns:Get("item:" .. id) then
                g = ns:ItemGroupFor(id, (r.t or "Other") .. ((r.st and r.st ~= "" and r.st ~= r.t) and (" - " .. r.st) or ""), r.x)
            end
        else
            local cls = db.ahItems and db.ahItems[id]
            local name = db.ahNames and db.ahNames[id]
            if name and cls ~= 7 and not ns:Get("item:" .. id) then
                g = ns:ItemGroupFor(id, GetItemClassInfo and GetItemClassInfo(cls) or "Other")
            end
        end
        if g then
            local list = lz.groups[g]
            if not list then list = {}; lz.groups[g] = list end
            list[#list + 1] = id
        end
    end, done)
end

function ns:LazyIndex(cat, done)
    local lz = self.lazy[cat]
    if not lz or not scanners[cat] then if done then done() end return end
    if lz.state == "ready" then if done then done() end return end
    if lz.state == "indexing" then
        lz.waiting = lz.waiting or {}
        if done then lz.waiting[#lz.waiting + 1] = done end
        return
    end
    lz.state = "indexing"
    lz.waiting = { done }
    scanners[cat](function()
        lz.state = "ready"
        local w = lz.waiting or {}
        lz.waiting = nil
        for _, fn in ipairs(w) do pcall(fn) end
        if ns.RefreshList then pcall(ns.RefreshList, ns, true) end
    end)
end

------------------------------------------------------------------------
-- making and removing the pages of one group
------------------------------------------------------------------------
local makers = {}

makers.quest = function(id)
    local q = ns.db.quests[id]
    if type(q) == "table" and q.t and ns.AddQuestEntry then ns.AddQuestEntry(id, q) end
end

makers.item = function(id)
    local db = SFP.db
    local r = db.knownItems and db.knownItems[id]
    if type(r) == "table" and r.n then
        if not ns:Get("item:" .. id) then
            ns:Add({ cat = "item", id = id, name = r.n,
                group = ns:ItemGroupFor(id, (r.t or "Other") .. ((r.st and r.st ~= "" and r.st ~= r.t) and (" - " .. r.st) or ""), r.x),
                icon = C_Item.GetItemIconByID(id), itemID = id, wh = "item=" .. id,
                sub = (r.t or "") .. ((r.st and r.st ~= "") and (" - " .. r.st) or "") .. ((r.i and r.i > 0) and ("  item level " .. r.i) or ""),
                lazy = true })
        end
    else
        local cls = db.ahItems and db.ahItems[id]
        local name = db.ahNames and db.ahNames[id]
        if name and not ns:Get("item:" .. id) then
            local cn = GetItemClassInfo and GetItemClassInfo(cls) or "Other"
            ns:Add({ cat = "item", id = id, name = name, group = ns:ItemGroupFor(id, cn), icon = C_Item.GetItemIconByID(id),
                itemID = id, wh = "item=" .. id, sub = cn, lazy = true })
        end
    end
end

function ns:BuildLazyGroup(cat, group, done)
    local lz = self.lazy[cat]
    local list = lz and lz.groups[group]
    if not list or lz.built[group] or lz.building and lz.building[group] then if done then done() end return end
    lz.building = lz.building or {}
    lz.building[group] = true
    budgetLoop(#list, 8, function(n) pcall(makers[cat], list[n]) end, function()
        lz.building[group] = nil
        lz.built[group] = true
        if ns.RefreshList then pcall(ns.RefreshList, ns, true) end
        if done then done() end
    end)
end

function ns:UnloadLazyGroup(cat, group)
    local lz = self.lazy[cat]
    if not lz or not lz.built[group] then return end
    lz.built[group] = nil
    self:UnloadLazy({ cat }, group)
end

function ns:BuildAllLazy(cat)
    local lz = self.lazy[cat]
    if not lz then return end
    local names = {}
    for g in pairs(lz.groups) do names[#names + 1] = g end
    local i = 0
    local function nextGroup()
        i = i + 1
        if names[i] then ns:BuildLazyGroup(cat, names[i], nextGroup) end
    end
    nextGroup()
end

-- everything of a section out of memory again (also the group lists): made again the next time that section is opened
function ns:UnloadAllLazy(cat)
    local lz = self.lazy[cat]
    if not lz or (lz.state == nil and next(lz.built) == nil) then return end
    self:UnloadLazy({ cat })
    lz.groups, lz.built, lz.building, lz.state, lz.waiting = {}, {}, nil, nil, nil
end

-- the number of pages of a group that are not built yet (for the count of its header)
function ns:LazyPending(cat, group)
    local lz = self.lazy[cat]
    if not lz or lz.built[group] then return 0 end
    local list = lz.groups[group]
    return list and #list or 0
end

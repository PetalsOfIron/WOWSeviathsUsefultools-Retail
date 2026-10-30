-- SeviathsUsefulTools - what your transmog collection says you already looted
-- The game keeps every appearance you collected, with the items behind it and, for drops, the boss or monster
-- (and the instance) they come from. That is history from before the addon was installed. It is read once in
-- the background (a few appearances at a time, never in combat) and saved account-wide:
--   db.history.items[itemID] = true           items you own the appearance of
--   db.history.by[lower monster name] = { n = monster, i = instance, c = items collected from it }
-- Monster tooltips say "you already have N items from this monster". /sfp history shows the numbers.

local _, SFP = ...

local CHUNK = 25          -- appearances per step
local STEP_DELAY = 0.05
local RESCAN_DAYS = 7

local TC = C_TransmogCollection
local running = false

local function secret(v) return issecretvalue and issecretvalue(v) end

local function hist()
    SFP.db.history = SFP.db.history or { items = {}, by = {}, t = 0, visuals = 0 }
    local h = SFP.db.history
    h.items, h.by = h.items or {}, h.by or {}
    return h
end

local function allVisuals()
    local list = {}
    for cat = 1, 30 do
        local ok, vis = pcall(TC.GetCategoryAppearances, cat)
        if ok and type(vis) == "table" then
            for _, v in ipairs(vis) do
                if v and v.isCollected and v.visualID then list[#list + 1] = v.visualID end
            end
        end
    end
    return list
end

local function readSource(h, sourceID)
    local ok, info = pcall(TC.GetSourceInfo, sourceID)
    if not ok or type(info) ~= "table" or not info.isCollected or not info.itemID then return end
    h.items[info.itemID] = true
    local ok2, drops = pcall(TC.GetAppearanceSourceDrops, sourceID)
    if not ok2 or type(drops) ~= "table" then return end
    for _, d in ipairs(drops) do
        local name = d.encounter
        if type(name) == "string" and not secret(name) and name ~= "" then
            local key = name:lower()
            local rec = h.by[key]
            if not rec then rec = { n = name, c = 0, ids = {} }; h.by[key] = rec end
            if type(d.instance) == "string" and not secret(d.instance) then rec.i = d.instance end
            if not rec.ids[info.itemID] then rec.ids[info.itemID] = true; rec.c = rec.c + 1 end
        end
    end
end

function SFP:ScanTransmogHistory(force)
    if running or not (TC and TC.GetCategoryAppearances and TC.GetAllAppearanceSources and TC.GetSourceInfo) then return end
    if not self.db then return end
    local h = hist()
    if not force and h.t and (time() - h.t) < RESCAN_DAYS * 86400 then return end
    running = true
    local visuals = allVisuals()
    local i, total = 1, #visuals
    local function step()
        if InCombatLockdown() then C_Timer.After(5, step); return end
        local stop = math.min(total, i + CHUNK - 1)
        while i <= stop do
            local ok, sources = pcall(TC.GetAllAppearanceSources, visuals[i])
            if ok and type(sources) == "table" then
                for _, sid in ipairs(sources) do readSource(h, sid) end
            end
            i = i + 1
        end
        if i <= total then
            C_Timer.After(STEP_DELAY, step)
        else
            h.t, h.visuals = time(), total
            running = false
            local n = 0
            for _ in pairs(h.by) do n = n + 1 end
            if SFP.db.historyReport then SFP:Print(("Transmog history read: %d appearances, %d monsters and bosses with gear you own."):format(total, n)) end
        end
    end
    step()
end

-- how many items you own the appearance of that this monster or boss drops (nil when none known)
function SFP:HistoryFor(name)
    local h = self.db and self.db.history
    if not (h and h.by) or type(name) ~= "string" or secret(name) then return nil end
    local rec = h.by[name:lower()]
    return rec and rec.c > 0 and rec or nil
end

SFP:OnLogin(function()
    -- wait until the game is settled, then read in the background
    C_Timer.After(40, function() SFP:Safe("transmog history", SFP.ScanTransmogHistory, SFP) end)
end)

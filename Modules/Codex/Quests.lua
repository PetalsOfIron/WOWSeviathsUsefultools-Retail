-- Seviath's Codex — quest helper: how to do it, where to go, who to turn in to
--
-- Sources, all from your own game:
--  • live objectives + map waypoints for quests in your log
--  • quest givers / turn-in NPCs recorded when you talk to them
--  • objective spots recorded where your quest progress goes up (kills, loot)
-- Everything is saved account-wide, so alts and later playthroughs benefit.

local ADDON, ns = SFP_Module("Codex")
local C = ns.CYAN

local function secret(v) return issecretvalue and issecretvalue(v) end

local function PlayerSpot()
    local m = C_Map.GetBestMapForUnit("player")
    if not m then return nil end
    local pos = C_Map.GetPlayerMapPosition(m, "player")
    if not pos or secret(pos.x) then return nil end
    return m, pos.x, pos.y
end

local function Loc(qid)
    ns.db.qloc = ns.db.qloc or {}
    local l = ns.db.qloc[qid]
    if not l then l = {}; ns.db.qloc[qid] = l end
    return l
end

local function NpcName()
    if not UnitExists("questnpc") then return nil end
    local n = UnitName("questnpc")
    if not n or secret(n) then return nil end
    return n
end

------------------------------------------------------------------------
-- Recording
------------------------------------------------------------------------
local pendingGiver = {}   -- [questID] = {n,m,x,y} seen in the quest dialog
local lastProgress = {}   -- [questID] = number fulfilled

local function ObjectiveProgress(qid)
    local objs = C_QuestLog.GetQuestObjectives(qid)
    if not objs then return nil end
    local sum = 0
    for _, o in ipairs(objs) do
        if o.numFulfilled and not secret(o.numFulfilled) then sum = sum + o.numFulfilled end
    end
    return sum
end

-- a saved objective spot without an area name gets the text of the minimap's zone line ("Zeb'Alar Lumbermill") when you are near it
function ns:LearnQuestAreas(qid)
    local ql0 = ns.db and ns.db.qloc and ns.db.qloc[qid]
    if not (ql0 and ql0.o) then return end
    local m0, x0, y0 = PlayerSpot()
    if not m0 then return end
    for _, sp in ipairs(ql0.o) do
        if not sp.a and sp.m == m0 and sp.x and sp.y and math.abs(sp.x - x0) < 0.06 and math.abs(sp.y - y0) < 0.06 then
            local okZ, zt = pcall(GetMinimapZoneText)
            if okZ and type(zt) == "string" and not secret(zt) and zt ~= "" then sp.a = zt end
        end
    end
end

-- one quest of the log (or a tracked world quest): its objective spots get their area name, and a spot is recorded where its progress went up
local function scanOne(qid)
    -- a saved objective spot without an area name gets it when you stand near it (the minimap's zone text, "Zeb'Alar Lumbermill")
    local ql0 = ns.db.qloc and ns.db.qloc[qid]
    if ql0 and ql0.o then
        local m0, x0, y0 = PlayerSpot()
        if m0 then
            for _, sp in ipairs(ql0.o) do
                if not sp.a and sp.m == m0 and sp.x and sp.y and math.abs(sp.x - x0) < 0.025 and math.abs(sp.y - y0) < 0.025 then
                    local okZ, zt = pcall(GetMinimapZoneText)
                    if okZ and type(zt) == "string" and not secret(zt) and zt ~= "" then sp.a = zt end
                end
            end
        end
    end
    -- progress went up here -> remember this spot as an objective area
    local prog = ObjectiveProgress(qid)
    if prog and lastProgress[qid] and prog > lastProgress[qid] then
        local m, x, y = PlayerSpot()
        if m then
            local l = Loc(qid)
            l.o = l.o or {}
            -- the area name is what the minimap's zone text says here ("Zeb'Alar Lumbermill"), saved with the spot
            local okA, area = pcall(GetMinimapZoneText)
            if not okA or type(area) ~= "string" or secret(area) or area == "" then area = nil end
            -- a spot is added only when it is a different place: not within a short distance of one already saved, and not in the
            -- same area; a new place (another item or monster of the same quest) is listed under the first
            local dup = false
            for _, sp in ipairs(l.o) do
                if sp.m == m and sp.x and sp.y and math.abs(sp.x - x) < 0.02 and math.abs(sp.y - y) < 0.02 then dup = true break end
                if area and sp.a == area and sp.m == m then dup = true break end
            end
            if not dup and #l.o < 5 then l.o[#l.o + 1] = { m = m, x = x, y = y, a = area } end
        end
    end
    lastProgress[qid] = prog
end

local function ScanLog()
    if not ns.db or InCombatLockdown() then return end
    local modern = C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo
    local n = modern and C_QuestLog.GetNumQuestLogEntries() or (GetNumQuestLogEntries and (GetNumQuestLogEntries())) or 0
    for i = 1, n do
        local info
        if modern then
            info = C_QuestLog.GetInfo(i)
        elseif GetQuestLogTitle then
            local _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
            info = { isHeader = isHeader, questID = questID }
        end
        if info and info.questID and not info.isHeader then
            local qid = info.questID
            scanOne(qid)
        end
    end
    -- world quests you track or are in the area of are not always in the quest log: they are read the same way
    if C_QuestLog.GetNumWorldQuestWatches and C_QuestLog.GetQuestIDForWorldQuestWatchIndex then
        for i = 1, (C_QuestLog.GetNumWorldQuestWatches() or 0) do
            local wq = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
            if type(wq) == "number" and wq > 0 then scanOne(wq) end
        end
    end
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "QUEST_DETAIL")
pcall(ev.RegisterEvent, ev, "QUEST_ACCEPTED")
pcall(ev.RegisterEvent, ev, "QUEST_COMPLETE")
pcall(ev.RegisterEvent, ev, "QUEST_LOG_UPDATE")
local logPending = false
ev:SetScript("OnEvent", function(_, event, arg1)
    if not ns.db then return end
    if event == "QUEST_DETAIL" then
        local qid = GetQuestID and GetQuestID()
        local name = NpcName()
        local m, x, y = PlayerSpot()
        if qid and qid > 0 and m then pendingGiver[qid] = { n = name, m = m, x = x, y = y } end
    elseif event == "QUEST_ACCEPTED" then
        local qid = arg1
        local g = qid and pendingGiver[qid]
        if g then Loc(qid).g = g; pendingGiver[qid] = nil end
        if qid then lastProgress[qid] = ObjectiveProgress(qid) end
    elseif event == "QUEST_COMPLETE" then
        local qid = GetQuestID and GetQuestID()
        local m, x, y = PlayerSpot()
        if qid and qid > 0 and m then
            Loc(qid).t = { n = NpcName(), m = m, x = x, y = y }
        end
    elseif event == "QUEST_LOG_UPDATE" then
        if logPending then return end
        logPending = true
        C_Timer.After(0.5, function() logPending = false; pcall(ScanLog) end)
    end
end)

------------------------------------------------------------------------
-- Reading it back for a quest page
------------------------------------------------------------------------
local function spot(p)
    if not p then return nil end
    return ("%s%s"):format(p.n and (p.n .. " — ") or "", ns:Coords(p))
end

-- Live objectives if the quest is in your log, else re-read the quest
-- (fixes names that weren't loaded during the scan, like "10 x").
function ns:QuestObjectives(e)
    local objs = C_QuestLog.GetQuestObjectives(e.id)
    if objs and #objs > 0 then
        local lines = {}
        for _, o in ipairs(objs) do
            if o.text and o.text ~= "" and not secret(o.text) then
                lines[#lines + 1] = (o.finished and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t " or "• ") .. o.text
            end
        end
        if #lines > 0 then return table.concat(lines, "\n") end
    end
    local text = e.objectives or ""
    local broken = text == "" or text:find(" x\n") or text:find(" x$") or text:find("%- %d+ x")
    if broken and ns.ReadQuestRaw then
        local rec = ns.ReadQuestRaw(e.id)
        if rec and rec.o and rec.o ~= "" and rec.o ~= text then
            e.objectives = rec.o
            if ns.db.quests and ns.db.quests[e.id] then ns.db.quests[e.id].o = rec.o end
            return rec.o
        end
        C_QuestLog.RequestLoadQuestByID(e.id)
        e._qtries = (e._qtries or 0) + 1
        if e._qtries <= 3 then
            C_Timer.After(0.8, function()
                if ns.state and ns.state.selected == e.key then ns:ShowEntry(e.key, true) end
            end)
        end
    end
    return text ~= "" and text or nil
end

-- the first objective you have not finished yet (nil when the quest is not in your log or all is done)
function ns:QuestNextObjective(e)
    local objs = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(e.id)
    for _, o in ipairs(objs or {}) do
        if o.text and o.text ~= "" and not secret(o.text) and not o.finished then return o.text end
    end
end

-- what the game itself says about the quest (story + instructions), only while it is in your log
function ns:QuestStory(e)
    local idx = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(e.id)
    if not idx then return nil end
    local fn = (C_QuestLog and C_QuestLog.GetQuestLogQuestText) or GetQuestLogQuestText
    if not fn then return nil end
    local ok, desc = pcall(fn, idx)
    if not ok or type(desc) ~= "string" or secret(desc) or desc == "" then return nil end
    desc = desc:gsub("%$[bB]", "\n"):gsub("<[^>]*>", "")
    if #desc > 700 then desc = desc:sub(1, 700):gsub("%s+%S*$", "") .. " ..." end
    return desc
end

-- "How to do it": practical steps by objective type. Judged by the objective you do NEXT when known,
-- so a finished "speak to ..." step does not bury the advice for the step in front of you.
function ns:QuestHowTo(e, objText, nextText)
    local t = (nextText or objText or ""):lower()
    local steps = {}
    local function add(s) steps[#steps + 1] = "• " .. s end
    if nextText then add("Next step: " .. nextText) end
    if e.worldQuest then
        add("World quest: no pick-up needed — fly into the area and it starts by itself.")
    end
    local trail = t:find("follow the") and (t:find("trail") or t:find("path") or t:find("track") or t:find("footprint")
        or t:find("flower") or t:find("light") or t:find("marker") or t:find("glow") or t:find("road") or t:find("stream")
        or t:find("petal") or t:find("wisp"))
    if trail then
        add("Follow the trail: walk along the glowing trail on the ground (it also shows on your minimap and map as a path of dots). The objective completes when you reach the end — nothing to kill or click.")
    end
    if t:find("slain") or t:find("kill") or t:find("defeat") or t:find("slay") or t:find("destroy") then
        add("Kill quest: the enemies are in the highlighted area on your map (M) while the quest is in your log. Kills count for everyone in your party who has the quest.")
    end
    if t:find("collect") or t:find("gather") or t:find("obtain") or t:find("recover") or t:find("%d+ x ") then
        add("Collect quest: items drop from the enemies in the quest area, or are glowing objects you click on the ground. Quest items only drop while you have the quest.")
    end
    if t:find("use ") or t:find("place") or t:find("plant") or t:find("throw") or t:find("ignite") then
        add("Use-item quest: use the quest item from the button next to the quest in the objective tracker (right side of the screen), standing near the target.")
    end
    if t:find("speak") or t:find("talk") or t:find("report to") or t:find("return to") then
        add("Talk / report: go to the named NPC and talk to them — the map shows a ? or ! where they are once the quest is in your log.")
    end
    if t:find("escort") or t:find("protect") or t:find("accompany") then
        add("Escort: stay close and kill attackers. If the NPC dies, abandon the quest and pick it up again to restart.")
    elseif t:find("follow") and not trail then
        add("Follow: stay close behind the named character while they walk to the destination; the objective completes on arrival.")
    end
    if t:find("explore") or t:find("investigate") or t:find("scout") or t:find("find") or t:find("locate") then
        add("Explore: walk into the marked area until the objective completes.")
    end
    if t:find("bring") or t:find("deliver") or t:find("take ") then
        add("Delivery: carry the item to the named person or place; it's already in your bags.")
    end
    local tag = (e.tag or ""):lower()
    if tag:find("elite") or tag:find("group") then
        add("Elite / group quest: enemies are stronger — bring a friend, or come back a few levels later.")
    elseif tag:find("dungeon") or tag:find("raid") then
        add("Instance quest: the objectives are inside a " .. (tag:find("raid") and "raid" or "dungeon") .. " — check the Entrances section for the way in.")
    end
    if #steps == 0 then
        add("Pick up the quest, then follow the highlighted area on your map and the tracker on the right.")
    end
    return table.concat(steps, "\n")
end

-- Where to go: giver, objective area, turn-in. Also picks what Show on map points to.
function ns:QuestWhere(e)
    local l = (ns.db.qloc and ns.db.qloc[e.id]) or {}
    local lines = {}
    local inLog = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(e.id)
    local complete = inLog and C_QuestLog.IsComplete(e.id)
    local target

    -- live waypoint for quests you have
    if inLog and C_QuestLog.GetNextWaypoint then
        local m, x, y = C_QuestLog.GetNextWaypoint(e.id)
        if m and x and y then
            target = { m = m, x = x, y = y }
            lines[#lines + 1] = (complete and "Ready to turn in — go to: " or "Next step: ") .. ns:Coords(target)
        end
    end
    -- world quests
    if not target and C_TaskQuest and C_TaskQuest.GetQuestZoneID then
        local m = C_TaskQuest.GetQuestZoneID(e.id)
        if m and C_TaskQuest.GetQuestLocation then
            local x, y = C_TaskQuest.GetQuestLocation(e.id, m)
            if x and y then
                target = { m = m, x = x, y = y }
                lines[#lines + 1] = "World quest area: " .. ns:Coords(target)
            end
        end
    end

    if l.g then lines[#lines + 1] = "Quest giver: " .. spot(l.g) end
    if l.o then
        for i, p in ipairs(l.o) do
            lines[#lines + 1] = (i == 1 and "Objectives (kills / items) here: " or "     also: ") .. ns:Coords(p)
        end
    end
    if l.t then lines[#lines + 1] = "Turn in to: " .. spot(l.t) end

    if not target then
        if complete and l.t then target = l.t
        elseif inLog and l.o then target = l.o[1]
        elseif not inLog and not e.collected and l.g then target = l.g
        else target = l.t or (l.o and l.o[1]) or l.g end
    end
    e.map = target and { m = target.m, x = target.x, y = target.y } or nil

    if #lines == 0 then
        lines[1] = "|cff888888Not known yet. The Codex learns the giver, the objective area and the turn-in the first time any of your characters does this quest. Until then use the Wowhead link.|r"
    elseif inLog then
        lines[#lines + 1] = "|cff888888This quest is in your log — the map (M) highlights the area too.|r"
    end
    return table.concat(lines, "\n")
end

------------------------------------------------------------------------
-- World quests: where they are, recorded when they show up on the map you look at (or the zone you are in), without having to take them
------------------------------------------------------------------------
local wqSeen = {}   -- [mapID] = number of world quests already recorded for that map this session
local function RecordWorldQuests(mapID)
    if not (ns.db and mapID and C_TaskQuest and C_TaskQuest.GetQuestsOnMap) then return end
    local okQ, list = pcall(C_TaskQuest.GetQuestsOnMap, mapID)
    if not okQ or type(list) ~= "table" then return end
    if wqSeen[mapID] == #list then return end
    wqSeen[mapID] = #list
    for _, q in ipairs(list) do
        local qid = q.questId or q.questID
        local x, y = q.x, q.y
        if type(qid) == "number" and type(x) == "number" and type(y) == "number" and not secret(x) and not secret(y) then
            local l = Loc(qid)
            l.o = l.o or {}
            local dup = false
            for _, sp in ipairs(l.o) do
                if sp.m == mapID and sp.x and sp.y and math.abs(sp.x - x) < 0.02 and math.abs(sp.y - y) < 0.02 then dup = true break end
            end
            if not dup and #l.o < 5 then
                local area
                if C_Map and C_Map.GetMapInfoAtPosition then
                    local okA, info = pcall(C_Map.GetMapInfoAtPosition, mapID, x, y)
                    if okA and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then area = info.name end
                end
                l.o[#l.o + 1] = { m = mapID, x = x, y = y, a = area }
                l.w = true   -- a world quest
            end
            -- the quest itself (title, objectives, kind) is saved too, when the game has it loaded (it is asked for first)
            if not ns.db.quests[qid] then
                if C_QuestLog.RequestLoadQuestByID then pcall(C_QuestLog.RequestLoadQuestByID, qid) end
                C_Timer.After(2, function()
                    if ns.db.quests[qid] then return end
                    local r = ns.ReadQuestRaw and ns.ReadQuestRaw(qid)
                    if r and r.t and r.t ~= "" then
                        r.w = true
                        ns.db.quests[qid] = r
                    end
                end)
            end
        end
    end
end

local wqFrame = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "QUEST_LOG_UPDATE" }) do pcall(wqFrame.RegisterEvent, wqFrame, e) end
local wqPending = false
wqFrame:SetScript("OnEvent", function()
    if wqPending then return end
    wqPending = true
    C_Timer.After(3, function()
        wqPending = false
        local m = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        if m then pcall(RecordWorldQuests, m) end
    end)
end)

-- the world map: the world quests of the map you are looking at are recorded when it changes (opened, another zone clicked)
local wqHooked = false
local function hookWorldMap()
    if wqHooked or not (_G.WorldMapFrame and WorldMapFrame.HookScript) then return end
    wqHooked = true
    local function onMap()
        local m = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
        if m then C_Timer.After(0.5, function() pcall(RecordWorldQuests, m) end) end
    end
    WorldMapFrame:HookScript("OnShow", onMap)
    if hooksecurefunc and WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", onMap) end
end
hookWorldMap()
local wqLoad = CreateFrame("Frame")
wqLoad:RegisterEvent("ADDON_LOADED")
wqLoad:SetScript("OnEvent", function(_, _, name) if name == "Blizzard_WorldMap" then hookWorldMap() end end)

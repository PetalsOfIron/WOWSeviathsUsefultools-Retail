-- Seviath's Codex — open quests and items in the Codex from anywhere
--
--  • Quest log / objective tracker: Alt+click a quest, or press the "Codex"
--    button on the quest details page.
--  • Items (bags, bank, chat links, loot, vendors, Auction House…): Alt+click.
--  • Chat quest/item links: Alt+click.
--  • /codex quest <id or name>   /codex item <link or id>

local ADDON, ns = SFP_Module("Codex")

------------------------------------------------------------------------
-- open helpers
------------------------------------------------------------------------
function ns:OpenQuest(questID)
    if not questID or questID == 0 then return end
    self:StartIndexing("quest")
    local key = "quest:" .. questID
    if not self:Get(key) then
        -- not scanned yet: build it now
        local rec = self.ReadQuestRaw and self.ReadQuestRaw(questID)
        if not rec then
            local title = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
            if title then rec = { t = title, o = "" } end
        end
        if rec then
            self.db.quests = self.db.quests or {}
            self.db.quests[questID] = self.db.quests[questID] or rec
            self.AddQuestEntry(questID, rec)
        end
    end
    if self:Get(key) then
        self:Open()
        self:ShowEntry(key)
    else
        if C_QuestLog.RequestLoadQuestByID then C_QuestLog.RequestLoadQuestByID(questID) end
        self:Print("loading that quest — try again in a second.")
    end
end

function ns:OpenItem(itemID, linkName)
    if not itemID then return end
    self:StartIndexing("item")
    local key = "item:" .. itemID
    if not self:Get(key) then
        if self.RecordItem then self.RecordItem(itemID) end
    end
    if not self:Get(key) then
        -- not cached yet: create it anyway, the name fills in when it loads
        local name = C_Item.GetItemNameByID(itemID) or linkName or ("item " .. itemID)
        local _, itemType = C_Item.GetItemInfoInstant(itemID)
        self:Add({
            cat = "item", id = itemID, name = name, itemID = itemID,
            group = self:ItemGroupFor(itemID, itemType), sub = itemType or "",
            icon = C_Item.GetItemIconByID(itemID), wh = "item=" .. itemID,
        })
        if not C_Item.GetItemNameByID(itemID) then
            C_Item.RequestLoadItemDataByID(itemID)
            C_Timer.After(0.6, function()
                local e = ns:Get(key)
                local n = C_Item.GetItemNameByID(itemID)
                if e and n then
                    e.name = n; e.lname = n:lower()
                    ns.db.items = ns.db.items or {}
                    ns.db.items[itemID] = ns.db.items[itemID] or { n = n, t = e.sub }
                    if ns.state and ns.state.selected == key then ns:ShowEntry(key, true) end
                end
            end)
        end
    end
    if self.MaybeMaterial then self:MaybeMaterial(itemID) end
    self:Open()
    self:ShowEntry(key)
end

local function ItemIDFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)")), link:match("|h%[(.-)%]|h")
end

local function PetFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("battlepet:(%d+)"))
end

------------------------------------------------------------------------
-- Alt+click items anywhere (Blizzard routes modified item clicks here)
------------------------------------------------------------------------
if HandleModifiedItemClick then
    hooksecurefunc("HandleModifiedItemClick", function(link)
        if IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown() then
            local id, name = ItemIDFromLink(link)
            if id then ns:OpenItem(id, name); return end
            local pet = PetFromLink(link)
            if pet and ns:Get("pet:" .. pet) then ns:Open(); ns:ShowEntry("pet:" .. pet) end
        end
    end)
end

-- Alt+click chat links (quests and items)
if SetItemRef then
    hooksecurefunc("SetItemRef", function(link)
        if not IsAltKeyDown() or type(link) ~= "string" then return end
        local qid = tonumber(link:match("^quest:(%d+)"))
        if qid then ns:OpenQuest(qid); return end
        local iid = tonumber(link:match("^item:(%d+)"))
        if iid then ns:OpenItem(iid); return end
        local pet = tonumber(link:match("^battlepet:(%d+)"))
        if pet and ns:Get("pet:" .. pet) then ns:Open(); ns:ShowEntry("pet:" .. pet) end
    end)
end

------------------------------------------------------------------------
-- Quest log + objective tracker
------------------------------------------------------------------------
-- Clicking a quest in the log or tracker opens its details through this.
for _, fname in ipairs({ "QuestMapFrame_OpenToQuestDetails", "QuestMapFrame_ShowQuestDetails" }) do
    if _G[fname] then
        hooksecurefunc(fname, function(questID)
            if IsAltKeyDown() then ns:OpenQuest(questID) end
        end)
    end
end

-- A "Codex" button on the quest details page
local function AddDetailsButton()
    local details = QuestMapFrame and QuestMapFrame.DetailsFrame
    if not details or details.SeviathsCodexButton then return end
    local b = CreateFrame("Button", nil, details, "UIPanelButtonTemplate")
    b:SetSize(70, 22)
    b:SetText("Codex")
    b:SetPoint("TOPRIGHT", details, "TOPRIGHT", -8, -6)
    b:SetFrameLevel(details:GetFrameLevel() + 20)
    b:SetScript("OnClick", function()
        local qid = (C_QuestLog.GetSelectedQuest and C_QuestLog.GetSelectedQuest()) or details.questID
        ns:OpenQuest(qid)
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cff33e6ffSeviath's|r Codex")
        GameTooltip:AddLine("Open this quest: what to do, how, and where.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    details.SeviathsCodexButton = b
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "ADDON_LOADED")
ev:SetScript("OnEvent", function()
    pcall(AddDetailsButton)
end)

------------------------------------------------------------------------
-- Hover a quest (quest log or objective tracker): what to do next and how
------------------------------------------------------------------------
local hoverOwner
-- our block is written once per tooltip: the flag is cleared when the tooltip is cleared for the next one
pcall(function() GameTooltip:HookScript("OnTooltipCleared", function(tt) tt.SeviathsQuestBlock = nil end) end)
local function QuestHoverTip(owner, questID)
    if not owner or type(questID) ~= "number" or questID <= 0 then return end
    if GameTooltip.SeviathsQuestBlock and GameTooltip:IsShown() and GameTooltip:GetOwner() == owner then return end
    if ns.db and ns.db.hideHint then return end
    pcall(function()
        local e = { id = questID, worldQuest = C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) or nil }
        local complete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID)
        local nextObj = ns:QuestNextObjective(e)
        local lines = {}
        if complete then
            lines[#lines + 1] = "Done - go and turn it in."
        elseif nextObj then
            lines[#lines + 1] = "Next: " .. nextObj
            -- every other objective that is not done yet is listed under it (all of them are shown, also when they are in the same place)
            local okAll, allObjs = pcall(C_QuestLog.GetQuestObjectives, questID)
            if okAll and type(allObjs) == "table" then
                local seenText = { [nextObj] = true }
                for _, o in ipairs(allObjs) do
                    local t = o.text
                    if type(t) == "string" and t ~= "" and not o.finished and not seenText[t] then
                        seenText[t] = true
                        lines[#lines + 1] = "Also: " .. t
                    end
                end
            end
        end
        if not complete then
            for raw in (ns:QuestHowTo(e, nil, nextObj) or ""):gmatch("[^\n]+") do
                local tip = raw:gsub("^•%s*", "")
                if not tip:find("^Next step:") then lines[#lines + 1] = tip end
            end
        end
        -- where to go, by how far the quest is: the places of the objectives (items, kills) and then the NPC to speak with, each with its
        -- coordinates; a finished quest shows the NPC to hand it in to. Only a quest with none of that known shows the first place line.
        if ns.LearnQuestAreas then ns:LearnQuestAreas(questID) end
        local ql = ns.db and ns.db.qloc and ns.db.qloc[questID] or {}
        -- the name of the area at a spot (the sub-area the map shows, e.g. "Temple of Halazzi"), else the zone
        local function areaName(p)
            if not (p and p.m) then return nil end
            if C_Map and C_Map.GetMapInfoAtPosition and p.x and p.y then
                local okA, info = pcall(C_Map.GetMapInfoAtPosition, p.m, p.x, p.y)
                if okA and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then return info.name end
            end
            local okM, mi = pcall(C_Map.GetMapInfo, p.m)
            return okM and mi and mi.name or nil
        end
        local function placeText(p)
            local a = p.a or areaName(p)   -- the minimap's zone text saved with the spot, else the area the map shows there
            local xy = (p.x and p.y) and (" (" .. ("%.1f, %.1f"):format(p.x * 100, p.y * 100) .. ")") or ""
            return (a or "") .. xy
        end
        -- "<place> - <NPC name>", like the vendor lines of items
        local function spotText(p) return placeText(p) .. (p.n and (" - " .. p.n) or "") end
        -- what the next objective asks for decides the words: an item is picked up, a monster is killed
        local objLabel = "Objective at"
        local okO, objs = pcall(C_QuestLog.GetQuestObjectives, questID)
        if okO and type(objs) == "table" then
            for _, o in ipairs(objs) do
                if not o.finished then
                    -- the words come from what the objective says, not only from its type (the game calls many tasks "monster")
                    local txt = tostring(o.text or ""):lower()
                    local kill = txt:find("slain", 1, true) or txt:find("killed", 1, true) or txt:find("defeated", 1, true)
                        or txt:find("kill ", 1, true) or txt:find("destroyed", 1, true)
                    local pick = txt:find("collect", 1, true) or txt:find("gather", 1, true) or txt:find("pick", 1, true)
                        or txt:find("loot", 1, true) or txt:find("retriev", 1, true) or txt:find("recover", 1, true)
                    if kill then objLabel = "Kill at"
                    elseif o.type == "item" or pick then objLabel = "Pick up at"
                    elseif o.type == "object" then objLabel = "Use at"
                    else objLabel = "Objective at" end
                    break
                end
            end
        end
        local added = false
        if not complete and ql.o then
            -- one line for a place: spots in the same area are said once
            local seenPlace = {}
            local shown = 0
            for _, p in ipairs(ql.o) do
                local text = placeText(p)
                local area = p.a or areaName(p) or text
                if not seenPlace[area] and shown < 5 then
                    seenPlace[area] = true
                    shown = shown + 1
                    lines[#lines + 1] = (shown == 1 and (objLabel .. ": ") or "also: ") .. text
                    added = true
                end
            end
        end
        -- the people of the quest: who gave it and who takes it back (one line when it is the same person at the same place)
        -- every quest giver and every hand-in NPC is listed (a quest can be given at more than one place), each once
        local givers = ql.gs or (ql.g and { ql.g }) or {}
        local takers = ql.ts or (ql.t and { ql.t }) or {}
        local function samePerson(a, c)
            return a.n and c.n and a.n == c.n and a.m == c.m and a.x and c.x and math.abs(a.x - c.x) < 0.01 and math.abs(a.y - c.y) < 0.01
        end
        local doneKey = {}
        for _, g in ipairs(givers) do
            local both = false
            for _, t in ipairs(takers) do if samePerson(g, t) then both = true doneKey[t] = true break end end
            lines[#lines + 1] = (both and "Quest giver and hand-in at: " or "Quest giver at: ") .. spotText(g)
            added = true
        end
        for _, t in ipairs(takers) do
            if not doneKey[t] then
                lines[#lines + 1] = (complete and "Hand in at: " or "Then hand in at: ") .. spotText(t)
                added = true
            end
        end
        if not added then
            local where = (ns:QuestWhere(e) or ""):match("[^\n]+")
            if where and not where:find("Not known yet") then lines[#lines + 1] = where end
        end
        if #lines == 0 then return end
        if GameTooltip:IsShown() and GameTooltip:GetOwner() == owner then
            GameTooltip:AddLine(" ")
        else
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        end
        GameTooltip:AddLine("|cff33e6ffSeviath's Codex|r - what to do")
        for _, l in ipairs(lines) do GameTooltip:AddLine(l, 1, 1, 1, true) end
        GameTooltip:AddLine("|cff33e6ffAlt+click: open in Codex|r")
        GameTooltip:Show()
        GameTooltip.SeviathsQuestBlock = true
        hoverOwner = owner
    end)
end

-- the quest tooltip is rebuilt while it is shown when the quest's progress changes (an item picked up, a monster killed): the numbers in
-- "Next: 1/6 Stolen Equipment" follow the objective instead of staying as they were when the mouse arrived
local refreshFrame = CreateFrame("Frame")
for _, ev in ipairs({ "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED", "QUEST_WATCH_UPDATE", "BAG_UPDATE_DELAYED" }) do
    pcall(refreshFrame.RegisterEvent, refreshFrame, ev)
end
local lastRefresh = 0
refreshFrame:SetScript("OnEvent", function()
    if not hoverOwner or GetTime() - lastRefresh < 0.4 then return end
    local owner = hoverOwner
    if not (GameTooltip:IsShown() and GameTooltip:GetOwner() == owner and owner:IsShown() and owner:IsMouseOver()) then hoverOwner = nil return end
    lastRefresh = GetTime()
    C_Timer.After(0.3, function()
        if hoverOwner ~= owner or not owner:IsMouseOver() then return end
        local onEnter = owner.GetScript and owner:GetScript("OnEnter")
        if onEnter then
            GameTooltip:Hide()
            pcall(onEnter, owner)   -- the owner builds its tooltip again
            -- (the hook on the owner's OnEnter adds our lines; they are not added a second time here)
        end
    end)
end)

-- quest log entries in the map window
if _G.QuestMapLogTitleButton_OnEnter then
    hooksecurefunc("QuestMapLogTitleButton_OnEnter", function(self)
        QuestHoverTip(self, self.questID)
    end)
end

-- objective tracker blocks (the quest list on the right of the screen)
local function HookTrackerBlock(block)
    if type(block) ~= "table" or block.SeviathsQuestTip or not block.HookScript then return end
    block.SeviathsQuestTip = true
    block:HookScript("OnEnter", function(self) QuestHoverTip(self, self.id or self.questID) end)
    block:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function ScanTracker()
    for _, mname in ipairs({ "QuestObjectiveTracker", "CampaignQuestObjectiveTracker", "WorldQuestObjectiveTracker",
        "BonusObjectiveTracker" }) do
        local mod = _G[mname]
        if mod and type(mod.usedBlocks) == "table" then
            for _, byId in pairs(mod.usedBlocks) do
                if type(byId) == "table" then
                    for _, block in pairs(byId) do HookTrackerBlock(block) end
                end
            end
        end
    end
end
C_Timer.NewTicker(3, function() pcall(ScanTracker) end)

------------------------------------------------------------------------
-- Tooltip hint on items
------------------------------------------------------------------------
-- Registered a few seconds after login, so this hint is the LAST tooltip block to run: the game calls the item tooltip hooks in the order
-- they were registered, and the hint must come after the prices and the Seviaths lines. (Adding it a frame later made the tooltip
-- change size again and again, because the game refreshes a tooltip all the time.)
local function RegisterItemHint()
    if not (TooltipDataProcessor and Enum.TooltipDataType) then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
        if tt ~= GameTooltip or not data or not data.id or InCombatLockdown() then return end
        if ns.db and ns.db.hideHint then return end
        tt:AddLine("|cff33e6ffAlt+click: open in Codex|r")
    end)
end
local hintFrame = CreateFrame("Frame")
hintFrame:RegisterEvent("PLAYER_LOGIN")
hintFrame:SetScript("OnEvent", function() C_Timer.After(8, RegisterItemHint) end)

------------------------------------------------------------------------
-- Slash: /codex quest …  /codex item …   (hooked into the main command)
------------------------------------------------------------------------
local base = SlashCmdList.SEVIATHSCODEX
SlashCmdList.SEVIATHSCODEX = function(msg)
    msg = msg or ""
    local kind, rest = msg:match("^%s*(%a+)%s+(.+)$")
    if kind == "quest" then
        local id = tonumber(rest)
        if id then ns:OpenQuest(id) return end
        ns:StartIndexing("all"); ns:Toggle(rest); return
    elseif kind == "item" then
        local id = ItemIDFromLink(rest) or tonumber(rest)
        if id then ns:OpenItem(id) return end
        ns:StartIndexing("all"); ns:Toggle(rest); return
    elseif msg:match("^%s*hint%s*$") then
        ns.db.hideHint = not ns.db.hideHint
        ns:Print("tooltip hints (items and quests) " .. (ns.db.hideHint and "off" or "on"))
        return
    end
    return base(msg)
end

-- keep the Best Grinding Spots ranking current: recalculated when the Codex opens (at most every 20 s)
do
    local open = ns.Open
    if open then
        ns.Open = function(self, ...)
            if self.RefreshGrind then pcall(self.RefreshGrind, self) end
            if self.RefreshHistory then pcall(self.RefreshHistory, self) end
            return open(self, ...)
        end
    end
end

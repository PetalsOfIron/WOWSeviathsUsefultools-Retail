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
    self:StartIndexing()
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
    self:StartIndexing()
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
local function QuestHoverTip(owner, questID)
    if not owner or type(questID) ~= "number" or questID <= 0 then return end
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
        end
        if not complete then
            for raw in (ns:QuestHowTo(e, nil, nextObj) or ""):gmatch("[^\n]+") do
                local tip = raw:gsub("^•%s*", "")
                if not tip:find("^Next step:") then lines[#lines + 1] = tip end
            end
        end
        local where = (ns:QuestWhere(e) or ""):match("[^\n]+")
        if where and not where:find("Not known yet") then lines[#lines + 1] = where end
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
    end)
end

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
        ns:StartIndexing(); ns:Toggle(rest); return
    elseif kind == "item" then
        local id = ItemIDFromLink(rest) or tonumber(rest)
        if id then ns:OpenItem(id) return end
        ns:StartIndexing(); ns:Toggle(rest); return
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

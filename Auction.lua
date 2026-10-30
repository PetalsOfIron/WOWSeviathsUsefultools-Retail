-- SeviathsUsefulTools - auction house prices
-- The first time you open the auction house (and again when prices are older
-- than db.rescanHours) every tracked item is looked up once, throttled, and the
-- cheapest unit price is saved. /sfp scan forces a new scan.

local _, SFP = ...

local queue, qIndex = {}, 0
local scanning, waitingFor, waitTimer = false, nil, nil
local ahOpen = false

-- what the scan bar on the auction house window shows (AuctionBar.lua draws it)
local function setProgress(phase, done, total)
    local old = SFP.scanState
    SFP.scanState = { phase = phase, done = done or 0, total = total or 0,
        t0 = (phase == "wait" and GetTime()) or (old and old.t0) or GetTime(), t = GetTime() }
    if SFP.UpdateScanBar then SFP:UpdateScanBar() end
end

local function buildQueue()
    wipe(queue)
    -- one-by-one search is slow (the game throttles it): only the farm items themselves, never every item ever seen
    for id in pairs(SFP.trackedIDs) do
        if SFP.RETAIL == nil or SFP.Items[id] then queue[#queue + 1] = id end
    end
    table.sort(queue)
    qIndex = 0
end

local function savePrice(itemID, copper)
    if not itemID then return end
    SFP:StorePrice(itemID, copper)
end

local function markScanned()
    local t = time()
    SFP.db.lastScan = t
    SFP.db.realmScan = SFP.db.realmScan or {}
    SFP.db.realmScan[SFP:RealmKey()] = t
end

local step  -- forward declared

local function finishItem()
    if waitTimer then waitTimer:Cancel(); waitTimer = nil end
    waitingFor = nil
    C_Timer.After(0, step)
end

step = function()
    if not scanning then return end
    if not ahOpen then
        scanning = false
        setProgress("idle")
        SFP:Print(string.format("Price scan paused at %d/%d - it continues next time you open the auction house.", qIndex, #queue))
        SFP:RefreshAll()
        return
    end
    if C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady() then
        return -- AUCTION_HOUSE_THROTTLED_SYSTEM_READY resumes us
    end
    qIndex = qIndex + 1
    local id = queue[qIndex]
    if not id then
        scanning = false
        markScanned()
        setProgress("done", #queue, #queue)
        SFP:Print(string.format("Prices updated for %d items.", #queue))
        SFP:RefreshAll()
        return
    end
    waitingFor = id
    setProgress("items", qIndex, #queue)
    local key = C_AuctionHouse.MakeItemKey(id)
    local sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } }
    C_AuctionHouse.SendSearchQuery(key, sorts, true)
    -- nothing listed -> no result event; move on after a short wait
    waitTimer = C_Timer.NewTimer(0.6, finishItem)
    if qIndex % 25 == 0 then
        SFP:RefreshAll()
    end
end

-- full scan: the whole auction house in one request (like other addons), instead of one search per item
local fullWaiting, fullTimer, fullTick = false, nil, nil

local function processReplicate()
    local n = C_AuctionHouse.GetNumReplicateItems and C_AuctionHouse.GetNumReplicateItems() or 0
    local best, i, found, nextPct = {}, 0, 0, 25
    local function chunk()
        -- work for about 25 ms per frame instead of a fixed small batch: the same data is read much faster
        local t0 = debugprofilestop and debugprofilestop() or 0
        while i < n and (not debugprofilestop or debugprofilestop() - t0 < 25) do
            local name, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = C_AuctionHouse.GetReplicateItemInfo(i)
            i = i + 1
            if itemID and buyout and buyout > 0 and SFP.trackedIDs[itemID] then
                -- retail commodities are listed per unit already; single items and stacks are divided
                local unit = buyout
                local commodity = C_AuctionHouse.GetItemCommodityStatus and Enum.ItemCommodityStatus
                    and C_AuctionHouse.GetItemCommodityStatus(itemID) == Enum.ItemCommodityStatus.Commodity
                if not commodity and count and count > 1 then unit = math.floor(buyout / count) end
                if not best[itemID] or unit < best[itemID] then best[itemID] = unit end
            end
        end
        setProgress("read", i, n)
        if i < n then
            C_Timer.After(0, chunk)
        else
            for id, p in pairs(best) do savePrice(id, p); found = found + 1 end
            scanning = false
            markScanned()
            setProgress("done", n, n)
            SFP:Print(("Full auction scan done: %d auctions read, prices for %d items."):format(n, found))
            SFP:RefreshAll()
        end
    end
    chunk()
end

function SFP:TryFullScan()
    if not (C_AuctionHouse and C_AuctionHouse.ReplicateItems and C_AuctionHouse.GetReplicateItemInfo) then return false end
    local ok = pcall(C_AuctionHouse.ReplicateItems)
    if not ok then return false end
    fullWaiting, scanning = true, true
    setProgress("wait")
    self:Print("Scanning the auction house...")
    if fullTimer then fullTimer:Cancel() end
    -- no repeating chat messages: the bar at the auction house shows the progress
    fullTimer = C_Timer.NewTimer(25, function()
        if fullWaiting then
            -- no answer (scan cooldown?): fall back to searching the items one by one
            fullWaiting, scanning = false, false
            SFP:Print("No full scan answer - searching the items one by one.")
            SFP:StartScan(true, true)
        end
    end)
    return true
end

-- section scan, the way Auctionator does it: open each auction house category and read its price list
-- (browse results come in big batches with the lowest price per item), instead of one search per item
local catQueue, catIndex, catSeen, catBest, catTimer, catBusy = {}, 0, 0, {}, nil, false
local catLearned, catSeenIDs, catNewIDs = 0, {}, 0
local catNext

local function catFinish()
    if catTimer then catTimer:Cancel(); catTimer = nil end
    local found = 0
    for id, p in pairs(catBest) do savePrice(id, p); found = found + 1 end
    scanning, catBusy = false, false
    markScanned()
    setProgress("done", 1, 1)
    SFP:Print(("Auction scan done: prices for %d items%s."):format(found, (catNewIDs > 0 and (", " .. catNewIDs .. " new item IDs learned") or "") .. (catLearned > 0 and (", " .. catLearned .. " new materials") or "")))
    SFP:RefreshAll()
end

local function catRead()
    if not catBusy then return end
    local results = C_AuctionHouse.GetBrowseResults and C_AuctionHouse.GetBrowseResults() or {}
    for i = catSeen + 1, #results do
        local r = results[i]
        local id = r and r.itemKey and r.itemKey.itemID
        local price = r and r.minPrice
        -- every item ID seen at the auction house is kept (item ID -> item class), so the addon knows them all
        if id and SFP.db then
            SFP.db.ahItems = SFP.db.ahItems or {}
            if not SFP.db.ahItems[id] then
                local cls = C_Item and C_Item.GetItemInfoInstant and select(6, C_Item.GetItemInfoInstant(id))
                SFP.db.ahItems[id] = cls or 0
                catNewIDs = catNewIDs + 1
            end
        end
        -- the auction house also teaches the addon: trade goods it has not seen are added to the learned items (and become farm items)
        local tracked = id and SFP.trackedIDs[id]
        if id and not tracked and not (SFP.db.knownItems and SFP.db.knownItems[id]) and C_Item and C_Item.GetItemInfoInstant then
            local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(id)
            if classID == 7 and SFP.RecordItem then
                SFP.RecordItem(id)
                tracked = SFP.trackedIDs[id]
                catLearned = catLearned + 1
                catSeenIDs[id] = true
            end
        end
        if id and price and price > 0 and (tracked or catSeenIDs[id]) and (not catBest[id] or price < catBest[id]) then catBest[id] = price end
    end
    catSeen = #results
    if catTimer then catTimer:Cancel() end
    catTimer = C_Timer.NewTimer(6, function() catNext() end)
    SFP.db.scanLog = SFP.db.scanLog or {}
    SFP.db.scanLog[catQueue[catIndex] or 0] = #results   -- for diagnosis: results read per section
    if C_AuctionHouse.HasFullBrowseResults and C_AuctionHouse.HasFullBrowseResults() then
        catNext()
    elseif C_AuctionHouse.RequestMoreBrowseResults then
        C_AuctionHouse.RequestMoreBrowseResults()
    else
        catNext()
    end
end

local function catSend()
    if not catBusy then return end
    if C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady() then
        C_Timer.After(0.3, catSend)   -- the game limits how fast we may ask; try again in a moment
        return
    end
    local cid = catQueue[catIndex]
    catSeen = 0
    setProgress("section", catIndex, #catQueue)
    C_AuctionHouse.SendBrowseQuery({
        searchString = "", filters = {},
        sorts = { { sortOrder = Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0, reverseSort = false } },
        itemClassFilters = { { classID = cid } },
    })
    if catTimer then catTimer:Cancel() end
    catTimer = C_Timer.NewTimer(4, function() catNext() end)   -- an empty category sends no answer: go on
end

catNext = function()
    if catTimer then catTimer:Cancel(); catTimer = nil end
    catIndex = catIndex + 1
    if catIndex > #catQueue then catFinish(); return end
    catSend()
end

function SFP:StartCategoryScan()
    local AH = C_AuctionHouse
    if not (AH and AH.SendBrowseQuery and AH.GetBrowseResults and Enum and Enum.ItemClass) then return false end
    wipe(catQueue)
    local seen = {}
    -- the sections the auction house window shows on the left (the game's own category list)
    for _, cat in ipairs(_G.AuctionCategories or {}) do
        local f = cat.filters and cat.filters[1]
        local cid = f and f.classID
        if cid and not seen[cid] then seen[cid] = true; catQueue[#catQueue + 1] = cid end
    end
    -- fallback: every item class the game knows
    if #catQueue == 0 then
        local all = {}
        for _, v in pairs(Enum.ItemClass) do if type(v) == "number" then all[#all + 1] = v end end
        table.sort(all)
        for _, v in ipairs(all) do catQueue[#catQueue + 1] = v end
    end
    if #catQueue == 0 then return false end
    catIndex, catSeen, catBusy = 0, 0, true
    wipe(catBest)
    wipe(catSeenIDs)
    SFP.db.scanLog = {}
    catLearned = 0
    catNewIDs = 0
    scanning = true
    self:Print("Scanning the auction house...")
    catNext()
    return true
end

SFP.StopCategoryScan = function()
    if catBusy then
        catBusy, scanning = false, false
        if catTimer then catTimer:Cancel(); catTimer = nil end
        setProgress("idle")
    end
end

SFP.CategoryScanEvent = function(event)
    if catBusy and (event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED") then catRead() end
end

function SFP:StartScan(force, noFull)
    if not ahOpen then
        self:Print("Open the auction house first.")
        return
    end
    if scanning then return end
    -- Auctionator keeps its own scan and GetPrice reads it: nothing to wait for
    if not force and not noFull and Auctionator and Auctionator.API and Auctionator.API.v1 then
        if not self.autoAnnounced then
            self.autoAnnounced = true
            self:Print("Using Auctionator's prices (type /sfp scan to run this addon's own scan).")
        end
        return
    end
    if not noFull and self:StartCategoryScan() then return end
    if not force and qIndex > 0 and qIndex < #queue then
        qIndex = qIndex - 1 -- resume the interrupted scan
    else
        buildQueue()
    end
    scanning = true
    self:Print(string.format("Loading auction house prices for %d farm items...", #queue))
    step()
end

local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_SHOW")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_CLOSED")
pcall(f.RegisterEvent, f, "COMMODITY_SEARCH_RESULTS_UPDATED")
pcall(f.RegisterEvent, f, "ITEM_SEARCH_RESULTS_UPDATED")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
pcall(f.RegisterEvent, f, "REPLICATE_ITEM_LIST_UPDATE")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
        if SFP.CategoryScanEvent then SFP.CategoryScanEvent(event) end
        return
    end
    if event == "AUCTION_HOUSE_SHOW" then
        ahOpen = true
        local age = time() - SFP:LastScan()
        local stale = age > (SFP.db.rescanHours or 12) * 3600
        local resume = qIndex > 0 and qIndex < #queue
        if stale or resume then
            C_Timer.After(1, function() SFP:StartScan(false) end)
        end
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        if fullWaiting then
            fullWaiting = false
            if fullTimer then fullTimer:Cancel(); fullTimer = nil end
            SFP:Safe("full scan", processReplicate)
        elseif ahOpen and not scanning then
            -- another addon (Auctionator, TSM) asked the server for the whole auction house: use that answer too, no extra waiting
            scanning = true
            setProgress("wait")
            SFP:Safe("full scan", processReplicate)
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        ahOpen = false
        if SFP.StopCategoryScan then SFP.StopCategoryScan() end
    elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
        if scanning and not waitingFor then step() end
    elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
        local itemID = arg1
        if itemID and C_AuctionHouse.GetNumCommoditySearchResults(itemID) > 0 then
            local r = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, 1)
            if r then savePrice(itemID, r.unitPrice) end
        end
        if scanning and waitingFor == itemID then finishItem() end
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
        local itemKey = arg1
        local itemID = itemKey and itemKey.itemID
        if itemID and C_AuctionHouse.GetNumItemSearchResults(itemKey) > 0 then
            local r = C_AuctionHouse.GetItemSearchResultInfo(itemKey, 1)
            if r and r.buyoutAmount then
                local qty = (r.quantity and r.quantity > 0) and r.quantity or 1
                savePrice(itemID, math.floor(r.buyoutAmount / qty))
            end
        end
        if scanning and waitingFor == itemID then finishItem() end
    end
end)

function SFP:IsScanning() return scanning, qIndex, #queue end

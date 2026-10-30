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
        SFP:Print(string.format("Scanning prices... %d/%d (%d%%)", qIndex, #queue, math.floor(qIndex * 100 / math.max(1, #queue))))
        SFP:RefreshAll()
    end
end

-- full scan: the whole auction house in one request (like other addons), instead of one search per item
local fullWaiting, fullTimer, fullTick = false, nil, nil

local function processReplicate()
    local n = C_AuctionHouse.GetNumReplicateItems and C_AuctionHouse.GetNumReplicateItems() or 0
    local best, i, found, nextPct = {}, 0, 0, 25
    SFP:Print(("Full scan: the auction house answered, reading %d auctions..."):format(n))
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
            local pct = math.floor(i * 100 / math.max(1, n))
            if pct >= nextPct then
                SFP:Print(("Full scan: %d%% read (%d/%d auctions)"):format(pct, i, n))
                nextPct = nextPct + 25
            end
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
    self:Print("Full auction scan started (one request for the whole auction house)...")
    if fullTimer then fullTimer:Cancel() end
    local waited = 0
    if fullTick then fullTick:Cancel() end
    fullTick = C_Timer.NewTicker(5, function(t)
        waited = waited + 5
        if fullWaiting then
            SFP:Print(("Full scan: waiting for the auction house answer... %d s (gives up after 25 s)"):format(waited))
        else
            t:Cancel()
        end
    end)
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
    if not noFull and self:TryFullScan() then return end
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
f:SetScript("OnEvent", function(_, event, arg1)
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

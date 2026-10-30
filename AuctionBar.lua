-- SeviathsUsefulTools - scan bar and scan button on the auction house window
-- Below the auction house window: a "Scan prices" button and a bar that shows how far the scan is.
-- Auction.lua reports the progress (SFP.scanState); this file only draws it.

local _, SFP = ...

local bar, status, label, button
local doneUntil = 0

local function ago(t)
    if not t or t <= 0 then return nil end
    local mins = math.floor((time() - t) / 60)
    if mins < 1 then return "just now" end
    if mins < 120 then return mins .. " min ago" end
    return math.floor(mins / 60) .. " h ago"
end

local function refresh()
    if not bar then return end
    local scanning = SFP:IsScanning()
    local st = SFP.scanState
    button:SetEnabled(not scanning)
    button:SetText(scanning and "Scanning..." or "Scan prices")

    local value, text, r, g, b = 0, nil, 0.1, 0.75, 0.9
    if scanning and st then
        if st.phase == "wait" then
            text = ("Waiting for the auction house...  %d s"):format(math.floor(GetTime() - (st.t0 or GetTime())))
        elseif st.phase == "read" then
            value = st.total > 0 and st.done / st.total or 0
            text = ("Reading auctions  %d%%"):format(math.floor(value * 100))
        elseif st.phase == "section" then
            value = st.total > 0 and st.done / st.total or 0
            text = ("Scanning section  %d / %d  (%d%%)"):format(st.done, st.total, math.floor(value * 100))
        elseif st.phase == "items" then
            value = st.total > 0 and st.done / st.total or 0
            text = ("Scanning items  %d / %d  (%d%%)"):format(st.done, st.total, math.floor(value * 100))
        end
    elseif st and st.phase == "done" and GetTime() < doneUntil then
        value, r, g, b = 1, 0.2, 0.85, 0.3
        text = "Scan done - prices updated"
    end
    if not text then
        local when = ago(SFP.LastScan and SFP:LastScan())
        text = when and ("Prices: last scan " .. when) or "Prices: not scanned yet"
    end
    status:SetValue(value)
    status:SetStatusBarColor(r, g, b)
    label:SetText(text)
end

local function build()
    if bar or not AuctionHouseFrame then return end
    bar = CreateFrame("Frame", "SeviathsUsefulToolsScanBar", AuctionHouseFrame)
    bar:SetSize(580, 22)
    bar:SetPoint("TOPLEFT", AuctionHouseFrame, "BOTTOMLEFT", 6, -40)   -- below the tab row, where Auctionator, TSM and others put their tabs
    bar:SetFrameStrata("HIGH")

    button = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    button:SetSize(96, 22)
    button:SetPoint("LEFT", 0, 0)
    button:SetText("Scan prices")
    button:SetScript("OnClick", function() SFP:StartScan(true) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("SeviathsUsefulTools")
        GameTooltip:AddLine("Scan the whole auction house for farm prices. It also starts by itself when the prices are old.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    status = CreateFrame("StatusBar", nil, bar)
    status:SetPoint("LEFT", button, "RIGHT", 6, 0)
    status:SetSize(272, 18)
    status:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    status:SetMinMaxValues(0, 1)
    status:SetValue(0)
    local bg = status:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)
    label = status:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")

    local deals = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    deals:SetSize(80, 22)
    deals:SetPoint("LEFT", status, "RIGHT", 6, 0)
    deals:SetText("BoE deals")
    deals:SetScript("OnClick", function() SFP:ShowDeals() end)

    -- long scan: keep everything the auction house shows (all items, full details, all prices)
    local long = CreateFrame("CheckButton", nil, bar, "UICheckButtonTemplate")
    long:SetSize(22, 22)
    long:SetPoint("LEFT", deals, "RIGHT", 4, 0)
    long.label = long:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    long.label:SetPoint("LEFT", long, "RIGHT", 0, 0)
    long.label:SetText("Long scan")
    long:SetHitRectInsets(0, -60, 0, 0)
    long:SetChecked(SFP.db.longScan and true or false)
    long:SetScript("OnClick", function(self) SFP.db.longScan = self:GetChecked() and true or false end)
    long:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Long scan: the next scans save the price and the full details of every item in the auction house, not only the ones the addon tracks. It makes the saved data bigger. Use it to collect everything, then switch it off.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    long:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local acc = 0
    bar:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 0.2 then return end
        acc = 0
        refresh()
    end)
    refresh()
end

function SFP:UpdateScanBar()
    local st = SFP.scanState
    if st and st.phase == "done" then doneUntil = GetTime() + 12 end
    if bar then refresh() end
end

local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_SHOW")
f:SetScript("OnEvent", function()
    -- the auction house window is created by the game when it first opens
    C_Timer.After(0.2, function() SFP:Safe("scan bar", build) end)
end)

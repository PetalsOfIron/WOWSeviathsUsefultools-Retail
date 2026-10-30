-- SeviathsUsefulTools - tools
--   route   : ticked spots of the zone ordered into a short loop, drawn on the map  (spot list button "Route")
--   weekly  : /sfp weekly  - Great Vault, raid lockouts and rare kills of all your characters
--   deals   : /sfp flip    - BoE items now against their typical price (also a button at the auction house)
--   shop    : /sfp shop    - pick recipes, get the reagent list with prices and where to farm them
-- Only reads the game and the addon's own saved data.

local _, SFP = ...

local function secret(v) return issecretvalue and issecretvalue(v) end
local function money(c)
    c = math.floor((c or 0) + 0.5)
    if GetCoinTextureString then return GetCoinTextureString(c) end
    return math.floor(c / 10000) .. "g"
end

---------------------------------------------------------------------------
-- a small scrolling text window
---------------------------------------------------------------------------
local function makeWindow(name, title, w, h)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    SFP.RegisterWindow(f)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(0.03, 0.05, 0.07, 0.95)
    f:SetBackdropBorderColor(0, 0.9, 1, 0.8)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 12, -10)
    f.title:SetText(title)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    f.scroll = CreateFrame("ScrollFrame", name .. "Scroll", f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", 12, -34)
    f.scroll:SetPoint("BOTTOMRIGHT", -30, 12)
    f.child = CreateFrame("Frame", nil, f.scroll)
    f.child:SetSize(w - 50, 10)
    f.scroll:SetScrollChild(f.child)
    f.text = f.child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("TOPLEFT")
    f.text:SetWidth(w - 56)
    f.text:SetJustifyH("LEFT")
    f.text:SetSpacing(3)
    f.SetContent = function(self, str)
        self.text:SetText(str)
        self.child:SetHeight(self.text:GetStringHeight() + 10)
    end
    f:Hide()
    return f
end

---------------------------------------------------------------------------
-- a scrolling list of rows, each with a text and a few buttons (the saved lists use it)
---------------------------------------------------------------------------
function SFP.MakeRowList(parent, x, y, w, h, rowH)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", x, y)
    sf:SetSize(w - 24, h)
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(w - 24, 10)
    sf:SetScrollChild(child)
    local rows = {}
    local list = { scroll = sf }
    -- items: { { text = "...", buttons = { { "label", width, function } , ... } }, ... }
    function list:Set(items)
        for i, it in ipairs(items) do
            local r = rows[i]
            if not r then
                r = CreateFrame("Frame", nil, child)
                r:SetSize(w - 24, rowH)
                r:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
                r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                r.text:SetPoint("LEFT", 4, 0)
                r.text:SetJustifyH("LEFT")
                r.text:SetWordWrap(false)
                r.btns = {}
                rows[i] = r
            end
            r.text:SetText(it.text or "")
            local used = 0
            for j = #(it.buttons or {}), 1, -1 do
                local def = it.buttons[j]
                local b = r.btns[j]
                if not b then
                    b = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
                    r.btns[j] = b
                end
                b:SetSize(def[2], rowH - 2)
                b:ClearAllPoints()
                b:SetPoint("RIGHT", r, "RIGHT", -used, 0)
                b:SetText(def[1])
                b:SetScript("OnClick", def[3])
                b:Show()
                used = used + def[2] + 2
            end
            for j = #(it.buttons or {}) + 1, #r.btns do r.btns[j]:Hide() end
            r.text:SetWidth(math.max(40, w - 24 - used - 8))
            r:Show()
        end
        for i = #items + 1, #rows do rows[i]:Hide() end
        child:SetHeight(#items * rowH + 4)
    end
    return list
end

---------------------------------------------------------------------------
-- route: nearest-neighbour loop through the ticked spots of a zone
---------------------------------------------------------------------------
local MAX_ROUTE = 12

function SFP:BuildRoute(mapID, only)
    local zone = self.zoneByMap and self.zoneByMap[mapID]
    if not (zone and zone.spawns) then self:Print("No farm spots on this map."); return end
    local spots = {}
    for _, sp in ipairs(zone.spawns) do
        local use
        if only then use = only[self.SpotKey(sp)] else use = self.ShowSpot and self.ShowSpot(sp) end
        if sp.hx and sp.hy and use then
            spots[#spots + 1] = { name = sp.name or "?", x = sp.hx, y = sp.hy }
        end
    end
    if #spots < 2 then self:Print("Pick at least two spots first."); return end
    -- start next to you when you are in this zone, else at the first spot
    local cx, cy
    if C_Map.GetBestMapForUnit("player") == mapID then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos and pos.GetXY then
            local x, y = pos:GetXY()
            if not secret(x) and not secret(y) and x and x > 0 then cx, cy = x, y end
        end
    end
    local route, left = {}, {}
    for i, s in ipairs(spots) do left[i] = s end
    cx, cy = cx or left[1].x, cy or left[1].y
    while #left > 0 and #route < MAX_ROUTE do
        local bi, bd
        for i, s in ipairs(left) do
            local d = (s.x - cx) ^ 2 + (s.y - cy) ^ 2
            if not bd or d < bd then bi, bd = i, d end
        end
        local s = table.remove(left, bi)
        route[#route + 1] = s
        cx, cy = s.x, s.y
    end
    -- close the loop back to the start
    local pts = {}
    for i, s in ipairs(route) do pts[i] = { x = s.x, y = s.y, name = s.name } end
    pts[#pts + 1] = { x = route[1].x, y = route[1].y, name = route[1].name }
    local total = 0
    for i = 1, #pts - 1 do total = total + math.sqrt((pts[i + 1].x - pts[i].x) ^ 2 + (pts[i + 1].y - pts[i].y) ^ 2) end
    if self.SetRoute then self.SetRoute(mapID, pts) end
    local names = {}
    for i, s in ipairs(route) do names[i] = i .. ". " .. s.name end
    self:Print(("Route of %d spots drawn on the map (about %.0f%% of the map across): %s"):format(#route, total * 100, table.concat(names, "  ")))
    if route[1] and self.SetWaypoint then self:SetWaypoint(mapID, route[1].x, route[1].y, route[1].name) end
end

-- every zone that has farm spots, in expansion order: { map, name, exp, count }
function SFP:RouteZones()
    local out = {}
    local order = {}
    for i, exp in ipairs(self.Expansions or {}) do order[exp.key] = i end
    for mapID, zone in pairs(self.zoneByMap or {}) do
        local n = 0
        for _, sp in ipairs(zone.spawns or {}) do
            if sp.hx and sp.hy then n = n + 1 end
        end
        if n >= 2 then
            local exp = self.zoneExp and self.zoneExp[mapID]
            out[#out + 1] = { map = mapID, name = self:ZoneName(mapID), exp = exp and exp.name or "", expOrder = exp and order[exp.key] or 99, count = n }
        end
    end
    -- two maps with the same name (floors, sub-areas): tell them apart
    local seen = {}
    for _, z in ipairs(out) do seen[z.name] = (seen[z.name] or 0) + 1 end
    for _, z in ipairs(out) do if seen[z.name] > 1 then z.name = z.name .. " (map " .. z.map .. ")" end end
    table.sort(out, function(a, b)
        if a.expOrder ~= b.expOrder then return a.expOrder > b.expOrder end   -- newest expansion first
        return a.name < b.name
    end)
    return out
end

function SFP:ClearRoute()
    if self.SetRoute then self.SetRoute(nil, nil) end
end

---------------------------------------------------------------------------
-- weekly checklist (all characters)
---------------------------------------------------------------------------
local function charKey()
    return (UnitName("player") or "?") .. "-" .. (GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName() or "?")
end

local VAULT_TYPES = { { "Raid", "Raid", 1 }, { "Dungeons", "Activities", 2 }, { "World", "World", 6 } }

function SFP:UpdateWeekly()
    if not self.db then return end
    local rec = { t = time(), vault = {}, locks = {} }
    if C_WeeklyRewards and C_WeeklyRewards.GetActivities then
        for _, v in ipairs(VAULT_TYPES) do
            local typ = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType[v[2]]) or v[3]
            local ok, acts = pcall(C_WeeklyRewards.GetActivities, typ)
            if ok and type(acts) == "table" and #acts > 0 then
                local open = 0
                for _, a in ipairs(acts) do
                    if type(a.progress) == "number" and type(a.threshold) == "number" and not secret(a.progress) and a.progress >= a.threshold then open = open + 1 end
                end
                rec.vault[#rec.vault + 1] = ("%s %d/%d"):format(v[1], open, #acts)
            end
        end
    end
    rec.raids, rec.fresh = {}, {}
    local locked = {}
    if GetNumSavedInstances then
        for i = 1, GetNumSavedInstances() do
            local name, _, reset, _, isLocked, _, _, isRaid, _, diffName, numEnc, encProg = GetSavedInstanceInfo(i)
            if isLocked and isRaid and type(name) == "string" and not secret(name) then
                rec.locks[#rec.locks + 1] = ("%s (%s) %s/%s"):format(name, tostring(diffName or "?"), tostring(encProg or "?"), tostring(numEnc or "?"))
                locked[name] = true
                local done, left = {}, {}
                for j = 1, tonumber(numEnc) or 0 do
                    local okE, bossName, _, killed = pcall(GetSavedInstanceEncounterInfo, i, j)
                    if okE and type(bossName) == "string" then
                        if killed then done[#done + 1] = bossName else left[#left + 1] = bossName end
                    end
                end
                rec.raids[#rec.raids + 1] = { name = name, diff = tostring(diffName or "?"), done = done, left = left }
            end
        end
    end
    -- the raids of the newest expansion that you have not entered this week
    local newest
    for _, exp in ipairs(self.Expansions or {}) do
        for _, inst in ipairs(exp.instances or {}) do
            if inst.kind == "raid" then newest = exp; break end
        end
    end
    for _, inst in ipairs(newest and newest.instances or {}) do
        if inst.kind == "raid" and not locked[inst.name] then
            local bosses, seen = {}, {}
            for _, list in pairs(self.lootIndex or {}) do
                for _, e in ipairs(list) do
                    if e[1] == inst.name and e[2] and not seen[e[2]] then seen[e[2]] = true; bosses[#bosses + 1] = e[2] end
                end
            end
            table.sort(bosses)
            rec.fresh[#rec.fresh + 1] = { name = inst.name, bosses = bosses }
        end
    end
    local kills = 0
    local k = self.db.killed and self.db.killed[charKey()]
    for id in pairs(k or {}) do if self:RareKilledToday(id) then kills = kills + 1 end end
    rec.rares = kills
    self.db.weekly = self.db.weekly or {}
    self.db.weekly[charKey()] = rec
end

local weeklyWin
function SFP:ShowWeekly()
    self:UpdateWeekly()
    weeklyWin = weeklyWin or makeWindow("SeviathsUsefulToolsWeekly", "Weekly checklist - all your characters", 460, 340)
    local lines = {}
    local keys = {}
    for key in pairs(self.db.weekly or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local r = self.db.weekly[key]
        local age = math.floor((time() - (r.t or 0)) / 3600)
        lines[#lines + 1] = "|cff00e5ff" .. key .. "|r  |cff808080(" .. (age < 1 and "now" or (age .. " h ago")) .. ")|r"
        lines[#lines + 1] = "  Great Vault: " .. (#r.vault > 0 and table.concat(r.vault, "   ") or "no data")
        lines[#lines + 1] = "  Rares killed today: " .. (r.rares or 0)
        lines[#lines + 1] = "  |cffffd100Raids this week|r"
        for _, raid in ipairs(r.raids or {}) do
            local total = #raid.done + #raid.left
            lines[#lines + 1] = ("    %s (%s)  %d/%d  %s"):format(raid.name, raid.diff, #raid.done, total,
                #raid.left == 0 and "|cff40ff40all done|r" or "|cffff6060to do:|r " .. table.concat(raid.left, ", "))
            if #raid.done > 0 then lines[#lines + 1] = "      |cff40ff40done:|r " .. table.concat(raid.done, ", ") end
        end
        for _, raid in ipairs(r.fresh or {}) do
            lines[#lines + 1] = ("    %s  |cffff6060not started|r%s"):format(raid.name,
                #raid.bosses > 0 and (" - " .. #raid.bosses .. " bosses: " .. table.concat(raid.bosses, ", ")) or "")
        end
        if #(r.raids or {}) == 0 and #(r.fresh or {}) == 0 then lines[#lines + 1] = "    no raid data yet (log in with this character again)" end
        lines[#lines + 1] = ""
    end
    if #lines == 0 then lines[1] = "No data yet." end
    lines[#lines + 1] = "|cff808080A character shows here after you log in with it. World boss and weekly quest status are not in this list: the game's quest numbers for them are not in the addon.|r"
    weeklyWin:SetContent(table.concat(lines, "\n"))
    weeklyWin:Show()
end

local wf = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "WEEKLY_REWARDS_UPDATE", "UPDATE_INSTANCE_INFO" }) do pcall(wf.RegisterEvent, wf, e) end
local weeklyTimer
wf:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" and RequestRaidInfo then pcall(RequestRaidInfo) end
    if weeklyTimer then return end
    weeklyTimer = true
    C_Timer.After(8, function() weeklyTimer = nil; SFP:Safe("weekly", SFP.UpdateWeekly, SFP) end)
end)

---------------------------------------------------------------------------
-- BoE deals: now against the typical price (median of what this realm showed before)
---------------------------------------------------------------------------
local function median(list)
    table.sort(list)
    local n = #list
    if n == 0 then return nil end
    if n % 2 == 1 then return list[(n + 1) / 2] end
    return (list[n / 2] + list[n / 2 + 1]) / 2
end

function SFP:TypicalPrice(itemID)
    local ph = self.db.priceHist and self.db.priceHist[self:RealmKey()]
    local samples = ph and ph[itemID]
    if samples and #samples >= 3 then
        local vals = {}
        -- the newest sample is "now"; the typical price is what came before
        for i = 1, #samples - 1 do vals[#vals + 1] = samples[i].p end
        return median(vals), #samples - 1, "your scans"
    end
    -- no history of our own: Auctionator's own price history (when this version offers it)
    if Auctionator and Auctionator.Database and Auctionator.Database.GetPriceHistory then
        for _, key in ipairs({ tostring(itemID), "g:" .. itemID }) do
            local ok, hist = pcall(Auctionator.Database.GetPriceHistory, Auctionator.Database, key)
            if ok and type(hist) == "table" and #hist >= 3 then
                local vals = {}
                for _, h in ipairs(hist) do
                    local v = type(h) == "table" and (h.minSeen or h.min or h.price) or h
                    if type(v) == "number" and v > 0 then vals[#vals + 1] = v end
                end
                if #vals >= 3 then return median(vals), #vals, "Auctionator history" end
            end
        end
    end
    -- TradeSkillMaster keeps a long-term price too
    if TSM_API and TSM_API.GetCustomPriceValue then
        for _, src in ipairs({ "DBHistorical", "DBMarket", "DBRegionMarketAvg" }) do
            local ok, v = pcall(TSM_API.GetCustomPriceValue, src, "i:" .. itemID)
            if ok and type(v) == "number" and v > 0 then return v, 0, "TradeSkillMaster " .. src end
        end
    end
end

function SFP:BoeDeals()
    local out, nohist = {}, {}
    for id, info in pairs(self.Items or {}) do
        if info.kind == "boe" then
            if C_Item and C_Item.RequestLoadItemDataByID and not (C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) then
                pcall(C_Item.RequestLoadItemDataByID, id)
            end
            -- now: our own scan, else Auctionator / TradeSkillMaster
            local now = self:GetPrice(id)
            if now and now > 0 then
                local typical, n, src = self:TypicalPrice(id)
                if typical and typical > 0 then
                    out[#out + 1] = { id = id, now = now, typical = typical, n = n, src = src, cut = 1 - now / typical }
                else
                    nohist[#nohist + 1] = { id = id, now = now }
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.cut > b.cut end)
    table.sort(nohist, function(a, b) return a.now > b.now end)
    return out, nohist
end

local dealWin
local function renderDeals(self)
    local list, nohist = self:BoeDeals()
    local lines = {}
    for i, d in ipairs(list) do
        if i > 40 then break end
        local pct = math.floor(d.cut * 100 + 0.5)
        local color = pct >= 20 and "|cff40ff40" or (pct <= -20 and "|cffff6060" or "|cffffffff")
        lines[#lines + 1] = ("%s%s%d%%|r  %s   now %s   typical %s  |cff808080(%s)|r"):format(
            color, pct >= 0 and "-" or "+", math.abs(pct), self:ItemName(d.id), money(d.now), money(d.typical),
            d.src == "your scans" and (d.n .. " scans") or d.src)
    end
    if #lines > 0 then
        table.insert(lines, 1, "|cff808080Green = cheaper than usual. Prices: your own scans, else Auctionator or TradeSkillMaster.|r\n")
    end
    -- items that have a price now but nothing to compare with yet
    if #nohist > 0 then
        lines[#lines + 1] = (#lines > 0 and "\n" or "") .. "|cff00e5ffBoE prices now|r  |cff808080(no price history yet - the addon keeps one from now on, so this fills in over a few days)|r"
        for i, d in ipairs(nohist) do
            if i > 30 then break end
            lines[#lines + 1] = ("  %s   %s"):format(self:ItemName(d.id), money(d.now))
        end
    end
    if #lines == 0 then
        lines[1] = "No BoE prices known yet. Scan the auction house (button below its window), or install Auctionator or TradeSkillMaster and scan there. Then open this list again."
    end
    dealWin:SetContent(table.concat(lines, "\n"))
end

function SFP:ShowDeals()
    if not dealWin then
        dealWin = makeWindow("SeviathsUsefulToolsDeals", "BoE deals - now against the typical price", 480, 360)
        local acc = 0
        dealWin:SetScript("OnUpdate", function(_, dt)
            acc = acc + dt
            if acc < 2 then return end
            acc = 0
            SFP:Safe("deals update", renderDeals, SFP)
        end)
    end
    renderDeals(self)
    dealWin:Show()
end

---------------------------------------------------------------------------
-- crafting shopping list
---------------------------------------------------------------------------
local shopWin, shopBox, shopResults, shopRows = nil, nil, {}, nil

-- the list is saved with the addon's data, so it is still there after a relog and on every character
local function shopData()
    SFP.db.shopList = SFP.db.shopList or {}
    return SFP.db.shopList
end

local function shopTotals()
    local need, order = {}, {}
    local products, productValue = {}, 0
    for _, entry in ipairs(shopData()) do
        local rec = SFP.db.recipes[entry.key]
        if rec then
            for _, rg in ipairs(rec.r or {}) do
                local id, cnt = rg[1], rg[2] or 1
                if not need[id] then need[id] = 0; order[#order + 1] = id end
                need[id] = need[id] + cnt * entry.qty
            end
            if rec.o then
                local p = SFP:GetPrice(rec.o)
                if p and p > 0 then productValue = productValue + p * entry.qty * 0.95 end
            end
            products[#products + 1] = ("%dx %s"):format(entry.qty, rec.n or entry.key)
        end
    end
    return need, order, products, productValue
end

local shopRefresh
local function shopFillRows()
    local items = {}
    for i, entry in ipairs(shopData()) do
        local rec = SFP.db.recipes[entry.key]
        items[#items + 1] = {
            text = ("%dx %s%s"):format(entry.qty, (rec and rec.n) or entry.key, rec and "" or "  |cffff6060(recipe not known on this account)|r"),
            buttons = {
                { "-", 24, function()
                    entry.qty = entry.qty - 1
                    if entry.qty < 1 then table.remove(shopData(), i) end
                    shopRefresh()
                end },
                { "+", 24, function() entry.qty = entry.qty + 1; shopRefresh() end },
                { "Remove", 60, function() table.remove(shopData(), i); shopRefresh() end },
            },
        }
    end
    shopRows:Set(items)
end

shopRefresh = function()
    if not shopWin then return end
    shopFillRows()
    local lines = {}
    if #shopData() == 0 then
        lines[1] = "Type part of a recipe name above and click a result to add it. The list is saved: you can add, remove or change the amount of each entry whenever you want. The recipes are the ones the addon learned when you opened your professions."
    else
        local need, order, products, productValue = shopTotals()
        lines[#lines + 1] = "|cff00e5ffMaking:|r " .. table.concat(products, ", ")
        lines[#lines + 1] = ""
        local total, unknown = 0, 0
        for _, id in ipairs(order) do
            local unit = SFP:GetPrice(id) or 0
            local cost = unit * need[id]
            total = total + cost
            if unit <= 0 then unknown = unknown + 1 end
            local src = SFP.itemSources and SFP.itemSources[id]
            local farm = (src and src[1]) and ("  |cff80ff80farm: " .. src[1] .. "|r") or ""
            lines[#lines + 1] = ("%dx %s   %s each = %s%s"):format(need[id], SFP:ItemName(id), unit > 0 and money(unit) or "|cffff6060no price|r", unit > 0 and money(cost) or "?", farm)
        end
        lines[#lines + 1] = ""
        lines[#lines + 1] = "|cff00e5ffBuying all reagents:|r " .. money(total) .. (unknown > 0 and ("  |cffff6060(" .. unknown .. " without a price)|r") or "")
        if productValue > 0 then
            lines[#lines + 1] = "|cff00e5ffThe crafts sell for about:|r " .. money(productValue) .. " (after the 5% auction cut)  ->  " ..
                (productValue - total >= 0 and ("|cff40ff40profit " .. money(productValue - total)) or ("|cffff6060loss " .. money(total - productValue))) .. "|r"
        end
        lines[#lines + 1] = ""
        lines[#lines + 1] = "|cff808080Farm or buy? A reagent is worth farming when your gold per hour from it (run /sfp session while you farm it) is more than the time you would spend buying it back. " ..
            "Green 'farm:' marks reagents the addon knows a place for.|r"
    end
    shopWin:SetContent(table.concat(lines, "\n"))
end

local function shopSearch(text)
    text = (text or ""):lower()
    local found = {}
    if #text >= 2 then
        for key, rec in pairs(SFP.db.recipes or {}) do
            if (rec.n or ""):lower():find(text, 1, true) then found[#found + 1] = key end
        end
        table.sort(found)
    end
    for i, b in ipairs(shopResults) do
        local key = found[i]
        b.key = key
        if key then
            local rec = SFP.db.recipes[key]
            b:SetText((rec.n or key) .. "  |cff808080" .. (rec.p or "") .. "|r")
            b:Show()
        else
            b:Hide()
        end
    end
end

function SFP:ShowShop()
    if not shopWin then
        shopWin = makeWindow("SeviathsUsefulToolsShop", "Crafting shopping list", 540, 540)
        shopWin.scroll:SetPoint("TOPLEFT", 12, -300)
        shopBox = CreateFrame("EditBox", nil, shopWin, "InputBoxTemplate")
        shopBox:SetSize(300, 22)
        shopBox:SetPoint("TOPLEFT", 22, -34)
        shopBox:SetAutoFocus(false)
        shopBox:SetScript("OnTextChanged", function(self) shopSearch(self:GetText()) end)
        shopBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local clear = CreateFrame("Button", nil, shopWin, "UIPanelButtonTemplate")
        clear:SetSize(110, 22)
        clear:SetPoint("LEFT", shopBox, "RIGHT", 10, 0)
        clear:SetText("Remove all")
        clear:SetScript("OnClick", function() wipe(shopData()); shopRefresh() end)
        for i = 1, 6 do
            local b = CreateFrame("Button", nil, shopWin, "UIPanelButtonTemplate")
            b:SetSize(490, 18)
            b:SetPoint("TOPLEFT", 22, -62 - (i - 1) * 16)
            b:SetScript("OnClick", function(self)
                if not self.key then return end
                for _, e in ipairs(shopData()) do if e.key == self.key then e.qty = e.qty + 1; shopRefresh(); return end end
                shopData()[#shopData() + 1] = { key = self.key, qty = 1 }
                shopRefresh()
            end)
            b:Hide()
            shopResults[i] = b
        end
        local label = shopWin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 22, -168)
        label:SetText("Your list (saved):")
        shopRows = SFP.MakeRowList(shopWin, 18, -186, 510, 104, 20)
    end
    shopWin:Show()
    shopRefresh()
end

SFP.MakeToolWindow = makeWindow

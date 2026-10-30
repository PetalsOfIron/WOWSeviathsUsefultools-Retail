-- SeviathsUsefulTools - more tools
--   alts     : account overview (level, item level, gold, professions, weekly activities)
--   keys     : delve keys and bountiful delves
--   planner  : delve companion role, curio hints and the tier you are comfortable with
--   ach      : achievement planner (what is left, where, what first)
--   zone     : "missing here" line when you enter a zone or an instance
--   decor    : Midnight housing decor you can craft, and which recipes you know
-- Reads the game and the addon's own data only. Everything is wrapped so a missing game function just shows nothing.

local _, SFP = ...

local function secret(v) return issecretvalue and issecretvalue(v) end
local function money(c)
    c = math.floor((c or 0) + 0.5)
    if GetCoinTextureString then return GetCoinTextureString(c) end
    return math.floor(c / 10000) .. "g"
end
local function charKey()
    return (UnitName("player") or "?") .. "-" .. (GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName() or "?")
end
local function window(name, title, w, h) return SFP.MakeToolWindow(name, title, w, h) end

---------------------------------------------------------------------------
-- 11. account-wide alt overview
---------------------------------------------------------------------------
function SFP:UpdateAlt()
    if not self.db then return end
    local rec = { t = time(), level = UnitLevel("player"), money = GetMoney(), profs = {} }
    local _, class = UnitClass("player")
    rec.class = class
    local okI, _, equipped = pcall(GetAverageItemLevel)
    rec.ilvl = okI and equipped and math.floor(equipped + 0.5) or nil
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local _, specName = GetSpecializationInfo(specIndex)
        rec.spec = specName
    end
    if GetProfessions and GetProfessionInfo then
        for _, idx in ipairs({ GetProfessions() }) do
            if idx then
                local ok, name, _, rank, maxRank = pcall(GetProfessionInfo, idx)
                if ok and type(name) == "string" and not secret(name) then rec.profs[#rec.profs + 1] = ("%s %d/%d"):format(name, rank or 0, maxRank or 0) end
            end
        end
    end
    self.db.alts = self.db.alts or {}
    local old = self.db.alts[charKey()]
    if old then rec.bags, rec.bagsT, rec.bank, rec.bankT = old.bags, old.bagsT, old.bank, old.bankT end
    self.db.alts[charKey()] = rec
end

-- what is in the bags: { [itemID] = count }, read from the given bag slots
local function readBags(ids)
    local counts, any = {}, false
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then return counts, false end
    for _, bag in ipairs(ids) do
        local okN, n = pcall(C_Container.GetContainerNumSlots, bag)
        if okN and type(n) == "number" and n > 0 then
            any = true
            for slot = 1, n do
                local okI, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
                if okI and type(info) == "table" and info.itemID and not secret(info.itemID) then
                    counts[info.itemID] = (counts[info.itemID] or 0) + (tonumber(info.stackCount) or 1)
                end
            end
        end
    end
    return counts, any
end

local function bagIDs(kind)
    local first, prefix, n
    if kind == "bags" then return { 0, 1, 2, 3, 4, 5 } end
    if kind == "bank" then first, prefix, n = 6, "CharacterBankTab_", 6 else first, prefix, n = 12, "AccountBankTab_", 5 end
    local ids = {}
    for i = 1, n do
        ids[#ids + 1] = (Enum and Enum.BagIndex and Enum.BagIndex[prefix .. i]) or (first + i - 1)
    end
    return ids
end

local bankOpen = false

-- bags are read all the time; the bank and the warband bank only while the bank window is open
function SFP:SnapshotBags()
    if not self.db then return end
    local key = charKey()
    self.db.alts = self.db.alts or {}
    if not self.db.alts[key] then self:UpdateAlt() end
    local rec = self.db.alts[key]
    if not rec then return end
    rec.bags, rec.bagsT = readBags(bagIDs("bags")), time()
    if bankOpen then
        local cb, anyC = readBags(bagIDs("bank"))
        if anyC then rec.bank, rec.bankT = cb, time() end
        local wb, anyW = readBags(bagIDs("warband"))
        if anyW then
            self.db.warband = self.db.warband or {}
            self.db.warband.items, self.db.warband.t = wb, time()
        end
        if C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType then
            local okM, m = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
            if okM and type(m) == "number" and not secret(m) then
                self.db.warband = self.db.warband or {}
                self.db.warband.money = m
            end
        end
    end
end

local altWin, altRows, altBox
local altView = "overview"
local ALT_VIEWS = { { "overview", "Overview", 80 }, { "bags", "Bags", 60 }, { "bank", "Bank", 60 }, { "warband", "Warband bank", 100 }, { "gold", "All gold", 80 } }
local altViewBtns = {}

local function ago(t)
    if not t then return "never" end
    local m = math.floor((time() - t) / 60)
    if m < 1 then return "just now" end
    if m < 120 then return m .. " min ago" end
    if m < 2880 then return math.floor(m / 60) .. " h ago" end
    return math.floor(m / 1440) .. " days ago"
end

local function itemLines(counts, filter)
    local list, distinct, value = {}, 0, 0
    for id, cnt in pairs(counts or {}) do
        distinct = distinct + 1
        local unit = SFP:GetPrice(id) or 0
        value = value + unit * cnt
        local name = SFP:ItemName(id)
        local plain = name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
        if filter == "" or plain:find(filter, 1, true) then list[#list + 1] = { name = name, plain = plain, cnt = cnt, unit = unit } end
    end
    table.sort(list, function(x, y) return x.plain < y.plain end)
    local lines = {}
    for i = 1, math.min(150, #list) do
        local e = list[i]
        lines[#lines + 1] = ("%dx %s%s"):format(e.cnt, e.name, e.unit > 0 and ("  |cff808080" .. money(e.unit) .. " each|r") or "")
    end
    if #list > 150 then lines[#lines + 1] = ("|cff808080+%d more - type part of a name in the search box|r"):format(#list - 150) end
    if #list == 0 then lines[1] = filter ~= "" and "Nothing matches the search." or "Empty." end
    return lines, distinct, value
end

local function altSelected()
    local db = SFP.db
    local keys = {}
    for k in pairs(db.alts or {}) do keys[#keys + 1] = k end
    table.sort(keys)
    if not (db.altSel and db.alts and db.alts[db.altSel]) then
        db.altSel = (db.alts and db.alts[charKey()]) and charKey() or keys[1]
    end
    return db.altSel, keys
end

local function altContent(key)
    local db = SFP.db
    local r = key and db.alts and db.alts[key]
    local filter = (altBox and altBox:GetText() or ""):lower()
    local lines = {}
    if altView == "gold" then
        local rows, total = {}, 0
        for k, rec in pairs(db.alts or {}) do rows[#rows + 1] = { k = k, m = rec.money or 0 }; total = total + (rec.money or 0) end
        table.sort(rows, function(x, y) return x.m > y.m end)
        lines[1] = "|cff00e5ffGold on every character|r"
        for _, e in ipairs(rows) do lines[#lines + 1] = ("%s   %s"):format(e.k, money(e.m)) end
        local wb = db.warband and db.warband.money
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Characters together: " .. money(total)
        lines[#lines + 1] = "Warband bank: " .. (wb and money(wb) or "|cff808080not read yet - open the bank once|r")
        lines[#lines + 1] = "|cff00e5ffTogether: " .. money(total + (wb or 0)) .. "|r"
        return table.concat(lines, "\n")
    end
    if altView == "warband" then
        local w = db.warband
        lines[1] = "|cff00e5ffWarband bank (shared by all your characters)|r"
        if not (w and w.items) then
            lines[2] = "Not read yet. Open your bank (the Warband tabs) with any character once: the addon saves what is in it."
        else
            local list, distinct, value = itemLines(w.items, filter)
            lines[2] = ("|cff808080Read %s. %d different items worth about %s. Gold in it: %s.|r"):format(ago(w.t), distinct, money(value), w.money and money(w.money) or "?")
            lines[3] = ""
            for _, l in ipairs(list) do lines[#lines + 1] = l end
        end
        return table.concat(lines, "\n")
    end
    if not r then return "No character saved yet. Log in with each character once." end
    local short = key:match("^([^-]+)") or key
    if altView == "bags" or altView == "bank" then
        local data = altView == "bags" and r.bags or r.bank
        lines[1] = ("|cff00e5ff%s - %s|r"):format(key, altView == "bags" and "bags" or "character bank")
        if not data then
            lines[2] = altView == "bags" and ("Not read yet. Log in with " .. short .. " once.") or
                ("Not read yet. Open the bank with " .. short .. " once: the addon saves what is in it.")
        else
            local list, distinct, value = itemLines(data, filter)
            lines[2] = ("|cff808080Read %s. %d different items worth about %s.|r"):format(ago(altView == "bags" and r.bagsT or r.bankT), distinct, money(value))
            lines[3] = ""
            for _, l in ipairs(list) do lines[#lines + 1] = l end
        end
        return table.concat(lines, "\n")
    end
    -- overview
    local age = math.floor((time() - (r.t or 0)) / 3600)
    lines[#lines + 1] = ("|cff00e5ff%s|r  |cff808080(%s)|r"):format(key, age < 1 and "now" or (age .. " h ago"))
    lines[#lines + 1] = ("Level %s %s %s"):format(tostring(r.level or "?"), r.spec or "", r.class or "")
    lines[#lines + 1] = ("Item level %s     Gold %s"):format(tostring(r.ilvl or "?"), money(r.money))
    lines[#lines + 1] = "Professions: " .. (#(r.profs or {}) > 0 and table.concat(r.profs, ", ") or "none")
    local w = db.weekly and db.weekly[key]
    if w then
        lines[#lines + 1] = "Weekly: Great Vault " .. (#w.vault > 0 and table.concat(w.vault, " ") or "no data") ..
            "   Raid lockouts: " .. (#w.locks > 0 and #w.locks or "none") .. "   Rares today: " .. (w.rares or 0)
    end
    local function count(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Bags: %s   Bank: %s"):format(r.bags and (count(r.bags) .. " different items, read " .. ago(r.bagsT)) or "not read yet",
        r.bank and (count(r.bank) .. " different items, read " .. ago(r.bankT)) or "not read yet (open the bank once)")
    lines[#lines + 1] = "Warband bank: " .. ((db.warband and db.warband.items) and (count(db.warband.items) .. " different items, " .. (db.warband.money and money(db.warband.money) or "?") .. " gold") or "not read yet")
    lines[#lines + 1] = ""
    lines[#lines + 1] = "|cff808080A character shows here after you log in with it. Use the buttons above to see its bags, bank, the warband bank and everybody's gold. Profession cooldowns are not shown.|r"
    return table.concat(lines, "\n")
end

local function altRefresh()
    if not altWin or not altWin:IsShown() then return end
    SFP:UpdateAlt()
    SFP:SnapshotBags()
    if SFP.UpdateWeekly then pcall(SFP.UpdateWeekly, SFP) end
    local sel, keys = altSelected()
    local items = {}
    for _, k in ipairs(keys) do
        local short = k:match("^([^-]+)") or k
        local rec = SFP.db.alts[k]
        local label = (k == sel and "|cff40ff40> |r" or "") .. short .. (rec.level and (" " .. rec.level) or "")
        items[#items + 1] = { text = "", buttons = { { label, 150, function() SFP.db.altSel = k; altRefresh() end } } }
    end
    altRows:Set(items)
    for _, bt in ipairs(altViewBtns) do bt:SetText((bt.view == altView and "|cff40ff40" or "") .. bt.label) end
    altWin:SetContent(altContent(sel))
end

function SFP:ShowAlts()
    self:UpdateAlt()
    self:SnapshotBags()
    if not altWin then
        altWin = window("SeviathsUsefulToolsAlts", "Alt overview - all your characters", 700, 520)
        altWin.scroll:ClearAllPoints()
        altWin.scroll:SetPoint("TOPLEFT", 190, -94)
        altWin.scroll:SetPoint("BOTTOMRIGHT", -30, 12)
        altWin.child:SetWidth(450)
        altWin.text:SetWidth(446)
        local lbl = altWin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", 14, -36)
        lbl:SetText("Characters:")
        altRows = SFP.MakeRowList(altWin, 10, -52, 176, 450, 24)
        local x = 190
        for _, v in ipairs(ALT_VIEWS) do
            local bt = CreateFrame("Button", nil, altWin, "UIPanelButtonTemplate")
            bt:SetSize(v[3], 22)
            bt:SetPoint("TOPLEFT", x, -34)
            bt.view, bt.label = v[1], v[2]
            bt:SetText(v[2])
            bt:SetScript("OnClick", function() altView = v[1]; altRefresh() end)
            altViewBtns[#altViewBtns + 1] = bt
            x = x + v[3] + 4
        end
        local sl = altWin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sl:SetPoint("TOPLEFT", 194, -68)
        sl:SetText("Search items:")
        altBox = CreateFrame("EditBox", nil, altWin, "InputBoxTemplate")
        altBox:SetSize(220, 20)
        altBox:SetPoint("TOPLEFT", 280, -64)
        altBox:SetAutoFocus(false)
        altBox:SetScript("OnTextChanged", function() altRefresh() end)
        altBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local acc = 0
        altWin:SetScript("OnUpdate", function(_, dt)
            acc = acc + dt
            if acc < 3 then return end
            acc = 0
            SFP:Safe("alt window", altRefresh)
        end)
    end
    altWin:Show()
    altRefresh()
end

local af = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT", "TRADE_SKILL_LIST_UPDATE", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do pcall(af.RegisterEvent, af, e) end
local altTimer, bagTimer
local function isBankType(t)
    local P = Enum and Enum.PlayerInteractionType
    return P and t and (t == P.Banker or t == P.AccountBanker)
end
af:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGOUT" then
        SFP:Safe("alt", SFP.UpdateAlt, SFP)
        SFP:Safe("bags", SFP.SnapshotBags, SFP)
        return
    end
    if event == "BANKFRAME_OPENED" or (event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and isBankType(arg1)) then
        bankOpen = true
        C_Timer.After(1.5, function() SFP:Safe("bank", SFP.SnapshotBags, SFP) end)
        return
    end
    if event == "BANKFRAME_CLOSED" or (event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and isBankType(arg1)) then
        SFP:Safe("bank", SFP.SnapshotBags, SFP)   -- the last look before it closes
        bankOpen = false
        return
    end
    if event == "BAG_UPDATE_DELAYED" then
        if bagTimer then return end
        bagTimer = true
        C_Timer.After(3, function() bagTimer = nil; SFP:Safe("bags", SFP.SnapshotBags, SFP) end)
        return
    end
    if altTimer then return end
    altTimer = true
    C_Timer.After(10, function()
        altTimer = nil
        SFP:Safe("alt", SFP.UpdateAlt, SFP)
        SFP:Safe("bags", SFP.SnapshotBags, SFP)
    end)
end)

---------------------------------------------------------------------------
-- 6. delve keys and bountiful delves
---------------------------------------------------------------------------
local DELVE_MAPS = { 2248, 2214, 2215, 2255, 2395, 2437, 2413, 2405, 2393 }

local function keyCurrencies()
    local out = {}
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize) then return out end
    for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyListInfo, i)
        if ok and type(info) == "table" and not info.isHeader and type(info.name) == "string" and not secret(info.name) then
            local n = info.name:lower()
            if n:find("key") or n:find("delve") or n:find("bountiful") then out[#out + 1] = info end
        end
    end
    return out
end

local function bountiful()
    local out = {}
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetDelvesForMap and C_AreaPoiInfo.GetAreaPOIInfo) then return nil end
    for _, mapID in ipairs(DELVE_MAPS) do
        local ok, ids = pcall(C_AreaPoiInfo.GetDelvesForMap, mapID)
        if ok and type(ids) == "table" then
            for _, poiID in ipairs(ids) do
                local ok2, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
                if ok2 and type(info) == "table" and type(info.atlasName) == "string" and info.atlasName:lower():find("bountiful") then
                    out[#out + 1] = { name = info.name or "?", zone = SFP:ZoneName(mapID) }
                end
            end
        end
    end
    return out
end

local keyWin
function SFP:ShowKeys()
    keyWin = keyWin or window("SeviathsUsefulToolsKeys", "Delve keys and bountiful delves", 480, 340)
    local lines = { "|cff00e5ffKeys and delve currencies|r" }
    local cur = keyCurrencies()
    for _, c in ipairs(cur) do
        local week = (c.canEarnPerWeek and c.maxWeeklyQuantity and c.maxWeeklyQuantity > 0)
            and ("   this week %d/%d"):format(c.quantityEarnedThisWeek or 0, c.maxWeeklyQuantity) or ""
        lines[#lines + 1] = ("  %s: %d%s"):format(c.name, c.quantity or 0, week)
    end
    if #cur == 0 then lines[#lines + 1] = "  none found (open the currency tab once, or you have none yet)" end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "|cff00e5ffBountiful delves today|r"
    local b = bountiful()
    if b == nil then
        lines[#lines + 1] = "  This game version does not tell addons which delves are bountiful. Open the map: they have the golden delve icon."
    elseif #b == 0 then
        lines[#lines + 1] = "  none found on the maps the addon checks (open the zone maps once so the game loads them)"
    else
        for _, d in ipairs(b) do lines[#lines + 1] = ("  %s - %s"):format(d.name, d.zone) end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "|cff00e5ffHow to get keys|r"
    lines[#lines + 1] = "  - A bountiful delve needs a Restored Coffer Key and gives an extra chest."
    lines[#lines + 1] = "  - Keys are made from Coffer Key Shards: 100 shards make 1 key (that is how it worked in The War Within)."
    lines[#lines + 1] = "  - Shards come from delve activity (finishing delves, delve bosses and chests) and from the weekly delve quest."
    lines[#lines + 1] = "  - There is a weekly limit on how many keys you can earn; the currency list above shows how many you earned this week."
    lines[#lines + 1] = "|cff808080The shard amounts and weekly limits come from the War Within rules and may differ in Midnight; the addon could not verify them against the current game.|r"
    keyWin:SetContent(table.concat(lines, "\n"))
    keyWin:Show()
end

---------------------------------------------------------------------------
-- 5. delve planner: companion role, curios, comfortable tier
---------------------------------------------------------------------------
local HYBRID_SPECS = { [70] = true, [103] = true }   -- Retribution, Feral: tank companion (as the Codex says)

-- Valeera's curios. Source: Icy Veins "Best Valeera Curios in Midnight Season 1" (March 2026), written in our own words.
-- Later seasons add more curios; they are not listed here until they are checked.
SFP.CURIOS = {
    { "Holy Bounding Hand Grenade", "combat", "Now and then she throws a grenade: moderate Holy damage, 50% to stun for 1.5 sec, and it can bounce to another enemy (40%). Safe for the party. Good if your class has no stun." },
    { "Mantle of Stars", "combat", "When a party member falls below 40% health in combat they get a shield worth 50% of their max health, and enemies around them are knocked up and take 25% more damage for 12 sec. An emergency button." },
    { "Nether Entropic Kris", "combat", "She sometimes curses an enemy with Void damage over 30 sec. Each tick has a 15% chance to spread to a nearby enemy, up to 5 stacks. Good against groups." },
    { "Porcelain Blade Tip", "combat", "Her spells and abilities sometimes weaken enemies: 10% more chance to be critically hit for 9 sec. Slightly the best combat curio at the start of Season 1." },
    { "Sanctum's Edict", "combat", "She collects blessings in combat and on kills (1 per normal enemy, 5 per elite). Each blessing gives 1% more healing and damage. At 15 she turns 30% of her current health into a shield that boosts the blessings while it lasts." },
    { "Ebon Crown of Subjugation", "utility", "Opening a Mislaid Curiosity summons a worshipper that adds 1% of your main stat in combat, up to 6 at once. With 6 the bonus per worshipper grows." },
    { "Mandate of Sacred Death", "utility", "When Valeera casts Tools of the Trade (she does near profession nodes) the party's harmful spells get a 5% chance to deal 1% of the target's max health as Holy damage per Mandate, once per target every 2 sec. The strongest utility curio, but it does nothing in delves without profession nodes (for example the Nullaeus fight)." },
    { "Motionless Nulltide", "utility", "Standing still in combat gives a stack every 6 sec (up to 10), each +1% movement speed. Jumping at 10 stacks turns them into 1% haste each for 10 sec and knocks up nearby enemies (once per 20 sec)." },
    { "Overflowing Voidspire", "utility", "After 25 sec of combat you and Valeera deal 18% more damage and healing for 35 sec (35 sec cooldown). Recommended for the Nullaeus fight." },
    { "Time Lost Edict", "utility", "She sometimes makes a zone at an ally: allies get 5% more movement speed, cooldown recharge and cast speed, enemies get the opposite, for 12 sec." },
    -- Season 2 (patch 12.1), from the Seramate PTR guide, Warcraft Wiki and boostroom/expcarry; the list may still change
    { "Essence Trap", "combat", "Season 2: she may place a trap in combat. An enemy within 3 yards triggers a 20% slow for 5 sec, then moderate Nature damage and a 1 sec stun." },
    { "Ouroboric Curse", "combat", "Season 2: when anyone drops below 50% health, nearby enemies are horrified for 8 sec and gain 15% primary damage and 100% Leech, Avoidance and Speed. Once per 2 min; killing Poisoned enemies shortens the cooldown by 12 sec." },
    { "Corrosive Bilespear", "combat", "Season 2: same trigger as Ouroboric Curse, but weaker: horrified 6 sec, 5% primary damage, 50% Leech, Avoidance and Speed. Once per 2 min." },
    { "Soul-Cracking Dreamcatcher", "utility", "Season 2: when a party member interrupts or crowd-controls an Elite, it takes 10% more damage for 30 sec, stacking up to 2 times." },
    { "Dundun's Favor", "utility", "Season 2: a Mislaid Spirit may appear in combat. Walking over a Mislaid Curiosity or Spirit fires 6 Volatile Sprites at random nearby enemies." },
    { "Venom Infusion", "utility", "Season 2: party members are Poisoned on entering combat (1% of current health as Nature damage per minute) but gain 1% movement speed and Haste per 5% health missing, reversed for the first 6 sec. Guides disagree whether this is a combat or utility curio - check in game." },
}
SFP.CURIO_BEST = "Best at the start of Season 1 (Icy Veins): Porcelain Blade Tip (combat) and Mandate of Sacred Death (utility). For the Nullaeus fight take Overflowing Voidspire instead of the Mandate."

-- the companion's curio slots, named by the game's own list (Enum.CompanionConfigSlotTypes), in slot order
function SFP:CurioSlots()
    local out, have = {}, {}
    local E = Enum and Enum.CompanionConfigSlotTypes
    if type(E) == "table" then
        local tmp = {}
        for name, value in pairs(E) do
            if type(name) == "string" and type(value) == "number" then tmp[#tmp + 1] = { name = name, value = value } end
        end
        table.sort(tmp, function(a, b) return a.value < b.value end)
        for _, e in ipairs(tmp) do
            local label = e.name:gsub("(%l)(%u)", "%1 %2")
            out[#out + 1] = { key = e.name:lower(), label = label }
            have[e.name:lower()] = true
        end
    end
    for _, k in ipairs({ "combat", "utility" }) do
        if not have[k] then out[#out + 1] = { key = k, label = k:sub(1, 1):upper() .. k:sub(2) } end
    end
    return out
end

-- tier, companion role and curios are saved per delve; "default" is used by every delve without its own choice
function SFP:DelveCfg()
    local db = self.db
    db.delveCfg = db.delveCfg or {}
    if not db.delveCfg.default then
        db.delveCfg.default = { tier = db.delveTier, companion = db.delveCompanion, curios = db.delveCurios or {} }
    end
    local key = db.delveSel and db.delveSel:lower() or "default"
    db.delveCfg[key] = db.delveCfg[key] or {}
    return db.delveCfg[key], db.delveCfg.default, key
end

function SFP:DelveGet(field, slot)
    local c, d = self:DelveCfg()
    if field == "curio" then
        return (c.curios and c.curios[slot]) or (d.curios and d.curios[slot])
    end
    if c[field] ~= nil then return c[field] end
    return d[field]
end

function SFP:DelveSet(field, value, slot)
    local c, d, key = self:DelveCfg()
    if not c then c = {}; self.db.delveCfg[key] = c end
    if field == "curio" then
        c.curios = c.curios or {}
        c.curios[slot] = value
    else
        c[field] = value
    end
end

-- what the addon's guide data says about running one delve with Valeera (sentences that mention her)
function SFP:DelveTips(name)
    local okM, _, cns = pcall(SFP_Module, "Codex")
    local g = okM and cns and cns.DELVE_GUIDES and cns.DELVE_GUIDES[(name or ""):lower()]
    if not g then return nil end
    local out = { where = g.where, variants = {}, tips = {} }
    for _, v in ipairs(g.variants or {}) do out.variants[#out.variants + 1] = v[1] end
    local function scan(label, text)
        for sentence in tostring(text or ""):gmatch("[^%.]+%.?") do
            if sentence:find("Valeera", 1, true) then out.tips[#out.tips + 1] = label .. ": " .. strtrim(sentence) end
        end
    end
    for _, v in ipairs(g.variants or {}) do scan(v[1], v[2]) end
    for _, b in ipairs(g.bosses or {}) do scan(b[1], b[2]) end
    for _, t in ipairs(g.trash or {}) do scan("Trash", t) end
    return out
end

local function recommendCompanion(spec)
    if not spec then return "Healer" end
    if spec.role == "TANK" or spec.role == "HEALER" then return "Damage" end
    if HYBRID_SPECS[spec.id] then return "Tank" end
    return "Healer"
end

-- class, all its specs, the spec you chose (or the one you play) and the companion role
function SFP:DelveInfo()
    local db = self.db
    local info = { specs = {} }
    local className, _, classID = UnitClass("player")
    info.className, info.classID = className, classID
    if db.delveClass ~= classID then db.delveClass = classID; db.delveSpec = nil end   -- another class: start again
    local n = (GetNumSpecializationsForClassID and classID) and GetNumSpecializationsForClassID(classID) or 0
    for i = 1, n do
        local ok, id, name, _, _, role = pcall(GetSpecializationInfoForClassID, classID, i)
        if ok and id then info.specs[#info.specs + 1] = { id = id, name = name, role = role } end
    end
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then info.currentID = (GetSpecializationInfo(specIndex)) end
    local want = db.delveSpec or info.currentID
    for _, sp in ipairs(info.specs) do if sp.id == want then info.spec = sp end end
    info.following = db.delveSpec == nil
    info.recommended = recommendCompanion(info.spec)
    info.chosen = self:DelveGet("companion")
    info.companion = info.chosen or info.recommended
    return info
end

-- the setup the guides recommend for the spec selected on the planner (changes when you pick another spec)
-- Sources: Icy Veins (Season 1), expcarry.com / Seramate (Season 2); only curios the addon lists are suggested
-- best curios per slot, in the order the guides give (Season 2 first, then Season 1); other curios are not ranked
SFP.CURIO_RANK = {
    combat = { "Corrosive Bilespear", "Porcelain Blade Tip" },
    utility = { "Soul-Cracking Dreamcatcher", "Mandate of Sacred Death" },
}

-- the best curio of a slot among the ones you marked as owned (right-click a curio on the planner); none marked = best overall
function SFP:BestCurio(slot)
    local owned = self.db.curiosOwned or {}
    local any = false
    for _, cu in ipairs(self.CURIOS or {}) do if cu[2] == slot and owned[cu[1]] then any = true end end
    for _, name in ipairs((self.CURIO_RANK or {})[slot] or {}) do
        if not any or owned[name] then return name, any end
    end
    return nil, any
end

-- curios learned from the game are added to the planner's list (after a /reload they also get a button)
function SFP:MergeLearnedCurios()
    local have = {}
    for _, cu in ipairs(self.CURIOS or {}) do have[cu[1]] = true end
    for name, r in pairs(self.CuriosLearned or {}) do
        if not have[name] then have[name] = true; table.insert(self.CURIOS, { name, r.slot or "combat", (r.text and r.text ~= "") and r.text or "Learned from the game (no description read).", learned = true, spell = r.spell }) end
    end
    for name, r in pairs(self.db and self.db.learnedCurios or {}) do
        if not have[name] then
            table.insert(self.CURIOS, { name, r.slot or "combat", (r.text and r.text ~= "") and r.text or "Learned from your game (no description read).", learned = true, spell = r.spell })
        end
    end
end
SFP:OnLogin(function() SFP:MergeLearnedCurios() end)

-- Reads the curios of the companion from the game (best effort: the delve companion API is not documented well).
-- Marks the ones found as owned. Returns how many were found and a short report of what the game answered.
function SFP:ScanOwnedCurios()
    local report, found = {}, 0
    local D = C_DelvesUI
    if not D then return 0, "The game has no delve interface (C_DelvesUI)." end
    local known = {}
    for _, cu in ipairs(self.CURIOS or {}) do known[cu[1]:lower()] = cu[1] end
    local configID
    for _, fname in ipairs({ "GetCompanionConfigID", "GetCurrentCompanionConfigID", "GetCompanionTraitConfigID" }) do
        if type(D[fname]) == "function" then
            local ok, id = pcall(D[fname])
            if ok and type(id) == "number" and id > 0 then configID = id; report[#report + 1] = fname .. " = " .. id; break end
        end
    end
    local nodes, nodeType = {}, {}
    local E = Enum and Enum.CurioType
    if type(E) == "table" and type(D.GetCurioNodeForCompanion) == "function" then
        for name, v in pairs(E) do
            local ok, node = pcall(D.GetCurioNodeForCompanion, v)
            if ok and type(node) == "number" and node > 0 then nodes[#nodes + 1] = node; nodeType[node] = tostring(name):lower(); report[#report + 1] = "curio type " .. tostring(name) .. " -> node " .. node end
        end
    end
    if configID and C_Traits and #nodes > 0 then
        for _, node in ipairs(nodes) do
            local okN, ni = pcall(C_Traits.GetNodeInfo, configID, node)
            if okN and type(ni) == "table" then
                for _, entryID in ipairs(ni.entryIDs or {}) do
                    local okE, ei = pcall(C_Traits.GetEntryInfo, configID, entryID)
                    local def = okE and type(ei) == "table" and ei.definitionID
                    local okD, di = pcall(C_Traits.GetDefinitionInfo, def or 0)
                    local name = okD and type(di) == "table" and (di.overrideName or (di.spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(di.spellID)))
                    if type(name) == "string" and not (issecretvalue and issecretvalue(name)) then
                        self.db.curiosOwned = self.db.curiosOwned or {}
                        if known[name:lower()] then
                            self.db.curiosOwned[known[name:lower()]] = true
                        else
                            -- a curio the addon did not know: learn it (name, slot, ids, text) and keep it in the saved data
                            local spellID = okD and type(di) == "table" and di.spellID or nil
                            local desc
                            if spellID and C_Spell and C_Spell.GetSpellDescription then
                                local okS, t = pcall(C_Spell.GetSpellDescription, spellID)
                                if okS and type(t) == "string" and not (issecretvalue and issecretvalue(t)) then desc = t end
                            end
                            self.db.learnedCurios = self.db.learnedCurios or {}
                            self.db.learnedCurios[name] = { slot = nodeType[node] or "combat", spell = spellID, node = node, entry = entryID, text = desc }
                            self.db.curiosOwned[name] = true
                            self:MergeLearnedCurios()
                        end
                        found = found + 1
                    end
                end
            end
        end
    end
    if found == 0 then
        local names = {}
        for k, v in pairs(D) do if type(v) == "function" then names[#names + 1] = k end end
        table.sort(names)
        report[#report + 1] = "Nothing matched. Delve functions of this game: " .. table.concat(names, ", ")
    end
    return found, table.concat(report, "; ")
end

function SFP:DelveBestSetup()
    local info = self:DelveInfo()
    local out = { companion = info.recommended, curios = {}, lines = {} }
    if not info.spec then return out end
    -- a delve's own guide can ask for a different companion role (sentences about Valeera)
    local delveNote
    if self.db.delveSel then
        local tips = self:DelveTips(self.db.delveSel)
        local roles, first = {}, nil
        for _, t in ipairs(tips and tips.tips or {}) do
            for _, r in ipairs({ "Healer", "Tank", "Damage" }) do
                if t:find(r, 1, true) then roles[r] = true; first = first or t end
            end
        end
        local n, only = 0, nil
        for r in pairs(roles) do n = n + 1; only = r end
        if n == 1 then out.companion = only; delveNote = first end
    end
    local known = {}
    for _, cu in ipairs(self.CURIOS or {}) do known[cu[1]] = cu[2] end
    local owned = self.db.curiosOwned or {}
    local function pick(slot, ...)
        local list = { ... }
        local anyOwned = false
        for _, cu in ipairs(self.CURIOS or {}) do if cu[2] == slot and owned[cu[1]] then anyOwned = true end end
        for _, name in ipairs(list) do
            if known[name] == slot and (not anyOwned or owned[name]) then out.curios[slot] = name; return end
        end
        -- none of the guide picks owned: the best-ranked one you own, if any
        for _, name in ipairs((self.CURIO_RANK or {})[slot] or {}) do
            if owned[name] then out.curios[slot] = name; return end
        end
    end
    -- Season 2 guide setup (one guide); Season 1 picks as the fallback when those curios are not in the list
    if out.companion == "Healer" then
        pick("combat", "Corrosive Bilespear", "Porcelain Blade Tip")
        pick("utility", "Soul-Cracking Dreamcatcher", "Mandate of Sacred Death")
    elseif out.companion == "Tank" then
        pick("combat", "Mantle of Stars", "Corrosive Bilespear", "Porcelain Blade Tip")
        pick("utility", "Soul-Cracking Dreamcatcher", "Mandate of Sacred Death")
    else
        pick("combat", "Corrosive Bilespear", "Porcelain Blade Tip")
        pick("utility", "Soul-Cracking Dreamcatcher", "Mandate of Sacred Death")
    end
    local L = out.lines
    L[#L + 1] = ("|cff00e5ffSuggested setup for %s|r"):format(info.spec.name)
    if self.db.delveSel then L[1] = ("|cff00e5ffSuggested setup for %s in %s|r"):format(info.spec.name, self.db.delveSel) end
    L[#L + 1] = ("  Valeera as |cff40ff40%s|r"):format(out.companion)
    if delveNote then L[#L + 1] = "  |cff808080Why (guide for this delve): " .. delveNote .. "|r" end
    for i, sl in ipairs(self:CurioSlots()) do
        if out.curios[sl.key] then L[#L + 1] = ("  Slot %d %s: |cff40ff40%s|r"):format(i, sl.label, out.curios[sl.key]) end
    end
    L[#L + 1] = "  Poison (Season 2): Frostheart Venom"
    L[#L + 1] = "|cff808080From the Season 2 guides (mostly one guide). Against the Nullaeus fight take Overflowing Voidspire as the utility curio; Mandate of Sacred Death does nothing where there are no profession nodes. Best-in-slot gear is not included: no checked source yet.|r"
    return out
end

function SFP:UseBestSetup()
    local b = self:DelveBestSetup()
    self:DelveSet("companion", b.companion)
    for slot, name in pairs(b.curios) do self:DelveSet("curio", name, slot) end
end

function SFP:DelveAdvice()
    local info = self:DelveInfo()
    local lines = {}
    if not info.spec then
        lines[#lines + 1] = "Your specialization is not known yet."
    else
        lines[#lines + 1] = ("You play %s (%s). Valeera should be |cff40ff40%s|r%s."):format(info.spec.name or "?", (info.spec.role or "?"):lower(), info.companion,
            info.chosen and (info.chosen ~= info.recommended and (" - your choice; the best for this spec is " .. info.recommended) or " - your choice, also the best for this spec") or " - the best for this spec")
        lines[#lines + 1] = "Curios: one Combat and one Utility slot. If your class has no crowd control, take a stun or slow curio. Tanks and healers: a damage curio helps the run go faster."
    end
    local parts = {}
    for i, sl in ipairs(self:CurioSlots()) do
        local n = self:DelveGet("curio", sl.key)
        if n then parts[#parts + 1] = ("Slot %d %s: %s"):format(i, sl.label, n) end
    end
    if #parts > 0 then lines[#lines + 1] = "Your curios: " .. table.concat(parts, "  |  ") end
    local tier = self:DelveGet("tier")
    lines[#lines + 1] = tier and ("Comfortable tier (you set it): |cffffd100" .. tier .. "|r. Use bountiful keys at this tier or one above.")
        or "Type the tier you can do safely into the box; the addon remembers it."
    return table.concat(lines, "\n\n")
end

-- text typed into the tier box: a number from 1 to 11, empty clears it
function SFP:SetDelveTier(text)
    local n = tonumber(text)
    if n then n = math.max(1, math.min(11, math.floor(n))) end
    self:DelveSet("tier", n)
    return n
end

-- every delve: the Codex seed list plus what the game's map shows now (with bountiful)
local delveCache, delveAt
function SFP:DelveList()
    if delveCache and GetTime() - delveAt < 60 then return delveCache end
    local out, seen = {}, {}
    local function add(name, zone, bountiful, live)
        if type(name) ~= "string" or secret(name) then return end
        local k = name:lower()
        local e = seen[k]
        if not e then e = { name = name, zone = zone or "?" }; seen[k] = e; out[#out + 1] = e end
        if live then e.live, e.bountiful, e.zone = true, bountiful, zone or e.zone end
    end
    local okM, _, cns = pcall(SFP_Module, "Codex")
    for _, d in ipairs((okM and cns and cns.DELVE_LIST) or {}) do add(d[1], d[2], nil, false) end
    local okZ, zones = pcall(C_Map.GetMapChildrenInfo, 946, Enum.UIMapType.Zone, true)
    if okZ and type(zones) == "table" and C_AreaPoiInfo and C_AreaPoiInfo.GetDelvesForMap then
        for _, z in ipairs(zones) do
            local ok, ids = pcall(C_AreaPoiInfo.GetDelvesForMap, z.mapID)
            for _, poiID in ipairs((ok and ids) or {}) do
                local okI, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, z.mapID, poiID)
                if okI and info and info.name then
                    local bountiful = info.atlasName and not secret(info.atlasName) and info.atlasName:lower():find("bountiful") and true or false
                    add(info.name, z.name, bountiful, true)
                end
            end
        end
    end
    table.sort(out, function(x, y) if x.zone ~= y.zone then return x.zone < y.zone end return x.name < y.name end)
    delveCache, delveAt = out, GetTime()
    return out
end

---------------------------------------------------------------------------
-- 9. missing here: mounts, pets and toys of the rares and bosses of this zone or instance
---------------------------------------------------------------------------
local function missingHere(mapID, instName, limit)
    local names, count = {}, 0
    local function check(itemIDs, label)
        for _, itemID in ipairs(itemIDs or {}) do
            local own = SFP.OwnedStatus and SFP:OwnedStatus(itemID)
            if own == false then
                count = count + 1
                if not limit or #names < limit then names[#names + 1] = SFP:ItemName(itemID) .. " (" .. label .. ")" end
            end
        end
    end
    for _, sp in ipairs((SFP.Rares and SFP.Rares[mapID]) or {}) do
        if sp.items and #sp.items > 0 then check(sp.items, sp.name or "rare") end
    end
    local zone = SFP.zoneByMap and SFP.zoneByMap[mapID]
    for _, inst in ipairs(zone and zone.instances or {}) do
        if not instName or inst.name == instName then check(inst.items, inst.name) end
    end
    return count, names
end

function SFP:ZoneCheck(quiet)
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local inInstance, itype = IsInInstance()
    local instName = (inInstance and (itype == "party" or itype == "raid")) and (GetInstanceInfo()) or nil
    local count, names = missingHere(mapID, instName, 3)
    if count > 0 then
        self:Print(("Missing here: %d collectible%s - %s%s"):format(count, count == 1 and "" or "s", table.concat(names, ", "),
            count > #names and (" and " .. (count - #names) .. " more") or ""))
    elseif not quiet then
        self:Print("Nothing missing here that the addon knows about (mounts, pets, toys of rares and bosses).")
    end
end

-- the same check as a text for the menu page: every missing collectible with where it comes from
function SFP:ZoneCheckReport()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return "Your zone is not known yet." end
    local inInstance, itype = IsInInstance()
    local instName = (inInstance and (itype == "party" or itype == "raid")) and (GetInstanceInfo()) or nil
    local count, names = missingHere(mapID, instName)
    local lines = { "|cff00e5ff" .. (instName or self:ZoneName(mapID)) .. "|r", "" }
    if count == 0 then
        lines[#lines + 1] = "Nothing missing here that the addon knows about (mounts, pets and toys of the rares and bosses here)."
    else
        lines[#lines + 1] = ("You still miss %d collectible%s here:"):format(count, count == 1 and "" or "s")
        for _, n in ipairs(names) do lines[#lines + 1] = "  - " .. n end
    end
    return table.concat(lines, "\n")
end

local zf = CreateFrame("Frame")
pcall(zf.RegisterEvent, zf, "ZONE_CHANGED_NEW_AREA")
pcall(zf.RegisterEvent, zf, "PLAYER_ENTERING_WORLD")
local lastZone, zoneTimer
zf:SetScript("OnEvent", function()
    if not (SFP.db and SFP.db.zoneCheck ~= false) or zoneTimer then return end
    zoneTimer = true
    C_Timer.After(6, function()
        zoneTimer = nil
        local m = C_Map.GetBestMapForUnit("player")
        if m and m ~= lastZone then
            lastZone = m
            SFP:Safe("zone check", SFP.ZoneCheck, SFP, true)
        end
    end)
end)

---------------------------------------------------------------------------
-- 10. housing decor you can craft (Midnight): the recipes the addon knows about
---------------------------------------------------------------------------
-- decor named in the Warcraft Tavern / Warcraft Secrets housing articles (no game IDs known): { name, where to get it }
local DECOR_NAMED = {
    { "Jewelcrafter's Tent", "Quest: The Perenolde Tiara (Alliance); Stormwind vendor for gold" },
    { "Akunda the Tapestry", "Quest: Clearing the Fog (Horde); Zuldazar vendor for War Resources" },
    { "Shaohao Ceremonial Bell", "Quest in Kun-Lai Summit; Lorewalkers in the Vale of Eternal Blossoms for gold" },
    { "Head of the Broodmother", "Achievement: More DoTs! (25 Player), Onyxia's Lair" },
    { "Portal to Damnation", "Achievement: Back from the Beyond; Ve'nari in the Maw" },
    { "Iron Dragonmaw Gate", "Achievement: The Master of Twin Peaks; capital-city vendors for Marks of Honor" },
    { "Lorewalker's Bookcase", "Lorewalkers, Revered" },
    { "Empty Lorewalker's Bookcase", "Lorewalkers, Revered" },
    { "Zandalari War Torch", "Talanji's Expedition, Honored" },
    { "Zandalari Sconce", "Talanji's Expedition, Honored" },
    { "Shadowmoon Greenhouse", "Council of Exarchs, Exalted" },
    { "Grand Draenethyst Lamp", "Council of Exarchs, Exalted" },
    { "The Large Razorwind Gazebo", "Neighborhood vendor, Razorwind Shores" },
    { "Wooden Gazebo", "Neighborhood vendor, Founder's Point" },
    { "A Wrought Iron Chandelier", "Neighborhood vendor, Founder's Point" },
    { "Iron Chain Chandelier", "Neighborhood vendor, Razorwind Shores" },
    { "Thunder Totem Brazier", "Neltharion's Lair, final boss" },
    { "Gilnean Circular Rug", "Shadowfang Keep, final boss" },
    { "Fate of All Life Painting", "Waycrest Manor, final boss" },
    { "Tidesage's Fireplace", "Shrine of the Storm, final boss" },
    { "Dalaran Display Shelves", "Inscription (Legion)" },
    { "Draenei Holo-Dais", "Enchanting (Outland)" },
    { "Draenei Holo-Path", "Enchanting (Outland)" },
    { "Intense Mogu Brazier", "Enchanting (Pandaria)" },
    { "Valdrakken Fences", "Jewelcrafting (Dragon Isles)" },
    { "Valdrakken Fenceposts", "Jewelcrafting (Dragon Isles)" },
    { "Draenethyst Sconce", "Jewelcrafting (Draenor)" },
    { "Miniature Replica Dark Portal", "Pre-Launch Event (recipe from a Heavy Junkbox)" },
}

local DECOR = {
    { 1246939, "Haranir Canopy Bed", "Harandar treasures" },
    { 1246943, "Plush Haranir Leather Pillow", "Heavy Trunk (Delves)" },
    { 1246893, "Replica Haranir Mural", "Heavy Trunk (Delves)" },
    { 1246892, "Resplendent Highborne Statue", "Eversong treasures" },
    { 1246894, "Shining Sin'dorei Hourglass", "Challenger's Cache" },
    { 1233132, "Entropic Illuminant", "Voidstorm treasures" },
    { 1233136, "Riftstone", "Heavy Trunk (Delves)" },
    { 1233138, "Silvermoon Spire Fountain", "Heavy Trunk (Delves)" },
    { 1248620, "Restful Bronze Bench", "Victorious Stormarion Pinnacle Cache" },
    { 1229002, "Luxurious Silvermoon Lounge Cushion", "Eversong treasures" },
    { 1246908, "Rootflame Campfire", "Heavy Trunk (Delves)" },
    { 1246903, "Ren'dorei Postage Repository", "Voidstorm treasures" },
}

local decorWin, decorBox, decorSearcher, decorCache, decorAt
local decorMode = "all"
local decorBtns = {}

local function plainText(t)
    return (tostring(t or ""):gsub("|n", "  "):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- every decor the game's own housing catalog lists, with the source the game gives for it
local function catalogEntries()
    local H = C_HousingCatalog
    if not (H and H.CreateCatalogSearcher and H.GetCatalogEntryInfo) then return nil end
    if not decorSearcher then
        local ok, srch = pcall(H.CreateCatalogSearcher)
        if not ok or type(srch) ~= "table" then return nil end
        for _, m in ipairs({ { "SetOwnedOnly", false }, { "SetCollected", true }, { "SetUncollected", true },
            { "SetAllowedIndoors", true }, { "SetAllowedOutdoors", true } }) do
            if type(srch[m[1]]) == "function" then pcall(srch[m[1]], srch, m[2]) end
        end
        if type(srch.RunSearch) == "function" then pcall(srch.RunSearch, srch) end
        decorSearcher = srch
    end
    if type(decorSearcher.GetCatalogSearchResults) ~= "function" then return nil end
    local ok, ids = pcall(decorSearcher.GetCatalogSearchResults, decorSearcher)
    if not ok or type(ids) ~= "table" or #ids == 0 then return nil end
    local out = {}
    for _, entryID in ipairs(ids) do
        local okI, info = pcall(H.GetCatalogEntryInfo, entryID)
        if okI and type(info) == "table" and type(info.name) == "string" and not secret(info.name) then
            local qty = (tonumber(info.quantity) or 0) + (tonumber(info.numPlaced) or 0)
            local eid = type(entryID) == "table" and entryID.recordID or nil
            out[#out + 1] = { name = info.name, owned = qty > 0, source = plainText(info.sourceText), itemID = tonumber(info.itemID), decorID = tonumber(eid) }
        end
    end
    return out
end

-- owned count of one decor item from the game's housing catalog (nil = the game would not say)
local function decorOwned(itemID)
    local H = C_HousingCatalog
    if not (H and H.GetCatalogEntryInfoByItem) then return nil end
    local ok, info = pcall(H.GetCatalogEntryInfoByItem, itemID, true)
    if not ok or type(info) ~= "table" then return nil end
    return (tonumber(info.quantity) or 0) + (tonumber(info.numPlaced) or 0)
end

local function decorEntries()
    if decorCache and GetTime() - decorAt < 60 then return decorCache.list, decorCache.fromGame end
    local list, byName, byItem, fromGame = {}, {}, {}, false
    for _, d in ipairs(SFP.DecorData or {}) do
        local name = d[3] ~= "" and d[3] or ("Decor item " .. d[1])
        local e = { name = name, itemID = d[1], decorID = d[2] > 0 and d[2] or nil, source = d[4], unknownOwned = true }
        local own = decorOwned(d[1])
        if own ~= nil then e.owned, e.unknownOwned, fromGame = own > 0, false, true end
        e.placeholder = d[3] == ""
        list[#list + 1] = e
        byName[name:lower()] = e
        byItem[d[1]] = e
    end
    -- decor shipped from a played account: fills names and sources and corrects the data
    for _, d in ipairs(SFP.DecorLearned or {}) do
        local name = d[3] ~= "" and d[3] or ("Decor item " .. d[1])
        local old = byItem[d[1]]
        if old then
            if d[3] ~= "" then old.name, old.placeholder = d[3], false; byName[d[3]:lower()] = old end
            if d[4] ~= "" then old.source = d[4] end
            if d[2] > 0 then old.decorID = d[2] end
        elseif not byName[name:lower()] then
            local e = { name = name, itemID = d[1] > 0 and d[1] or nil, decorID = d[2] > 0 and d[2] or nil, source = d[4], unknownOwned = true }
            list[#list + 1] = e
            byName[name:lower()] = e
        end
    end
    -- what the game's catalog lists on top (decor newer than the addon's data), and its owned state
    local cat = catalogEntries()
    if cat then
        fromGame = true
        for _, c in ipairs(cat) do
            local e = (c.itemID and byItem[c.itemID]) or byName[c.name:lower()]
            local hadID = e and e.decorID
            local changed = false
            if e then
                e.owned, e.unknownOwned = c.owned, false
                -- the game is right: fill what is empty and fix what differs
                if c.name ~= e.name then e.name, changed = c.name, true end
                if (c.source or "") ~= "" and c.source ~= e.source then e.source, changed = c.source, true end
                if c.decorID and e.decorID ~= c.decorID then e.decorID, changed = c.decorID, true end
                e.placeholder = false
            else
                list[#list + 1] = c
            end
            -- learn what the addon's data lacks (new decor, missing decor IDs); saved with the account data
            if SFP.db and (not e or changed or (c.decorID and not hadID)) then
                SFP.db.learnedDecor = SFP.db.learnedDecor or {}
                local key = c.itemID and tostring(c.itemID) or c.name
                SFP.db.learnedDecor[key] = { item = c.itemID, decor = c.decorID or (e and e.decorID), name = c.name, source = c.source }
            end
        end
    end
    -- the craftable recipes: known or not
    local have = {}
    for _, d in ipairs(DECOR) do
        local ok, has = pcall(function() return IsPlayerSpell and IsPlayerSpell(d[1]) or (IsSpellKnown and IsSpellKnown(d[1])) end)
        if ok and has then have[d[2]:lower()] = true end
    end
    for _, e in ipairs(list) do e.recipeKnown = have[e.name:lower()] end
    for _, e in ipairs(list) do
        local src = e.source or ""
        local kind = src:match("^(.-)[:%(]") or src
        kind = strtrim(kind)
        if kind == "" then kind = "Unknown" end
        e.kind = kind:sub(1, 1):upper() .. kind:sub(2)
        -- place: the zone or instance after the last " - ", or the profession of a crafted decor
        local place = src:match(".* %- (.-)$")
        if e.kind == "Crafted" then place = src:match("^Crafted %(([^,%)]+)") end
        e.place = (place and place ~= "") and place or "Unknown"
    end
    table.sort(list, function(x, y) return x.name:lower() < y.name:lower() end)
    decorCache, decorAt = { list = list, fromGame = fromGame }, GetTime()
    return list, fromGame
end

-- learning needs no window: reads the housing catalog by itself
function SFP:LearnDecor()
    decorCache = nil
    decorEntries()
end

local decorKind, decorPlace
local decorFilterBox

local function decorList(counts, order, current, onPick, total)
    local items = { { text = "", buttons = { { (current == nil and "|cff40ff40" or "") .. "All (" .. total .. ")", 168, function() onPick(nil) end } } } }
    for _, k in ipairs(order) do
        items[#items + 1] = { text = "", buttons = { { (current == k and "|cff40ff40" or "") .. k .. " (" .. counts[k] .. ")", 168, function() onPick(k) end } } }
    end
    return items
end

local function decorRefresh()
    if not decorWin or not decorWin:IsShown() then return end
    local list, fromGame = decorEntries()
    local filter = (decorBox:GetText() or ""):lower()
    local own = 0
    local kc, korder, pc, porder = {}, {}, {}, {}
    for _, e in ipairs(list) do
        if e.owned then own = own + 1 end
        if not kc[e.kind] then kc[e.kind] = 0; korder[#korder + 1] = e.kind end
        kc[e.kind] = kc[e.kind] + 1
    end
    table.sort(korder, function(x, y) return kc[x] > kc[y] end)
    -- the places depend on the chosen type
    for _, e in ipairs(list) do
        if not decorKind or e.kind == decorKind then
            if not pc[e.place] then pc[e.place] = 0; porder[#porder + 1] = e.place end
            pc[e.place] = pc[e.place] + 1
        end
    end
    table.sort(porder, function(x, y) if pc[x] ~= pc[y] then return pc[x] > pc[y] end return x < y end)
    decorWin.kinds:Set(decorList(kc, korder, decorKind, function(k) decorKind = k; decorPlace = nil; decorRefresh() end, #list))
    local ptotal = 0
    for _, n in pairs(pc) do ptotal = ptotal + n end
    decorWin.places:Set(decorList(pc, porder, decorPlace, function(k) decorPlace = k; decorRefresh() end, ptotal))

    local lines, shown = {}, 0
    lines[1] = ("|cff808080%d decor items. %s|r"):format(#list,
        fromGame and ("You own " .. own .. " (read from the game).") or "The game's housing catalog could not be read, so owned or not is unknown (owned? = unknown).")
    lines[2] = ""
    for _, e in ipairs(list) do
        local pass = (decorMode == "all") or (decorMode == "missing" and not e.owned and not e.unknownOwned) or (decorMode == "owned" and e.owned)
        if pass and decorKind and e.kind ~= decorKind then pass = false end
        if pass and decorPlace and e.place ~= decorPlace then pass = false end
        if pass and filter ~= "" then
            pass = e.name:lower():find(filter, 1, true) or (e.source or ""):lower():find(filter, 1, true)
        end
        if pass then
            shown = shown + 1
            if shown <= 250 then
                local farm = ""
                local src = e.itemID and SFP.itemSources and SFP.itemSources[e.itemID]
                if src and src[1] then farm = "  |cff80ff80farm: " .. src[1] .. "|r" end
                lines[#lines + 1] = ("%s %s%s%s"):format(e.unknownOwned and "|cff808080owned?|r" or (e.owned and "|cff40ff40owned|r" or "|cffff6060missing|r"),
                    e.name .. (e.recipeKnown and "  |cff40ff40recipe known|r" or ""),
                    (e.source and e.source ~= "") and ("\n      |cff808080" .. e.source .. "|r") or "", farm)
            end
        end
    end
    lines[2] = ("|cffffd100%d shown|r"):format(shown) .. (decorKind and ("  type: " .. decorKind) or "") .. (decorPlace and ("  place: " .. decorPlace) or "")
    if shown > 250 then lines[#lines + 1] = ("|cff808080+%d more - pick a type or place, or search|r"):format(shown - 250) end
    if shown == 0 then lines[#lines + 1] = "Nothing matches." end
    for _, bt in ipairs(decorBtns) do bt:SetText((bt.mode == decorMode and "|cff40ff40" or "") .. bt.label) end
    decorWin:SetContent(table.concat(lines, "\n"))
end

function SFP:ShowDecor()
    if not decorWin then
        decorWin = window("SeviathsUsefulToolsDecor", "Housing decor - all of it, and where to get it", 820, 580)
        decorWin.scroll:ClearAllPoints()
        decorWin.scroll:SetPoint("TOPLEFT", 214, -66)
        decorWin.scroll:SetPoint("BOTTOMRIGHT", -30, 12)
        decorWin.child:SetWidth(570)
        decorWin.text:SetWidth(566)
        local sl = decorWin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sl:SetPoint("TOPLEFT", 216, -40)
        sl:SetText("Search:")
        decorBox = CreateFrame("EditBox", nil, decorWin, "InputBoxTemplate")
        decorBox:SetSize(230, 20)
        decorBox:SetPoint("TOPLEFT", 270, -37)
        decorBox:SetAutoFocus(false)
        decorBox:SetScript("OnTextChanged", function() decorRefresh() end)
        decorBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); decorRefresh() end)
        decorBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local x = 520
        for _, m in ipairs({ { "all", "All", 50 }, { "missing", "Missing", 70 }, { "owned", "Owned", 60 } }) do
            local bt = CreateFrame("Button", nil, decorWin, "UIPanelButtonTemplate")
            bt:SetSize(m[3], 22)
            bt:SetPoint("TOPLEFT", x, -36)
            bt.mode, bt.label = m[1], m[2]
            bt:SetText(m[2])
            bt:SetScript("OnClick", function() decorMode = m[1]; decorRefresh() end)
            decorBtns[#decorBtns + 1] = bt
            x = x + m[3] + 4
        end
        local l1 = decorWin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        l1:SetPoint("TOPLEFT", 14, -36)
        l1:SetText("Type (quest, crafted, drop ...):")
        decorWin.kinds = SFP.MakeRowList(decorWin, 10, -52, 196, 190, 22)
        local l2 = decorWin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        l2:SetPoint("TOPLEFT", 14, -252)
        l2:SetText("Place (zone, instance, profession):")
        decorWin.places = SFP.MakeRowList(decorWin, 10, -268, 196, 300, 22)
        local acc = 0
        decorWin:SetScript("OnUpdate", function(_, dt)
            acc = acc + dt
            if acc < 5 then return end
            acc = 0
            SFP:Safe("decor", decorRefresh)
        end)
    end
    decorWin:Show()
    decorRefresh()
end

---------------------------------------------------------------------------
-- 8. achievement planner
---------------------------------------------------------------------------
local achWin, achBox, achResults, achRows, achAddBtn = nil, nil, {}, nil, nil
local achCur
local npcIndex

local function npcWhere(npcID)
    if not npcIndex then
        npcIndex = {}
        for mapID, list in pairs(SFP.Rares or {}) do
            for _, sp in ipairs(type(list) == "table" and list or {}) do
                if sp.npc and sp.npc > 0 and sp.hx then npcIndex[sp.npc] = { map = mapID, x = sp.hx, y = sp.hy, name = sp.name } end
            end
        end
        for mapID, list in pairs(SFP.Spawns or {}) do
            for _, sp in ipairs(type(list) == "table" and list or {}) do
                if sp.npc and sp.npc > 0 and sp.hx and not npcIndex[sp.npc] then npcIndex[sp.npc] = { map = mapID, x = sp.hx, y = sp.hy, name = sp.name } end
            end
        end
    end
    return npcIndex[npcID]
end

local function achDetail(id)
    local ok, _, name, points, completed, _, _, _, desc = pcall(GetAchievementInfo, id)
    if not ok or not name then return "Could not read that achievement.", nil end
    local lines = { "|cff00e5ff" .. name .. "|r  |cff808080" .. (points or 0) .. " points|r" }
    if desc and desc ~= "" then lines[#lines + 1] = desc end
    if completed then lines[#lines + 1] = "|cff40ff40Completed on this account.|r"; return table.concat(lines, "\n"), nil end
    local n = GetAchievementNumCriteria and GetAchievementNumCriteria(id) or 0
    local left, done, firstWhere = {}, 0, nil
    for i = 1, n do
        local ok2, cname, ctype, ccomplete, qty, req, _, _, assetID = pcall(GetAchievementCriteriaInfo, id, i)
        if ok2 then
            if ccomplete then done = done + 1
            else
                local where = (ctype == 0 and assetID and assetID > 0) and npcWhere(assetID) or nil
                local label = (cname and cname ~= "") and cname or ("step " .. i)
                local prog = (req and req > 1) and ("  " .. (qty or 0) .. "/" .. req) or ""
                local loc = where and ("  |cff80ff80" .. SFP:ZoneName(where.map) .. (where.x and (" %.1f, %.1f"):format(where.x * 100, where.y * 100) or "") .. "|r") or ""
                left[#left + 1] = "• " .. label .. prog .. loc
                if where and not firstWhere then firstWhere = where; firstWhere.label = label end
            end
        end
    end
    lines[#lines + 1] = ("%d of %d steps done, %d left:"):format(done, n, n - done)
    for i = 1, math.min(25, #left) do lines[#lines + 1] = left[i] end
    if #left > 25 then lines[#lines + 1] = "+" .. (#left - 25) .. " more" end
    if firstWhere then lines[#lines + 1] = "\n|cffffd100Do first:|r " .. firstWhere.label .. " - the nearest step with a known place (button: waypoint)." end
    return table.concat(lines, "\n"), firstWhere
end

local achWay

-- the saved list lives with the addon's data: { { id =, name = }, ... }
local function achData()
    SFP.db.achList = SFP.db.achList or {}
    return SFP.db.achList
end

local function achIndex(id)
    for i, e in ipairs(achData()) do if e.id == id then return i end end
end

local function achProgress(id)
    local ok, _, name, _, completed = pcall(GetAchievementInfo, id)
    if not ok or not name then return nil end
    local n = GetAchievementNumCriteria and GetAchievementNumCriteria(id) or 0
    local done = 0
    for i = 1, n do
        local ok2, _, _, ccomplete = pcall(GetAchievementCriteriaInfo, id, i)
        if ok2 and ccomplete then done = done + 1 end
    end
    return name, completed, n, done
end

local function achOpen(id, name)
    achCur = { id = id, name = name }
    local text, where = achDetail(id)
    achWay = where
    achWin:SetContent(text)
    SFP:AchRefreshList()
end

function SFP:AchRefreshList()
    if not achWin then return end
    local items = {}
    for _, e in ipairs(achData()) do
        local name, completed, n, done = achProgress(e.id)
        local state = completed and "|cff40ff40completed|r" or (n and n > 0 and ("|cff808080" .. done .. "/" .. n .. " steps|r") or "")
        local id, saved = e.id, e.name
        items[#items + 1] = {
            text = (name or saved or ("#" .. id)) .. "  " .. state,
            buttons = {
                { "Open", 50, function() achOpen(id, name or saved) end },
                { "Remove", 60, function()
                    local i = achIndex(id)
                    if i then table.remove(achData(), i) end
                    SFP:AchRefreshList()
                end },
            },
        }
    end
    achRows:Set(items)
    if achAddBtn then
        achAddBtn:SetEnabled(achCur ~= nil)
        achAddBtn:SetText((achCur and achIndex(achCur.id)) and "Remove from list" or "Add to list")
    end
end

local function achSearch(text)
    local found = {}
    local _, ns = SFP_Module("Codex")
    if ns and ns.Search and #(text or "") >= 3 then
        local ok, res = pcall(ns.Search, ns, text, "achievement", 6)
        if ok and type(res) == "table" then found = res end
    end
    for i, b in ipairs(achResults) do
        local e = found[i]
        b.e = e
        if e then b:SetText(e.name .. "  |cff808080#" .. tostring(e.id) .. "|r"); b:Show() else b:Hide() end
    end
end

function SFP:ShowAchPlanner()
    if not achWin then
        achWin = window("SeviathsUsefulToolsAch", "Achievement planner", 560, 580)
        achWin.scroll:SetPoint("TOPLEFT", 12, -300)
        achBox = CreateFrame("EditBox", nil, achWin, "InputBoxTemplate")
        achBox:SetSize(220, 22)
        achBox:SetPoint("TOPLEFT", 22, -34)
        achBox:SetAutoFocus(false)
        achBox:SetScript("OnTextChanged", function(self) achSearch(self:GetText()) end)
        achBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        achAddBtn = CreateFrame("Button", nil, achWin, "UIPanelButtonTemplate")
        achAddBtn:SetSize(120, 22)
        achAddBtn:SetPoint("LEFT", achBox, "RIGHT", 10, 0)
        achAddBtn:SetText("Add to list")
        achAddBtn:SetScript("OnClick", function()
            if not achCur then return end
            local i = achIndex(achCur.id)
            if i then table.remove(achData(), i) else achData()[#achData() + 1] = { id = achCur.id, name = achCur.name } end
            SFP:AchRefreshList()
        end)
        local way = CreateFrame("Button", nil, achWin, "UIPanelButtonTemplate")
        way:SetSize(150, 22)
        way:SetPoint("LEFT", achAddBtn, "RIGHT", 6, 0)
        way:SetText("Waypoint to first step")
        way:SetScript("OnClick", function()
            if achWay and SFP.SetWaypoint then SFP:SetWaypoint(achWay.map, achWay.x, achWay.y, achWay.label) end
        end)
        for i = 1, 6 do
            local b = CreateFrame("Button", nil, achWin, "UIPanelButtonTemplate")
            b:SetSize(510, 18)
            b:SetPoint("TOPLEFT", 22, -62 - (i - 1) * 16)
            b:SetScript("OnClick", function(self)
                if not self.e then return end
                achOpen(tonumber(self.e.id) or 0, self.e.name)
            end)
            b:Hide()
            achResults[i] = b
        end
        local label = achWin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 22, -168)
        label:SetText("Your list (saved - add or remove whenever you want):")
        achRows = SFP.MakeRowList(achWin, 18, -186, 530, 104, 20)
        achWin:SetContent("Type part of an achievement name above and click a result. You get what is left, where each step is when the addon knows the place, and what to do first. Press Add to list to keep it: the list is saved and shows your progress each time you open this window.")
        achWin:HookScript("OnShow", function() SFP:Safe("ach list", SFP.AchRefreshList, SFP) end)
    end
    achWin:Show()
    self:AchRefreshList()
end

-- curios and decor are learned automatically (silent; the delve planner button reads the curios again with a report)
SFP:OnLogin(function()
    -- everything is learned by itself: a minute after login, then every 15 minutes while you play
    local function learnAll()
        SFP:Safe("curio scan", SFP.ScanOwnedCurios, SFP)
        SFP:Safe("decor learning", SFP.LearnDecor, SFP)
    end
    C_Timer.After(45, learnAll)
    C_Timer.NewTicker(900, learnAll)
end)

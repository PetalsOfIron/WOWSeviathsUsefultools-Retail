-- SeviathsUsefulTools - main menu
-- One window for everything. Left and right click on the minimap button open it, so does /sut.
-- Sections: Home, Farm & Map, Guides (Codex), Groups, Guild, Learned data, Settings.

local ADDON, SFP = ...
local CY = SFP.CYAN
local CYHEX = "|c" .. SFP.CYAN_HEX

local frame
local navButtons, panes, current = {}, {}, nil

local SECTIONS = {
    { key = "home",     label = "Home" },
    { key = "farm",     label = "Farm & Map" },
    { key = "alerts",   label = "Rare Alerts" },
    { key = "killed",   label = "Killed Today" },
    { key = "route",    label = "Farm Route" },
    { key = "session",  label = "Farm Session" },
    { key = "next",     label = "What To Farm Next" },
    { key = "weekly",   label = "Weekly Checklist" },
    { key = "deals",    label = "BoE Deals" },
    { key = "shop",     label = "Shopping List" },
    { key = "collect",  label = "My Collections" },
    { key = "share",    label = "Share Data" },
    { key = "delve",    label = "Delve Planner" },
    { key = "keys",     label = "Delve Keys" },
    { key = "ach",      label = "Achievement Planner" },
    { key = "zone",     label = "Zone Check" },
    { key = "decor",    label = "Housing Decor" },
    { key = "alts",     label = "Alt Overview" },
    { key = "guides",   label = "Guides (Codex)" },
    { key = "groups",   label = "Groups" },
    { key = "guild",    label = "Guild" },
    { key = "know",     label = "Learned data" },
    { key = "settings", label = "Settings" },
}

local function backdrop(f, r, g, b, a, br, bg_, bb, ba)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(r, g, b, a)
    f:SetBackdropBorderColor(br, bg_, bb, ba)
end

local function mkButton(parent, text, w, fn, tip)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, 22)
    backdrop(b, 0.06, 0.18, 0.22, 0.95, CY.r, CY.g, CY.b, 0.6)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("CENTER")
    b.text:SetText(text)
    b:SetScript("OnClick", function(self) fn(self) end)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.1, 0.35, 0.42, 1)
        if tip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self) self:SetBackdropColor(0.06, 0.18, 0.22, 0.95); GameTooltip:Hide() end)
    return b
end

local function mkText(parent, text, x, y, w, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    if w then fs:SetWidth(w) end
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

local function mkCheck(parent, label, getter, setter, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    t:SetText(label)
    cb:SetHitRectInsets(0, -(t:GetStringWidth() + 6), 0, 0)   -- the label can be clicked too
    cb:SetScript("OnClick", function(self) setter(self:GetChecked() and true or false) end)
    cb.refresh = function() cb:SetChecked(getter() and true or false) end
    return cb
end

local function codex() return _G.SeviathsCodex end

---------------------------------------------------------------------------
-- Sections
---------------------------------------------------------------------------
local function countKeys(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end

local function buildHome(pane)
    mkText(pane, CYHEX .. "SeviathsUsefulTools|r", 12, -10, 480, "GameFontNormalLarge")
    mkText(pane, "Everything in one place. Pick a section on the left:", 12, -36, 500)
    local list = {
        { "Farm & Map", "farm", "Glowing farm spots, rares and gathering routes on the world map, prices, layers." },
        { "Guides (Codex)", "guides", "How to do things: dungeons, raids, bosses, quests, mounts, pets, entrances, materials, gold." },
        { "Groups", "groups", "Raid buffs, tier tokens, player tags and notes for dungeons and raids." },
        { "Guild", "guild", "Find and invite players for your guild, charter signatures." },
        { "Learned data", "know", "Every monster, item, node and recipe the addon has learned from your play." },
        { "Settings", "settings", "Switches for the map, tooltips and learning." },
    }
    for i, e in ipairs(list) do
        local y = -64 - (i - 1) * 44
        mkButton(pane, e[1], 130, function() SFP:ShowMenuSection(e[2]) end):SetPoint("TOPLEFT", 12, y)
        mkText(pane, e[3], 152, y - 2, 360, "GameFontHighlightSmall"):SetTextColor(0.8, 0.8, 0.8)
    end
    pane.stats = mkText(pane, "", 12, -420, 500, "GameFontHighlightSmall")
    pane.refresh = function()
        local db = SFP.db
        pane.stats:SetText(("|cff808080Learned so far: %d monsters, %d items, %d gathering nodes, %d recipes. Saved for all your characters.|r")
            :format(countKeys(db.npcs), countKeys(db.knownItems), countKeys(db.objects), countKeys(db.recipes)))
    end
end

local function buildFarm(pane)
    mkText(pane, CYHEX .. "Farm & Map|r", 12, -10, 480, "GameFontNormalLarge")
    mkText(pane, "Farm spots, rares, hunter tames and best gathering zones on the world map.", 12, -34, 500, "GameFontHighlightSmall")
    mkButton(pane, "Farm browser", 130, function() SFP:ToggleBrowser() end, "Expansions, zones, items with auction prices, coordinates"):SetPoint("TOPLEFT", 12, -58)
    mkButton(pane, "Open world map", 130, function() SFP:OpenMapTo(C_Map.GetBestMapForUnit("player") or 1) end):SetPoint("TOPLEFT", 150, -58)
    mkButton(pane, "Scan auction prices", 150, function() SFP:StartScan(true) end, "The auction house must be open"):SetPoint("TOPLEFT", 288, -58)
    mkText(pane, "Layers on the world map:", 12, -92, 400)
    local checks = {
        { "mapOverlay", "Show farm layer" }, { "showSpawns", "Monster farm spots" }, { "showRares", "Rares (mounts, pets)" },
        { "showHunter", "Hunter tames" }, { "showMining", "Mining zones" }, { "showHerbs", "Herb zones" },
        { "showDungeons", "Dungeon entrances" }, { "showRaids", "Raid entrances" }, { "showSpecial", "Special materials" },
        { "showGatherList", "Gathering list" }, { "showSpotList", "Farm spot list (switch single spots off)" }, { "showLabels", "Names on the map" }, { "learn", "Learn farm spots from my loot" },
        { "exactSpots", "Exact spot markers (not areas)" }, { "continentSpots", "Also on continent maps (crowded)" }, { "minimapSpots", "Also show spots on the minimap" },
    }
    pane.checks = {}
    for i, c in ipairs(checks) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local cb = mkCheck(pane, c[2], function() return SFP.db[c[1]] end, function(v) SFP.db[c[1]] = v; SFP:RefreshAll() end,
            12 + col * 250, -116 - row * 26)
        pane.checks[#pane.checks + 1] = cb
    end
    pane.refresh = function() for _, cb in ipairs(pane.checks) do cb.refresh() end end
end

-- a simple page: title, a short explanation, then whatever the page adds
local function pageHead(pane, title, desc)
    mkText(pane, CYHEX .. title .. "|r", 12, -10, 480, "GameFontNormalLarge")
    local fs = mkText(pane, desc, 12, -38, 500, "GameFontHighlightSmall")
    fs:SetTextColor(0.85, 0.85, 0.85)
    fs:SetSpacing(2)
    return -38 - math.max(30, fs:GetStringHeight() or 30) - 14
end

local function simplePage(title, desc, fill)
    return function(pane)
        local y = pageHead(pane, title, desc)
        local refresh = fill(pane, y) or function() end
        pane.refresh = function() refresh() end
    end
end

local buildAlerts = simplePage("Rare Alerts",
    "When a rare you still miss a mount, pet or toy from shows up near you, the addon plays a sound and prints a chat line with a clickable [set waypoint]. " ..
    "It uses the game's map markers for rares. It only alerts for rares you do not own everything from and have not killed today. " ..
    "The switches for this are on the Settings page.",
    function(pane, y)
        mkButton(pane, "Open Settings", 150, function() SFP:ShowMenuSection("settings") end):SetPoint("TOPLEFT", 12, y)
    end)

local buildKilled = simplePage("Killed Today",
    "Everything you killed today (since the daily reset) that gave loot, per character. Rares are greyed out on the map and marked [killed today] until the reset. " ..
    "The switch for this is on the Settings page.",
    function(pane, y)
        mkButton(pane, "Forget today's kills", 170, function() SFP:ClearKilled(); pane.refresh() end,
            "Shows the rares you killed today on the map again."):SetPoint("TOPLEFT", 12, y)
        mkButton(pane, "Open Settings", 150, function() SFP:ShowMenuSection("settings") end):SetPoint("TOPLEFT", 192, y)
        local scroll = CreateFrame("ScrollFrame", nil, pane, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, y - 34)
        scroll:SetPoint("BOTTOMRIGHT", -30, 10)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(480, 10)
        scroll:SetScrollChild(child)
        local txt = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        txt:SetPoint("TOPLEFT")
        txt:SetWidth(470)
        txt:SetJustifyH("LEFT")
        txt:SetSpacing(3)
        return function()
            local list = SFP:KilledTodayList()
            local lines, last = {}, nil
            for _, k in ipairs(list) do
                if k.char ~= last then
                    lines[#lines + 1] = (#lines > 0 and "\n" or "") .. "|cff00e5ff" .. k.char .. "|r"
                    last = k.char
                end
                lines[#lines + 1] = ("  %s%s  |cff808080%s  -  %s|r"):format(k.name, k.rare and "  |cffff9933[rare]|r" or "", k.zone, date("%H:%M", k.t))
            end
            if #lines == 0 then lines[1] = "Nothing killed today yet that gave loot." end
            txt:SetText(table.concat(lines, "\n"))
            child:SetHeight(txt:GetStringHeight() + 10)
        end
    end)

local buildRoute = simplePage("Farm Route",
    "Pick a zone from the list: the addon orders its farm spots into a short loop, opens the map there, draws the route as a yellow line and sets a waypoint to the first stop. " ..
    "Spots you switched off in the spot list on the map are left out. The switch to show or hide the line is on the Settings page.",
    function(pane, y)
        mkButton(pane, "Route for the open map / this zone", 250, function()
            local m = WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame:GetMapID() or C_Map.GetBestMapForUnit("player")
            if m then SFP:BuildRoute(m) end
        end, "Uses the zone map that is open, or the zone you are in."):SetPoint("TOPLEFT", 12, y)
        mkButton(pane, "Clear route", 130, function() SFP:ClearRoute() end):SetPoint("TOPLEFT", 270, y)
        mkText(pane, "Search a zone:", 12, y - 38, 120, "GameFontHighlightSmall")
        local filter = CreateFrame("EditBox", nil, pane, "InputBoxTemplate")
        filter:SetSize(220, 22)
        filter:SetPoint("TOPLEFT", 110, y - 34)
        filter:SetAutoFocus(false)
        filter:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local scroll = CreateFrame("ScrollFrame", nil, pane, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, y - 66)
        scroll:SetPoint("BOTTOMRIGHT", -30, 10)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(470, 10)
        scroll:SetScrollChild(child)
        local rows = {}
        local function fill()
            local text = (filter:GetText() or ""):lower()
            local n = 0
            for _, z in ipairs(SFP:RouteZones()) do
                if text == "" or z.name:lower():find(text, 1, true) or z.exp:lower():find(text, 1, true) then
                    n = n + 1
                    local b = rows[n]
                    if not b then
                        b = mkButton(child, "", 460, function(self)
                            local zone = self.zone
                            if not zone then return end
                            if SFP.OpenMapTo then SFP:OpenMapTo(zone.map) end
                            SFP:BuildRoute(zone.map)
                        end)
                        b.text:ClearAllPoints()
                        b.text:SetPoint("LEFT", 8, 0)
                        rows[n] = b
                    end
                    b:ClearAllPoints()
                    b:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(n - 1) * 24)
                    b.zone = z
                    b.text:SetText(("%s  |cff808080%s  -  %d spots|r"):format(z.name, z.exp, z.count))
                    b:Show()
                end
            end
            for i = n + 1, #rows do rows[i]:Hide() end
            child:SetHeight(n * 24 + 6)
        end
        filter:SetScript("OnTextChanged", fill)
        return fill
    end)

local buildSession = simplePage("Farm Session",
    "Start a session before you farm: it counts your kills, the gold you loot and what the loot is worth at auction prices, and shows the total and the gold per hour in a small window you can move. Stop it when you are done: the result is printed in chat.",
    function(pane, y)
        local state = mkText(pane, "", 12, y - 4, 500, "GameFontNormal")
        mkButton(pane, "Start session", 130, function() SFP:SessionStart(); pane.refresh() end):SetPoint("TOPLEFT", 12, y - 26)
        mkButton(pane, "Stop session", 130, function() SFP:SessionStop(); pane.refresh() end):SetPoint("TOPLEFT", 150, y - 26)
        mkButton(pane, "Show / hide window", 160, function() SFP:SessionToggle("window") end):SetPoint("TOPLEFT", 288, y - 26)
        local txt = mkText(pane, "", 12, y - 64, 500, "GameFontHighlightSmall")
        local cmds = mkText(pane, "Commands:\n/sfp session  -  start a session (or show the window)\n/sfp session stop  -  stop it and print the result\n" ..
            "/sfp session hide  -  hide the window     /sfp session show  -  show it again", 12, y - 150, 500, "GameFontHighlightSmall")
        cmds:SetTextColor(0.7, 0.7, 0.7)
        return function()
            local s = SFP.session
            state:SetText(not s and "No session running" or (s.stop and "Session stopped" or "|cff40ff40Session running|r"))
            txt:SetText(SFP.SessionSummary and SFP:SessionSummary() or "")
        end
    end)

local buildNext = simplePage("What To Farm Next",
    "Rares that still drop a mount, pet or toy you do not own, nearest first (killed today come last). Press Waypoint on the one you want. It needs your collections to be read (see My Collections).",
    function(pane, y)
        local rows = {}
        for i = 1, 9 do
            local btn = mkButton(pane, "Waypoint", 80, function() end)
            btn:SetPoint("TOPLEFT", 12, y - 28 - (i - 1) * 36)
            local fs = mkText(pane, "", 100, y - 30 - (i - 1) * 36, 410, "GameFontHighlightSmall")
            rows[i] = { btn = btn, fs = fs }
        end
        local head = mkText(pane, "", 12, y, 500, "GameFontNormal")
        local retry
        local function fill()
            local top, total = SFP:FarmNext(9)
            head:SetText(total > 0 and (total .. " rares have something you miss") or "Nothing to suggest (or your collections are not read yet)")
            for i, r in ipairs(rows) do
                local c = top[i]
                if c then
                    local names = {}
                    for _, id in ipairs(c.missing) do names[#names + 1] = SFP:ItemName(id) end
                    local where = c.sp.hx and ("%.1f, %.1f"):format(c.sp.hx * 100, c.sp.hy * 100) or ""
                    r.fs:SetText(("|cffffd100%s|r  %s %s%s\nmissing: %s"):format(c.sp.name, SFP:ZoneName(c.map), where,
                        c.killed and "  |cff808080killed today|r" or "", table.concat(names, ", ")))
                    r.btn:SetScript("OnClick", function()
                        if c.sp.hx then SFP:SetWaypoint(c.map, c.sp.hx, c.sp.hy, c.sp.name) end
                    end)
                    r.btn:Show(); r.fs:Show()
                else
                    r.btn:Hide(); r.fs:Hide()
                end
            end
        end
        return function()
            fill()
            -- item names and ownership arrive a moment after the first request: look again
            if not retry then
                retry = true
                C_Timer.After(1.5, function() retry = nil; if pane:IsShown() then fill() end end)
            end
        end
    end)

local buildWeekly = simplePage("Weekly Checklist",
    "One window for all your characters: Great Vault progress, raid lockouts and the rares each one killed today. A character appears after you log in with it.",
    function(pane, y)
        mkButton(pane, "Open weekly checklist", 190, function() SFP:ShowWeekly() end):SetPoint("TOPLEFT", 12, y)
    end)

local buildDeals = simplePage("BoE Deals",
    "Bind-on-equip items that are cheaper than usual right now. The addon remembers every auction house scan, so the list gets better after a few scans on different days. " ..
    "The same list opens from the BoE deals button below the auction house window.",
    function(pane, y)
        mkButton(pane, "Open BoE deals", 170, function() SFP:ShowDeals() end):SetPoint("TOPLEFT", 12, y)
    end)

local buildShop = simplePage("Shopping List",
    "Pick the recipes you want to craft: you get the total reagents, their auction prices, the profit and, for each reagent, a place to farm it. " ..
    "To decide farm or buy, compare with your gold per hour from a Farm Session.",
    function(pane, y)
        mkButton(pane, "Open shopping list", 170, function() SFP:ShowShop() end):SetPoint("TOPLEFT", 12, y)
    end)

local buildCollect = simplePage("My Collections",
    "The game remembers your transmog, mounts and battle pets, also from before this addon was installed. The addon reads them by itself in the background: on the first start after the install, and again when the number of mounts or pets changes, so you never have to press anything. Monster tooltips and the Codex " ..
    "(tab My Collection History) can say what you already own from a monster, and so What To Farm Next knows what you miss.",
    function(pane, y)
        local txt = mkText(pane, "", 12, y - 40, 500, "GameFontHighlightSmall")
        local function status()
            local h = SFP.db.history
            if not h or not h.t or h.t == 0 then return "Not read yet - it starts by itself about 20 seconds after you log in." end
            local items, mons, mnt, pets = 0, 0, 0, 0
            for _ in pairs(h.items or {}) do items = items + 1 end
            for _, r in pairs(h.by or {}) do
                mons = mons + 1
                mnt = mnt + (r.mounts and #r.mounts or 0)
                pets = pets + (r.pets and #r.pets or 0)
            end
            local mins = math.floor((time() - h.t) / 60)
            return ("Last read %s: %d transmog items, %d mounts and %d pets from %d monsters and bosses."):format(
                mins < 1 and "just now" or (mins < 120 and (mins .. " min ago") or (math.floor(mins / 60) .. " h ago")), items, mnt, pets, mons)
        end
        mkButton(pane, "Read my collections", 190, function()
            SFP.db.historyReport = true
            SFP:Print("Reading your transmog, mount and pet collections (in the background)...")
            SFP:ScanTransmogHistory(true)
            C_Timer.After(1, function() txt:SetText(status()) end)
        end):SetPoint("TOPLEFT", 12, y)
        return function() txt:SetText(status()) end
    end)

local buildShare = simplePage("Share Data",
    "Export what the addon learned (monsters, drops, items, nodes, recipes, learned spots) as a copy-paste text, to give to a friend or to move to another account. " ..
    "Import merges a string into your data and never lowers your counts, so importing it twice changes nothing.",
    function(pane, y)
        mkButton(pane, "Export learned data", 190, function() SFP:ShowExport() end):SetPoint("TOPLEFT", 12, y)
        mkButton(pane, "Import learned data", 190, function() SFP:ShowImport() end):SetPoint("TOPLEFT", 214, y)
    end)

local buildDelve = simplePage("Delve Planner",
    "Suggests the role for your delve companion and curio hints from your specialization, and remembers the delve tier you can do safely. The suggestions follow the Codex delve guides.",
    function(pane, y)
        local txt = mkText(pane, "", 12, y - 40, 500, "GameFontHighlightSmall")
        local tierText = mkText(pane, "", 150, y - 4, 200, "GameFontNormal")
        mkButton(pane, "Tier -", 60, function() SFP:SetDelveTier(-1); pane.refresh() end):SetPoint("TOPLEFT", 12, y)
        mkButton(pane, "Tier +", 60, function() SFP:SetDelveTier(1); pane.refresh() end):SetPoint("TOPLEFT", 80, y)
        return function()
            tierText:SetText("Comfortable tier: " .. (SFP.db.delveTier or "not set"))
            txt:SetText(SFP:DelveAdvice())
        end
    end)

local buildKeys = simplePage("Delve Keys",
    "Your delve keys and key shards, how many you earned this week, and the delves that are bountiful today. A bountiful delve needs a key and gives an extra chest, so save keys for your best tier.",
    function(pane, y)
        mkButton(pane, "Open delve keys", 170, function() SFP:ShowKeys() end):SetPoint("TOPLEFT", 12, y)
    end)

local buildAch = simplePage("Achievement Planner",
    "Pick an achievement and see what is left, where each step is when the addon knows the place, and what to do first. A button sets a waypoint to the first step with a known place.",
    function(pane, y)
        mkButton(pane, "Open achievement planner", 210, function() SFP:ShowAchPlanner() end):SetPoint("TOPLEFT", 12, y)
    end)

local buildZone = simplePage("Zone Check",
    "When you enter a zone or an instance, one chat line says how many mounts, pets and toys of its rares and bosses you still miss, with the first few names. The switch is on the Settings page.",
    function(pane, y)
        mkButton(pane, "Check this zone now", 190, function() SFP:ZoneCheck(false) end):SetPoint("TOPLEFT", 12, y)
        mkButton(pane, "Open Settings", 150, function() SFP:ShowMenuSection("settings") end):SetPoint("TOPLEFT", 214, y)
    end)

local buildDecor = simplePage("Housing Decor",
    "Midnight housing decor that you craft: where each recipe drops and whether you know it. The game does not tell addons which decor you own in your house, so only the recipes are checked.",
    function(pane, y)
        mkButton(pane, "Open decor list", 170, function() SFP:ShowDecor() end):SetPoint("TOPLEFT", 12, y)
    end)

local buildAlts = simplePage("Alt Overview",
    "One window with every character you logged in with: level, item level, gold, professions and the weekly activities. Profession cooldowns are not shown.",
    function(pane, y)
        mkButton(pane, "Open alt overview", 170, function() SFP:ShowAlts() end):SetPoint("TOPLEFT", 12, y)
    end)

local GUIDE_CATS = {
    { "guide", "New Player Guide", "Start here: classes, gear, professions, travel, gold" },
    { "dungeon", "Dungeons", "Every dungeon: how to enter, bosses, loot" },
    { "raid", "Raids", "Every raid: bosses, tactics, loot" },
    { "boss", "Bosses", "Boss abilities and how to beat them" },
    { "creature", "Monsters & Creatures", "Monsters, rares, tames, world bosses and their drops" },
    { "item", "Loot & Items", "Gear and items and how to get them" },
    { "delve", "Delves", "Every delve: how to run it, bosses, rewards" },
    { "entrance", "Entrances (How to Enter)", "Where and how to enter every dungeon and raid" },
    { "quest", "Quests (what to do)", "How to do the quests" },
    { "mount", "Mounts", "How to get every mount" },
    { "pet", "Battle Pets", "Where to find the pets" },
    { "achievement", "Achievements & Titles", "How to earn them" },
    { "material", "Materials (what for)", "What every material is used for" },
    { "mats", "Gold Farming", "How to make gold in the current game" },
}
local function buildGuides(pane)
    mkText(pane, CYHEX .. "Guides (Codex)|r", 12, -10, 480, "GameFontNormalLarge")
    mkText(pane, "A guide to doing things: each part opens the Codex on that page.", 12, -34, 500, "GameFontHighlightSmall")
    local box = CreateFrame("EditBox", nil, pane, "InputBoxTemplate")
    box:SetSize(260, 20)
    box:SetPoint("TOPLEFT", 18, -60)
    box:SetAutoFocus(false)
    box:SetScript("OnEnterPressed", function(self)
        local cx = codex()
        if cx then cx:StartIndexing(); cx:Toggle(self:GetText()) end
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    mkText(pane, "|cff808080search everything, press Enter|r", 290, -64, 220, "GameFontHighlightSmall")
    for i, c in ipairs(GUIDE_CATS) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        mkButton(pane, c[2], 245, function()
            local cx = codex()
            if cx then cx:StartIndexing(); cx:OpenCategory(c[1]) else SFP:Print("The Codex is not loaded.") end
        end, c[3]):SetPoint("TOPLEFT", 12 + col * 255, -92 - row * 30)
    end
end

local function buildGroups(pane)
    mkText(pane, CYHEX .. "Groups|r", 12, -10, 480, "GameFontNormalLarge")
    mkText(pane, "Tools for dungeon and raid groups: your group's raid buffs and tier tokens, tags and notes on players you met, filters for Premade Groups when the game offers them.", 12, -34, 500, "GameFontHighlightSmall")
    mkButton(pane, "Open Dungeons & Raids", 190, function() SFP:RunModule("SEVIATHSDUNGEONSRAIDS", "") end):SetPoint("TOPLEFT", 12, -90)
    mkButton(pane, "My group's makeup", 190, function() SFP:RunModule("SEVIATHSDUNGEONSRAIDS", "comp") end, "Roles, Bloodlust, battle res, missing raid buffs, tier tokens"):SetPoint("TOPLEFT", 12, -120)
    mkButton(pane, "Rate my last group", 190, function() SFP:RunModule("SEVIATHSDUNGEONSRAIDS", "rate") end):SetPoint("TOPLEFT", 12, -150)
    mkText(pane, "Tag a player: /sdr tag Name-Realm good|bad|fav|block", 12, -190, 500, "GameFontHighlightSmall"):SetTextColor(0.7, 0.7, 0.7)
end

local function buildGuild(pane)
    mkText(pane, CYHEX .. "Guild|r", 12, -10, 480, "GameFontNormalLarge")
    mkText(pane, "Find players with /who by level and class, whisper them your pitch and invite them when they say yes. Not in a guild? It helps you collect charter signatures.", 12, -34, 500, "GameFontHighlightSmall")
    mkButton(pane, "Open Guild Helper", 190, function() SFP:RunModule("SEVIATHSGUILDHELPER", "") end):SetPoint("TOPLEFT", 12, -90)
    mkButton(pane, "Scan next level range", 190, function() SFP:RunModule("SEVIATHSGUILDHELPER", "scan") end):SetPoint("TOPLEFT", 12, -120)
end

local function buildSettings(pane)
    mkText(pane, CYHEX .. "Settings|r", 12, -10, 480, "GameFontNormalLarge")
    pane.checks = {
        -- left column
        mkCheck(pane, "Item and monster tooltip lines", function() return SFP.db.tooltip end, function(v) SFP.db.tooltip = v end, 12, -40),
        mkCheck(pane, "Learn farm spots from my loot", function() return SFP.db.learn end, function(v) SFP.db.learn = v end, 12, -66),
        mkCheck(pane, "Learn everything constantly", function() return SFP.db.learnAll ~= false end,
            function(v) SFP.db.learnAll = v end, 12, -92),
        mkCheck(pane, "Show the minimap button", function() return not SFP.db.minimap.hide end,
            function(v) SFP.db.minimap.hide = not v; SFP:RefreshAll() end, 12, -118),
        mkCheck(pane, "Minimap button glows in farm zones", function() return SFP.db.minimapGlow end, function(v) SFP.db.minimapGlow = v; SFP:RefreshAll() end, 12, -144),
        mkCheck(pane, "Compare monsters: my level and below only", function() return SFP.db.compareMineOnly end,
            function(v) SFP.db.compareMineOnly = v end, 12, -170),
        -- right column
        mkCheck(pane, "Chat message when an auction sells", function() return SFP.db.auctionSold ~= false end,
            function(v) SFP.db.auctionSold = v end, 260, -40),
        mkCheck(pane, "Chat message: mailbox / vendor gold", function() return SFP.db.incomeMessages ~= false end,
            function(v) SFP.db.incomeMessages = v end, 260, -66),
    }
    mkButton(pane, "Show internal errors", 160, function() SFP:Print("see /sfp errors"); SFP:RunModule("SEVIATHSUSEFULTOOLS", "errors") end):SetPoint("TOPLEFT", 12, -190)
    mkButton(pane, "Reload UI", 160, function() ReloadUI() end):SetPoint("TOPLEFT", 180, -190)
    mkButton(pane, "About / options page", 160, function() SFP:OpenAbout() end):SetPoint("TOPLEFT", 348, -190)
    -- rares, alerts and the farm route
    mkText(pane, CYHEX .. "Rares & alerts|r", 12, -220, 400, "GameFontNormal")
    local more = {
        mkCheck(pane, "Rare alerts (chat line)", function() return SFP.db.rareAlerts ~= false end, function(v) SFP.db.rareAlerts = v end, 12, -244),
        mkCheck(pane, "Rare alert sound", function() return SFP.db.rareAlertSound ~= false end, function(v) SFP.db.rareAlertSound = v end, 12, -270),
        mkCheck(pane, "Grey out rares killed today", function() return SFP.db.greyKilled ~= false end,
            function(v) SFP.db.greyKilled = v; SFP:RefreshAll() end, 260, -244),
        mkCheck(pane, "Show the farm route on the map", function() return SFP.db.showRoute ~= false end,
            function(v) SFP.db.showRoute = v; SFP:RefreshAll() end, 260, -270),
    }
    for _, cb in ipairs(more) do pane.checks[#pane.checks + 1] = cb end
    local zc = mkCheck(pane, "Zone check: say what I still miss when I enter a zone", function() return SFP.db.zoneCheck ~= false end,
        function(v) SFP.db.zoneCheck = v end, 12, -306)
    pane.checks[#pane.checks + 1] = zc
    mkText(pane, "Each tool has its own page in the list on the left.", 12, -336, 480, "GameFontHighlightSmall"):SetTextColor(0.7, 0.7, 0.7)
    pane.refresh = function() for _, cb in ipairs(pane.checks) do cb.refresh() end end
end

local function buildKnow(pane)
    mkText(pane, CYHEX .. "Learned data|r", 12, -10, 400, "GameFontNormalLarge")
    pane.rows = {}
    local modes = { { "npc", "Monsters" }, { "obj", "Nodes" }, { "item", "Items" }, { "recipe", "Recipes" } }
    pane.tabs = {}
    for i, m in ipairs(modes) do
        local b = mkButton(pane, m[2], 70, function()
            know.mode, know.sel = m[1], nil
            knowRebuild(pane); knowRefresh(pane)
            for _, t in ipairs(pane.tabs) do t:SetBackdropBorderColor(CY.r, CY.g, CY.b, t.mode == m[1] and 1 or 0.4) end
        end)
        b.mode = m[1]
        b:SetPoint("TOPLEFT", 12 + (i - 1) * 74, -36)
        pane.tabs[i] = b
    end
    pane.search = CreateFrame("EditBox", nil, pane, "InputBoxTemplate")
    pane.search:SetSize(190, 20)
    pane.search:SetPoint("TOPLEFT", 18, -68)
    pane.search:SetAutoFocus(false)
    pane.search:SetScript("OnTextChanged", function() knowRebuild(pane); knowRefresh(pane) end)
    pane.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    pane.count = mkText(pane, "", 220, -72, 100, "GameFontHighlightSmall")
    local listFrame = CreateFrame("Frame", nil, pane)
    listFrame:SetPoint("TOPLEFT", 12, -92)
    listFrame:SetSize(230, ROWS * 18)
    listFrame:EnableMouseWheel(true)
    listFrame:SetScript("OnMouseWheel", function(_, delta)
        local maxOff = math.max(0, #know.list - ROWS)
        know.offset = math.max(0, math.min(maxOff, know.offset - delta * 3))
        knowRefresh(pane)
    end)
    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, listFrame)
        row:SetSize(230, 18)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 18)
        row.hl = row:CreateTexture(nil, "BACKGROUND")
        row.hl:SetAllPoints(); row.hl:SetColorTexture(CY.r, CY.g, CY.b, 0.25); row.hl:Hide()
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 4, 0); row.text:SetWidth(222); row.text:SetJustifyH("LEFT")
        row:SetScript("OnClick", function(self) know.sel = self.key; knowRefresh(pane) end)
        pane.rows[i] = row
    end
    pane.detail = mkText(pane, "", 252, -40, 262, "GameFontHighlightSmall")
    pane.detail:SetWidth(262)
    pane.detail:SetJustifyV("TOP")
    pane.refresh = function() knowRebuild(pane); knowRefresh(pane) end
end

local BUILDERS = {
    home = buildHome, farm = buildFarm, alerts = buildAlerts, killed = buildKilled, route = buildRoute, session = buildSession,
    next = buildNext, weekly = buildWeekly, deals = buildDeals, shop = buildShop, collect = buildCollect, share = buildShare,
    delve = buildDelve, keys = buildKeys, ach = buildAch, zone = buildZone, decor = buildDecor, alts = buildAlts,
    guides = buildGuides, groups = buildGroups, guild = buildGuild, know = buildKnow, settings = buildSettings,
}

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
function SFP:ShowMenuSection(key)
    if not frame then return end
    frame:Raise()
    current = key
    for _, s in ipairs(SECTIONS) do
        local b = navButtons[s.key]
        b:SetBackdropColor(s.key == key and 0.1 or 0.03, s.key == key and 0.35 or 0.1, s.key == key and 0.42 or 0.13, 0.95)
        if panes[s.key] then panes[s.key]:Hide() end
    end
    local pane = panes[key]
    if not pane then
        pane = CreateFrame("Frame", nil, frame.content)
        pane:SetAllPoints()
        panes[key] = pane
        SFP:Safe("build " .. key, BUILDERS[key], pane)
    end
    pane:Show()
    if pane.refresh then SFP:Safe("refresh " .. key, pane.refresh) end
end

local function build()
    frame = CreateFrame("Frame", "SeviathsUsefulToolsMenu", UIParent, "BackdropTemplate")
    frame:SetSize(710, 540)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    SFP.RegisterWindow(frame)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    backdrop(frame, 0.03, 0.06, 0.08, 0.97, CY.r, CY.g, CY.b, 0.6)
    tinsert(UISpecialFrames, "SeviathsUsefulToolsMenu")

    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT"); title:SetPoint("TOPRIGHT", -34, 0); title:SetHeight(28)
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() frame:StartMoving() end)
    title:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local tt = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tt:SetPoint("LEFT", 12, 0)
    tt:SetText(CYHEX .. "Seviaths|r UsefulTools  |cff808080v" .. SFP.VERSION .. "|r")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetFrameLevel(frame:GetFrameLevel() + 30)
    close:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    close:SetScript("OnClick", function() frame:Hide() end)
    frame.close = close

    local navScroll = CreateFrame("ScrollFrame", nil, frame)
    navScroll:SetPoint("TOPLEFT", 4, -34)
    navScroll:SetPoint("BOTTOMLEFT", 4, 8)
    navScroll:SetWidth(150)
    local navChild = CreateFrame("Frame", nil, navScroll)
    navChild:SetSize(150, #SECTIONS * 25 + 8)
    navScroll:SetScrollChild(navChild)
    navScroll:EnableMouseWheel(true)
    navScroll:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, navChild:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.min(maxScroll, math.max(0, self:GetVerticalScroll() - delta * 50)))
    end)
    for i, s in ipairs(SECTIONS) do
        local b = mkButton(navChild, s.label, 138, function() SFP:ShowMenuSection(s.key) end)
        b:SetHeight(22)
        b:SetPoint("TOPLEFT", 6, -2 - (i - 1) * 25)
        navButtons[s.key] = b
    end
    frame.content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.content:SetPoint("TOPLEFT", 156, -34)
    frame.content:SetPoint("BOTTOMRIGHT", -8, 8)
    backdrop(frame.content, 0.02, 0.04, 0.06, 0.6, CY.r, CY.g, CY.b, 0.25)
end

function SFP:ToggleMenu(section)
    if not frame then build() end
    if frame:IsShown() and not section then frame:Hide(); return end
    frame:Show()
    frame:Raise()
    self:ShowMenuSection(section or current or "home")
end

-- the minimap button's old menu now opens the main menu
SFP.ShowHubMenu = function() SFP:ToggleMenu() end

-- one minimap button for everything: hide the merged addons' own buttons
SFP:OnLogin(function()
    if not SFP.db.mergedButtonsHidden then
        SFP.db.mergedButtonsHidden = true
        if SeviathsCodexDB and SeviathsCodexDB.minimap then SeviathsCodexDB.minimap.hide = true end
        if SeviathsDungeonsRaidsDB and SeviathsDungeonsRaidsDB.minimap then SeviathsDungeonsRaidsDB.minimap.show = false end
        if SeviathsGuildHelperDB and SeviathsGuildHelperDB.settings and SeviathsGuildHelperDB.settings.minimap then
            SeviathsGuildHelperDB.settings.minimap.hide = true
        end
    end
    for _, name in ipairs({ "SeviathsCodexMinimapButton", "SDRMinimapButton", "SeviathsGuildHelperMinimapButton" }) do
        local f = _G[name]
        if f and f.Hide then f:Hide() end
    end
end)

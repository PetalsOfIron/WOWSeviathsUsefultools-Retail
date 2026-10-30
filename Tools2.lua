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
    self.db.alts[charKey()] = rec
end

local altWin
function SFP:ShowAlts()
    self:UpdateAlt()
    if self.UpdateWeekly then pcall(self.UpdateWeekly, self) end
    altWin = altWin or window("SeviathsUsefulToolsAlts", "Alt overview - all your characters", 520, 420)
    local keys, lines, totalGold = {}, {}, 0
    for k in pairs(self.db.alts or {}) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local r = self.db.alts[k]
        totalGold = totalGold + (r.money or 0)
        local age = math.floor((time() - (r.t or 0)) / 3600)
        lines[#lines + 1] = ("|cff00e5ff%s|r  level %s %s %s  |cff808080(%s)|r"):format(k, tostring(r.level or "?"), r.spec or "", r.class or "",
            age < 1 and "now" or (age .. " h ago"))
        lines[#lines + 1] = ("  Item level %s   Gold %s"):format(tostring(r.ilvl or "?"), money(r.money))
        lines[#lines + 1] = "  Professions: " .. (#(r.profs or {}) > 0 and table.concat(r.profs, ", ") or "none")
        local w = self.db.weekly and self.db.weekly[k]
        if w then
            lines[#lines + 1] = "  Weekly: Great Vault " .. (#w.vault > 0 and table.concat(w.vault, " ") or "no data") ..
                "   Raid lockouts: " .. (#w.locks > 0 and #w.locks or "none") .. "   Rares today: " .. (w.rares or 0)
        end
        lines[#lines + 1] = ""
    end
    if #lines == 0 then lines[1] = "No data yet." end
    table.insert(lines, 1, "|cff808080Total gold on these characters: " .. money(totalGold) .. ". A character shows here after you log in with it. Profession cooldowns are not shown.|r\n")
    altWin:SetContent(table.concat(lines, "\n"))
    altWin:Show()
end

local af = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT", "TRADE_SKILL_LIST_UPDATE" }) do pcall(af.RegisterEvent, af, e) end
local altTimer
af:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then SFP:Safe("alt", SFP.UpdateAlt, SFP); return end
    if altTimer then return end
    altTimer = true
    C_Timer.After(10, function() altTimer = nil; SFP:Safe("alt", SFP.UpdateAlt, SFP) end)
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
    keyWin:SetContent(table.concat(lines, "\n"))
    keyWin:Show()
end

---------------------------------------------------------------------------
-- 5. delve planner: companion role, curios, comfortable tier
---------------------------------------------------------------------------
local HYBRID_SPECS = { [70] = true, [103] = true }   -- Retribution, Feral: tank companion (as the Codex says)

function SFP:DelveAdvice()
    local specIndex = GetSpecialization and GetSpecialization()
    local specID, specName, role
    if specIndex and GetSpecializationInfo then
        specID, specName, _, _, role = GetSpecializationInfo(specIndex)
    end
    local lines = {}
    if not role then
        lines[#lines + 1] = "Your specialization is not known yet."
    else
        local companion
        if role == "TANK" or role == "HEALER" then companion = "Damage"
        elseif HYBRID_SPECS[specID] then companion = "Tank"
        else companion = "Healer" end
        lines[#lines + 1] = ("You play %s (%s). Set your companion to |cff40ff40%s|r."):format(specName or "?", role:lower(), companion)
        lines[#lines + 1] = "Curios: one Combat and one Utility slot. If your class has no crowd control, take a slow or stun curio. Tanks and healers: a damage curio helps the run go faster."
    end
    local tier = self.db.delveTier
    lines[#lines + 1] = tier and ("Comfortable tier (you set it): |cffffd100" .. tier .. "|r. Use bountiful keys at this tier or one above.")
        or "Set the tier you can do safely below; the addon remembers it."
    return table.concat(lines, "\n\n")
end

function SFP:SetDelveTier(delta)
    local t = (self.db.delveTier or 1) + delta
    self.db.delveTier = math.max(1, math.min(11, t))
end

---------------------------------------------------------------------------
-- 9. missing here: mounts, pets and toys of the rares and bosses of this zone or instance
---------------------------------------------------------------------------
local function missingHere(mapID, instName)
    local names, count = {}, 0
    local function check(itemIDs, label)
        for _, itemID in ipairs(itemIDs or {}) do
            local own = SFP.OwnedStatus and SFP:OwnedStatus(itemID)
            if own == false then
                count = count + 1
                if #names < 3 then names[#names + 1] = SFP:ItemName(itemID) .. " (" .. label .. ")" end
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
    local count, names = missingHere(mapID, instName)
    if count > 0 then
        self:Print(("Missing here: %d collectible%s - %s%s"):format(count, count == 1 and "" or "s", table.concat(names, ", "),
            count > #names and (" and " .. (count - #names) .. " more") or ""))
    elseif not quiet then
        self:Print("Nothing missing here that the addon knows about (mounts, pets, toys of rares and bosses).")
    end
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

local decorWin
function SFP:ShowDecor()
    decorWin = decorWin or window("SeviathsUsefulToolsDecor", "Housing decor you can craft", 500, 380)
    local lines = { "|cff808080Crafting recipes for housing decor and where they drop (from the profession guides). Only recipes are checked: the game does not tell addons which decor items you own in your house.|r\n" }
    local known = 0
    for _, d in ipairs(DECOR) do
        local ok, has = pcall(function() return IsPlayerSpell and IsPlayerSpell(d[1]) or (IsSpellKnown and IsSpellKnown(d[1])) end)
        has = ok and has
        if has then known = known + 1 end
        lines[#lines + 1] = ("%s %s  |cff808080- %s|r"):format(has and "|cff40ff40known|r" or "|cffff6060missing|r", d[2], d[3])
    end
    table.insert(lines, 2, ("You know %d of %d recipes.\n"):format(known, #DECOR))
    decorWin:SetContent(table.concat(lines, "\n"))
    decorWin:Show()
end

---------------------------------------------------------------------------
-- 8. achievement planner
---------------------------------------------------------------------------
local achWin, achBox, achResults, achSelected = nil, nil, {}, nil
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
local function achSearch(text)
    local found = {}
    local _, ns = SFP_Module("Codex")
    if ns and ns.Search and #(text or "") >= 3 then
        local ok, res = pcall(ns.Search, ns, text, "achievement", 8)
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
        achWin = window("SeviathsUsefulToolsAch", "Achievement planner", 520, 440)
        achWin.scroll:SetPoint("TOPLEFT", 12, -200)
        achBox = CreateFrame("EditBox", nil, achWin, "InputBoxTemplate")
        achBox:SetSize(300, 22)
        achBox:SetPoint("TOPLEFT", 22, -34)
        achBox:SetAutoFocus(false)
        achBox:SetScript("OnTextChanged", function(self) achSearch(self:GetText()) end)
        achBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local way = CreateFrame("Button", nil, achWin, "UIPanelButtonTemplate")
        way:SetSize(150, 22)
        way:SetPoint("LEFT", achBox, "RIGHT", 10, 0)
        way:SetText("Waypoint to first step")
        way:SetScript("OnClick", function()
            if achWay and SFP.SetWaypoint then SFP:SetWaypoint(achWay.map, achWay.x, achWay.y, achWay.label) end
        end)
        for i = 1, 8 do
            local b = CreateFrame("Button", nil, achWin, "UIPanelButtonTemplate")
            b:SetSize(470, 18)
            b:SetPoint("TOPLEFT", 22, -62 - (i - 1) * 16)
            b:SetScript("OnClick", function(self)
                if not self.e then return end
                local text, where = achDetail(tonumber(self.e.id) or 0)
                achWay = where
                achWin:SetContent(text)
            end)
            b:Hide()
            achResults[i] = b
        end
        achWin:SetContent("Type part of an achievement name above, then click a result. You get what is left, where each step is when the addon knows the place, and what to do first.")
    end
    achWin:Show()
end

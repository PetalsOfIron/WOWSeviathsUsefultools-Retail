-- SeviathsUsefulTools - players and party
--
-- Player tooltip: item level (read with the game's inspect, for everybody), empty sockets and missing enchants,
-- and, for players who also have this addon, a small profile they share: collected mounts and pets, Mythic+ score,
-- dungeons and raid bosses done this week (numbers only), play style and what they dislike in a group.
-- The profile travels in addon messages (group, guild, or a whisper when you hover the player). No server, nothing leaves the game.

local _, SFP = ...

local S = {}
SFP.Social = S

local PREFIX = "SUTProfile"
local PROFILE_VERSION = 2

local function secret(v) return issecretvalue and issecretvalue(v) end

---------------------------------------------------------------------------
-- settings and the lists the player chooses from
---------------------------------------------------------------------------
-- styles the player can choose by hand; "auto" lets the addon decide from the numbers below
S.STYLES = {
    { "auto",     "Automatic (from my collections, Mythic+ and raids)" },
    { "relaxed",  "Relaxed, no pressure" },
    { "learning", "Learning the content" },
    { "social",   "Social, guild and friends" },
    { "housing",  "Housing fan" },
    { "speed",    "Fast runs and farming" },
}
local AUTO_LABEL = { raider = "Raider", mythic = "Mythic+ player", delver = "Delve player", collector = "Collector",
    achiever = "Achievement hunter", pvp = "PvP player", dailies = "Daily quest player", farmer = "Farmer",
    gold = "Gold collector", ["gold:loot"] = "Gold collector (farming)", ["gold:daily"] = "Gold collector (daily quests)",
    ["gold:trade"] = "Gold collector (auction and vendor)", housing = "Housing fan",
    alliance = "Alliance player", horde = "Horde player", altaholic = "Alt collector", casual = "Casual" }
local STYLE_LABEL = { relaxed = "Relaxed", learning = "Learning", social = "Social", speed = "Fast runs and farming" }

-- what a player can say they dislike in a group (the number is what is sent)
S.DISLIKES = {
    { 1,  "Leaving after one wipe" },
    { 2,  "Blaming players for wipes" },
    { 3,  "Rude or toxic chat" },
    { 4,  "Going AFK or being slow to come back" },
    { 5,  "Ignoring mechanics and interrupts" },
    { 6,  "Pulling before the group is ready" },
    { 7,  "Skipping trash or bosses" },
    { 8,  "Long explanations and too much talking" },
    { 9,  "Ninja looting or greeding everything" },
    { 10, "A silent group with no communication" },
    { 11, "Backseat playing, telling others how to play" },
    { 12, "Strict gear or score checks" },
}
local DISLIKE_TEXT = {}
for _, d in ipairs(S.DISLIKES) do DISLIKE_TEXT[d[1]] = d[2] end

function S.Config()
    SFP.db.social = SFP.db.social or {}
    local c = SFP.db.social
    if c.share == nil then c.share = true end        -- share my profile with other addon users
    if c.tip == nil then c.tip = true end            -- item level and profile on player tooltips
    if c.groupLine == nil then c.groupLine = true end -- one chat line about the group when it forms
    if c.style == nil then c.style = "auto" end
    c.dislikes = c.dislikes or {}
    c.stats = c.stats or {}
    return c
end

-- note this character (faction, class, level) so the account's characters are known: Alliance or Horde player, many alts
function S.RecordChar()
    local c = S.Config()
    c.chars = c.chars or {}
    local name = UnitName("player")
    local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName()) or "?"
    if not name or secret(name) then return end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local _, class = UnitClass("player")
    c.chars[name .. "-" .. realm] = { faction = faction, class = class, level = UnitLevel("player"), t = time() }
end

-- what the player DOES: activities are counted per day and kept for 28 days; the play style follows these counts
-- (raid bosses, Mythic+ keys, delves, new collectibles, achievements earned, PvP matches, daily quests, looting, gold by source)
local DAY, WINDOW_DAYS = 86400, 28
function S.Act(name, n)
    local c = S.Config()
    c.act = c.act or {}
    local day = math.floor(time() / DAY)
    local d = c.act[day]
    if not d then
        d = {}
        c.act[day] = d
        for k in pairs(c.act) do if k < day - WINDOW_DAYS then c.act[k] = nil end end
    end
    d[name] = (d[name] or 0) + (n or 1)
end

function S.ActSum(name)
    local c = S.Config()
    local sum, day = 0, math.floor(time() / DAY)
    for k, d in pairs(c.act or {}) do
        if k >= day - WINDOW_DAYS then sum = sum + (d[name] or 0) end
    end
    return sum
end

-- small counters for the automatic play style (farm sessions started, auction scans, ...)
function S.Count(name)
    S.Act(name, 1)
end

---------------------------------------------------------------------------
-- my own numbers
---------------------------------------------------------------------------
local counts = { mounts = 0, pets = 0, decor = 0, t = 0 }

-- owned housing decor, counted over the addon's decor list with the game's catalog (a few hundred per frame)
local function countDecor()
    local H = C_HousingCatalog
    local data = SFP.DecorData
    if not (H and H.GetCatalogEntryInfoByItem and data) then return end
    local i, n = 1, 0
    local function step()
        local stop = math.min(#data, i + 149)
        while i <= stop do
            local itemID = data[i][1]
            if itemID and itemID > 0 then
                local ok, info = pcall(H.GetCatalogEntryInfoByItem, itemID, true)
                if ok and type(info) == "table" then
                    local own = math.max((tonumber(info.quantity) or 0) + (tonumber(info.numPlaced) or 0),
                        (tonumber(info.totalNumStored) or 0) + (tonumber(info.totalNumPlaced) or 0) + (tonumber(info.remainingRedeemable) or 0))
                    if own > 0 then n = n + 1 end
                end
            end
            i = i + 1
        end
        if i <= #data then C_Timer.After(0, step) else counts.decor = n end
    end
    step()
end

local function countMounts()
    local MJ = C_MountJournal
    if not (MJ and MJ.GetMountIDs and MJ.GetMountInfoByID) then return end
    local ok, ids = pcall(MJ.GetMountIDs)
    if not ok or type(ids) ~= "table" then return end
    local i, n = 1, 0
    local function step()
        local stop = math.min(#ids, i + 99)
        while i <= stop do
            local okI, _, _, _, _, _, _, _, _, _, _, collected = pcall(MJ.GetMountInfoByID, ids[i])
            if okI and collected == true then n = n + 1 end
            i = i + 1
        end
        if i <= #ids then
            C_Timer.After(0, step)
        else
            counts.mounts = n
            counts.t = time()
        end
    end
    step()
end

local function refreshCounts()
    if C_PetJournal and C_PetJournal.GetNumPets then
        local ok, _, owned = pcall(C_PetJournal.GetNumPets)
        if ok and type(owned) == "number" then counts.pets = owned end
    end
    countMounts()
    countDecor()
end

local function vaultMax(typeName, fallback)
    if not (C_WeeklyRewards and C_WeeklyRewards.GetActivities) then return 0 end
    local typ = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType[typeName]) or fallback
    local ok, acts = pcall(C_WeeklyRewards.GetActivities, typ)
    if not ok or type(acts) ~= "table" then return 0 end
    local best = 0
    for _, a in ipairs(acts) do
        if type(a.progress) == "number" and not secret(a.progress) and a.progress > best then best = a.progress end
    end
    return best
end

local function mplusScore()
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local ok, s = pcall(C_PlayerInfo.GetPlayerMythicPlusRatingSummary, "player")
        if ok and type(s) == "table" and type(s.currentSeasonScore) == "number" then return math.floor(s.currentSeasonScore) end
    end
    return 0
end

-- the play style the addon decides on from the numbers: collections, Mythic+ and raids
function S.AutoStyles(p)
    -- by what the player DOES in the last 28 days, never by how much they own: every activity gets a score
    -- (its count against what a regular player of it does), and the two strongest are the play style
    local a = p.act or {}
    local cand = {}
    local function add(id, count, regular)
        count = count or 0
        if count >= 1 then cand[#cand + 1] = { id = id, score = count / regular } end
    end
    add("raider", math.max(a.raid or 0, (p.rw or 0) * 2), 8)                  -- raid bosses killed (this week counts double)
    add("mythic", math.max((a.mythic or 0) + (a.dungeon or 0) * 0.5, (p.dw or 0) * 2), 8)   -- Mythic+ keys and dungeons
    add("delver", math.max(a.delve or 0, (p.dl or 0) * 2), 8)                 -- delves
    add("collector", a.collect, 10)                                           -- new mounts, pets, toys and appearances collected
    add("achiever", a.achv, 30)                                               -- achievements earned
    add("pvp", a.pvp, 10)                                                     -- PvP matches
    add("dailies", a.daily, 20)                                               -- daily and world quests handed in
    add("farmer", (a.loot or 0) + (a.session or 0) * 40, 150)                 -- monsters looted, farm sessions
    -- gold earned, by where it came from
    local sources = { loot = a.g_loot or 0, daily = a.g_daily or 0, trade = a.g_trade or 0 }
    local goldTotal = sources.loot + sources.daily + sources.trade + (a.g_quest or 0) + (a.g_other or 0)
    goldTotal = math.floor(goldTotal / 10000)   -- in gold
    if goldTotal >= 1 then
        local best, bestV = nil, 0
        for k, v in pairs(sources) do if v > bestV then best, bestV = k, v end end
        local id = (best and bestV / 10000 >= goldTotal * 0.4) and ("gold:" .. best) or "gold"
        cand[#cand + 1] = { id = id, score = goldTotal / 10000 + (a.scan or 0) / 40 }
    end
    table.sort(cand, function(x, y) if x.score ~= y.score then return x.score > y.score end return x.id < y.id end)
    local out = {}
    for i = 1, math.min(2, #cand) do out[#out + 1] = cand[i].id end   -- the two best
    -- the characters of the account (Alt data): most of them Alliance or Horde, and how many there are
    local total = (p.nAlliance or 0) + (p.nHorde or 0)
    if total >= 3 then
        if (p.nAlliance or 0) / total >= 0.6 then out[#out + 1] = "alliance"
        elseif (p.nHorde or 0) / total >= 0.6 then out[#out + 1] = "horde" end
    end
    if (p.nChars or 0) >= 8 then out[#out + 1] = "altaholic" end
    if #out == 0 then out[1] = "casual" end
    return out
end

local function styleLabels(list)
    local names = {}
    for _, id in ipairs(list) do names[#names + 1] = AUTO_LABEL[id] or STYLE_LABEL[id] or id end
    return table.concat(names, ", ")
end
S.StyleLabels = styleLabels

function S.MyProfile()
    local c = S.Config()
    local overall, equipped = GetAverageItemLevel and GetAverageItemLevel()
    local p = {
        ilvl = math.floor(tonumber(equipped) or tonumber(overall) or 0),
        mplus = mplusScore(),
        ach = (GetTotalAchievementPoints and tonumber(GetTotalAchievementPoints())) or 0,
        mounts = counts.mounts, pets = counts.pets, decor = counts.decor,
        dw = vaultMax("Activities", 2),   -- dungeons done this week (the Great Vault row counts them)
        rw = vaultMax("Raid", 1),         -- raid bosses killed this week
        dl = vaultMax("World", 6),        -- delves done this week (the Great Vault world row)
    }
    -- guild: guild master (rank 0) or officer
    p.role, p.guild = 0, ""
    if GetGuildInfo then
        local okG, gname, _, rankIndex = pcall(GetGuildInfo, "player")
        if okG and type(gname) == "string" and not secret(gname) then
            p.guild = gname:gsub("[;,]", " ")
            if (IsGuildLeader and IsGuildLeader()) or rankIndex == 0 then
                p.role = 2
            elseif C_GuildInfo and C_GuildInfo.IsGuildOfficer and C_GuildInfo.IsGuildOfficer() then
                p.role = 1
            end
        end
    end
    -- the account's characters, as the addon met them (it notes each one when you log in with it)
    p.nAlliance, p.nHorde, p.nChars = 0, 0, 0
    for _, ch in pairs(c.chars or {}) do
        p.nChars = p.nChars + 1
        if ch.faction == "Alliance" then p.nAlliance = p.nAlliance + 1 elseif ch.faction == "Horde" then p.nHorde = p.nHorde + 1 end
    end
    -- "always goes for gold": a lot of gold, farm sessions started, or many auction scans
    local st = c.stats or {}
    -- what the player did in the last 28 days (the play style is decided from this)
    p.act = {}
    for _, k in ipairs({ "raid", "mythic", "dungeon", "delve", "collect", "achv", "pvp", "daily", "loot", "session", "scan",
        "g_loot", "g_daily", "g_quest", "g_trade", "g_other" }) do
        p.act[k] = S.ActSum(k)
    end
    if c.style == "auto" or not c.style then
        p.style = S.AutoStyles(p)
    else
        p.style = { c.style }
    end
    local dis = {}
    for id, on in pairs(c.dislikes) do if on then dis[#dis + 1] = tonumber(id) end end
    table.sort(dis)
    p.dis = dis
    return p
end

---------------------------------------------------------------------------
-- the message
---------------------------------------------------------------------------
local function encode(p)
    return table.concat({
        "P", PROFILE_VERSION, p.ilvl, p.mplus, p.ach, p.mounts, p.pets, p.dw, p.rw, p.dl, p.decor,
        table.concat(p.style, ","), table.concat(p.dis, ","), p.role or 0, p.guild or "",
    }, ";")
end

local function split(str, sep)
    local out, pos = {}, 1
    while true do
        local a, b = str:find(sep, pos, true)
        if not a then out[#out + 1] = str:sub(pos); break end
        out[#out + 1] = str:sub(pos, a - 1)
        pos = b + 1
    end
    return out
end

local function decode(text)
    local f = split(text, ";")
    if f[1] ~= "P" or tonumber(f[2]) ~= PROFILE_VERSION then return nil end
    local rec = {
        t = time(), ilvl = tonumber(f[3]) or 0, mplus = tonumber(f[4]) or 0, ach = tonumber(f[5]) or 0,
        mounts = tonumber(f[6]) or 0, pets = tonumber(f[7]) or 0, dw = tonumber(f[8]) or 0, rw = tonumber(f[9]) or 0,
        dl = tonumber(f[10]) or 0, decor = tonumber(f[11]) or 0,
        style = {}, dis = {},
    }
    for id in (f[12] or ""):gmatch("[^,]+") do rec.style[#rec.style + 1] = id end
    for id in (f[13] or ""):gmatch("[^,]+") do rec.dis[#rec.dis + 1] = tonumber(id) end
    rec.role, rec.guild = tonumber(f[14]) or 0, f[15] or ""
    return rec
end

local peers = {}   -- ["Name" or "Name-Realm"] = decoded profile (only this session)
S.peers = peers

local function shortName(n) return (tostring(n):match("^[^-]+")) or tostring(n) end

local function unitKey(unit)
    local ok, n, r = pcall(UnitName, unit)
    if not ok or type(n) ~= "string" or secret(n) then return nil end
    if type(r) == "string" and r ~= "" and not secret(r) then return n .. "-" .. r end
    return n
end

function S.PeerOf(unit)
    local k = unitKey(unit)
    if not k then return nil end
    return peers[k] or peers[shortName(k)]
end

local function send(text, channel, target)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, text, channel, target)
end

local function groupChannel()
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

local lastBroadcast, lastReply, queried, lastQuery = 0, {}, {}, 0

-- what is shared with a player who has the addon: the profile, your talent build ("T") and your gear check ("G")
local function sendProfile(channel, target)
    send(encode(S.MyProfile()), channel, target)
    local TA = SFP.TalentAdvisor
    local build = TA and TA.MyLoadout and TA.MyLoadout()
    if build and #build < 240 then send("T;" .. build, channel, target) end
    local GH = SFP.GemHelper
    local okG, g = false, nil
    if GH and GH.CheckUnit then okG, g = pcall(GH.CheckUnit, "player") end
    if okG and type(g) == "table" and g.any then
        send(("G;%d;%s;%s"):format(g.empty or 0, table.concat(g.emptyWhere or {}, ","), table.concat(g.missing or {}, ",")), channel, target)
    end
end

local function broadcastGroup(force)
    if not S.Config().share then return end
    local ch = groupChannel()
    if not ch then return end
    if not force and GetTime() - lastBroadcast < 30 then return end
    lastBroadcast = GetTime()
    sendProfile(ch)
end

local function replyTo(sender, delay)
    if not S.Config().share then return end
    local now = GetTime()
    if lastReply[sender] and now - lastReply[sender] < 20 then return end
    lastReply[sender] = now
    C_Timer.After(delay or 0, function() sendProfile("WHISPER", sender) end)
end

---------------------------------------------------------------------------
-- item level, sockets and enchants of other players: the game's inspect
---------------------------------------------------------------------------
local inspectCache = {}   -- [guid] = { t, ilvl, gear }
local pendingGUID, lastInspect = nil, 0

local function inspectFresh(guid)
    local c = inspectCache[guid]
    if c and time() - c.t < 300 then return c end
    return nil
end

local function requestInspect(unit)
    if InCombatLockdown and InCombatLockdown() then return end
    if GetTime() - lastInspect < 1.5 then return end
    if InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown() then return end
    if not (CanInspect and NotifyInspect) then return end
    local okC, can = pcall(CanInspect, unit)
    if not okC or not can then return end
    if CheckInteractDistance and not CheckInteractDistance(unit, 1) then return end
    local okG, guid = pcall(UnitGUID, unit)
    if not okG or type(guid) ~= "string" or secret(guid) then return end
    lastInspect = GetTime()
    pendingGUID = guid
    pcall(NotifyInspect, unit)
end

local function inspectReady(guid)
    if guid ~= pendingGUID then return end
    pendingGUID = nil
    local unit
    for _, u in ipairs({ "mouseover", "target", "focus" }) do
        local ok, g = pcall(UnitGUID, u)
        if ok and g == guid and not secret(g) then unit = u; break end
    end
    if not unit then return end
    local rec = { t = time() }
    if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
        local ok, v = pcall(C_PaperDollInfo.GetInspectItemLevel, unit)
        if ok and type(v) == "number" and not secret(v) and v > 0 then rec.ilvl = math.floor(v) end
    end
    local GH = SFP.GemHelper
    if GH then
        local ok, res = pcall(GH.CheckUnit, unit)
        if ok then rec.gear = res end
    end
    inspectCache[guid] = rec
    if ClearInspectPlayer then pcall(ClearInspectPlayer) end
    -- show the new numbers on the tooltip that is open
    if GameTooltip:IsShown() then
        local okT, _, tu = pcall(GameTooltip.GetUnit, GameTooltip)
        if okT and tu then
            local okU, g2 = pcall(UnitGUID, tu)
            if okU and g2 == guid then pcall(GameTooltip.SetUnit, GameTooltip, tu) end
        end
    end
end

---------------------------------------------------------------------------
-- the tooltip
---------------------------------------------------------------------------
local CY = "|cff00e5ff"

local function dislikeText(list, max)
    local names = {}
    for _, id in ipairs(list) do if DISLIKE_TEXT[id] then names[#names + 1] = DISLIKE_TEXT[id] end end
    if #names == 0 then return nil end
    if max and #names > max then
        local more = #names - max
        for i = #names, max + 1, -1 do names[i] = nil end
        names[#names + 1] = "+" .. more .. " more"
    end
    return table.concat(names, ", ")
end

local function addProfileLines(tt, rec)
    tt:AddLine(CY .. "Seviaths|r")
    -- only what the player has: a number at 0 is left out, and a line with nothing on it is not shown
    local function parts(list)
        local out = {}
        for _, e in ipairs(list) do
            if (e[2] or 0) > 0 then out[#out + 1] = ("%s |cffffffff%d|r"):format(e[1], e[2]) end
        end
        return table.concat(out, "   ")
    end
    local l1 = parts({ { "Mythic+ score", rec.mplus }, { "Achievements", rec.ach } })
    local l2 = parts({ { "Mounts", rec.mounts }, { "Battle pets", rec.pets }, { "Housing decor", rec.decor } })
    local l3 = parts({ { "dungeons", rec.dw }, { "raid bosses", rec.rw }, { "delves", rec.dl } })
    if l1 ~= "" then tt:AddLine(l1, 0.8, 0.8, 0.8) end
    if l2 ~= "" then tt:AddLine(l2, 0.8, 0.8, 0.8) end
    if l3 ~= "" then tt:AddLine("This week: " .. l3, 0.8, 0.8, 0.8) end
    if #rec.style > 0 then tt:AddLine("Play style: " .. styleLabels(rec.style), 1, 0.82, 0) end
    if (rec.role or 0) > 0 then
        tt:AddLine((rec.role == 2 and "Guild Master" or "Guild officer") .. ((rec.guild or "") ~= "" and (" of " .. rec.guild) or ""), 0.4, 1, 0.6)
    end
    local d = dislikeText(rec.dis, 3)
    if d then tt:AddLine("Dislikes in a group: " .. d, 1, 0.5, 0.5, true) end
end

local function playerTooltip(tt, unit)
    local c = S.Config()
    if not c.tip then return end
    if not (UnitIsPlayer and UnitIsPlayer(unit)) then return end
    local isSelf = UnitIsUnit(unit, "player")
    local guid = UnitGUID(unit)
    if type(guid) ~= "string" or secret(guid) then return end
    local rec = (not isSelf) and S.PeerOf(unit) or nil
    local insp = (not isSelf) and inspectFresh(guid) or nil

    -- item level
    local ilvl
    if isSelf then
        local overall, equipped = GetAverageItemLevel()
        ilvl = math.floor(tonumber(equipped) or tonumber(overall) or 0)
    elseif insp and insp.ilvl then
        ilvl = insp.ilvl
    elseif rec and rec.ilvl and rec.ilvl > 0 then
        ilvl = rec.ilvl
    end
    if ilvl then
        tt:AddLine("Item level: |cffffffff" .. ilvl .. "|r", 1, 0.82, 0)
    elseif not isSelf then
        requestInspect(unit)
        tt:AddLine("Item level: |cff808080reading... (stay in range)|r", 0.6, 0.6, 0.6)
    end

    -- sockets and enchants
    local gear
    if isSelf and SFP.GemHelper then gear = SFP.GemHelper.CheckUnit("player")
    elseif insp and insp.gear then gear = insp.gear
    elseif rec and rec.gear then gear = rec.gear end
    if gear and gear.any then
        if gear.empty > 0 then
            tt:AddLine(("Empty sockets: %d (%s)"):format(gear.empty, table.concat(gear.emptyWhere, ", ")), 1, 0.4, 0.4, true)
        end
        if #gear.missing > 0 then
            tt:AddLine("Missing enchants: " .. table.concat(gear.missing, ", "), 1, 0.4, 0.4, true)
        end
        if gear.empty == 0 and #gear.missing == 0 then tt:AddLine("All sockets filled, all enchanted", 0.4, 1, 0.4) end
    end

    -- Raider.IO (when installed) knows every player of either faction, from the data file it carries: the score comes from there
    if not isSelf and not (rec and (rec.mplus or 0) > 0) then
        local RIO = _G.RaiderIO
        if RIO and RIO.GetProfile then
            local okR, prof = pcall(RIO.GetProfile, unit)
            local mk = okR and type(prof) == "table" and prof.mythicKeystoneProfile
            local sc = type(mk) == "table" and (mk.currentScore or mk.mainCurrentScore)
            if type(sc) == "number" and not secret(sc) and sc > 0 then
                tt:AddLine(("Mythic+ score (Raider.IO): |cffffffff%d|r"):format(sc), 0.8, 0.8, 0.8)
            end
        end
    end

    -- baked public character data of a player you met before (tools/bake_players.py), when they share nothing themselves
    if not isSelf and not rec and S.NormKey and SFP.PlayerData then
        local d = SFP.PlayerData[S.NormKey(unit) or ""]
        if d then
            local out = {}
            -- row: { ilvl, achievement points, M+ rating, mounts, pets, date }
            if (d[1] or 0) > 0 then out[#out + 1] = "item level " .. d[1] end
            if (d[3] or 0) > 0 then out[#out + 1] = "M+ " .. d[3] end
            if (d[2] or 0) > 0 then out[#out + 1] = d[2] .. " achievement points" end
            if (d[4] or 0) > 0 then out[#out + 1] = d[4] .. " mounts" end
            if (d[5] or 0) > 0 then out[#out + 1] = d[5] .. " pets" end
            if #out > 0 then tt:AddLine(("Armory (%s): %s"):format(d[6] or "?", table.concat(out, ", ")), 0.8, 0.8, 0.8, true) end
        end
    end

    -- the shared profile (players with this addon)
    if isSelf then
        addProfileLines(tt, S.MyProfile())
    elseif rec then
        addProfileLines(tt, rec)
    elseif C_ChatInfo and c.share then
        -- ask them once in a while: if they have the addon they answer by themselves
        local key = unitKey(unit)
        if key and not queried[key] and GetTime() - lastQuery > 3 and UnitIsConnected(unit) and UnitIsFriend("player", unit) then
            queried[key] = GetTime()
            lastQuery = GetTime()
            send("Q", "WHISPER", key)
        end
    end
    tt:Show()
end

---------------------------------------------------------------------------
-- group window and the one line when a group forms
---------------------------------------------------------------------------
local function groupUnits()
    local out = { "player" }
    if IsInRaid and IsInRaid() then
        for i = 1, GetNumGroupMembers() do out[#out + 1] = "raid" .. i end
    elseif IsInGroup and IsInGroup() then
        for i = 1, 4 do if UnitExists("party" .. i) then out[#out + 1] = "party" .. i end end
    end
    return out
end

-- counts of dislikes in the group, most common first
function S.GroupSummary()
    local n, sharing, sumIlvl, cntIlvl = 0, 0, 0, 0
    local dis = {}
    for _, u in ipairs(groupUnits()) do
        if UnitExists(u) then
            n = n + 1
            local rec = UnitIsUnit(u, "player") and S.MyProfile() or S.PeerOf(u)
            if rec then
                sharing = sharing + 1
                for _, id in ipairs(rec.dis or {}) do dis[id] = (dis[id] or 0) + 1 end
            end
            local g = UnitGUID(u)
            local insp = (type(g) == "string" and not secret(g)) and inspectFresh(g) or nil
            local il = (rec and rec.ilvl and rec.ilvl > 0 and rec.ilvl) or (insp and insp.ilvl)
            if il then sumIlvl, cntIlvl = sumIlvl + il, cntIlvl + 1 end
        end
    end
    local list = {}
    for id, c in pairs(dis) do list[#list + 1] = { id = id, c = c } end
    table.sort(list, function(a, b) if a.c ~= b.c then return a.c > b.c end return a.id < b.id end)
    return { members = n, sharing = sharing, avgIlvl = cntIlvl > 0 and math.floor(sumIlvl / cntIlvl) or nil, dislikes = list }
end

local function printGroupLine()
    if not S.Config().groupLine then return end
    local g = S.GroupSummary()
    if g.members < 2 or g.sharing < 2 then return end
    local parts = { ("Group of %d: %d share a profile"):format(g.members, g.sharing) }
    if g.avgIlvl then parts[#parts + 1] = "average item level " .. g.avgIlvl end
    local top = {}
    for i = 1, math.min(3, #g.dislikes) do
        local d = g.dislikes[i]
        top[#top + 1] = ("%s (%d)"):format(DISLIKE_TEXT[d.id] or ("#" .. d.id), d.c)
    end
    if #top > 0 then parts[#parts + 1] = "dislikes: " .. table.concat(top, ", ") end
    SFP:Print(table.concat(parts, "; ") .. ".")
end

local groupWin, groupList

local function groupRows()
    local items = {}
    for _, u in ipairs(groupUnits()) do
        if UnitExists(u) then
            local isSelf = UnitIsUnit(u, "player")
            local rec = isSelf and S.MyProfile() or S.PeerOf(u)
            local g = UnitGUID(u)
            local insp = (type(g) == "string" and not secret(g)) and inspectFresh(g) or nil
            local name = UnitName(u) or "?"
            local _, class = UnitClass(u)
            local col = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
            local hex = col and col.colorStr and ("|c" .. col.colorStr) or "|cffffffff"
            local il = (rec and rec.ilvl and rec.ilvl > 0 and rec.ilvl) or (insp and insp.ilvl)
            local text = ("%s%s|r  ilvl %s"):format(hex, name, il and ("|cffffffff" .. il .. "|r") or "|cff808080?|r")
            if rec and (rec.role or 0) > 0 then text = text .. (rec.role == 2 and "  |cff66ff99[Guild Master]|r" or "  |cff66ff99[Officer]|r") end
            if rec then
                -- only what the player has: zeros are left out
                if rec.mplus > 0 then text = text .. ("  M+ %d"):format(rec.mplus) end
                local wk = {}
                if rec.dw > 0 then wk[#wk + 1] = rec.dw .. " dungeons" end
                if rec.rw > 0 then wk[#wk + 1] = rec.rw .. " raid bosses" end
                if (rec.dl or 0) > 0 then wk[#wk + 1] = rec.dl .. " delves" end
                if #wk > 0 then text = text .. "  wk " .. table.concat(wk, ", ") end
                if #rec.style > 0 then text = text .. "  " .. styleLabels(rec.style) end
                if #rec.dis > 0 then text = text .. ("  |cffff8080dislikes %d|r"):format(#rec.dis) end
            else
                text = text .. "  |cff808080no addon|r"
            end
            if insp and insp.gear and insp.gear.any then
                if insp.gear.empty > 0 then text = text .. ("  |cffff6060%d empty sockets|r"):format(insp.gear.empty) end
                if #insp.gear.missing > 0 then text = text .. ("  |cffff6060%d unenchanted|r"):format(#insp.gear.missing) end
            end
            items[#items + 1] = { text = text, buttons = {} }
        end
    end
    return items
end

function S.RefreshGroupWindow()
    if not (groupWin and groupWin:IsShown()) then return end
    local g = S.GroupSummary()
    local lines = { ("%d in the group, %d share a profile%s."):format(g.members, g.sharing, g.avgIlvl and (", average item level " .. g.avgIlvl) or "") }
    if #g.dislikes > 0 then
        local top = {}
        for i = 1, math.min(5, #g.dislikes) do
            top[#top + 1] = ("%s (%d)"):format(DISLIKE_TEXT[g.dislikes[i].id] or ("#" .. g.dislikes[i].id), g.dislikes[i].c)
        end
        lines[#lines + 1] = "|cffff8080Dislikes in this group:|r " .. table.concat(top, ", ")
    end
    groupWin.info:SetText(table.concat(lines, "\n"))
    groupList:Set(groupRows())
end

function S.ShowGroup()
    if not groupWin then
        groupWin = SFP.MakeToolWindow("SeviathsUsefulToolsGroup", "Your group", 620, 330)
        groupWin.scroll:Hide()
        groupWin.info = groupWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        groupWin.info:SetPoint("TOPLEFT", 14, -32)
        groupWin.info:SetWidth(590)
        groupWin.info:SetJustifyH("LEFT")
        groupList = SFP.MakeRowList(groupWin, 10, -84, 600, 236, 20)
        groupWin:SetScript("OnShow", function() S.RefreshGroupWindow() end)
    end
    groupWin:Show()
    for _, u in ipairs(groupUnits()) do
        if not UnitIsUnit(u, "player") then S.PeerOf(u) end
    end
    broadcastGroup(true)
    S.RefreshGroupWindow()
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "INSPECT_READY", "PLAYER_MONEY",
    "MERCHANT_SHOW", "MERCHANT_CLOSED", "MAIL_SHOW", "MAIL_CLOSED", "LOOT_OPENED", "LOOT_CLOSED", "QUEST_TURNED_IN",
    "BOSS_KILL", "CHALLENGE_MODE_COMPLETED", "NEW_MOUNT_ADDED", "NEW_PET_ADDED", "NEW_TOY_ADDED",
    "TRANSMOG_COLLECTION_SOURCE_ADDED", "ACHIEVEMENT_EARNED", "PVP_MATCH_COMPLETE", "LFG_COMPLETION_REWARD" }) do
    pcall(ev.RegisterEvent, ev, e)
end

-- where the player's gold comes from: every gain of money is filed under what the player was doing at that moment
local ctx = { merchant = false, mail = false, loot = false, lootT = 0, questT = -10, questDaily = false }
local lastMoney

local function noteMoney()
    if not GetMoney then return end
    local now = GetMoney()
    if type(now) ~= "number" or secret(now) then return end
    local delta = lastMoney and (now - lastMoney) or 0
    lastMoney = now
    if delta <= 0 then return end
    local cat
    local t = GetTime()
    if ctx.merchant then cat = "vendor"
    elseif ctx.mail then cat = "mail"
    elseif t - ctx.questT < 3 then cat = ctx.questDaily and "daily" or "quest"
    elseif ctx.loot or t - ctx.lootT < 3 then cat = "loot"
    else cat = "other" end
    local key = (cat == "vendor" or cat == "mail") and "g_trade" or ("g_" .. cat)
    S.Act(key, delta)
end

local function questTurnedIn(questID)
    ctx.questT = GetTime()
    ctx.questDaily = false
    if questID and C_QuestLog then
        if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) then ctx.questDaily = true
        elseif C_QuestLog.IsRepeatableQuest and C_QuestLog.IsRepeatableQuest(questID) then ctx.questDaily = true end
        if QuestIsDaily and QuestIsDaily() then ctx.questDaily = true end
    end
    if ctx.questDaily then S.Act("daily") end
end

local rosterPending, summaryPending = false, false

ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    if event == "CHAT_MSG_ADDON" then
        if a1 ~= PREFIX or type(a2) ~= "string" then return end
        local sender = a4
        if type(sender) ~= "string" then return end
        local name = Ambiguate and Ambiguate(sender, "none") or sender
        if name == UnitName("player") then return end
        local kind = a2:sub(1, 1)
        if kind == "Q" then
            replyTo(sender, 0)
        elseif kind == "R" then
            replyTo(sender, math.random(1, 8))
        elseif kind == "T" then
            -- the sender's talent build: the talent advisor learns it as an example
            local TA = SFP.TalentAdvisor
            if TA and TA.SaveSeen then TA.SaveSeen(a2:sub(3), shortName(name)) end
        elseif kind == "G" then
            -- the sender's gear check: empty sockets and missing enchants
            local f = split(a2, ";")
            local rec = peers[name] or peers[shortName(name)]
            if rec then
                local where, miss = {}, {}
                for s in (f[3] or ""):gmatch("[^,]+") do where[#where + 1] = s end
                for s in (f[4] or ""):gmatch("[^,]+") do miss[#miss + 1] = s end
                rec.gear = { any = true, empty = tonumber(f[2]) or 0, emptyWhere = where, missing = miss }
            end
        elseif kind == "P" then
            local rec = decode(a2)
            if rec then
                peers[name] = rec
                peers[shortName(name)] = peers[shortName(name)] or rec
                if groupWin and groupWin:IsShown() then S.RefreshGroupWindow() end
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if not rosterPending then
            rosterPending = true
            C_Timer.After(math.random(2, 6), function()
                rosterPending = false
                SFP:Safe("share profile", broadcastGroup, false)
            end)
        end
        if not summaryPending then
            summaryPending = true
            C_Timer.After(12, function()
                summaryPending = false
                SFP:Safe("group line", printGroupLine)
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- entering a scenario instance is a delve (the only scenario content in Midnight)
        do
            local okI, inInst, itype = pcall(IsInInstance)
            if okI and inInst and itype == "scenario" then S.Act("delve") end
        end
        if a1 or a2 then   -- log in or reload
            C_Timer.After(10, function() SFP:Safe("note character", S.RecordChar) end)
            C_Timer.After(20, function()
                SFP:Safe("counts", refreshCounts)
                if S.Config().share and IsInGuild and IsInGuild() then send("R", "GUILD") end
            end)
            C_Timer.After(40, function()
                if S.Config().share and IsInGuild and IsInGuild() then sendProfile("GUILD") end
            end)
        end
    elseif event == "INSPECT_READY" then
        SFP:Safe("inspect", inspectReady, a1)
    elseif event == "PLAYER_MONEY" then
        SFP:Safe("gold source", noteMoney)
    elseif event == "MERCHANT_SHOW" then ctx.merchant = true
    elseif event == "MERCHANT_CLOSED" then ctx.merchant = false
    elseif event == "MAIL_SHOW" then ctx.mail = true
    elseif event == "MAIL_CLOSED" then ctx.mail = false
    elseif event == "LOOT_OPENED" then ctx.loot, ctx.lootT = true, GetTime(); S.Act("loot")
    elseif event == "BOSS_KILL" then
        local _, itype = IsInInstance()
        if itype == "raid" then S.Act("raid") elseif itype == "party" then S.Act("dungeon") end
    elseif event == "CHALLENGE_MODE_COMPLETED" then S.Act("mythic")
    elseif event == "LFG_COMPLETION_REWARD" then S.Act("dungeon")
    elseif event == "NEW_MOUNT_ADDED" or event == "NEW_PET_ADDED" or event == "NEW_TOY_ADDED"
        or event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then S.Act("collect")
    elseif event == "ACHIEVEMENT_EARNED" then S.Act("achv")
    elseif event == "PVP_MATCH_COMPLETE" then S.Act("pvp")
    elseif event == "LOOT_CLOSED" then ctx.loot, ctx.lootT = false, GetTime()
    elseif event == "QUEST_TURNED_IN" then SFP:Safe("quest turned in", questTurnedIn, a1)
    end
end)

-- Players around you: ask each one once, without any hover. If they have this addon they answer with their profile
-- (item level included), which does not need the inspect range, and it is added at once.
local nearFrame = CreateFrame("Frame")
nearFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
-- "Name-Realm" (the realm always written out) of a player unit, for the list of players seen and the baked data
local function normKey(unit)
    local ok, n, r = pcall(UnitName, unit)
    if not ok or type(n) ~= "string" or secret(n) then return nil end
    if type(r) ~= "string" or r == "" or secret(r) then r = GetNormalizedRealmName and GetNormalizedRealmName() or nil end
    return r and (n .. "-" .. r) or nil
end
S.NormKey = normKey

-- every player that comes near you (either faction) is noted: tools/bake_players.py reads this list and bakes their public
-- character data (Data/PlayerData.lua) so the tooltip can show it next time, without asking anyone
local function notePlayer(unit)
    if not (SFP.db and UnitIsPlayer(unit)) or UnitIsUnit(unit, "player") then return end
    local key = normKey(unit)
    if not key then return end
    SFP.db.seenPlayers = SFP.db.seenPlayers or {}
    SFP.db.seenPlayers[key] = time()
    SFP.seenCount = (SFP.seenCount or 0) + 1
    if SFP.seenCount % 200 == 0 then   -- keep the list to the newest 3000
        local n, oldest = 0, {}
        for k, t in pairs(SFP.db.seenPlayers) do n = n + 1; oldest[#oldest + 1] = { k, t } end
        if n > 3000 then
            table.sort(oldest, function(a, b) return a[2] < b[2] end)
            for i = 1, n - 3000 do SFP.db.seenPlayers[oldest[i][1]] = nil end
        end
    end
end

nearFrame:SetScript("OnEvent", function(_, _, unit)
    SFP:Safe("note nearby player", notePlayer, unit)
    SFP:Safe("ask nearby player", function()
        if not (C_ChatInfo and S.Config().share and unit and UnitIsPlayer(unit)) then return end
        if UnitIsUnit(unit, "player") or not UnitIsConnected(unit) or not UnitIsFriend("player", unit) then return end
        local key = unitKey(unit)
        if not key or peers[key] or peers[shortName(key)] then return end
        local last = queried[key]
        if last and GetTime() - last < 600 then return end
        if GetTime() - lastQuery < 1.5 then return end   -- one ask every moment: a crowd is asked one by one as the plates appear
        queried[key] = GetTime()
        lastQuery = GetTime()
        send("Q", "WHISPER", key)
    end)
end)

SFP:OnLogin(function()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
    C_Timer.NewTicker(1800, function() SFP:Safe("counts", refreshCounts) end)
    lastMoney = GetMoney and GetMoney() or nil   -- the first reading: later gains are counted from here
    if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, function(tt)
            if tt ~= GameTooltip then return end
            local ok, _, unit = pcall(tt.GetUnit, tt)
            if ok and unit then SFP:Safe("player tooltip", playerTooltip, tt, unit) end
        end)
    end
end)

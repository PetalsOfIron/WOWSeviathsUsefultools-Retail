-- Seviath's Codex — My Collection History
-- Every monster, rare or boss your collections say you already own something from (transmog appearances, mounts,
-- battle pets), including the ones the Codex has no page for. The data is read by TransmogHistory.lua in the
-- main addon and saved account-wide, so it covers things you did before the addon was installed.

local ADDON, ns = SFP_Module("Codex")
local C = ns.CYAN

local function main() return _G.SeviathsUsefulTools end

-- names of the rares the addon knows (lower case)
local function rareNames()
    local set = {}
    local S = main()
    for _, list in pairs(S and S.Rares or {}) do
        if type(list) == "table" then
            for _, sp in ipairs(list) do if sp.name then set[sp.name:lower()] = true end end
        end
    end
    return set
end

-- Bosses (by instance), Rares, or other monsters
local function groupFor(self, rec, rares)
    local key = rec.n:lower()
    if rares[key] then return "Rares" end
    local isBoss = (self.FindByName and self:FindByName("boss", rec.n))
        or (rec.i and self.FindByName and (self:FindByName("dungeon", rec.i) or self:FindByName("raid", rec.i)))
    if isBoss then return "Bosses - " .. (rec.i or "other") end
    return rec.i and ("Monsters - " .. rec.i) or "Monsters - open world / unknown place"
end

function ns:LoadHistory()
    local S = main()
    local h = S and S.db and S.db.history
    if not (h and h.by) then return end
    local rares = rareNames()
    for key, rec in pairs(h.by) do
        if rec.n and ((rec.c or 0) > 0 or rec.mounts or rec.pets) then
            local bits = {}
            if (rec.c or 0) > 0 then bits[#bits + 1] = rec.c .. " items" end
            if rec.mounts then bits[#bits + 1] = #rec.mounts .. " mount" .. (#rec.mounts == 1 and "" or "s") end
            if rec.pets then bits[#bits + 1] = #rec.pets .. " pet" .. (#rec.pets == 1 and "" or "s") end
            local sub = table.concat(bits, ", ") .. (rec.i and ("  ·  " .. rec.i) or "")
            local e = self:Get("history:" .. key)
            if e then
                e.hist, e.sub = rec, sub
            else
                e = self:Add({
                    cat = "history", id = key, name = rec.n, group = groupFor(self, rec, rares),
                    icon = (rec.mounts and "Interface\\Icons\\Ability_Mount_RidingHorse")
                        or (rec.pets and "Interface\\Icons\\INV_Box_PetCarrier_01") or "Interface\\Icons\\INV_Chest_Plate16",
                    sub = sub .. " " .. rec.n, hist = rec, tags = "collection history owned " .. key,
                })
                -- link to the Codex page of the same monster or boss, when there is one
                if e then
                    local page = (self.FindByName and (self:FindByName("boss", rec.n) or self:FindByName("creature", rec.n)))
                    if page then self:Link(e, page) end
                end
            end
        end
    end
    -- every rare the addon knows with a mount / pet / toy: what you have and what you still miss
    for _, list in pairs(S.Rares or {}) do
        if type(list) == "table" then
            for _, sp in ipairs(list) do
                if sp.name and sp.items and #sp.items > 0 then
                    local owned, total, rows = 0, 0, {}
                    for _, itemID in ipairs(sp.items) do
                        local own = S.OwnedStatus and S:OwnedStatus(itemID)
                        if own ~= nil then
                            total = total + 1
                            if own then owned = owned + 1 end
                            rows[#rows + 1] = { id = itemID, own = own }
                        end
                    end
                    if total > 0 then
                        local key = "rare:" .. sp.name:lower()
                        local e = self:Get("history:" .. key)
                        local sub = ("%d of %d collectibles"):format(owned, total)
                        if e then
                            e.rareRows, e.sub = rows, sub
                        else
                            self:Add({ cat = "history", id = key, name = sp.name, group = "Rares - collectibles (owned or missing)",
                                icon = "Interface\\Icons\\Ability_Mount_RidingHorse", sub = sub .. " " .. sp.name, rareRows = rows,
                                tags = "rare mount pet toy collection missing owned" })
                        end
                    end
                end
            end
        end
    end
    -- BoE and world-drop gear you own (the open-world kind has no monster to hang it on)
    local boeIds = {}
    for id in pairs(h.boe or {}) do boeIds[id] = true end
    for id in pairs(h.items or {}) do
        local info = S.Items and S.Items[id]
        if info and info.kind == "boe" then boeIds[id] = true end
    end
    local n = 0
    for _ in pairs(boeIds) do n = n + 1 end
    if n > 0 then
        local e = self:Get("history:__boe")
        local sub = n .. " BoE / world-drop items you own"
        if e then
            e.boeIds, e.sub = boeIds, sub
        else
            self:Add({ cat = "history", id = "__boe", name = "BoE and world-drop gear you own", group = "Gear",
                icon = "Interface\\Icons\\INV_Misc_Bag_10", sub = sub .. " boe bind on equip world drop", boeIds = boeIds,
                tags = "boe bind on equip world drop gear owned" })
        end
    end
    self.historyTime = GetTime and GetTime() or 0
end

function ns:RefreshHistory()
    if self.historyTime and GetTime and GetTime() - self.historyTime < 20 then return end
    if self.LoadHistory then self:LoadHistory() end
end

function ns:HistoryEntryText(e)
    local S = main()
    if e.rareRows then
        local lines = {}
        for _, r in ipairs(e.rareRows) do
            lines[#lines + 1] = "• " .. S:ItemName(r.id) .. (r.own and "   |cff40ff40owned|r" or "   |cffff6060not collected yet|r")
        end
        return C .. "Collectibles|r\n" .. table.concat(lines, "\n") ..
            "\n\n|cff888888Mounts, pets and toys this rare can drop, and whether this account already has them.|r"
    end
    if e.boeIds then
        local lines, n = {}, 0
        for id in pairs(e.boeIds) do
            n = n + 1
            if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
            lines[#lines + 1] = "• " .. S:ItemName(id)
        end
        table.sort(lines)
        local shown = {}
        for i = 1, math.min(60, #lines) do shown[i] = lines[i] end
        return C .. "You already own|r\n" .. n .. " Bind-on-Equip / world-drop items (from your transmog collection and the BoE lists in this addon)." ..
            "\n\n" .. C .. "Items|r\n" .. table.concat(shown, "\n") .. (n > 60 and ("\n|cff888888+" .. (n - 60) .. " more|r") or "") ..
            "\n\n|cff888888Item names appear as they load - open this page again if some still say item.|r"
    end
    local rec = e.hist
    if not rec then return "" end
    local out = {}
    out[#out + 1] = C .. "You already own|r\n" .. S:HistoryText(rec)
    if rec.i then out[#out + 1] = C .. "Where|r\n" .. rec.i end
    if rec.mounts then out[#out + 1] = C .. "Mounts|r\n• " .. table.concat(rec.mounts, "\n• ") end
    if rec.pets then out[#out + 1] = C .. "Battle pets|r\n• " .. table.concat(rec.pets, "\n• ") end
    if rec.ids then
        local names, n = {}, 0
        for id in pairs(rec.ids) do
            n = n + 1
            if n <= 20 then names[#names + 1] = "• " .. S:ItemName(id) end
        end
        table.sort(names)
        if #names > 0 then
            out[#out + 1] = C .. "Gear (transmog)|r\n" .. table.concat(names, "\n") ..
                (n > 20 and ("\n|cff888888+" .. (n - 20) .. " more|r") or "")
        end
    end
    out[#out + 1] = "|cff888888Read from your transmog, mount and pet collections, so it includes things you did before the addon was installed. " ..
        "Type /sfp history rescan to read it again.|r"
    return table.concat(out, "\n\n")
end

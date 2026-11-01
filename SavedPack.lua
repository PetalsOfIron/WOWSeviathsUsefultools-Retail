-- SeviathsUsefulTools - the saved data in pieces.
--
-- WoW writes a player's saved data as ONE chunk of Lua that can hold only about 262,000 different names and numbers; a player who collects a
-- lot would reach that limit one day and the game would then load none of the data ("constant table overflow"). Here the big tables are
-- written as a few long TEXT pieces instead: a long text counts as ONE name however much is inside it. Just before the game saves (at
-- logout / reload / exit) each big table is cut into pieces of about 200 KB and written as text (db.__packed); when the game loads the data
-- again the pieces are turned back into tables, before anything reads them. Nothing is dropped; the data in the game is the same.
--
-- Safety: a table is only removed from the saved data after its text was made without an error; a piece that cannot be read back is kept
-- as it is (db.__packedKept), and that table is not packed again.

local PIECE = 200000   -- characters of text per piece

-- the big tables of each saved database (the small ones stay as they are)
local PACK = {
    SeviathsUsefulToolsDB = { "ahAll", "ahNames", "ahItems", "prices", "realmPrices", "priceHist", "ahListings", "knownItems", "npcs",
        "objects", "nameplateText", "inspected", "seenInfo", "rioCache", "playerIDs", "seenPlayers", "nameRealms", "nameRealm", "history",
        "learnedDecor", "itemExp", "guildDir", "guildNotes", "guildAch", "towns", "itemZones", "petPrices", "ejCache", "learned", "hiddenSpots" },
    SeviathsCodexDB = { "quests", "loot", "matUses", "items", "qloc", "lootZones", "npcs", "vendors", "vendorItems", "beasts", "rares" },
}

local loadfn = loadstring or load
local format, floor, concat = string.format, math.floor, table.concat

local function num(v)
    if v ~= v or v == math.huge or v == -math.huge then return "0" end
    if v == floor(v) and v > -9007199254740992 and v < 9007199254740992 then return format("%d", v) end
    return format("%.17g", v)
end

-- one value as Lua text, appended to out
local function ser(v, out, depth)
    local t = type(v)
    if t == "number" then out[#out + 1] = num(v)
    elseif t == "string" then out[#out + 1] = format("%q", v)
    elseif t == "boolean" then out[#out + 1] = v and "true" or "false"
    elseif t == "table" then
        if depth > 14 then error("table too deep") end
        out[#out + 1] = "{"
        for k, x in pairs(v) do
            local tk, tx = type(k), type(x)
            if (tk == "number" or tk == "string") and (tx == "number" or tx == "string" or tx == "boolean" or tx == "table") then
                out[#out + 1] = "["
                ser(k, out, depth + 1)
                out[#out + 1] = "]="
                ser(x, out, depth + 1)
                out[#out + 1] = ","
            end
        end
        out[#out + 1] = "}"
    else
        out[#out + 1] = "nil"
    end
end

-- a table cut into text pieces: { "{[k]=v,...}", ... }
local function pack(t)
    local pieces, buf, size = {}, {}, 0
    for k, v in pairs(t) do
        local out = {}
        out[1] = "["
        ser(k, out, 1)
        out[#out + 1] = "]="
        ser(v, out, 1)
        out[#out + 1] = ","
        local text = concat(out)
        buf[#buf + 1] = text
        size = size + #text
        if size >= PIECE then
            pieces[#pieces + 1] = "{" .. concat(buf) .. "}"
            buf, size = {}, 0
        end
    end
    if #buf > 0 then pieces[#pieces + 1] = "{" .. concat(buf) .. "}" end
    return pieces
end

local function unpackPiece(text)
    local fn = loadfn("return " .. text)
    if not fn then return nil end
    local ok, t = pcall(fn)
    if ok and type(t) == "table" then return t end
end

-- turns db.__packed back into the tables (called when the saved data was loaded, before anything reads it)
function SeviathsUnpackSaved(db)
    if type(db) ~= "table" or type(db.__packed) ~= "table" then return end
    local packed = db.__packed
    db.__packed = nil
    for name, pieces in pairs(packed) do
        local into = type(db[name]) == "table" and db[name] or {}
        local okAll = true
        for _, text in ipairs(pieces) do
            local t = unpackPiece(text)
            if t then
                for k, v in pairs(t) do if into[k] == nil then into[k] = v end end
            else
                okAll = false
            end
        end
        db[name] = into
        if not okAll then
            -- a piece could not be read: it is kept as it was, and this table is left unpacked from now on
            db.__packedKept = db.__packedKept or {}
            db.__packedKept[name] = pieces
        end
    end
end

-- cuts the big tables of a saved database into text pieces (called just before the game saves)
function SeviathsPackSaved(db, dbName)
    local list = PACK[dbName]
    if type(db) ~= "table" or not list then return end
    local packed = type(db.__packed) == "table" and db.__packed or {}
    for _, name in ipairs(list) do
        local t = db[name]
        if type(t) == "table" and next(t) ~= nil and not (db.__packedKept and db.__packedKept[name]) then
            local ok, pieces = pcall(pack, t)
            if ok and #pieces > 0 then
                packed[name] = pieces
                db[name] = nil
            end
        end
    end
    if next(packed) ~= nil then db.__packed = packed end
end

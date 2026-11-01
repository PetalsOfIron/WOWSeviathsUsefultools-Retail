-- Shipped monsters and gray items: read only when they are needed.
--
-- They are in their own load-on-demand addon folder (SeviathsUsefulTools_Monsters, made by tools/bake_collected.py), so the game does not
-- read them at login. The addon is loaded the first time a monster tooltip, a gray item tooltip or the farm menu needs it. A monster is
-- kept there as a short text, and only the records of the map that is shown (or of the monster that is hovered) are turned into tables.

local _, SFP = ...

local NAME = "SeviathsUsefulTools_Monsters"
local state          -- nil = not tried yet, true = loaded, false = not there
local cache = {}     -- [npcID] = decoded record (false = none), freed when the window closes

function SFP:LoadMonsterData()
    if state ~= nil then return state end
    local ok = false
    if C_AddOns and C_AddOns.LoadAddOn then
        if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(NAME) then
            ok = true
        else
            local loaded = C_AddOns.LoadAddOn(NAME)
            ok = loaded and true or false
        end
    end
    state = ok
    return ok
end

-- the shipped tables the load-on-demand folder fills: the monsters (a text per record), the monsters of each map (ids only)
local function shipped()
    local C = _G.SeviathsUsefulToolsCollected
    local packed = C and C.packed and C.packed.SeviathsUsefulToolsDB
    local data = C and C.data and C.data.SeviathsUsefulToolsDB
    return packed and packed.npcs, data and data.npcMaps
end

-- a monster's shipped record, decoded now: a fresh table each time
function SFP:ShippedNpcRecord(id)
    if not self:LoadMonsterData() then return nil end
    local npcs = shipped()
    local text = npcs and npcs[id]
    if type(text) == "string" and SeviathsDecode then return SeviathsDecode(text) end
    return nil
end

-- a monster: the player's own record, else the shipped one (decoded when it is first asked for)
function SFP:Npc(id)
    local rec = self.db and self.db.npcs and self.db.npcs[id]
    if rec ~= nil then return rec end
    local c = cache[id]
    if c ~= nil then return c or nil end
    rec = self:ShippedNpcRecord(id)
    cache[id] = rec or false
    return rec
end

-- the ids of the shipped monsters of a map (no record is decoded)
function SFP:ShippedNpcIDs(map)
    if not self:LoadMonsterData() then return {} end
    local _, maps = shipped()
    return maps and maps[map] or {}
end

-- the maps that have shipped monsters
function SFP:ShippedNpcMaps()
    if not self:LoadMonsterData() then return {} end
    local _, maps = shipped()
    return maps or {}
end

function SFP:FreeMonsterCache()
    cache = {}
end

---------------------------------------------------------------------------
-- Transmog items (SeviathsUsefulTools_Transmog): where an item comes from, read from its block of 500 ids only when that item is looked at
---------------------------------------------------------------------------
local TNAME = "SeviathsUsefulTools_Transmog"
local tstate
local TSOURCE = {
    "Crafted", "Drop", "PvP", "Quest", "Vendor", "Trainer", "Discovery", "Redemption", "Talent", "Starter", "Event", "Achievement",
    "Black Market", "Disenchanting", "Fishing", "Gathering", "Milling", "Mining", "Prospecting", "Pickpocketing", "Salvaging", "In-game shop",
}

local TCLASS = { "Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Death Knight", "Shaman", "Mage", "Warlock", "Monk", "Druid", "Demon Hunter", "Evoker" }
local TARMOR = { [0] = "Miscellaneous", "Cloth", "Leather", "Mail", "Plate", "Cosmetic", "Shield", "Libram", "Idol", "Totem", "Sigil", "Relic", [-6] = "Cloak" }
local TWEAPON = { [0] = "One-handed axe", "Two-handed axe", "Bow", "Gun", "One-handed mace", "Two-handed mace", "Polearm", "One-handed sword", "Two-handed sword",
    "Warglaive", "Staff", [13] = "Fist weapon", [14] = "Miscellaneous", [15] = "Dagger", [16] = "Thrown", [17] = "Spear", [18] = "Crossbow", [19] = "Wand", [20] = "Fishing pole" }
local TSLOT = { "Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands", "Finger", "Trinket", "One-hand", "Shield", "Ranged", "Back",
    "Two-hand", "Bag", "Tabard", "Robe", "Main hand", "Off hand", "Held in off-hand", "Ammo", "Thrown", "Ranged" }

-- { name, quality, source ("Drop", "Vendor" ...), source name (the quest, zone or achievement Wowhead names) } or nil
function SFP:TransmogItem(id)
    if type(id) ~= "number" then return nil end
    if tstate == nil then
        tstate = false
        if C_AddOns and C_AddOns.LoadAddOn then
            if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(TNAME) then tstate = true
            else tstate = C_AddOns.LoadAddOn(TNAME) and true or false end
        end
    end
    if not tstate then return nil end
    local blocks = _G.SeviathsTransmogBlocks
    local text = blocks and blocks[math.floor(id / 500)]
    if not text then return nil end
    local key = id .. "|"
    local from = 1
    while true do
        local s = text:find(key, from, true)
        if not s then return nil end
        if s == 1 or text:sub(s - 1, s - 1) == "\n" then
            local e = text:find("\n", s, true) or (#text + 1)
            local name, q, src, sname, ic, isub, slot, req, cls = text:sub(s + #key, e - 1):match("^(.-)|(%d+)|(%d+)|([^|]*)|?([^|]*)|?([^|]*)|?([^|]*)|?([^|]*)|?([^|]*)$")
            if not name then return nil end
            local st = tonumber(src)
            local classes
            if cls and cls ~= "" then
                classes = {}
                for c in cls:gmatch("%d+") do classes[#classes + 1] = TCLASS[tonumber(c)] end
            end
            ic, isub = tonumber(ic), tonumber(isub)
            local kind = (ic == 4 and TARMOR[isub]) or (ic == 2 and TWEAPON[isub]) or nil
            return {
                name = name, quality = tonumber(q), source = TSOURCE[st], sourceName = sname ~= "" and sname or nil,
                type = kind, slot = TSLOT[tonumber(slot) or 0], reqLevel = tonumber(req), classes = classes,
            }
        end
        from = s + 1
    end
end

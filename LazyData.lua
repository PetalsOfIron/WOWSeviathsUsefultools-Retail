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

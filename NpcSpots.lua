-- SeviathsUsefulTools - every NPC you speak to
-- Whenever you open a conversation or a window with an NPC (talk, quest, vendor, trainer, flight master, banker,
-- auctioneer, innkeeper ...), the addon saves its name, ID, the map and the spot you stood at, and what it does for you.
-- Saved for all your characters: it is the place list for waypoints later (vendors, quest givers, trainers ...).

local _, SFP = ...

local function secret(v) return issecretvalue and issecretvalue(v) end

-- what an opened window or conversation says the NPC is
local WHAT = {
    GOSSIP_SHOW = "talk", QUEST_DETAIL = "quest giver", QUEST_PROGRESS = "quest", QUEST_COMPLETE = "quest turn-in",
    MERCHANT_SHOW = "vendor", TRAINER_SHOW = "trainer", TAXIMAP_OPENED = "flight master", BANKFRAME_OPENED = "banker",
    AUCTION_HOUSE_SHOW = "auctioneer",
}

local interactionNames
local function interactionName(t)
    if not interactionNames then
        interactionNames = {}
        for name, v in pairs((Enum and Enum.PlayerInteractionType) or {}) do
            if type(name) == "string" and type(v) == "number" then interactionNames[v] = name:lower() end
        end
    end
    return interactionNames[t]
end

local function npcIDFromGUID(guid)
    if type(guid) ~= "string" or secret(guid) then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    return tonumber(id)
end

local nameIndex   -- lowercase name -> npcID, rebuilt when a new NPC is added

local function record(what)
    if not SFP.db then return end
    local okU, exists = pcall(UnitExists, "npc")
    if not okU or not exists then return end
    local okG, guid = pcall(UnitGUID, "npc")
    local id = okG and npcIDFromGUID(guid)
    if not id then return end
    local okN, name = pcall(UnitName, "npc")
    if not okN or type(name) ~= "string" or secret(name) or name == "" then return end
    local m = C_Map.GetBestMapForUnit("player")
    local pos = m and C_Map.GetPlayerMapPosition(m, "player")
    if not (pos and pos.GetXY) then return end
    local px, py = pos:GetXY()
    if not px or secret(px) or px <= 0 then return end
    SFP.db.npcPos = SFP.db.npcPos or {}
    local rec = SFP.db.npcPos[id]
    if not rec then
        rec = { n = name, m = m, x = px, y = py, v = 1, k = {}, t = time() }
        SFP.db.npcPos[id] = rec
        nameIndex = nil
    elseif rec.m == m then
        -- the NPC stands still: the spot is the average of every visit
        rec.x = (rec.x * rec.v + px) / (rec.v + 1)
        rec.y = (rec.y * rec.v + py) / (rec.v + 1)
        rec.v = rec.v + 1
        rec.t = time()
    else
        rec.m, rec.x, rec.y, rec.v, rec.t = m, px, py, 1, time()   -- it moved to another map
    end
    rec.n = name
    if what then rec.k[what] = true end
end

-- the place of an NPC you spoke to, by name: { map, x, y, label } or nil
function SFP:LearnedNpcByName(name)
    if type(name) ~= "string" or not (self.db and self.db.npcPos) then return nil end
    if not nameIndex then
        nameIndex = {}
        for id, r in pairs(self.db.npcPos) do
            if type(r) == "table" and r.n then nameIndex[r.n:lower()] = id end
        end
    end
    local id = nameIndex[name:lower()]
    local r = id and self.db.npcPos[id]
    if r and r.m and r.x then return { map = r.m, x = r.x, y = r.y, label = r.n } end
    return nil
end

local f = CreateFrame("Frame")
for ev in pairs(WHAT) do pcall(f.RegisterEvent, f, ev) end
pcall(f.RegisterEvent, f, "PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
local pending = false
f:SetScript("OnEvent", function(_, event, arg)
    local what = WHAT[event]
    if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then what = interactionName(arg) end
    if pending then return end
    pending = true
    -- a moment later: the NPC is then the "npc" unit of the window that opened
    C_Timer.After(0.4, function()
        pending = false
        SFP:Safe("npc spot", record, what)
    end)
end)

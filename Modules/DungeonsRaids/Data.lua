-- Seviath's Dungeons & Raids - class data
-- Check these after big patches: Blizzard sometimes moves raid buffs between classes.
local _, ns = SFP_Module("DungeonsRaids")
local D = {}
ns.Data = D

-- Raid buffs and raid-wide debuffs, one provider class each
D.BUFFS = {
  { key = "INT",    name = "Arcane Intellect",       short = "Int",    class = "MAGE" },
  { key = "STAM",   name = "Power Word: Fortitude",  short = "Stam",   class = "PRIEST" },
  { key = "AP",     name = "Battle Shout",           short = "AP",     class = "WARRIOR" },
  { key = "VERS",   name = "Mark of the Wild",       short = "Vers",   class = "DRUID" },
  { key = "MAST",   name = "Skyfury",                short = "Mast",   class = "SHAMAN" },
  { key = "BRONZE", name = "Blessing of the Bronze", short = "Bronze", class = "EVOKER" },
  { key = "PHYS",   name = "Mystic Touch",           short = "Phys",   class = "MONK" },
  { key = "MAGIC",  name = "Chaos Brand",            short = "Magic",  class = "DEMONHUNTER" },
  { key = "MARK",   name = "Hunter's Mark",          short = "Mark",   class = "HUNTER" },
  { key = "AURA",   name = "Devotion Aura",          short = "Aura",   class = "PALADIN" },
}

-- does this class bring the buff?
function D.Provides(buff, class)
  return (buff.classes and buff.classes[class]) or buff.class == class
end

-- "Mage, Warlock, Shaman" in the player's language
function D.ProviderText(buff)
  local names = {}
  for class in pairs(buff.classes or { [buff.class] = true }) do names[#names + 1] = D.ClassLabel(class) end
  table.sort(names)
  return table.concat(names, ", ")
end

D.LUST = { SHAMAN = true, MAGE = true, HUNTER = true, EVOKER = true }
D.BREZ = { DRUID = true, DEATHKNIGHT = true, WARLOCK = true, PALADIN = true }

D.ARMOR = {
  WARRIOR = "Plate", PALADIN = "Plate", DEATHKNIGHT = "Plate",
  HUNTER = "Mail", SHAMAN = "Mail", EVOKER = "Mail",
  ROGUE = "Leather", DRUID = "Leather", MONK = "Leather", DEMONHUNTER = "Leather",
  PRIEST = "Cloth", MAGE = "Cloth", WARLOCK = "Cloth",
}

-- Tier token groups
D.TOKEN = {
  DEATHKNIGHT = "Dreadful", DEMONHUNTER = "Dreadful", WARLOCK = "Dreadful",
  DRUID = "Mystic", HUNTER = "Mystic", MAGE = "Mystic",
  PALADIN = "Venerated", PRIEST = "Venerated", SHAMAN = "Venerated",
  EVOKER = "Zenith", MONK = "Zenith", ROGUE = "Zenith", WARRIOR = "Zenith",
}

D.DIFF_ID = { N = 14, H = 15, M = 16 }
-- Every difficulty that counts as Normal / Heroic / Mythic, including old 10/25/40-player raids
D.DIFF_IDS = { N = { 14, 3, 4, 9, 1 }, H = { 15, 5, 6, 2 }, M = { 16, 23, 8 } }

-- Small class icon for use inside text
function D.ClassIcon(class, size)
  size = size or 14
  local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
  if c then
    return string.format("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:%d:%d:0:0:256:256:%d:%d:%d:%d|t",
      size, size, c[1] * 256, c[2] * 256, c[3] * 256, c[4] * 256)
  end
  return "|A:classicon-" .. class:lower() .. ":" .. size .. ":" .. size .. "|a"
end
D.DIFF_LABEL = { N = "Normal", H = "Heroic", M = "Mythic" }
D.ROLE_LABEL = { TANK = "Tank", HEALER = "Healer", DAMAGER = "DPS" }

function D.ClassLabel(class)
  return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
end

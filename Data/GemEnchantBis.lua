-- SeviathsUsefulTools - recommended gems and enchants per specialization (Gem & Enchant Helper)
-- Source: the Method.gg "stats, races and consumables" page of each specialization, patch 12.1.5, read 2026-10-31.
-- Facts only (names and order). A line "A > B" means A first. Where a page gives one option per slot, the list has one name.
-- Key: class token : specialization name as the game shows it.
local _, SFP = ...

local BIS = {}
SFP.GemEnchantBis = BIS
SFP.GemEnchantBisPatch = "12.1.5"

local function E(class, spec, t) BIS[class .. ":" .. spec] = t end

E("HUNTER", "Beast Mastery", {
    stat = "Weapon Damage > Agility > Mastery > Haste >= Crit > Versatility",
    gems = { "Indecipherable Eversong Diamond", "Flawless Deadly Amethyst" },
    gemNote = "1 diamond (only one can be worn), all other sockets Deadly Amethyst",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Lynx's Dexterity" }, ring = { "Zul'jin's Mastery" }, weapon = { "Rite of the Hash'ey" },
})
E("PRIEST", "Holy", {
    stat = "Raid: Crit > Mastery > Versatility > Haste.  M+: Haste > Versatility = Crit > Mastery",
    gems = { "Telluric Eversong Diamond", "Flawless Masterful Garnet", "Flawless Deadly Amethyst", "Flawless Deadly Peridot", "Flawless Versatile Peridot" },
    gemNote = "Raid: Masterful Garnet or Deadly Amethyst. M+: Deadly Peridot or Versatile Peridot",
    head = { "Hex of Leeching", "Rune of Avoidance" }, shoulder = { "Silvermoon's Mending", "Amirdrassil's Grace" },
    chest = { "Mark of the Worldsoul", "Mark of the Magister" }, legs = { "Arcanoweave Spellthread" },
    feet = { "Lynx's Dexterity", "Shaladrassil's Roots" }, ring = { "Nature's Fury" }, weapon = { "Acuity of the Ren'dorei" },
})
E("DEATHKNIGHT", "Blood", {
    stat = "Deathbringer: Strength > Crit = Vers = Mastery > Haste.  San'layn: Strength > Haste > Crit = Vers = Mastery",
    gems = { "Indecipherable Eversong Diamond", "Flawless Quick Garnet", "Flawless Masterful Garnet" },
    gemNote = "1 diamond; the rest Quick Garnet (San'layn) or Masterful Garnet (Deathbringer)",
    head = { "Rune of Avoidance", "Empowered Blessing of Speed" }, shoulder = { "Amirdrassil's Grace", "Akil'zon's Swiftness" },
    chest = { "Mark of the Worldsoul", "Mark of Nalorakk" }, legs = { "Forest Hunter's Armor Kit", "Blood Knight's Armor Kit" },
    feet = { "Lynx's Dexterity", "Farstrider's Hunt" }, ring = { "Eyes of the Eagle" }, weapon = { "Rune of Sanguination", "Rune of the Fallen Crusader" },
})
E("DEATHKNIGHT", "Frost", {
    stat = "Strength > Crit > Mastery >= Haste > Versatility",
    gems = { "Powerful Eversong Diamond", "Indecipherable Eversong Diamond", "Flawless Deadly Amethyst" },
    gemNote = "Powerful or Indecipherable diamond (the page calls the difference small); dual-stat gems for the rest, for example Deadly Amethyst",
    head = { "Empowered Blessing of Speed" }, shoulder = { "Flight of the Eagle" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Farstrider's Hunt" }, ring = { "Nature's Fury", "Zul'jin's Mastery" },
    weapon = { "Rune of the Fallen Crusader", "Rune of Razorice", "Rune of the Stoneskin Gargoyle" },
})
E("DEATHKNIGHT", "Unholy", {
    stat = "Strength > Crit > Mastery >= Haste > Versatility",
    gems = { "Powerful Eversong Diamond", "Indecipherable Eversong Diamond", "Flawless Deadly Amethyst" },
    gemNote = "Powerful or Indecipherable diamond; dual-stat gems for the rest, for example Deadly Amethyst",
    head = { "Empowered Blessing of Speed" }, shoulder = { "Flight of the Eagle" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Farstrider's Hunt" }, ring = { "Eyes of the Eagle" }, weapon = { "Rune of the Apocalypse" },
})
E("DEMONHUNTER", "Havoc", {
    stat = "Agility > Crit > Mastery > Haste > Versatility (Fel-Scarred leans Mastery, Aldrachi Reaver leans Crit)",
    gems = { "Powerful Eversong Diamond", "Indecipherable Eversong Diamond", "Flawless Quick Amethyst", "Flawless Masterful Peridot", "Flawless Masterful Lapis", "Flawless Masterful Garnet" },
    gemNote = "1 Quick Amethyst, 1 Masterful Peridot, 1 Masterful Lapis, 1 Masterful Garnet; all other sockets Masterful Garnet",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})
E("DEMONHUNTER", "Vengeance", {
    stat = "Defensive: Agility (item level) > Haste > Crit = Versatility = Mastery",
    gems = { "Indecipherable Eversong Diamond", "Flawless Deadly Peridot" },
    gemNote = "1 diamond; Haste, Crit or Versatility gems for the rest, for example Deadly Peridot",
    head = { "Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" }, ring = { "Silvermoon's Alacrity" }, weapon = { "Berserker's Rage" },
})
E("DEMONHUNTER", "Devourer", {
    stat = "Intellect > Mastery > Haste >= Crit >> Versatility",
    gems = { "Powerful Eversong Diamond", "Indecipherable Eversong Diamond", "Flawless Quick Amethyst", "Flawless Masterful Garnet", "Flawless Masterful Peridot" },
    gemNote = "Quick Amethyst, Masterful Garnet and Masterful Peridot once each; the rest Amethyst",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})
E("DRUID", "Balance", {
    stat = "Mastery > Haste = Crit > Versatility",
    gems = { "Indecipherable Eversong Diamond", "Flawless Quick Amethyst" },
    gemNote = "at least 1 diamond; the rest as simulated, suggested Quick Amethyst",
    head = { "Empowered Rune of Avoidance", "Empowered Hex of Leeching" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity", "Shaladrassil's Roots" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei" },
})
E("DRUID", "Feral", {
    stat = "Agility > secondaries (no breakpoint, simulate your gear)",
    gems = { "Indecipherable Eversong Diamond", "Flawless Masterful Peridot", "Flawless Quick Amethyst" },
    gemNote = "always the diamond; the others as simulated, default Masterful Peridot or Quick Amethyst",
    head = { "Empowered Rune of Avoidance", "Empowered Hex of Leeching" }, shoulder = { "Amirdrassil's Grace", "Silvermoon's Mending" },
    chest = { "Mark of the Worldsoul" }, legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" },
    ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})
E("DRUID", "Guardian", {
    stat = "Item level > Haste > Versatility >= Crit > Mastery",
    gems = { "Indecipherable Eversong Diamond", "Flawless Versatile Peridot", "Flawless Deadly Peridot" },
    gemNote = "1 diamond; Versatile Peridot or Deadly Peridot",
    head = { "Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" }, ring = { "Silvermoon's Alacrity" }, weapon = { "Acuity of the Ren'dorei" },
})
E("DRUID", "Restoration", {
    stat = "Raid: item level > Haste = Mastery > Crit >= Versatility.  M+: item level > Haste > Mastery > Versatility > Crit",
    gems = { "Indecipherable Eversong Diamond", "Flawless Masterful Peridot", "Flawless Quick Amethyst" },
    gemNote = "1 diamond; Masterful Peridot or Quick Amethyst",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Shaladrassil's Roots" }, ring = { "Silvermoon's Alacrity" }, weapon = { "Acuity of the Ren'dorei" },
})

E("EVOKER", "Devastation", {
    stat = "Intellect > Crit > Haste = Mastery > Versatility",
    gems = { "Indecipherable Eversong Diamond" }, gemNote = "1 diamond; Crit or Haste gems for the rest",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei" },
})
E("EVOKER", "Preservation", {
    stat = "Raid and M+ healing: Intellect > Mastery > Crit > Haste > Versatility.  M+ damage: Intellect > Crit > Haste > Mastery > Versatility",
    gems = { "Telluric Eversong Diamond", "Indecipherable Eversong Diamond", "Flawless Quick Amethyst", "Flawless Masterful Garnet" },
    gemNote = "neck: Telluric diamond (needs all four gem colors) or Indecipherable if mana is no problem; the other sockets Quick Amethyst and Masterful Garnet",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Arcanoweave Spellthread" }, feet = { "Shaladrassil's Roots" }, ring = { "Zul'jin's Mastery", "Eyes of the Eagle" },
    weapon = { "Acuity of the Ren'dorei", "Rite of the Hash'ey" },
})
E("EVOKER", "Augmentation", {
    stat = "Intellect > Mastery > Haste = Crit > Versatility",
    gems = { "Indecipherable Eversong Diamond" }, gemNote = "1 diamond (required); Mastery gems for the rest",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Zul'jin's Mastery" }, weapon = { "Arcane Mastery" },
})
E("HUNTER", "Marksmanship", {
    stat = "Weapon Damage > Agility > Crit > Mastery > Versatility > Haste",
    gems = { "Indecipherable Eversong Diamond", "Flawless Masterful Garnet" }, gemNote = "1 diamond (only one can be worn); all other sockets Masterful Garnet",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei" },
})
E("HUNTER", "Survival", {
    stat = "Single target: Agility > Mastery > Crit = Haste > Versatility.  AoE: Agility > Mastery > Haste > Crit > Versatility",
    gems = { "Powerful Eversong Diamond", "Flawless Deadly Amethyst" }, gemNote = "Powerful diamond; all other sockets Deadly Amethyst",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Rootwarden" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" }, ring = { "Zul'jin's Mastery" }, weapon = { "Acuity of the Ren'dorei" },
})
E("MAGE", "Arcane", {
    stat = "Intellect > Haste > Versatility > Crit > Mastery",
    gems = { "Indecipherable Eversong Diamond" }, gemNote = "1 diamond; Haste or Crit gems for the rest, as simulated",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Arcanoweave Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})
E("MAGE", "Fire", {
    stat = "Intellect > Haste > Versatility > Mastery > Crit (Sunfury and Frostfire)",
    gems = { "Powerful Eversong Diamond" }, gemNote = "1 Powerful diamond; Haste or Mastery gems for the rest, any mix",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei" },
})
E("MAGE", "Frost", {
    stat = "Intellect > Mastery = Crit > Haste > Versatility",
    gems = { "Indecipherable Eversong Diamond", "Flawless Masterful Garnet" }, gemNote = "1 diamond; all other sockets Masterful Garnet",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei" },
})
E("MONK", "Brewmaster", {
    stat = "Item level first, then Agility >> Crit = Versatility > Mastery >> Haste",
    gems = { "Indecipherable Eversong Diamond", "Powerful Eversong Diamond", "Flawless Versatile Peridot", "Flawless Deadly Lapis", "Flawless Deadly Amethyst", "Flawless Versatile Garnet" },
    gemNote = "Indecipherable diamond, or Powerful diamond with one each of Versatile Peridot, Deadly Lapis, Deadly Amethyst, Versatile Garnet",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei" },
})
E("MONK", "Windwalker", {
    stat = "Agility > Haste > Mastery = Crit >>> Versatility",
    gems = { "Indecipherable Eversong Diamond", "Flawless Masterful Peridot", "Flawless Quick Garnet" }, gemNote = "1 diamond; Masterful Peridot and Quick Garnet (simulate for exact counts)",
    head = { "Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})

E("MONK", "Mistweaver", {
    stat = "Haste > Crit = Versatility > Mastery",
    gems = { "Indecipherable Eversong Diamond", "Flawless Deadly Peridot" }, gemNote = "1 diamond; all other sockets Deadly Peridot",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Magister" },
    legs = { "Arcanoweave Spellthread" }, feet = { "Shaladrassil's Roots" }, ring = { "Silvermoon's Alacrity" }, weapon = { "Acuity of the Ren'dorei" },
})
E("PALADIN", "Holy", {
    stat = "Intellect > Mastery > Haste = Crit > Versatility",
    gems = { "Telluric Eversong Diamond", "Flawless Masterful Peridot", "Flawless Quick Amethyst" }, gemNote = "Telluric diamond; Masterful Peridot or Quick Amethyst for the rest",
    head = { "Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Magister" },
    legs = { "Arcanoweave Spellthread" }, feet = { "Shaladrassil's Roots" }, ring = { "Zul'jin's Mastery" }, weapon = { "Acuity of the Ren'dorei" },
})
E("PALADIN", "Protection", {
    stat = "Item level, then Haste, Crit, Versatility, Mastery (simulate for pure damage)",
    gems = { "Indecipherable Eversong Diamond", "Flawless Deadly Peridot" }, gemNote = "1 diamond; Deadly Peridot for the rest",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" }, ring = { "Silvermoon's Alacrity" }, weapon = { "Acuity of the Ren'dorei" },
})
E("PALADIN", "Retribution", {
    stat = "Strength > Mastery > Haste > Crit > Versatility (simulate to confirm)",
    gems = { "Indecipherable Eversong Diamond", "Flawless Quick Amethyst", "Flawless Masterful Peridot" }, gemNote = "1 diamond; Quick Amethyst or Masterful Peridot, depending on gear",
    head = { "Empowered Rune of Avoidance", "Empowered Blessing of Speed" }, shoulder = { "Amirdrassil's Grace", "Akil'zon's Swiftness" },
    chest = { "Mark of the Worldsoul", "Mark of Nalorakk" }, legs = { "Forest Hunter's Armor Kit", "Blood Knight's Armor Kit" },
    feet = { "Lynx's Dexterity", "Farstrider's Hunt" }, ring = { "Eyes of the Eagle", "Zul'jin's Mastery" }, weapon = { "Rite of the Hash'ey", "Arcane Mastery" },
})
E("PRIEST", "Discipline", {
    stat = "Item level > Haste > Mastery > Crit > Versatility (Voidweaver: Haste up to 1800, Oracle: up to about 1300)",
    gems = { "Telluric Eversong Diamond", "Flawless Deadly Peridot", "Flawless Masterful Peridot", "Flawless Quick Amethyst", "Flawless Quick Garnet" },
    gemNote = "Telluric diamond; Deadly or Masterful Peridot, Quick Amethyst or Quick Garnet, following your stat weights",
    head = { "Hex of Leeching", "Rune of Avoidance" }, shoulder = { "Silvermoon's Mending", "Amirdrassil's Grace" },
    chest = { "Mark of the Worldsoul", "Mark of the Magister" }, legs = { "Arcanoweave Spellthread" },
    feet = { "Lynx's Dexterity", "Shaladrassil's Roots" }, ring = { "Silvermoon's Alacrity" }, weapon = { "Acuity of the Ren'dorei" },
})
E("PRIEST", "Shadow", {
    stat = "Broad: item level > Haste >= Mastery > Crit > Versatility (Voidweaver and Archon have different targets, see the guide)",
    gems = { "Indecipherable Eversong Diamond", "Flawless Masterful Peridot", "Flawless Deadly Amethyst", "Flawless Quick Garnet" },
    gemNote = "1 diamond; Masterful Peridot, Deadly Amethyst and Quick Garnet by stat weights",
    head = { "Empowered Blessing of Speed" }, shoulder = { "Akil'zon's Swiftness" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Farstrider's Hunt" }, ring = { "Eyes of the Eagle" }, weapon = { "Berserker's Rage", "Arcane Mastery" },
})
E("ROGUE", "Assassination", {
    stat = "Crit > Haste > Mastery >> Versatility",
    gems = { "Indecipherable Eversong Diamond" }, gemNote = "1 diamond; Haste or Crit gems for the rest",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" }, ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})
E("ROGUE", "Outlaw", {
    stat = "Agility > Haste > Crit > Versatility > Mastery (Haste target about 25%)",
    gems = { "Indecipherable Eversong Diamond", "Powerful Eversong Diamond", "Flawless Quick Garnet", "Flawless Deadly Peridot" }, gemNote = "Indecipherable diamond first; Quick Garnet and Deadly Peridot by gear",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei" },
})
E("ROGUE", "Subtlety", {
    stat = "Trickster: Agility > Mastery > Haste (to 700) > Crit > Versatility.  Deathstalker: Agility > Haste (to 1050) > Mastery > Crit > Versatility",
    gems = { "Indecipherable Eversong Diamond", "Flawless Quick Amethyst" }, gemNote = "1 diamond; Quick Amethyst for the rest",
    head = { "Empowered Rune of Avoidance" }, shoulder = {}, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei", "Arcane Mastery" },
})

E("SHAMAN", "Elemental", {
    stat = "Farseer: Mastery > Haste >= Crit > Versatility.  Stormbringer: Mastery > Crit > Haste > Versatility",
    gems = { "Powerful Eversong Diamond", "Flawless Deadly Amethyst", "Flawless Masterful Garnet", "Flawless Deadly Lapis", "Flawless Deadly Peridot" },
    gemNote = "1 Powerful diamond; 1 Deadly Amethyst, 1 Masterful Garnet, 1 Deadly Lapis, the rest Deadly Peridot",
    head = { "Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})
E("SHAMAN", "Enhancement", {
    stat = "Agility > Mastery >= Haste > Crit >= Versatility",
    gems = { "Indecipherable Eversong Diamond", "Powerful Eversong Diamond", "Flawless Quick Amethyst", "Flawless Masterful Peridot", "Flawless Masterful Garnet", "Flawless Masterful Lapis" },
    gemNote = "Indecipherable diamond with Quick Amethyst or Masterful Peridot, or Powerful diamond with at least one each of Quick Amethyst, Masterful Peridot, Masterful Garnet, Masterful Lapis",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Shaladrassil's Roots" }, ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})
E("SHAMAN", "Restoration", {
    stat = "Raid: Intellect > Crit > Versatility = Haste > Mastery.  M+: Intellect > Crit = Versatility = Haste > Mastery",
    gems = { "Telluric Eversong Diamond", "Flawless Versatile Garnet", "Flawless Deadly Lapis", "Flawless Deadly Peridot" },
    gemNote = "1 Telluric diamond; at least one each of Versatile Garnet, Deadly Lapis, Deadly Peridot",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Arcanoweave Spellthread" }, feet = { "Shaladrassil's Roots" }, ring = { "Nature's Fury" }, weapon = { "Jan'alai's Precision" },
})
E("WARLOCK", "Affliction", {
    stat = "Single target: Crit > Haste = Mastery > Versatility.  AoE: Haste = Crit > Mastery > Versatility",
    gems = { "Powerful Eversong Diamond", "Flawless Masterful Garnet", "Flawless Deadly Amethyst", "Flawless Deadly Lapis", "Flawless Deadly Peridot" },
    gemNote = "1 Powerful diamond; 1 each of Masterful Garnet, Deadly Amethyst, Deadly Lapis, Deadly Peridot",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Amirdrassil's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Nature's Wrath" }, weapon = { "Acuity of the Ren'dorei" },
})
E("WARLOCK", "Demonology", {
    stat = "Intellect >>> Crit > Haste / Mastery > Versatility",
    gems = { "Powerful Eversong Diamond" }, gemNote = "Powerful diamond first, then 4 Crit gems of different colors",
    head = { "Empowered Rune of Avoidance" }, shoulder = {}, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Jan'alai's Precision", "Rite of the Hash'ey" },
})
E("WARLOCK", "Destruction", {
    stat = "Haste > Crit = Mastery >> Versatility",
    gems = { "Powerful Eversong Diamond", "Flawless Deadly Peridot" }, gemNote = "Powerful diamond, then Deadly Peridot with Quick gems of other colors; Deadly Peridot in the remaining sockets",
    head = { "Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Sunfire Silk Spellthread" }, feet = { "Shaladrassil's Roots" }, ring = { "Eyes of the Eagle" }, weapon = { "Acuity of the Ren'dorei" },
})
E("WARRIOR", "Arms", {
    stat = "Crit > Haste > Mastery > Versatility",
    gems = { "Indecipherable Eversong Diamond", "Flawless Deadly Peridot" }, gemNote = "1 diamond; Deadly Peridot for the rest",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Nature's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Blood Knight's Armor Kit" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})
E("WARRIOR", "Fury", {
    stat = "Mastery > Haste > Crit = Versatility",
    gems = { "Indecipherable Eversong Diamond", "Flawless Masterful Peridot" }, gemNote = "1 diamond; Masterful Peridot for the rest",
    head = { "Empowered Rune of Avoidance" }, shoulder = { "Nature's Grace" }, chest = { "Mark of the Worldsoul" },
    legs = { "Blood Knight's Armor Kit" }, feet = { "Lynx's Dexterity" }, ring = { "Eyes of the Eagle" }, weapon = { "Arcane Mastery", "Berserker's Rage" },
    weaponNote = "Arcane Mastery on the main hand, Berserker's Rage on the off hand",
})
E("WARRIOR", "Protection", {
    stat = "Item level first, then Strength >> Haste > Crit = Versatility > Mastery",
    gems = { "Indecipherable Eversong Diamond", "Powerful Eversong Diamond", "Flawless Deadly Peridot", "Flawless Quick Lapis", "Flawless Quick Amethyst", "Flawless Quick Garnet" },
    gemNote = "Indecipherable diamond, or Powerful diamond with one each of Deadly Peridot, Quick Lapis, Quick Amethyst, Quick Garnet",
    head = { "Empowered Hex of Leeching" }, shoulder = { "Silvermoon's Mending" }, chest = { "Mark of the Worldsoul" },
    legs = { "Forest Hunter's Armor Kit" }, feet = { "Farstrider's Hunt" }, ring = { "Silvermoon's Alacrity", "Eyes of the Eagle" }, weapon = { "Rite of the Hash'ey" },
})

-- the enchantable slots of Midnight Season 1 and the inventory slot numbers they use
-- (cloak and bracer enchants were removed; legs take a Tailoring spellthread or a Leatherworking armor kit)
SFP.EnchantSlots = {
    { key = "head",     label = "Head",      slot = 1 },
    { key = "shoulder", label = "Shoulders", slot = 3 },
    { key = "chest",    label = "Chest",     slot = 5 },
    { key = "legs",     label = "Legs",      slot = 7 },
    { key = "feet",     label = "Boots",     slot = 8 },
    { key = "ring",     label = "Ring 1",    slot = 11 },
    { key = "ring",     label = "Ring 2",    slot = 12 },
    { key = "weapon",   label = "Main hand", slot = 16 },
}

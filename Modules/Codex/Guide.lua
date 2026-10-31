-- Seviath's Codex — hand-written new-player guide articles
-- Written for this addon (CC BY-NC 3.0). Kept evergreen on purpose: numbers
-- and names that change every season live in the live journals, not here.

local ADDON, ns = SFP_Module("Codex")
local C = "|cff33e6ff"   -- cyan headings
local R = "|r"

ns.GUIDE = {
------------------------------------------------------------------------
-- Start here
------------------------------------------------------------------------
{ id = "codex", group = "1. Start Here", title = "How to use the Codex", icon = "INV_Misc_Book_09",
  tags = "help search waypoint",
  body = [[
Type anything in the search box at the top — a boss, a dungeon, an item, a mount, a pet, an achievement, a title — and the Codex searches every section at once. Click a section on the left to browse it by expansion or type.

]]..C.."Buttons on a page"..R..[[

• Show on map — puts an arrow on your map and minimap (uses TomTom if you have it).
• Adventure Guide / Collections — opens the matching Blizzard window.
• Wowhead link — a link you can copy (Ctrl+C) for full comments and guides.

]]..C.."Where the data comes from"..R..[[

Dungeons, raids, bosses, abilities, loot, entrances, mounts, pets, achievements, transmog sets and quests are read straight from your game client, so they are always correct for the current patch. The first time you log in it takes a minute or two to read most of it in the background.

Quests are the big one: the Codex asks the server about every quest once (about 30–60 minutes of background reading the first time, it pauses in combat and continues next login). After that they load instantly. Each quest page shows only what to do — the objectives — not the story text. The bar at the bottom shows progress.

Slash commands: /codex, /codex <search>, /codex minimap, /codex reindex]] },

{ id = "first-steps", group = "1. Start Here", title = "Your first hours: what to do", icon = "Achievement_Quests_Completed_01",
  tags = "new player leveling start beginner",
  body = [[
1. Finish your starting area and the introduction quests — they teach movement, combat and your class.
2. Pick a ]]..C.."specialization"..R..[[ (Talents window, N) — it decides your role: tank, healer or damage.
3. Level by questing, running dungeons (the Group Finder queues you automatically) or both.
4. Talk to ]]..C.."Chromie"..R..[[ in Stormwind or Orgrimmar to choose which older expansion you level in (Chromie Time). Pick the one whose story or look you like most — they all level you equally.
5. At max level the current expansion opens up: world quests, delves, dungeons, raids, professions and renown.

Tip: set your Hearthstone at an inn in a city you visit often. It's your free teleport home.]] },

{ id = "roles", group = "1. Start Here", title = "Classes, specs and roles", icon = "ClassIcon_Warrior",
  tags = "tank healer dps damage class spec talents",
  body = [[
Every class has 2–4 specializations. Each spec has one role:

]]..C.."Tank"..R..[[ — holds the enemies' attention and takes the hits. Leads the pace in dungeons.
]]..C.."Healer"..R..[[ — keeps the group alive.
]]..C.."Damage (DPS)"..R..[[ — kills things, avoids standing in bad stuff.

You can change spec any time out of combat for free. Talents are saved per spec as loadouts, and you can import builds people share as text strings (Talents window » Import).

Damage roles have the longest queue in the Group Finder; tanks and healers get in fastest.]] },

{ id = "gear", group = "1. Start Here", title = "Gear, item level and upgrades", icon = "INV_Chest_Plate16",
  tags = "ilvl item level gear upgrade crest stats",
  body = [[
]]..C.."Item level (ilvl)"..R..[[ is the main number that says how strong a piece is. Your average ilvl shows in the character window (C).

Where gear comes from, from easiest to hardest: world quests and leveling » normal/heroic dungeons and delves » Mythic+ and raids.

Most current-season gear can be ]]..C.."upgraded"..R..[[ at an upgrade vendor in the expansion hub using the season's upgrade currencies. The tooltip shows the upgrade track (for example 2/6).

Stats: your main stat (Strength, Agility or Intellect) matters most; secondary stats (Crit, Haste, Mastery, Versatility) depend on your spec — check a class guide for priorities.]] },

{ id = "warband", group = "1. Start Here", title = "Warband: what's shared between your characters", icon = "Achievement_Character_Human_Female",
  tags = "warband account alt bank warbound reputation",
  body = [[
Your ]]..C.."Warband"..R..[[ is every character on your account. Shared across it:

• Mounts, pets, toys, transmog appearances and most achievements.
• The Warband bank tab at any banker — put items there to move them to alts.
• Many reputations and renown (marked as Warband on the reputation panel).
• Items marked ]]..C.."Warbound"..R..[[ (or "Warbound until equipped") can be sent to your own alts but not traded.

Alts level faster thanks to account-wide progress and heirlooms (see the Heirloom tab in Collections).]] },

{ id = "keys", group = "1. Start Here", title = "Keys and windows you will use every day", icon = "INV_Misc_Note_02",
  tags = "keybind shortcut hotkey window map bags talents character quest log group finder collections",
  body = [[
Default keys (you can change them in Options » Keybindings):

]]..C.."M"..R..[[ — world map          ]]..C.."B"..R..[[ — all bags          ]]..C.."C"..R..[[ — character and gear
]]..C.."N"..R..[[ — talents            ]]..C.."P"..R..[[ — spellbook         ]]..C.."L"..R..[[ — quest log
]]..C.."I"..R..[[ — Group Finder       ]]..C.."Y"..R..[[ — achievements       ]]..C.."O"..R..[[ — social and friends
]]..C.."Shift+P"..R..[[ — collections (mounts, pets, toys, transmog)       ]]..C.."Shift+J"..R..[[ — Adventure Guide

Useful habits:
• Right-click a quest giver's quest in the tracker to see it on the map; Shift+click a quest in the log to track it.
• Click the small bag-sort button at the top of your bags to tidy them, and use "Sell all junk" at any vendor (the coin button that appears there).
• Use /reload if the interface acts strange; it is safe and fast.]] },

{ id = "newbie-tips", group = "1. Start Here", title = "Tips nobody tells new players", icon = "INV_Misc_Bag_10",
  tags = "tips beginner new player rested xp repair auto loot flight points durability hearthstone",
  body = [[
• ]]..C.."Rested experience"..R..[[: log out in an inn or a city and you earn bonus experience while away. Your next kills give extra XP (the bar turns blue).
• ]]..C.."Repair"..R..[[: gear loses durability when you die. A vendor with an anvil icon repairs it for a small price. Don't let it reach zero.
• ]]..C.."Auto Loot"..R..[[: turn it on in Options » Controls so a corpse empties into your bags with one click (hold Shift to loot manually).
• ]]..C.."Flight points"..R..[[: talk to a flight master in each new zone to learn the point; later you can fly there from any other one.
• ]]..C.."Bags are limited"..R..[[: buy or craft bigger bags early, and put things you do not need now in the Warband bank.
• ]]..C.."Not a rush"..R..[[: you do not have to follow a "best" order. Leveling, dungeons, pets, mounts and professions all count as progress.
• Read the tooltip of every new ability and item; it tells you what it does and how much it costs.
• Ask in the guild or in a dungeon "first time here, any tips?" — most players are glad to help.]] },

{ id = "loot-rules", group = "1. Start Here", title = "Loot rules and group manners", icon = "INV_Misc_Bag_09",
  tags = "need greed pass loot roll group etiquette dungeon queue leave",
  body = [[
When a dungeon or raid drops an item, everyone who can use it gets a roll window:

]]..C.."Need"..R..[[ — only if the item is an upgrade for the spec you are playing (or you will use it as a main item).
]]..C.."Greed"..R..[[ — you would sell or disenchant it, or use it as a spare.
]]..C.."Transmog"..R..[[ — you only want the look (shown when you do not have the appearance yet).
]]..C.."Pass"..R..[[ — you do not want it.

Manners that keep groups friendly:
• Do not Need on gear for another spec or for selling, unless the group agreed.
• Say "hi" and "ready" in chat; tell the group if you are new — they will explain the bosses.
• Do not leave right after a wipe; one more try is often enough.
• Tanks lead the pace: in a dungeon follow the tank unless told otherwise.

Loot you won can be traded to a group member within 2 hours if it is not an upgrade for you.]] },

{ id = "combat-basics", group = "1. Start Here", title = "Combat basics and staying alive", icon = "Ability_Warrior_Rampage",
  tags = "combat interrupt kick defensive cooldown red circle avoid aoe death resurrect corpse spirit healer",
  body = [[
• ]]..C.."Stay out of the red"..R..[[: red circles, cones and lines on the ground are damage coming. Step out of them; this alone is most of what keeps players alive in dungeons.
• ]]..C.."Interrupt"..R..[[ (kick): most classes have a short interrupt. Use it on enemy casts that show a shield or a dangerous cast bar.
• ]]..C.."Defensive abilities"..R..[[: every class has a few. Use one when your health is dropping, not at one percent.
• ]]..C.."Health potions and food"..R..[[: eat or drink out of combat to heal; potions work in combat.
• Kill the small adds first if your group says so; focus the marked target in a group.

If you die:
• Click ]]..C.."Release Spirit"..R..[[ and run back to your body as a ghost; when you stand on your corpse press Resurrect. Or accept a resurrect from a healer.
• The ]]..C.."Spirit Healer"..R..[[ revives you right away at a small durability cost if the run back is too far.
• In dungeons and raids you can often be resurrected by a combat resurrection; wait for the group's call.]] },

{ id = "lingo", group = "1. Start Here", title = "Chat lingo and abbreviations", icon = "INV_Letter_15",
  tags = "lfg lfm dps tank healer aoe cc cd boe bop lfr wq mount farm alt rp glossary",
  body = [[
]]..C.."LFG / LFM"..R..[[ — looking for group / looking for more.     ]]..C.."DPS"..R..[[ — damage dealer.
]]..C.."M+ / key"..R..[[ — Mythic+ dungeon and its keystone.             ]]..C.."LFR"..R..[[ — Raid Finder (easiest raid).
]]..C.."AoE"..R..[[ — damage to many enemies at once.                          ]]..C.."CC"..R..[[ — crowd control (stun, sleep, root...).
]]..C.."CD"..R..[[ — cooldown, an ability you can use again later.      ]]..C.."BoE / BoP"..R..[[ — bind on equip / bind on pickup.
]]..C.."WQ"..R..[[ — world quest.                                                                ]]..C.."Alt"..R..[[ — another of your characters.
]]..C.."Farm"..R..[[ — kill or gather the same thing over and over for loot.   ]]..C.."RNG"..R..[[ — random luck.
]]..C.."BRB / AFK"..R..[[ — be right back / away from keyboard.
]]..C.."Pug"..R..[[ — a group of strangers from the Group Finder.         ]]..C.."GG"..R..[[ — good game, said after a run.

Typing /who <name> or checking the Group Finder entry tells you about a player; use the player tags in this addon's Groups page for your own notes on people.]] },

{ id = "tools", group = "1. Start Here", title = "What Seviath's Useful Tools does and where", icon = "INV_Misc_Map_01",
  tags = "addon seviath useful tools menu minimap farm map decor delve planner auction alt overview what where",
  body = [[
Open the menu with the minimap button or ]]..C.."/sut"..R..[[. The left list is the whole addon:

• ]]..C.."Farm & Map, Farm Route, Farm Session"..R..[[ — farm spots on the world map, a route through them, and a timer with gold gained.
• ]]..C.."Rare Alerts, Killed Today, What To Farm Next"..R..[[ — rares that still drop a mount, pet or toy you miss; best first.
• ]]..C.."My Collections, Housing Decor"..R..[[ — plan the mounts and decor you want; the lists show owned and missing.
• ]]..C.."Delve Planner, Delve Keys"..R..[[ — best companion setup per spec and per delve.
• ]]..C.."Zone Check"..R..[[ — what you still miss in the zone you stand in, with a waypoint button per rare.
• ]]..C.."Weekly Checklist, Alt Overview"..R..[[ — what is left this week and a list of all your characters, bags, bank and gold.
• ]]..C.."BoE Deals, Shopping List"..R..[[ — auction prices; scan the auction house once to fill them.
• ]]..C.."Guides (Codex)"..R..[[ — this guide book.

All saved data is shared by all your characters. The addon is new and still being tested: if something looks wrong, tell the author.]] },

------------------------------------------------------------------------
-- Group content
------------------------------------------------------------------------
{ id = "dungeons", group = "2. Dungeons, Raids & Delves", title = "Dungeons and their difficulties", icon = "INV_Misc_Key_14",
  tags = "dungeon normal heroic mythic group finder",
  body = [[
A dungeon is a 5-player instance: 1 tank, 1 healer, 3 damage.

]]..C.."Normal"..R..[[ — leveling and fresh max-level characters. Queue with the Group Finder (I).
]]..C.."Heroic"..R..[[ — harder, better loot, still queueable.
]]..C.."Mythic"..R..[[ — no queue: form a group yourself (Premade Groups) and walk in.
]]..C.."Mythic+"..R..[[ — Mythic with a timer and a keystone (see "Mythic+ keystones").

Don't have a group? ]]..C.."Follower Dungeons"..R..[[ let you run selected dungeons with NPC companions.

Find any dungeon's entrance in the Entrances section of this Codex, and each boss's abilities and loot under Bosses.]] },

{ id = "mplus", group = "2. Dungeons, Raids & Delves", title = "Mythic+ keystones", icon = "INV_Relics_Hourglass",
  tags = "mythic plus m+ keystone key affix timer rating",
  body = [[
After your first Mythic dungeon each week you get a ]]..C.."keystone"..R..[[ in your bags. Put it in the font at the dungeon's start and the run begins with a timer.

• Beat the timer » the key upgrades (+1 to +3 levels) and you get better rewards.
• Run out of time » you still get loot, but the key goes down a level.
• Higher keys add ]]..C.."affixes"..R..[[ — extra rules that make the run harder.

Your best runs give you a Mythic+ rating (visible in the Group Finder) and fill the Dungeon row of your Great Vault. Only the dungeons in the current season's rotation can be keystone dungeons — in this Codex they're tagged "current season".]] },

{ id = "raids", group = "2. Dungeons, Raids & Delves", title = "Raids and difficulties", icon = "Achievement_Boss_Ragnaros",
  tags = "raid lfr normal heroic mythic lockout",
  body = [[
Raids are big instances for 10–30 players (Mythic is exactly 20).

]]..C.."Raid Finder (LFR)"..R..[[ — queue and go, easiest, split into wings.
]]..C.."Normal / Heroic"..R..[[ — 10–30 players, group with Premade Groups or a guild.
]]..C.."Mythic"..R..[[ — 20 players, the hardest content in the game.

Each difficulty has a weekly ]]..C.."lockout"..R..[[: each boss gives loot once per week per difficulty. The reset is weekly (Wednesday in Europe, Tuesday in the Americas).]] },

{ id = "delves", group = "2. Dungeons, Raids & Delves", title = "Delves (solo-friendly)", icon = "INV_Misc_Lantern_01",
  tags = "delve solo companion tier bountiful key",
  body = [[
Delves are short adventures for 1–5 players with an NPC companion who heals or fights with you. They have tiers — higher tiers are harder and give better loot.

• Entrances show on the world map as delve icons.
• ]]..C.."Bountiful"..R..[[ delves (marked on the map) give an extra chest if you bring the season's delve key.
• Delves count for the World row of the Great Vault.

Great for players who prefer to play alone or at their own pace.]] },

{ id = "vault", group = "2. Dungeons, Raids & Delves", title = "The Great Vault (weekly reward)", icon = "INV_Misc_Treasurechest02b",
  tags = "great vault weekly chest reward",
  body = [[
Every week you fill up to 9 slots in the ]]..C.."Great Vault"..R..[[ (in the expansion hub):

• Raid row — by bosses killed.
• Dungeon row — by Mythic / Mythic+ dungeons completed.
• World row — by delves and other world activities.

After the weekly reset you open it and choose ONE item from the unlocked slots. Better runs = better choices. Even a few runs a week is worth it.]] },

{ id = "timewalking", group = "2. Dungeons, Raids & Delves", title = "Timewalking", icon = "Spell_Holy_BorrowedTime",
  tags = "timewalking old dungeon scaled event badges",
  body = [[
During Timewalking weeks (see the calendar) you can queue for old-expansion dungeons scaled to your level. Rewards include Timewarped Badges, which buy old-expansion mounts, pets, toys and transmog from Timewalking vendors.

Timewalking also counts for some weekly quests and can give current-level gear.]] },

{ id = "legacy", group = "2. Dungeons, Raids & Delves", title = "Soloing old raids for mounts & transmog", icon = "Achievement_Boss_LichKing",
  tags = "legacy solo old raid mount transmog farm lockout",
  body = [[
At max level you can solo most raids from older expansions. They use ]]..C.."Legacy Loot"..R..[[: bosses drop loot just for you, so you get everything.

Easy classic mount farms (weekly lockouts):
• ]]..C.."Invincible"..R..[[ — The Lich King, Icecrown Citadel (25 Heroic).
• ]]..C.."Ashes of Al'ar"..R..[[ — Kael'thas, Tempest Keep (The Eye).
• ]]..C.."Mimiron's Head"..R..[[ — Yogg-Saron with no keepers helping, Ulduar.
• ]]..C.."Fiery Warhorse"..R..[[ — Attumen the Huntsman, Karazhan.
• ]]..C.."Blue Proto-Drake"..R..[[ — Skadi the Ruthless, Utgarde Pinnacle (Heroic).
• ]]..C.."Swift White Hawkstrider"..R..[[ — Kael'thas, Magisters' Terrace (Heroic).
• ]]..C.."Rivendare's Deathcharger"..R..[[ — Lord Aurius Rivendare, Stratholme.

Search any of these names in the Codex to see the boss, the instance and the entrance with a map arrow. Drop rates are low — farm a few every week.]] },

{ id = "groupfinder", group = "2. Dungeons, Raids & Delves", title = "Finding a group", icon = "INV_Misc_GroupNeedMore",
  tags = "group finder premade lfg guild",
  body = [[
]]..C.."Group Finder"..R..[[ (I) has two parts:

• Dungeon Finder / Raid Finder — automatic queue for Normal/Heroic dungeons and LFR.
• Premade Groups — player-made listings for everything else: Mythic+, raids, delves, quests, PvP, custom.

Tips: write your goal in the listing ("learning", "fast run", "for achievement"), check the leader's rating, and be honest if it's your first time — many groups are happy to explain.

]]..C.."Seviath's Dungeons & Raids"..R..[[ (sister addon) makes Premade Groups faster to use, and ]]..C.."Seviath's Guild Helper"..R..[[ helps find and invite guild members.]] },

------------------------------------------------------------------------
-- The world
------------------------------------------------------------------------
{ id = "travel", group = "3. World & Travel", title = "Getting around: hearth, portals, flying", icon = "Spell_Arcane_PortalStormwind",
  tags = "travel portal room hearthstone flying flight path taxi",
  body = [[
]]..C.."Hearthstone"..R..[[ — teleports you to the inn you bound it to. Many toys work as extra hearthstones.
]]..C.."Flight masters"..R..[[ — talk to them to fly between discovered points.
]]..C.."Portal rooms"..R..[[ — Stormwind (Mage Quarter area) and Orgrimmar have rooms full of portals to every expansion's hub. This is the fastest way to old content.
]]..C.."Skyriding"..R..[[ — fast dynamic flying with charges you spend to boost. You can switch a mount to Steady Flight for classic flying.

Each Entrances page in this Codex includes how to reach that continent.]] },

{ id = "oldworld", group = "3. World & Travel", title = "Famous old places and how to enter", icon = "INV_Misc_Map_01",
  tags = "entrance old raid caverns of time blackrock karazhan black temple icecrown",
  body = [[
Some places new players often can't find:

• ]]..C.."Blackrock Mountain"..R..[[ — between Searing Gorge and Burning Steppes. Inside: Blackrock Depths, Blackwing Lair, Molten Core and more.
• ]]..C.."Caverns of Time"..R..[[ — Tanaris (Kalimdor). Many dungeons and raids from history.
• ]]..C.."Karazhan"..R..[[ — Deadwind Pass (Eastern Kingdoms).
• ]]..C.."Black Temple"..R..[[ — Shadowmoon Valley (Outland).
• ]]..C.."Icecrown Citadel"..R..[[ — Icecrown (Northrend).
• ]]..C.."Ulduar"..R..[[ — The Storm Peaks (Northrend).

Open the ]]..C.."Entrances"..R..[[ section and press Show on map — every dungeon and raid entrance the game knows is listed with exact coordinates.]] },

{ id = "quests", group = "3. World & Travel", title = "How quests work", icon = "INV_Misc_Note_01",
  tags = "quest daily weekly world campaign elite group objectives",
  body = [[
]]..C.."Yellow !"..R..[[ — a quest you can pick up. ]]..C.."Blue !"..R..[[ — a repeatable one (daily/weekly). ]]..C.."?"..R..[[ — ready to hand in.

Quest types you'll see:
• Normal — do the objectives once, hand in, done.
• Daily / Weekly — repeatable after the daily or weekly reset.
• World quests — appear on the map with a timer, no pick-up needed; just go there.
• Campaign — the expansion's main chain; often unlocks features (flying, renown, zones).
• Elite / Group — tougher enemies; bring a friend or a group.
• Dungeon / Raid — objectives inside an instance.

Your quest log (L) holds a limited number of quests; abandon old ones you don't need. Use the map (M) — objective areas are highlighted and the tracker on the right shows progress.

The Quests section lists every quest with only its objectives (what to do), its type, expansion and whether this character has done it.]] },

{ id = "worldquests", group = "3. World & Travel", title = "World quests, renown and reputation", icon = "Achievement_Reputation_01",
  tags = "world quest renown reputation faction rewards",
  body = [[
]]..C.."World quests"..R..[[ — short repeatable quests on the map with a timer and a reward icon. Do the ones whose rewards you need.
]]..C.."Renown"..R..[[ — each current-expansion faction has renown levels. Raising them unlocks mounts, transmog, pets, recipes, and sometimes gameplay features.
]]..C.."Reputation"..R..[[ — older factions use classic levels (Friendly » Exalted). Some sell mounts and recipes at Exalted.

Track progress in the reputation panel (Character window » Reputation).]] },

{ id = "rares", group = "3. World & Travel", title = "Rares and treasures", icon = "Achievement_Boss_Archaedas",
  tags = "rare elite treasure skull silver dragon",
  body = [[
]]..C.."Rares"..R..[[ are special enemies with a silver dragon around their portrait. They respawn on timers and can drop mounts, pets, toys and transmog. Many show as skull icons on the map when up.

]]..C.."Treasures"..R..[[ are chests hidden around zones, often with achievements for finding them all.

Every rare that shows up on your minimap is saved to the Bosses section (Rares groups) with its exact spot, for all your characters.]] },

{ id = "housing", group = "3. World & Travel", title = "Player housing", icon = "INV_Misc_Rune_01",
  tags = "housing house decor neighborhood plot",
  body = [[
Midnight added ]]..C.."player housing"..R..[[: you get a house in a neighborhood and decorate it with décor items.

Décor comes from quests, vendors, achievements, professions and drops — many old achievements now also reward décor. Your house is shared by your Warband.

Use the Codex search with "decor" to find achievements that mention décor rewards.]] },

------------------------------------------------------------------------
-- Collections
------------------------------------------------------------------------
{ id = "mounts", group = "4. Collections", title = "Getting mounts", icon = "Ability_Mount_RidingHorse",
  tags = "mount collect riding drop vendor reputation",
  body = [[
Mounts come from: drops (bosses, rares), vendors (gold or currencies), reputation/renown, achievements, quests, professions, events, the Trading Post and the shop.

The ]]..C.."Mounts"..R..[[ section here lists every mount in the game grouped by how you get it, with the exact source text from the game (boss, zone, cost). Uncollected ones are shown dimmed.

Search a boss name to see if it drops a mount, or search "drop" + a zone name.]] },

{ id = "pets", group = "4. Collections", title = "Battle pets and pet battles", icon = "INV_Box_PetCarrier_01",
  tags = "pet battle wild family strong weak trainer",
  body = [[
Talk to a Battle Pet Trainer in any city to unlock pet battles. Then click wild pets (paw icons in zones) to fight and capture them.

]]..C.."Family strengths"..R..[[ (attacker deals extra damage to):
Humanoid » Dragonkin · Dragonkin » Magic · Magic » Flying · Flying » Aquatic · Aquatic » Elemental · Elemental » Mechanical · Mechanical » Beast · Beast » Critter · Critter » Undead · Undead » Humanoid

Rarity: Poor < Common < Uncommon < Rare. Stones from pet battles upgrade rarity.

The Battle Pets section lists every obtainable species grouped by family, with where to find it.]] },

{ id = "transmog", group = "4. Collections", title = "Transmog (appearances)", icon = "INV_Chest_Cloth_17",
  tags = "transmog appearance wardrobe outfit look",
  body = [[
When you loot or equip gear you can wear, its appearance is added to your ]]..C.."Wardrobe"..R..[[ (Collections » Appearances) for your whole Warband.

Change your look at a Transmogrifier NPC in any major city — it costs a little gold. Save full looks as outfits.

Farm old raids (see "Soloing old raids") to collect armor sets. The Transmog Sets section here lists every set by expansion, with which pieces you already have.]] },

{ id = "achievements", group = "4. Collections", title = "Achievements and titles", icon = "Achievement_Quests_Completed_08",
  tags = "achievement title points reward",
  body = [[
Achievements (Y) track goals: exploration, quests, dungeons, raids, PvP, collections and more. Many give rewards: ]]..C.."titles"..R..[[, mounts, pets, toys, décor.

Search "title" in the Codex to find achievements that reward a title, or "reward" to see everything that gives something. Each achievement page shows your criteria progress.]] },

------------------------------------------------------------------------
-- Professions
------------------------------------------------------------------------
{ id = "professions", group = "5. Professions", title = "Professions: the basics", icon = "Trade_BlackSmithing",
  tags = "profession gathering crafting trainer cooking fishing",
  body = [[
You can learn ]]..C.."two primary professions"..R..[[ plus the secondary ones (Cooking, Fishing, Archaeology).

]]..C.."Gathering"..R..[[: Herbalism, Mining, Skinning — collect materials from nodes and corpses. Easy gold and good for beginners.
]]..C.."Crafting"..R..[[: Alchemy, Blacksmithing, Enchanting, Engineering, Inscription, Jewelcrafting, Leatherworking, Tailoring — turn materials into gear, potions and more.

Each expansion has its own skill line (e.g. "Classic Mining", current-expansion Mining). Learn from a trainer in the expansion hub. A classic pair: one gathering + one crafting that uses it (Mining + Blacksmithing, Herbalism + Alchemy, Skinning + Leatherworking).]] },

{ id = "prof-modern", group = "5. Professions", title = "Knowledge, specializations and quality", icon = "INV_Misc_Book_10",
  tags = "knowledge points specialization quality rank concentration crafting order",
  body = [[
Current-expansion professions have:

• ]]..C.."Knowledge points"..R..[[ — earned from weekly quests, treatises, first crafts and hidden treasures. Spend them in the profession's specialization trees.
• ]]..C.."Quality ranks"..R..[[ on materials and crafts — higher-rank reagents give higher-quality results.
• ]]..C.."Crafting orders"..R..[[ — other players (and NPCs) send you orders to craft with their materials, and you earn a commission.

Pick one specialization and stay focused — spreading points too thin is a common beginner mistake.]] },

{ id = "mats", group = "5. Professions", title = "Finding materials (mats & reagents)", icon = "INV_Misc_Herb_Felblossom",
  tags = "mats reagents materials farm cloth leather ore herb",
  body = [[
• ]]..C.."Herbs and ore"..R..[[ — nodes in the open world (track them from the minimap's tracking menu).
• ]]..C.."Leather"..R..[[ — skin beasts after killing them (Skinning).
• ]]..C.."Cloth"..R..[[ — drops from humanoid enemies; no profession needed.
• ]]..C.."Enchanting dust"..R..[[ — disenchant green-or-better gear.
• ]]..C.."Meat and fish"..R..[[ — beasts and fishing pools, for Cooking.

The ]]..C.."Gold Farming"..R..[[ section lists the best places to make gold right now, with live auction prices if you use Auctionator. For open-world farm spots on the map, use ]]..C.."Seviath's Farm Pack"..R..[[.]] },

------------------------------------------------------------------------
-- Economy
------------------------------------------------------------------------
{ id = "auction", group = "6. Gold & Trading", title = "The Auction House", icon = "INV_Misc_Coin_02",
  tags = "auction house ah sell buy commodity deposit gold",
  body = [[
Auction Houses are in every capital. Two kinds of listings:

• ]]..C.."Commodities"..R..[[ (mats, potions): one shared price list — you buy the cheapest first.
• ]]..C.."Items"..R..[[ (gear, mounts, pets): individual listings.

Selling costs a small deposit (returned if it sells) and the house takes a 5% cut. Check prices before listing, and don't undercut by a lot — you only lose gold.]] },

{ id = "binding", group = "6. Gold & Trading", title = "Soulbound, BoE and Warbound", icon = "INV_Misc_Key_03",
  tags = "soulbound boe bind on equip warbound trade",
  body = [[
]]..C.."Soulbound"..R..[[ — yours forever; can't be traded.
]]..C.."Binds when equipped (BoE)"..R..[[ — tradeable and sellable until someone wears it. Often worth gold!
]]..C.."Warbound"..R..[[ — can move between your own characters via the Warband bank, not to other players.
]]..C.."Warbound until equipped"..R..[[ — like BoE but only within your Warband.

Group loot you got in a dungeon or raid can be traded to group members for 2 hours if it isn't an upgrade for you.]] },

{ id = "gold", group = "6. Gold & Trading", title = "Simple ways to make gold", icon = "INV_Misc_Coin_01",
  tags = "gold money farm sell",
  body = [[
• Gather: herbs, ore, leather and cloth always sell.
• Sell BoE gear and recipes from old raids on the Auction House.
• Do world quests with gold rewards.
• Crafting orders if you have a crafting profession.
• Old content farming — Seviath's Farm Pack shows the best open-world spots per expansion with auction values.

Never buy gold from outside the game — it gets accounts banned.]] },
}

-- Register the articles as Codex entries
function ns:LoadGuide()
    for i, a in ipairs(self.GUIDE) do
        self:Add({
            cat = "guide", id = a.id, name = a.title, group = a.group,
            icon = "Interface\\Icons\\" .. (a.icon or "INV_Misc_Book_09"),
            sub = a.tags, tags = a.tags, body = a.body, order = i,
        })
    end
end

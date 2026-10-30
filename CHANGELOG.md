# Changelog

## 2.0.0-retail
- New retail edition of SeviathsUsefulTools: Farm Pack + Codex (with Delves) + Dungeons & Raids + Guild Helper in one addon,
  plus the newer features of the classic edition (auction sold / mailbox / vendor messages, crafting and farming profit,
  worth-grinding comparison by creature type, learning of monsters, drops, nodes and recipes, main menu).
- Not carried over because retail does it natively: Questie-style quest marks, the MoP quest database, the MoP materials/mounts data.
- Warns once at login if one of the four old separate addons is still enabled.
- Farm spots learned with the old SeviathsFarmPack (11 maps) are copied in once (Data/Seed.lua).
- Auction prices: one full scan of the whole auction house (like Auctionator) instead of one search per item; falls back to per-item search if the game gives no answer.
- Item tooltips (bags, auction house, links): 'Where to get' (boss drops, vendors you visited, learned drops/nodes) and 'How to use' (recipes, consumables, gems, mounts, pets, toys, bags, gear) lines.
- The addon now learns where you got every item (looted in a zone, quest reward) and shows those zones on item tooltips; saved in the learned data.

- Fixed the "Worth grinding" verdict missing on monsters without a known auction price (the price fallback used a game function retail removed). An error in that verdict can no longer cut off the rest of the monster tooltip.

- Auction prices are now kept per realm (connected realms share one list) on top of the account-wide "newest price" list, so a scan on one character no longer overwrites what another realm showed, and every character sees the prices the others saved. Auctionator prices are saved too. The "prices are old" check is per realm.

- Midnight ores and herbs now have real node data (Wowhead spawn data, all node variants combined): best zone, glowing spots, node counts per zone and node object IDs for Refulgent Copper, Umbral Tin, Brilliant Silver, Tranquility Bloom, Sanguithorn, Azeroot, Argentleaf and Mana Lily; Dazzling Thorium and Nocturnal Lotus are listed as rare bonus drops.

- Midnight farm monsters: added 38 monsters with real spawn points and Wowhead drop rates (hawkstriders, lynx, wyrms, mournbats, consumptors, pangos, hawks, Twilight cloth mobs ...) in Eversong Woods, Zul'Aman, Harandar, Voidstorm, Isle of Quel'Danas, Slayer's Rise, Atal'Aman and The Coiled Isle, so their tooltips and map spots work.

- Minimap farm spots no longer need HereBeDragons (Questie, RareScanner ...): without it the addon places them itself, following the minimap zoom and rotation.

- Farm spot list on the left of every zone map: all farm monsters, rares, hunter tames, special materials, ore and herb spots of the zone, each with its own checkbox (untick = hidden on the map and the minimap), Show all / Hide all, scroll with the mouse wheel, click a name for a waypoint, [-]/[+] to fold it. Switch the list off in the menu ("Farm spot list").

- Prices: when the auction house is not scanned the addon now takes prices from Auctionator or TradeSkillMaster (TSM: DBMinBuyout, then DBMarket); they are saved per realm like scanned prices.

- War Within farm monsters: 22 more with real spawn points and Wowhead drop rates (Ringing Deeps, Hallowfall, Isle of Dorn, Azj-Kahet, Undermine, K'aresh).
- 84 rare-drop mounts, pets and toys added to the item data (they now show their kind and icon on tooltips and the map).

- Midnight enchanting materials (Eversinging Dust, Radiant Shard, Dawn Crystal, both qualities) are now known to the item data and the Midnight "any zone" list.

- Raid BoE gear (trash / lieutenant drops) with Wowhead-checked item IDs: Midnight Voidspire / March on Quel'Danas, The Venomous Abyss, Nerub-ar Palace, Liberation of Undermine and Manaforge Omega (new raid entry in K'aresh); they show as BoE on tooltips and on the raid entrances.
- 81 Classic / Outland recipe drops (patterns, plans, formulas, schematics, designs) with checked IDs, new "Recipe" item kind.

- Dragonflight raid BoE gear: 9 items each from Vault of the Incarnates and Amirdrassil (IDs from Wowhead's raid loot guides, checked on the item pages). Wowhead has no BoE list for Aberrus yet.

- Midnight recipe drops: 38 patterns, plans, formulas and designs (Windrunner Spire, Magisters' Terrace, The Voidspire, The Dreamrift, Murder Row, Delve chests ...) plus the Amirdrassil recipe satchel, with Wowhead-checked item IDs and where they drop.

- Fixed a Lua error when hovering a world quest reward on the map (the item tooltip hook asked comparison tooltips for their item); tooltip hooks can no longer throw.

- Nerub-ar Palace recipe drops: Plans: Siphoning Stiletto, Pattern: Duskthread Lining, Recipe: Sticky Sweet Treat, Formula: Enchant Weapon - Authority of the Depths (Wowhead-checked IDs).

- Three more War Within recipe drops: Pattern: Adrenal Surge Clasp (Sikran), Plans: Sanctified Steps, Recipe: Feast of the Divine Day.

- 14 Dragonflight raid recipe drops (Vault of the Incarnates / Aberrus patterns, plans, schematics, designs, formulas) with Wowhead-checked IDs and where they drop.

- Aberrus recipe drops (6) and three Dragonflight world recipe drops (Zaralek Cavern and Emerald Dream enchanting crest formulas), IDs checked on Wowhead.

- Recipe tooltips now say where they really drop: the Zaralek Cavern and Emerald Dream crest formulas (rares, elites, chests, Small Somnuts) and Feast of the Divine Day (Radiant Cache).

- 20 Outland rares (Hellfire, Zangarmarsh, Nagrand, Terokkar, Blade's Edge, Netherstorm, Shadowmoon) with NPC IDs and spawn points; Topaz Skyfang added to the Coiled Isle rare drops; Satchel of Pilfered Recipes (Aberrus) added.

- 21 more Northrend rares (Frostbitten / Northern Exposure) and 21 Thaldraszus rares with NPC IDs and spawn points from Wowhead.

- NPC IDs filled in for 159 rares (Siren Isle, Isle of Dorn, Ringing Deeps, Hallowfall, Azj-Kahet, Undermine, Eversong, Voidstorm, Harandar, Zul'Aman, Coiled Isle ...); checked against Wowhead spawn maps. Blightpaw the Depraved added on the Ohn'ahran Plains.

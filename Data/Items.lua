-- SeviathsUsefulTools - item data
-- Every item ID here was checked against Wowhead's item data (name + quality).
-- Grey/poor items are left out on purpose. Names and icons come from the game
-- client at runtime, so they show in your own language.
-- drop  = drop chance for BoE items, from Wowhead's drop data / comments (approximate)
-- tiers = Dragonflight crafting-quality versions (all scanned on the AH)

local _, SFP = ...

SFP.Items = {
    ---------------------------------------------------------------- Classic
    [4306]  = { kind = "cloth" },                 -- Silk Cloth
    [4338]  = { kind = "cloth" },                 -- Mageweave Cloth
    [14047] = { kind = "cloth" },                 -- Runecloth
    [14256] = { kind = "cloth" },                 -- Felcloth
    [4304]  = { kind = "leather" },               -- Thick Leather
    [8170]  = { kind = "leather" },               -- Rugged Leather
    [15417] = { kind = "leather" },               -- Devilsaur Leather
    [17012] = { kind = "leather" },               -- Core Leather
    [15408] = { kind = "leather" },               -- Heavy Scorpid Scale
    [15416] = { kind = "leather" },               -- Black Dragonscale
    [15412] = { kind = "leather" },               -- Green Dragonscale
    [15415] = { kind = "leather" },               -- Blue Dragonscale
    [8165]  = { kind = "leather" },               -- Worn Dragonscale
    [7078]  = { kind = "element" },               -- Essence of Fire
    [7080]  = { kind = "element" },               -- Essence of Water
    [7076]  = { kind = "element" },               -- Essence of Earth
    [7082]  = { kind = "element" },               -- Essence of Air
    [12808] = { kind = "element" },               -- Essence of Undeath
    [12803] = { kind = "element" },               -- Living Essence
    [7068]  = { kind = "element" },               -- Elemental Fire
    [7067]  = { kind = "element" },               -- Elemental Earth
    [7077]  = { kind = "element" },               -- Heart of Fire
    [12811] = { kind = "element" },               -- Righteous Orb
    [17010] = { kind = "element" },               -- Fiery Core
    [17011] = { kind = "element" },               -- Lava Core
    [12207] = { kind = "meat" },                  -- Giant Egg
    [12208] = { kind = "meat" },                  -- Tender Wolf Meat
    [8494]  = { kind = "pet", drop = "~0.012%", note = "Bloodsail pirates / STV mobs" }, -- Parrot Cage (Hyacinth Macaw)
    [10822] = { kind = "pet", drop = "~0.1%",   note = "whelps" },                       -- Dark Whelpling
    [8499]  = { kind = "pet", drop = "~0.01%",  note = "any Wetlands mob" },              -- Tiny Crimson Whelpling
    [8498]  = { kind = "pet", drop = "~0.1%",   note = "whelps" },                       -- Emerald Whelpling
    [34535] = { kind = "pet", drop = "~0.01-0.04%", note = "Winterspring mobs" },        -- Azure Whelpling
    [20769] = { kind = "pet", drop = "~0.1%",   note = "oozes (Oozing Bag)" },           -- Disgusting Oozeling

    ---------------------------------------------------------------- The Burning Crusade
    [21877] = { kind = "cloth" },                 -- Netherweave Cloth
    [21887] = { kind = "leather" },               -- Knothide Leather
    [25700] = { kind = "leather" },               -- Fel Scales
    [29548] = { kind = "leather" },               -- Nether Dragonscales
    [29539] = { kind = "leather" },               -- Cobra Scales
    [29547] = { kind = "leather" },               -- Wind Scales
    [25708] = { kind = "leather" },               -- Thick Clefthoof Leather
    [21884] = { kind = "element" },               -- Primal Fire
    [21885] = { kind = "element" },               -- Primal Water
    [22451] = { kind = "element" },               -- Primal Air
    [22452] = { kind = "element" },               -- Primal Earth
    [21886] = { kind = "element" },               -- Primal Life
    [22457] = { kind = "element" },               -- Primal Mana
    [22456] = { kind = "element" },               -- Primal Shadow
    [22574] = { kind = "element" },               -- Mote of Fire
    [22578] = { kind = "element" },               -- Mote of Water
    [22572] = { kind = "element" },               -- Mote of Air
    [22573] = { kind = "element" },               -- Mote of Earth
    [22575] = { kind = "element" },               -- Mote of Life
    [22576] = { kind = "element" },               -- Mote of Mana
    [22577] = { kind = "element" },               -- Mote of Shadow
    [27678] = { kind = "meat" },                  -- Clefthoof Meat

    ---------------------------------------------------------------- Wrath of the Lich King
    [33470] = { kind = "cloth" },                 -- Frostweave Cloth
    [33568] = { kind = "leather" },               -- Borean Leather
    [44128] = { kind = "leather", note = "rare skinning find" }, -- Arctic Fur
    [38557] = { kind = "leather" },               -- Icy Dragonscale
    [38558] = { kind = "leather" },               -- Nerubian Chitin
    [38561] = { kind = "leather" },               -- Jormungar Scale
    [37702] = { kind = "element" },               -- Crystallized Fire
    [37705] = { kind = "element" },               -- Crystallized Water
    [37700] = { kind = "element" },               -- Crystallized Air
    [37701] = { kind = "element" },               -- Crystallized Earth
    [37704] = { kind = "element" },               -- Crystallized Life
    [37703] = { kind = "element" },               -- Crystallized Shadow
    [43013] = { kind = "meat" },                  -- Chilled Meat
    [43009] = { kind = "meat" },                  -- Shoveltusk Flank

    ---------------------------------------------------------------- Cataclysm
    [53010] = { kind = "cloth" },                 -- Embersilk Cloth
    [52976] = { kind = "leather" },               -- Savage Leather
    [52979] = { kind = "leather" },               -- Blackened Dragonscale
    [52982] = { kind = "leather" },               -- Deepsea Scale
    [52325] = { kind = "element" },               -- Volatile Fire
    [52326] = { kind = "element" },               -- Volatile Water
    [52327] = { kind = "element" },               -- Volatile Earth
    [52328] = { kind = "element" },               -- Volatile Air
    [52329] = { kind = "element" },               -- Volatile Life

    ---------------------------------------------------------------- Mists of Pandaria
    [72988] = { kind = "cloth" },                 -- Windwool Cloth
    [72120] = { kind = "leather" },               -- Mist-Touched Leather
    [79101] = { kind = "leather" },               -- Prismatic Scale
    [72163] = { kind = "leather", note = "rare skinning find" }, -- Magnificent Hide
    [74833] = { kind = "meat" },                  -- Raw Tiger Steak
    [74837] = { kind = "meat" },                  -- Raw Turtle Meat
    [74838] = { kind = "meat" },                  -- Raw Crab Meat
    [74839] = { kind = "meat" },                  -- Wildfowl Breast
    [75014] = { kind = "meat" },                  -- Raw Crocolisk Belly
    [74834] = { kind = "meat" },                  -- Mushan Ribs

    ---------------------------------------------------------------- Warlords of Draenor
    [111557] = { kind = "cloth" },                -- Sumptuous Fur
    [110609] = { kind = "leather" },              -- Raw Beast Hide
    [109131] = { kind = "meat" },                 -- Raw Clefthoof Meat
    [109132] = { kind = "meat" },                 -- Raw Talbuk Meat
    [109133] = { kind = "meat" },                 -- Rylak Egg
    [109134] = { kind = "meat" },                 -- Raw Elekk Meat
    [109135] = { kind = "meat" },                 -- Raw Riverbeast Meat
    [109136] = { kind = "meat" },                 -- Raw Boar Meat

    ---------------------------------------------------------------- Legion
    [124437] = { kind = "cloth" },                -- Shal'dorei Silk
    [151567] = { kind = "cloth" },                -- Lightweave Cloth
    [124113] = { kind = "leather" },              -- Stonehide Leather
    [124115] = { kind = "leather" },              -- Stormscale
    [124116] = { kind = "leather" },              -- Felhide
    [151566] = { kind = "leather" },              -- Fiendish Leather
    [124117] = { kind = "meat" },                 -- Lean Shank
    [124118] = { kind = "meat" },                 -- Fatty Bearsteak
    [124119] = { kind = "meat" },                 -- Big Gamy Ribs
    [124120] = { kind = "meat" },                 -- Leyblood
    [124121] = { kind = "meat" },                 -- Wildfowl Egg

    ---------------------------------------------------------------- Battle for Azeroth
    [152576] = { kind = "cloth" },                -- Tidespray Linen
    [152577] = { kind = "cloth" },                -- Deep Sea Satin
    [167738] = { kind = "cloth" },                -- Gilded Seaweave
    [152541] = { kind = "leather" },              -- Coarse Leather
    [154722] = { kind = "leather" },              -- Tempest Hide
    [154164] = { kind = "leather" },              -- Blood-Stained Bone
    [154165] = { kind = "leather" },              -- Calcified Bone
    [153050] = { kind = "leather" },              -- Shimmerscale
    [153051] = { kind = "leather" },              -- Mistscale
    [168649] = { kind = "leather" },              -- Dredged Leather
    [168650] = { kind = "leather" },              -- Cragscale
    [154898] = { kind = "meat" },                 -- Meaty Haunch
    [154897] = { kind = "meat" },                 -- Stringy Loins
    [154899] = { kind = "meat" },                 -- Thick Paleo Steak

    ---------------------------------------------------------------- Shadowlands
    [173202] = { kind = "cloth" },                -- Shrouded Cloth
    [173204] = { kind = "cloth" },                -- Lightless Silk
    [172089] = { kind = "leather" },              -- Desolate Leather
    [172092] = { kind = "leather" },              -- Pallid Bone
    [172094] = { kind = "leather" },              -- Callous Hide
    [172096] = { kind = "leather" },              -- Heavy Desolate Leather
    [172097] = { kind = "leather", note = "rare skinning find" }, -- Heavy Callous Hide
    [172052] = { kind = "meat" },                 -- Aethereal Meat
    [172053] = { kind = "meat" },                 -- Tenebrous Ribs
    [172054] = { kind = "meat" },                 -- Raw Seraphic Wing
    [179314] = { kind = "meat" },                 -- Creeping Crawler Meat
    [179315] = { kind = "meat" },                 -- Shadowy Shank

    ---------------------------------------------------------------- Dragonflight
    [193050] = { kind = "cloth" },                -- Tattered Wildercloth
    [193922] = { kind = "cloth" },                -- Wildercloth
    [193923] = { kind = "cloth" },                -- Decayed Wildercloth
    [193924] = { kind = "cloth" },                -- Frostbitten Wildercloth
    [193925] = { kind = "cloth" },                -- Singed Wildercloth
    [193208] = { kind = "leather", tiers = { 193210, 193211 } }, -- Resilient Leather (Q1-Q3)
    [193213] = { kind = "leather", tiers = { 193214, 193215 } }, -- Adamant Scales (Q1-Q3)
    [193216] = { kind = "leather", tiers = { 193217, 193218 }, note = "rare skinning find" }, -- Dense Hide
    [193222] = { kind = "leather", tiers = { 193223, 193224 }, note = "rare skinning find" }, -- Lustrous Scaled Hide
    [193226] = { kind = "leather", tiers = { 193227, 193228 }, note = "rare skinning find" }, -- Stonecrust Hide
    [193229] = { kind = "leather", tiers = { 193230, 193231 }, note = "rare skinning find" }, -- Mireslush Hide
    [193232] = { kind = "leather", note = "rare skinning find" }, -- Deathchill Hide
    [190315] = { kind = "element" },              -- Rousing Earth
    [190320] = { kind = "element" },              -- Rousing Fire
    [190322] = { kind = "element" },              -- Rousing Order
    [190326] = { kind = "element" },              -- Rousing Air
    [190328] = { kind = "element" },              -- Rousing Frost
    [190330] = { kind = "element" },              -- Rousing Decay
    [197741] = { kind = "meat" },                 -- Maybe Meat
    [197742] = { kind = "meat" },                 -- Ribbed Mollusk Meat
    [197743] = { kind = "meat" },                 -- Waterfowl Filet
    [197744] = { kind = "meat" },                 -- Hornswog Hunk
    [197745] = { kind = "meat" },                 -- Basilisk Eggs
    [197746] = { kind = "meat" },                 -- Bruffalon Flank
    [197747] = { kind = "meat" },                 -- Mighty Mammoth Ribs
    [197748] = { kind = "meat" },                 -- Burly Bear Haunch
    ---------------------------------------------------------------- The War Within
    [224828] = { kind = "cloth" },                                       -- Weavercloth
    [228233] = { kind = "cloth" },                                       -- Duskweave
    [212664] = { kind = "leather", tiers = { 212665, 212666 } },         -- Stormcharged Leather (Q1-Q3)
    [212667] = { kind = "leather", tiers = { 212668, 212669 } },         -- Gloom Chitin (Q1-Q3)
    [212670] = { kind = "leather", tiers = { 212672 }, note = "rare skinning find" },          -- Thunderous Hide
    [212674] = { kind = "leather", tiers = { 212675, 212676 }, note = "rare skinning find" },  -- Sunless Carapace

    ---------------------------------------------------------------- Midnight
    [236963] = { kind = "cloth" },                                       -- Bright Linen
    [237016] = { kind = "cloth", note = "needs Tailoring knowledge" },   -- Sunfire Silk
    [237017] = { kind = "cloth", note = "needs Tailoring knowledge" },   -- Arcanoweave
    [238511] = { kind = "leather", tiers = { 238512 } },                 -- Void-Tempered Leather
    [238513] = { kind = "leather", tiers = { 238514 } },                 -- Void-Tempered Scales
    [238518] = { kind = "leather", tiers = { 238519 }, note = "rare mobs / lures" },           -- Void-Tempered Hide
    [238520] = { kind = "leather", tiers = { 238521 }, note = "rare scale mobs / lures" },     -- Void-Tempered Plating
    [238525] = { kind = "leather", note = "furred beasts" },             -- Fantastic Fur
    [238522] = { kind = "leather", note = "feathered beasts" },          -- Peerless Plumage
    [238523] = { kind = "leather", note = "fanged beasts" },             -- Carving Canine
    [238528] = { kind = "leather", note = "Renowned Beasts (lures)" },   -- Majestic Claw
    [238529] = { kind = "leather", note = "Renowned Beasts (lures)" },   -- Majestic Hide
    [238530] = { kind = "leather", note = "Renowned Beasts (lures)" },   -- Majestic Fin

    ---------------------------------------------------------------- BoE gear & recipes (checked on Wowhead: binds when equipped / tradeable)
    -- drop chances are community estimates from Wowhead comments - treat them as rough
    [16252]  = { kind = "boe", drop = "~0.8%",        note = "Scarlet Archmage, Tyr's Hand" },          -- Formula: Enchant Weapon - Crusader
    [1982]   = { kind = "boe", drop = "very rare",    note = "world drop, Classic mobs" },               -- Nightblade
    [812]    = { kind = "boe", drop = "~0.02%",       note = "world drop, Sunken Temple / Blasted Lands" }, -- Glowing Brightwood Staff
    [1168]   = { kind = "boe", drop = "very rare",    note = "world drop, Classic mobs" },               -- Skullflame Shield
    [1728]   = { kind = "boe", drop = "very rare",    note = "level 31-33 elites" },                     -- Teebu's Blazing Longsword
    [31331]  = { kind = "boe", drop = "~0.07%",       note = "Outland mobs, Karazhan ghosts" },          -- The Night Blade
    [36479]  = { kind = "boe", drop = "<1%",          note = "Northrend mobs, Dragonblight" },           -- Snobold Ripper
    [118785] = { kind = "boe", drop = "rare",         note = "Draenor mobs" },                           -- Void Bound Knife
    [158180] = { kind = "boe", drop = "~0.01-0.1%",   note = "Flowing Honey / Bubbling Mead" },          -- The Glazer
    [190735] = { kind = "boe", drop = "~0.01-0.18%",  note = "Mawsworn in Zereth Mortis" },              -- Varruth's Guillotine
    ---------------------------------------------------------------- Rare drops (mounts, pets, toys)
    -- Drop chances are not published for these; they are listed so tooltips, prices and the worth-grinding lines know them.
    [44168]   = { kind = "mount", note = "rare mount drop" }, -- Reins of the Time-Lost Proto-Drake
    [63042]   = { kind = "mount", note = "rare mount drop" }, -- Reins of the Phosphorescent Stone Drake
    [67151]   = { kind = "mount", note = "rare mount drop" }, -- Reins of Poseidus
    [94229]   = { kind = "mount", note = "rare mount drop" }, -- Reins of the Slate Primordial Direhorn
    [94230]   = { kind = "mount", note = "rare mount drop" }, -- Reins of the Amber Primordial Direhorn
    [94231]   = { kind = "mount", note = "rare mount drop" }, -- Reins of the Jade Primordial Direhorn
    [104269]  = { kind = "mount", note = "rare mount drop" }, -- Reins of the Thundering Onyx Cloud Serpent
    [116658]  = { kind = "mount", note = "rare mount drop" }, -- Tundra Icehoof
    [116669]  = { kind = "mount", note = "rare mount drop" }, -- Armored Razorback
    [116780]  = { kind = "mount", note = "rare mount drop" }, -- Warsong Direfang
    [116794]  = { kind = "mount", note = "rare mount drop" }, -- Garn Nighthowl
    [142233]  = { kind = "mount", note = "rare mount drop" }, -- Shadowy Reins of the Accursed Wrathsteed
    [152790]  = { kind = "mount", note = "rare mount drop" }, -- Vile Fiend
    [152814]  = { kind = "mount", note = "rare mount drop" }, -- Maddened Chaosrunner
    [152840]  = { kind = "mount", note = "rare mount drop" }, -- Scintillating Mana Ray
    [152841]  = { kind = "mount", note = "rare mount drop" }, -- Felglow Mana Ray
    [152842]  = { kind = "mount", note = "rare mount drop" }, -- Vibrant Mana Ray
    [152843]  = { kind = "mount", note = "rare mount drop" }, -- Darkspore Mana Ray
    [152844]  = { kind = "mount", note = "rare mount drop" }, -- Lambent Mana Ray
    [152903]  = { kind = "mount", note = "rare mount drop" }, -- Biletooth Gnasher
    [152904]  = { kind = "mount", note = "rare mount drop" }, -- Acid Belcher
    [152905]  = { kind = "mount", note = "rare mount drop" }, -- Crimson Slavermaw
    [153054]  = { kind = "pet", note = "rare pet drop" }, -- Docile Skyfin
    [153055]  = { kind = "pet", note = "rare pet drop" }, -- Fel-Afflicted Skyfin
    [163578]  = { kind = "mount", note = "rare mount drop" }, -- Broken Highland Mustang
    [163579]  = { kind = "mount", note = "rare mount drop" }, -- Highland Mustang
    [163644]  = { kind = "mount", note = "rare mount drop" }, -- Swift Albino Raptor
    [163645]  = { kind = "mount", note = "rare mount drop" }, -- Skullripper
    [163646]  = { kind = "mount", note = "rare mount drop" }, -- Lil' Donkey
    [163706]  = { kind = "mount", note = "rare mount drop" }, -- Witherbark Direwing
    [166428]  = { kind = "mount", note = "rare mount drop" }, -- Blackpaw
    [166432]  = { kind = "mount", note = "rare mount drop" }, -- Ashenvale Chimaera
    [166434]  = { kind = "mount", note = "rare mount drop" }, -- Captured Umber Nightsaber
    [166435]  = { kind = "mount", note = "rare mount drop" }, -- Kaldorei Nightsaber
    [166437]  = { kind = "mount", note = "rare mount drop" }, -- Captured Kaldorei Nightsaber
    [166438]  = { kind = "mount", note = "rare mount drop" }, -- Caged Bear
    [166449]  = { kind = "pet", note = "rare pet drop" }, -- Darkshore Sentinel
    [166803]  = { kind = "mount", note = "rare mount drop" }, -- Umber Nightsaber
    [180461]  = { kind = "mount", note = "rare mount drop" }, -- Horrid Dredwing
    [180581]  = { kind = "mount", note = "rare mount drop" }, -- Hopecrusher Gargon
    [180582]  = { kind = "mount", note = "rare mount drop" }, -- Endmire Flyer Tether
    [180725]  = { kind = "mount", note = "rare mount drop" }, -- Spinemaw Gladechewer
    [180728]  = { kind = "mount", note = "rare mount drop" }, -- Swift Gloomhoof
    [180730]  = { kind = "mount", note = "rare mount drop" }, -- Wild Glimmerfur Prowler
    [180773]  = { kind = "mount", note = "rare mount drop" }, -- Sundancer
    [181815]  = { kind = "mount", note = "rare mount drop" }, -- Armored Bonehoof Tauralus
    [182075]  = { kind = "mount", note = "rare mount drop" }, -- Bonehoof Tauralus
    [182080]  = { kind = "mount", note = "rare mount drop" }, -- Predatory Plagueroc
    [182084]  = { kind = "mount", note = "rare mount drop" }, -- Gorespine
    [182085]  = { kind = "mount", note = "rare mount drop" }, -- Blisterback Bloodtusk
    [182589]  = { kind = "mount", note = "rare mount drop" }, -- Loyal Gorger
    [184062]  = { kind = "mount", note = "rare mount drop" }, -- Gnawed Reins of the Battle-Bound Warhound
    [186479]  = { kind = "mount", note = "rare mount drop" }, -- Mastercraft Gravewing
    [186483]  = { kind = "mount", note = "rare mount drop" }, -- Forsworn Aquilon
    [186489]  = { kind = "mount", note = "rare mount drop" }, -- Lord of the Corpseflies
    [186645]  = { kind = "mount", note = "rare mount drop" }, -- Crimson Shardhide
    [186652]  = { kind = "mount", note = "rare mount drop" }, -- Garnet Razorwing
    [186659]  = { kind = "mount", note = "rare mount drop" }, -- Fallen Charger's Reins
    [187176]  = { kind = "toy", note = "rare toy drop" }, -- Vesper of Harmony
    [187183]  = { kind = "mount", note = "rare mount drop" }, -- Rampaging Mauler
    [190765]  = { kind = "mount", note = "rare mount drop" }, -- Iska's Mawrat Leash
    [192772]  = { kind = "mount", note = "rare mount drop" }, -- Ancient Salamanther
    [193364]  = { kind = "pet", note = "rare pet drop" }, -- Scruffles
    [198825]  = { kind = "mount", note = "rare mount drop" }, -- Zenet Hatchling
    [200249]  = { kind = "toy", note = "rare toy drop" }, -- Mage's Chewed Wand
    [201440]  = { kind = "mount", note = "rare mount drop" }, -- Reins of the Liberated Slyvern
    [205147]  = { kind = "pet", note = "rare pet drop" }, -- Ridged Shalewing
    [205203]  = { kind = "mount", note = "rare mount drop" }, -- Cobalt Shalewing
    [223270]  = { kind = "mount", note = "rare mount drop" }, -- Alunira
    [223315]  = { kind = "mount", note = "rare mount drop" }, -- Beledar's Spawn
    [223501]  = { kind = "mount", note = "rare mount drop" }, -- Regurgitated Mole Reins
    [229955]  = { kind = "mount", note = "rare mount drop" }, -- Darkfuse Spy-Eye
    [246067]  = { kind = "mount", note = "rare mount drop" }, -- Pearlescent Krolusk
    [246159]  = { kind = "mount", note = "rare mount drop" }, -- Translocated Gorger
    [246160]  = { kind = "mount", note = "rare mount drop" }, -- Sthaarbs's Last Lunch
    [246735]  = { kind = "mount", note = "rare mount drop" }, -- Rootstalker Grimlynx
    [252012]  = { kind = "mount", note = "rare mount drop" }, -- Vibrant Petalwing
    [257085]  = { kind = "mount", note = "rare mount drop" }, -- Augmented Stormray
    [257147]  = { kind = "mount", note = "rare mount drop" }, -- Cobalt Dragonhawk
    [257152]  = { kind = "mount", note = "rare mount drop" }, -- Amani Sharptalon
    [257156]  = { kind = "mount", note = "rare mount drop" }, -- Cerulean Hawkstrider
    [257200]  = { kind = "mount", note = "rare mount drop" }, -- Escaped Witherbark Pango
    [260635]  = { kind = "mount", note = "rare mount drop" }, -- Sanguine Harrower
    [276803]  = { kind = "mount", note = "rare mount drop" }, -- Ruby Writhe
    ---------------------------------------------------------------- Raid BoE gear (trash / lieutenants)
    -- Item IDs checked on Wowhead item pages; names from Method / Wowhead news. Drop chances are not published.
    [260370]  = { kind = "boe", note = "Midnight S1: Voidspire / March on Quel'Danas lieutenants" }, -- Visage of Unseen Truths
    [260371]  = { kind = "boe", note = "Midnight S1: Voidspire / March on Quel'Danas lieutenants" }, -- Infernal Greatlock Girdle
    [260372]  = { kind = "boe", note = "Midnight S1: Voidspire / March on Quel'Danas lieutenants" }, -- Nullstrider's Boots
    [260373]  = { kind = "boe", note = "Midnight S1: Voidspire / March on Quel'Danas lieutenants" }, -- Power Stance Breeches
    [260374]  = { kind = "boe", note = "Midnight S1: Voidspire / March on Quel'Danas lieutenants" }, -- Primal Spark Pauldrons
    [260375]  = { kind = "boe", note = "Midnight S1: Voidspire / March on Quel'Danas lieutenants" }, -- Raging Storm Sash
    [260376]  = { kind = "boe", note = "Midnight S1: Voidspire / March on Quel'Danas lieutenants" }, -- Breastplate of the Final Defense
    [260377]  = { kind = "boe", note = "Midnight S1: Voidspire / March on Quel'Danas lieutenants" }, -- Fading Dawn Sabatons
    [271638]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Bound Serpent's Jade Eye
    [271445]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Fanged Brute's Greatbelt
    [271444]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Pauldrons of the Forgotten Sacrifice
    [271440]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Greaves of the Noxious Depths
    [271441]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Crushing Coiler Coif
    [271436]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Slitherscale Girdle
    [271438]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Temple Delver's Mystic Helm
    [271435]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Slippers of the Hissing Cult
    [271434]  = { kind = "boe", note = "The Venomous Abyss lieutenants" }, -- Venom Rite Mantle
    [225720]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Web Acolyte's Hood
    [225721]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Prime Slime Slippers
    [225722]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Adorned Lynxborne Pauldrons
    [225723]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Venom Stalker's Strap
    [225724]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Shrillwing Hunter's Prey
    [225725]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Lurking Marauder's Binding
    [225727]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Captured Earthen's Ironhorns
    [225728]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Acidic Attendant's Loop
    [225744]  = { kind = "boe", note = "Nerub-ar Palace trash / lieutenants" }, -- Heritage Militia's Stompers
    [232655]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Vatwork Janitor's Wasteband
    [232656]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Psychopath's Ravemantle
    [232657]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Mechgineer's Blowtorch Cover
    [232658]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Firebug's Anklegear
    [232659]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Loyalist's Holdout Hood
    [232660]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Midnight Lounge Cummerbund
    [232661]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Bootleg Wrynn Shoulderplates
    [232662]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Globlin-Fused Greatbelt
    [232663]  = { kind = "boe", note = "Liberation of Undermine trash" }, -- Undermine Merc's Dog Tags
    [238027]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Harvested Creephide Cord
    [238028]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Bone-Melted Faceplate
    [238030]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Voidhound Trainer's Boots
    [238031]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Veiled Manta Vest
    [238032]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Acolyte's Infused Leggings
    [238033]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Zadus's Liturgical Hat
    [238034]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Jak'tull's Intruder Stompers
    [238036]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Entropy
    [243048]  = { kind = "boe", note = "Manaforge Omega lieutenants" }, -- Technomancer's Service Sandals
    ---------------------------------------------------------------- Recipe drops (Classic / Outland world drops)
    -- IDs and names checked on Wowhead item pages. Drop chances are not published.
    [3734]    = { kind = "recipe", note = "Cooking recipe drop" }, -- Recipe: Big Bear Steak
    [4597]    = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Discolored Healing Potion
    [4624]    = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Lesser Stoneshield Potion
    [5489]    = { kind = "recipe", note = "Cooking recipe drop" }, -- Recipe: Lean Venison
    [6474]    = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Deviate Scale Cloak
    [6475]    = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Deviate Scale Gloves
    [6476]    = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Deviate Scale Belt
    [7290]    = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Red Whelp Gloves
    [9294]    = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Wildvine Potion
    [9296]    = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Gift of Arthas
    [9367]    = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Golden Scale Gauntlets
    [11205]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Gloves - Advanced Herbalism
    [12227]   = { kind = "recipe", note = "Cooking recipe drop" }, -- Recipe: Lean Wolf Steak
    [12821]   = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Dawn's Edge
    [12824]   = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Enchanted Battlehammer
    [12825]   = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Blazing Rapier
    [12834]   = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Arcanite Champion
    [12837]   = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Masterwork Stormhammer
    [13308]   = { kind = "recipe", note = "Engineering recipe drop" }, -- Schematic: Ice Deflector
    [13491]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Elixir of the Mongoose
    [13496]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Greater Nature Protection Potion
    [13497]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Greater Arcane Protection Potion
    [13499]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Greater Shadow Protection Potion
    [14492]   = { kind = "recipe", note = "Tailoring recipe drop" }, -- Pattern: Felcloth Boots
    [14496]   = { kind = "recipe", note = "Tailoring recipe drop" }, -- Pattern: Felcloth Hood
    [14514]   = { kind = "recipe", note = "Tailoring recipe drop" }, -- Pattern: Robe of the Void
    [15727]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Heavy Scorpid Vest
    [15728]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Wicked Leather Bracers
    [15729]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Chimeric Gloves
    [15731]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Runic Leather Gauntlets
    [15739]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Runic Leather Bracers
    [15744]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Wicked Leather Headband
    [15745]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Runic Leather Belt
    [15747]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Frostsaber Leggings
    [15751]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Blue Dragonscale Breastplate
    [15752]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Living Leggings
    [15753]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Stormshroud Armor
    [15756]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Runic Leather Headband
    [15757]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Wicked Leather Pants
    [15763]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Blue Dragonscale Shoulders
    [15768]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Wicked Leather Belt
    [15771]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Living Breastplate
    [15773]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Wicked Leather Armor
    [15776]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Runic Leather Armor
    [15777]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Runic Leather Shoulders
    [16247]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant 2H Weapon - Superior Impact
    [16254]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Weapon - Lifestealing
    [18414]   = { kind = "recipe", note = "Tailoring recipe drop" }, -- Pattern: Belt of the Archmage
    [18517]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Chromatic Cloak
    [18518]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Hide of the Wild
    [18519]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Shifting Cloak
    [18657]   = { kind = "recipe", note = "Engineering recipe drop" }, -- Schematic: Hyper-Radiant Flame Reflector
    [21025]   = { kind = "recipe", note = "Cooking recipe drop" }, -- Recipe: Dirge's Kickin' Chimaerok Chops
    [21548]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Stormshroud Gloves
    [22541]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Shield - Resistance
    [22542]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Boots - Vitality
    [22548]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Cloak - Major Resistance
    [22553]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Weapon - Potency
    [22557]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Weapon - Battlemaster
    [22558]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Weapon - Spellsurge
    [22903]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Insane Strength Potion
    [22904]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Elixir of the Searching Eye
    [22912]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Heroic Potion
    [22913]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Haste Potion
    [22914]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Destruction Potion
    [22919]   = { kind = "recipe", note = "Alchemy recipe drop" }, -- Recipe: Elixir of Major Mageblood
    [23154]   = { kind = "recipe", note = "Jewelcrafting recipe drop" }, -- Design: Stormy Azure Moonstone
    [23621]   = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Gauntlets of the Iron Tower
    [23804]   = { kind = "recipe", note = "Engineering recipe drop" }, -- Schematic: Power Amplification Goggles
    [23810]   = { kind = "recipe", note = "Engineering recipe drop" }, -- Schematic: Crashin' Thrashin' Robot
    [23883]   = { kind = "recipe", note = "Engineering recipe drop" }, -- Schematic: Healing Potion Injector
    [23884]   = { kind = "recipe", note = "Engineering recipe drop" }, -- Schematic: Mana Potion Injector
    [24163]   = { kind = "recipe", note = "Jewelcrafting recipe drop" }, -- Design: Heavy Felsteel Ring
    [25887]   = { kind = "recipe", note = "Engineering recipe drop" }, -- Schematic: Purple Smoke Flare
    [28270]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Chest - Major Resilience
    [28279]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Boots - Cat's Swiftness
    [28280]   = { kind = "recipe", note = "Enchanting recipe drop" }, -- Formula: Enchant Boots - Boar's Speed
    [29730]   = { kind = "recipe", note = "Leatherworking recipe drop" }, -- Pattern: Earthen Netherscale Boots
    [33186]   = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Adamantite Weapon Chain
    [33954]   = { kind = "recipe", note = "Blacksmithing recipe drop" }, -- Plans: Hammer of Righteous Might
    [35204]   = { kind = "recipe", note = "recipe drop" }, -- Pattern: Sunfire Handwraps
    -- Dragonflight raid BoE gear (IDs from Wowhead's raid loot guides, checked on the item pages)
    [202004]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Brawler's Earthen Cuirass
    [201992]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Emissary's Flamewrought Seal
    [202005]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Frozen Claw Mantle
    [202008]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Galvanic Gaiters
    [202006]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Greathelm of Horned Fury
    [202009]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Lavamancer's Ceremonial Waistguard
    [202003]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Primal Seeker's Leggings
    [202010]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Primalist Warden's Bracers
    [202007]  = { kind = "boe", note = "Vault of the Incarnates trash / lieutenants" }, -- Woven Stone Bracelets
    [208430]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Whispering Fanged Cord
    [208431]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Lost Scholar's Temporal Shoulderdials
    [208432]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Vengeful Bladebeak Girdle
    [208420]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Visage of the Devouring Flame
    [208428]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Mantle of Slumbering Sands
    [208434]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Sentinel's Gilded Poulaines
    [208427]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Insurgent Flame Warboots
    [208426]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Mask of the Unbidden Grim
    [208442]  = { kind = "boe", note = "Amirdrassil trash / lieutenants" }, -- Daydreamer's Glimmering Ring
    ---------------------------------------------------------------- Midnight recipe drops (wow-professions.com guides; item IDs from Wowhead's 'taught by' lists)
    [256625]  = { kind = "recipe", note = "Leatherworking recipe: Rak'tul, Maisara Caverns" }, -- Pattern: Hexwoven Strand
    [256640]  = { kind = "recipe", note = "Leatherworking recipe: Lithiel Cinderfury, Murder Row" }, -- Pattern: Row Walker's Insurance
    [256638]  = { kind = "recipe", note = "Leatherworking recipe: Heavy Trunk, Delves" }, -- Pattern: Row Walker's Swiftgrips
    [256637]  = { kind = "recipe", note = "Leatherworking recipe: Heavy Trunk, Delves" }, -- Pattern: Axe-Flingin' Bands
    [256653]  = { kind = "recipe", note = "Leatherworking recipe: Restless Heart, Windrunner Spire" }, -- Pattern: Ranger-General's Grips
    [256656]  = { kind = "recipe", note = "Leatherworking recipe: Chimaerus, The Dreamrift" }, -- Pattern: World Tender's Barkclasp
    [256650]  = { kind = "recipe", note = "Leatherworking recipe: Heavy Trunk, Delves" }, -- Pattern: World Tender's Rootslippers
    [256652]  = { kind = "recipe", note = "Leatherworking recipe: Ziekket, The Blinding Vale" }, -- Pattern: World Tender's Trunkplate
    [256642]  = { kind = "recipe", note = "Leatherworking recipe: Ziekket, The Blinding Vale" }, -- Pattern: Primal Spore Binding
    [259365]  = { kind = "recipe", note = "Leatherworking recipe: Heavy Trunk, Delves" }, -- Pattern: Plush Haranir Leather Pillow
    [258517]  = { kind = "recipe", note = "Blacksmithing recipe: General Amias Bellamy" }, -- Plans: Knight-Commander's Palisade
    [258487]  = { kind = "recipe", note = "Blacksmithing recipe: Lithiel Cinderfury, Murder Row" }, -- Plans: Murder Row Fleet Feet
    [258518]  = { kind = "recipe", note = "Blacksmithing recipe: Lithiel Cinderfury, Murder Row" }, -- Plans: Murder Row Fishhook
    [258521]  = { kind = "recipe", note = "Blacksmithing recipe: Vaelgor" }, -- Plans: Blood Knight's Impetus
    [258522]  = { kind = "recipe", note = "Blacksmithing recipe: Vorasius, The Voidspire" }, -- Plans: Bloomforged Greataxe
    [256759]  = { kind = "recipe", note = "Enchanting recipe: Degentrius, Magisters' Terrace" }, -- Formula: Enchant Weapon - Flames of the Sin'dorei
    [256750]  = { kind = "recipe", note = "Enchanting recipe: Chimaerus, The Dreamrift" }, -- Formula: Enchant Weapon - Worldsoul Cradle
    [256747]  = { kind = "recipe", note = "Enchanting recipe: Heavy Trunk, Delves" }, -- Formula: Enchant Boots - Shaladrassil's Roots
    [256755]  = { kind = "recipe", note = "Enchanting recipe: Degentrius, Magisters' Terrace" }, -- Formula: Enchant Chest - Mark of the Magister
    [256737]  = { kind = "recipe", note = "Enchanting recipe: Den of Nalorakk" }, -- Formula: Enchant Chest - Mark of Nalorakk
    [256753]  = { kind = "recipe", note = "Enchanting recipe: Heavy Trunk, Delves" }, -- Formula: Enchant Helm - Empowered Rune of Avoidance
    [256738]  = { kind = "recipe", note = "Enchanting recipe: Heavy Trunk, Delves" }, -- Formula: Enchant Helm - Empowered Hex of Leeching
    [256748]  = { kind = "recipe", note = "Enchanting recipe: Heavy Trunk, Delves" }, -- Formula: Enchant Shoulders - Amirdrassil's Grace
    [256740]  = { kind = "recipe", note = "Enchanting recipe: Heavy Trunk, Delves" }, -- Formula: Enchant Shoulders - Akil'zon's Swiftness
    [256752]  = { kind = "recipe", note = "Enchanting recipe: Heavy Trunk, Delves" }, -- Formula: Enchant Ring - Nature's Fury
    [256739]  = { kind = "recipe", note = "Enchanting recipe: Zul'Aman treasures" }, -- Formula: Enchant Ring - Eyes of the Eagle
    [256746]  = { kind = "recipe", note = "Enchanting recipe: Lithiel Cinderfury, Murder Row" }, -- Formula: Smuggler's Enchanted Edge
    [256714]  = { kind = "recipe", note = "Jewelcrafting recipe: Midnight dungeons" }, -- Design: Indecipherable Eversong Diamond
    [256704]  = { kind = "recipe", note = "Jewelcrafting recipe: Midnight dungeons" }, -- Design: Powerful Eversong Diamond
    [256720]  = { kind = "recipe", note = "Jewelcrafting recipe: Midnight dungeons" }, -- Design: Stoic Eversong Diamond
    [256708]  = { kind = "recipe", note = "Jewelcrafting recipe: Midnight dungeons" }, -- Design: Telluric Eversong Diamond
    [256715]  = { kind = "recipe", note = "Jewelcrafting recipe: Belo'ren, Isle of Quel'Danas" }, -- Design: Thalassian Phoenix Torque
    [256721]  = { kind = "recipe", note = "Jewelcrafting recipe: Charonus, Voidscar Arena" }, -- Design: Voidstone Shielding Array
    [256716]  = { kind = "recipe", note = "Jewelcrafting recipe: Lothraxion, Nexus-Point Xenas" }, -- Design: Prismatic Focusing Iris
    [256718]  = { kind = "recipe", note = "Jewelcrafting recipe: Heavy Trunk, Delves" }, -- Design: Stabilizing Gemstone Bandolier
    [258126]  = { kind = "recipe", note = "Tailoring recipe: Heavy Trunk, Delves" }, -- Pattern: Arcanoweave Cord
    [258125]  = { kind = "recipe", note = "Tailoring recipe: Restless Heart, Windrunner Spire" }, -- Pattern: Sunfire Sash
    [258123]  = { kind = "recipe", note = "Tailoring recipe: Fallen-King Salhadaar, The Voidspire" }, -- Pattern: Sunfire Silk Spellthread
    [210148]  = { kind = "recipe", note = "profession recipes, Amirdrassil raid" }, -- Overflowing Satchel of Pilfered Recipes
    -- Nerub-ar Palace recipe drops (names from Icy Veins / Warcraft Wiki, IDs from Wowhead)
    [223048]  = { kind = "recipe", note = "Blacksmithing recipe: Nexus-Princess Ky'veza, Nerub-ar Palace" }, -- Plans: Siphoning Stiletto
    [224435]  = { kind = "recipe", note = "Tailoring recipe: Rasha'nan, Nerub-ar Palace" }, -- Pattern: Duskthread Lining
    [226190]  = { kind = "recipe", note = "Cooking recipe: Broodtwister Ovi'nax, Nerub-ar Palace" }, -- Recipe: Sticky Sweet Treat
    [223144]  = { kind = "recipe", note = "Enchanting recipe: Queen Ansurek, Nerub-ar Palace" }, -- Formula: Enchant Weapon - Authority of the Depths
    -- More War Within recipe drops (IDs checked on Wowhead item pages)
    [223097]  = { kind = "recipe", note = "Leatherworking recipe: Sikran, Nerub-ar Palace" }, -- Pattern: Adrenal Surge Clasp
    [223043]  = { kind = "recipe", note = "Blacksmithing recipe: low chance from Arathi mobs in Hallowfall and Priory of the Sacred Flame, some Delves and surplus satchels" }, -- Plans: Sanctified Steps
    [227283]  = { kind = "recipe", note = "Cooking recipe: Radiant Cache (War Within weekly cache)" }, -- Recipe: Feast of the Divine Day
    -- Dragonflight raid recipe drops (IDs checked on Wowhead item pages)
    [191597]  = { kind = "recipe", note = "Alchemy recipe: Vault of the Incarnates bosses" }, -- Recipe: Potion Absorption Inhibitor
    [193881]  = { kind = "recipe", note = "Leatherworking recipe: Vault of the Incarnates bosses" }, -- Pattern: Scale Rein Grips
    [201740]  = { kind = "recipe", note = "Alchemy recipe: Broodkeeper Diurna, Vault of the Incarnates" }, -- Elemental Codex of Ultimate Power
    [194489]  = { kind = "recipe", note = "Blacksmithing recipe: Vault of the Incarnates / Aberrus bosses" }, -- Plans: Allied Chestplate of Generosity
    [194490]  = { kind = "recipe", note = "Blacksmithing recipe: Warlord Kagni (Aberrus), Igira (Amirdrassil), Vault bosses" }, -- Plans: Allied Wristguard of Companionship
    [199227]  = { kind = "recipe", note = "Engineering recipe: Vault of the Incarnates / Aberrus bosses" }, -- Schematic: Ol' Smoky
    [194642]  = { kind = "recipe", note = "Jewelcrafting recipe: Warlord Kagni, Aberrus" }, -- Design: Choker of Shielding
    [193873]  = { kind = "recipe", note = "Leatherworking recipe: Vault of the Incarnates bosses" }, -- Pattern: Old Spirit's Wristwraps
    [193872]  = { kind = "recipe", note = "Leatherworking recipe: Kurog Grimtotem, Vault of the Incarnates" }, -- Pattern: String of Spiritual Knick-Knacks
    [193880]  = { kind = "recipe", note = "Leatherworking recipe: Kurog Grimtotem, Vault of the Incarnates" }, -- Pattern: Wind Spirit's Lasso
    [194259]  = { kind = "recipe", note = "Tailoring recipe: Vault of the Incarnates bosses" }, -- Pattern: Allied Wristguards of Time Dilation
    [194260]  = { kind = "recipe", note = "Tailoring recipe: Vault of the Incarnates bosses" }, -- Pattern: Blue Dragon Soles
    [194266]  = { kind = "recipe", note = "Tailoring recipe: Vault of the Incarnates bosses" }, -- Pattern: Bronzed Grip Wrappings
    [204975]  = { kind = "recipe", note = "Enchanting recipe: Magmorax, Aberrus" }, -- Formula: Enchant Weapon - Shadowflame Wreathe
    -- Aberrus and Dragonflight world recipe drops (IDs checked on Wowhead item pages)
    [205145]  = { kind = "recipe", note = "Blacksmithing recipe: Kazzara, Aberrus" }, -- Plans: Shadowed Impact Buckler
    [205144]  = { kind = "recipe", note = "Blacksmithing recipe: Rashok, Aberrus" }, -- Plans: Shadowed Razing Annihilator
    [204696]  = { kind = "recipe", note = "Alchemy recipe: The Amalgamation Chamber, Aberrus" }, -- Recipe: Draconic Phial Cauldron
    [205140]  = { kind = "recipe", note = "Tailoring recipe: The Forgotten Experiments, Aberrus" }, -- Pattern: Undulating Sporecloak
    [205036]  = { kind = "recipe", note = "Engineering recipe: Zskarn, Aberrus" }, -- Schematic: Tinker: Shadowflame Rockets
    [204968]  = { kind = "recipe", note = "Leatherworking recipe: Echo of Neltharion, Aberrus" }, -- Pattern: Shadowflame-Tempered Armor Patch
    [205339]  = { kind = "recipe", drop = "~0.1-0.2%", note = "Enchanting recipe (BoP): Zaralek Cavern rares and elites (Elder Magma Serpent, Alcanon, Professor Gastrinax ...) and treasure chests" }, -- Formula: Enchanted Wyrm's Shadowflame Crest
    [205338]  = { kind = "recipe", drop = "~0.1-0.2%", note = "Enchanting recipe (BoP): Zaralek Cavern rares and elites (Alcanon, Elder Magma Serpent, General Zskorro ...) and treasure chests" }, -- Formula: Enchanted Whelpling's Shadowflame Crest
    [210172]  = { kind = "recipe", drop = "~0.1% (Small Somnut ~0.4%)", note = "Enchanting recipe: Emerald Dream rares and elites, Small Somnuts" }, -- Formula: Enchanted Wyrm's Dreaming Crest
    -- Aberrus satchel and Coiled Isle mount (IDs checked on Wowhead item pages)
    [205256]  = { kind = "recipe", note = "Aberrus: Warlord Kagni; teaches one random profession recipe" }, -- Satchel of Pilfered Recipes
    [276549]  = { kind = "mount", note = "Coiled Isle rare mount drop" }, -- Topaz Skyfang
}

-- Dungeon / raid mounts (Cataclysm to The War Within). Drop chances are the usual
-- community estimates (Wowhead comments / guides) - treat them as rough.
local function boss(id, drop, note) SFP.Items[id] = { kind = "mount", drop = drop, note = note } end
-- Classic / TBC / Wrath instance mounts
boss(21218,  "~1-2%", "trash, Temple of Ahn'Qiraj")                -- Blue Qiraji Resonating Crystal
boss(21323,  "~1-2%", "trash, Temple of Ahn'Qiraj")                -- Green Qiraji Resonating Crystal
boss(21324,  "~1-2%", "trash, Temple of Ahn'Qiraj")                -- Yellow Qiraji Resonating Crystal
boss(21321,  "<1%",   "trash, Temple of Ahn'Qiraj (rarest)")       -- Red Qiraji Resonating Crystal
boss(13335,  "~1%",   "Baron Rivendare, Stratholme")               -- Deathcharger's Reins
boss(49636,  "~1%",   "Onyxia, Onyxia's Lair")                     -- Reins of the Onyxian Drake
boss(30480,  "~1%",   "Attumen the Huntsman, Karazhan")            -- Fiery Warhorse's Reins
boss(32458,  "~1-2%", "Kael'thas Sunstrider, Tempest Keep")        -- Ashes of Al'ar
boss(35513,  "~3%",   "Kael'thas (Heroic), Magisters' Terrace")    -- Swift White Hawkstrider
boss(32768,  "~1-2%", "Anzu (Heroic), Sethekk Halls")              -- Reins of the Raven Lord
boss(44151,  "~1%",   "Skadi the Ruthless (Heroic), Utgarde Pinnacle") -- Reins of the Blue Proto-Drake
boss(43952,  "~4%",   "Malygos, The Eye of Eternity")              -- Reins of the Azure Drake
boss(43953,  "~1-4%", "Malygos / Ley-Guardian Eregos (Heroic, Oculus)") -- Reins of the Blue Drake
boss(43986,  "100%",  "Sartharion with 3 drakes up (10)")          -- Reins of the Black Drake
boss(43954,  "100%",  "Sartharion with 3 drakes up (25)")          -- Reins of the Twilight Drake
boss(43959,  "~1%",   "any boss, Vault of Archavon")               -- Reins of the Grand Black War Mammoth
boss(45693,  "~1%",   "Yogg-Saron with no Keepers (25), Ulduar")   -- Mimiron's Head
boss(50818,  "~1%",   "The Lich King (Heroic 25), Icecrown Citadel") -- Invincible's Reins
-- Midnight
boss(260231, "~1-2%", "Degentrius (Mythic / Mythic+), Magisters' Terrace") -- Lucent Hawkstrider
boss(262914, "~1-2%", "The Restless Heart (Mythic / Mythic+), Windrunner Spire") -- Spectral Hawkstrider
boss(246590, "Mythic", "Midnight Falls (Mythic), March on Quel'Danas") -- Ashes of Belo'ren
boss(63043,  "~0.8%", "Slabhide, The Stonecore")                   -- Reins of the Vitreous Stone Drake
boss(63040,  "~0.8%", "Altairus, The Vortex Pinnacle")             -- Reins of the Drake of the North Wind
boss(63041,  "~1%",   "Al'Akir, Throne of the Four Winds")         -- Reins of the Drake of the South Wind
boss(68824,  "~1%",   "High Priestess Kilnara, Zul'Gurub")         -- Swift Zulian Panther
boss(68823,  "~1%",   "Bloodlord Mandokir, Zul'Gurub")             -- Armored Razzashi Raptor
boss(71665,  "~1-2%", "Alysrazor, Firelands")                      -- Flametalon of Alysrazor
boss(69224,  "~1%",   "Ragnaros, Firelands")                       -- Smoldering Egg of Millagazor
boss(78919,  "~1%",   "Ultraxion, Dragon Soul")                    -- Experiment 12-B
boss(77067,  "~1%",   "Madness of Deathwing, Dragon Soul")         -- Reins of the Blazing Drake
boss(87777,  "~1%",   "Elegon, Mogu'shan Vaults")                  -- Reins of the Astral Cloud Serpent
boss(93666,  "~1-2%", "Horridon, Throne of Thunder")               -- Spawn of Horridon
boss(95059,  "~1-2%", "Ji-Kun, Throne of Thunder")                 -- Clutch of Ji-Kun
boss(104253, "~1%",   "Garrosh (Mythic), Siege of Orgrimmar")      -- Kor'kron Juggernaut
boss(116660, "~1%",   "Blackhand (Mythic), Blackrock Foundry")     -- Ironhoof Destroyer
boss(123890, "~1%",   "Archimonde (Mythic), Hellfire Citadel")     -- Felsteel Annihilator
boss(142236, "~1%",   "Attumen (Mythic), Return to Karazhan")      -- Midnight's Eternal Reins
boss(142552, "~20%",  "Nightbane (Mythic), Return to Karazhan")    -- Smoldering Ember Wyrm
boss(137574, "~1%",   "Gul'dan (Mythic), The Nighthold")           -- Living Infernal Core
boss(137575, "~1%",   "Gul'dan, The Nighthold")                    -- Fiendish Hellfire Core
boss(143643, "~1%",   "Mistress Sassz'ine, Tomb of Sargeras")      -- Abyss Worm
boss(152789, "~1%",   "Argus (Mythic), Antorus")                   -- Shackled Ur'zul
boss(159842, "~0.5%", "Harlan Sweete (Mythic), Freehold")          -- Sharkbait's Favorite Crackers
boss(160829, "~0.5%", "Unbound Abomination (Mythic), The Underrot") -- Underrot Crawg Harness
boss(168826, "~1%",   "HK-8 (Mythic), Operation: Mechagon")        -- Mechagon Peacekeeper
boss(166518, "~1%",   "High Tinker Mekkatorque, Battle of Dazar'alor") -- G.M.O.D.
boss(166705, "~1%",   "Jaina (Mythic), Battle of Dazar'alor")      -- Glacial Tidestorm
boss(174872, "~1%",   "N'Zoth (Mythic), Ny'alotha")                -- Ny'alotha Allseer
boss(186638, "~1%",   "So'leah (Mythic), Tazavesh")                -- Cartel Master's Gearglider
boss(186656, "~1%",   "Sylvanas, Sanctum of Domination")           -- Sanctum Gloomcharger's Reins
boss(190768, "~1%",   "Anduin, Sepulcher of the First Ones")       -- Fractal Cypher of the Zereth Overseer
boss(210061, "~1%",   "Fyrakk, Amirdrassil")                       -- Reins of Anu'relos, Flame's Guidance
boss(224147, "~1%",   "Queen Ansurek, Nerub-ar Palace")            -- Reins of the Sureki Skyrazor
boss(236960, "~1%",   "Chrome King Gallywix, Liberation of Undermine") -- Prototype A.S.M.R.

-- Possible BoEs, NOT confirmed: listed by guides from test-realm data as Bind on Equip
-- drops from The Venomous Abyss trash lieutenants. Live item data may differ (Blizzard can
-- change binding before release), so they are shown separately as "unconfirmed".
for _, id in ipairs({ 271638, 271445, 271444, 271440, 271441, 271436, 271438, 271435, 271434 }) do
    SFP.Items[id] = { kind = "boe", unconfirmed = true, drop = "rare",
        note = "trash lieutenants, The Venomous Abyss - may have been changed" }
end

-- Enchanting: disenchant BoE gear from that expansion (any zone)
for _, id in ipairs({ 52555, 52719, 52721,     -- Hypnotic Dust, Greater Celestial Essence, Heavenly Shard
                      74249, 74250, 74248,     -- Spirit Dust, Mysterious Essence, Sha Crystal
                      109693, 113588,          -- Draenic Dust, Temporal Crystal
                      124440, 124441, 124442,  -- Arkhana, Leylight Shard, Chaos Crystal
                      152875, 152876, 152877,  -- Gloom Dust, Umbra Shard, Veiled Crystal
                      172230, 172231, 172232,  -- Soul Dust, Sacred Shard, Eternal Crystal
                      194123, 194124, 200113,  -- Chromatic Dust, Vibrant Shard, Resonant Crystal
                      219946, 219949, 219952,  -- Storm Dust, Gleaming Shard, Refulgent Crystal
                    }) do
    SFP.Items[id] = { kind = "enchant" }
end
-- Midnight: quality versions are scanned on the AH too
SFP.Items[243599] = { kind = "enchant", tiers = { 243600 } }  -- Eversinging Dust
SFP.Items[243602] = { kind = "enchant", tiers = { 243603 } }  -- Radiant Shard
SFP.Items[243605] = { kind = "enchant", tiers = { 243606 } }  -- Dawn Crystal


-- special materials: rare finds, profession-gated cloth, lure / beast-type drops.
-- Spots that drop them glow magenta instead of cyan.
for _, id in ipairs({ 44128, 72163, 172097, 193216, 193222, 193226, 193229, 193232, 212670, 212674,
                      237016, 237017, 238518, 238520, 238525, 238522, 238523, 238528, 238529, 238530 }) do
    if SFP.Items[id] then SFP.Items[id].special = true end
end

SFP.KindOrder = { mount = -1, toy = -1, boe = 0, recipe = 0, pet = 1, ore = 2, herb = 2, element = 3, leather = 4, cloth = 5, enchant = 6, meat = 7 }
SFP.KindLabel = { mount = "Mount", toy = "Toy", boe = "BoE", recipe = "Recipe", pet = "Pet", element = "Element", leather = "Skinning",
                  cloth = "Cloth", meat = "Meat", ore = "Mining", herb = "Herbalism", enchant = "Enchanting" }
-- small icon per source, shown on every loot line (tooltips, browser)
SFP.KindIcon = {
    ore     = "Interface\\Icons\\Trade_Mining",
    herb    = "Interface\\Icons\\Trade_Herbalism",
    leather = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    cloth   = "Interface\\Icons\\Trade_Tailoring",
    element = "Interface\\Icons\\Trade_Alchemy",
    enchant = "Interface\\Icons\\Trade_Engraving",
    meat    = "Interface\\Icons\\INV_Misc_Food_15",
    boe     = "Interface\\Icons\\INV_Misc_Bag_10",
    recipe  = "Interface\\Icons\\INV_Scroll_03",
    mount   = "Interface\\Icons\\Ability_Mount_RidingHorse",
    pet     = "Interface\\Icons\\INV_Box_PetCarrier_01",
    toy     = "Interface\\Icons\\INV_Misc_Toy_10",
}
-- how each kind is obtained (drop chances for creature materials are not published)
SFP.KindHow = {
    ore = "mine the veins", herb = "pick the herbs", leather = "skin beasts", cloth = "humanoid kills",
    element = "elementals / motes", enchant = "disenchant BoE gear", meat = "beast kills",
}
SFP.DUNGEON_ICON = "Interface\\Minimap\\Dungeon"
SFP.RAID_ICON    = "Interface\\Minimap\\Raid"

function SFP:KindIconTag(kind, size)
    local t = self.KindIcon[kind]
    return t and ("|T" .. t .. ":" .. (size or 13) .. "|t") or ""
end

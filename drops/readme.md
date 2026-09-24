# Project Slayer — Boss & Chest Drops

Pulled from the live client on 2026-09-24 (Ouwland, place `136406881576517`), from the same tables the in-game item viewer reads: `LiveConfig.get("NpcDataTable")` and `LiveConfig.get("ChestsLootTable")` in `ReplicatedStorage.CAM.Global.LiveConfig`.

**How to read it**

- **Chance** is the roll per kill or per chest opened. A chest's chances add up to 41%–311%, so each item seems to roll on its own (inferred — the roll happens on the server).
- **Pity N**: the skill is probably guaranteed by kill N if it hasn't dropped yet (config field `Pity`).
- **Lv N**: config field `Level` on the drop, most likely the minimum player level to receive it.
- **Unboosted**: luck boosts don't apply to that roll.
- Rarity: ⬜ Common · 🟩 Uncommon · 🟦 Rare · 🟪 Epic · 🟨 Legendary · 🟥 Mythic · ⬛ Impossible

**Contents:** [Bosses](#bosses) · [Mob drops](#mob-drops) · [Chests](#chests) · [Where to get an item](#where-to-get-an-item)

## Bosses

### World bosses

| | Boss | HP | Respawn | Exp / Wen | Chest | Drops |
|:-:|---|--:|--:|--:|---|---|
| <img src="icons/93452648734236.png" width="48" height="48"> | **Akazo**<br><sub>The Shockwave Demon</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/107300958665418_tile.png" width="24" height="24"> Annihilation Type — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/72246927346753.png" width="24" height="24"> Akazo's Bottom — **5%**<br><img src="icons/123209032567019.png" width="24" height="24"> Akazo's Top — **5%** |
| <img src="icons/101666209144226.png" width="48" height="48"> | **Datai**<br><sub>The Obi Demon</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/96191763762223_tile.png" width="24" height="24"> Obi Charge — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/140248745348256.png" width="24" height="24"> Datai's Outfit — **5%**<br><img src="icons/134089215496967.png" width="24" height="24"> Golden Kanzashi — **5%** |
| <img src="icons/89038846694171.png" width="48" height="48"> | **Domae**<br><sub>The Cryokinetic Demon</sub><br><sub>🌙 night only</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/117188368608461_tile.png" width="24" height="24"> Bodhisattva — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/105471122563052.png" width="24" height="24"> War Fans — **7%**<br><img src="icons/95657999477355.png" width="24" height="24"> Black Lotus Crown — **5%**<br><img src="icons/130703831803818.png" width="24" height="24"> Domae's Bottom — **5%**<br><img src="icons/135859903914328.png" width="24" height="24"> Domae's Top — **5%** |
| <img src="icons/93399676613740.png" width="48" height="48"> | **Enru**<br><sub>The Dream Demon</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/123241521003523_tile.png" width="24" height="24"> Flesh Monster — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/94418128521034.png" width="24" height="24"> Enru's Bottom — **5%**<br><img src="icons/106899720140800.png" width="24" height="24"> Enru's Top — **5%** |
| <img src="icons/94540567741963.png" width="48" height="48"> | **Giyen**<br><sub>The Water Hashira</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/140303524288158_tile.png" width="24" height="24"> Dead Calm — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/109428456454495.png" width="24" height="24"> Water Katana — **5%**<br><img src="icons/123481812741942.png" width="24" height="24"> Water Haori — **3%** |
| <img src="icons/90757597716886.png" width="48" height="48"> | **Gyorei**<br><sub>The Stone Hashira</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/80796560822561_tile.png" width="24" height="24"> Arcs of Justice — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/77727343637223.png" width="24" height="24"> Stone Necklace — **5%**<br><img src="icons/93728198021149.png" width="24" height="24"> Stone Slayer Uniform — **5%**<br><img src="icons/94608454664117.png" width="24" height="24"> Stone Haori — **3%** |
| <img src="icons/109390346292090.png" width="48" height="48"> | **Gyutai**<br><sub>The Blood Sickle Demon</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/104576401654266_tile.png" width="24" height="24"> Circular Slashes — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/17802518265.png" width="24" height="24"> Blood Sickles — **7%**<br><img src="icons/114532020510299.png" width="24" height="24"> Gyutai's Outfit — **5%** |
| <img src="icons/118227676164869.png" width="48" height="48"> | **Nezura**<br><sub>The Pyrokinetic Demon</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/102382175922370_tile.png" width="24" height="24"> Blood Rupture — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/84678831045338.png" width="24" height="24"> Nezura's Outfit — **5%**<br><img src="icons/119821932700197.png" width="24" height="24"> Bamboo Muzzle — **3%** |
| <img src="icons/78844218100909.png" width="48" height="48"> | **Obari**<br><sub>The Serpent King</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/80622219017756_tile.png" width="24" height="24"> Slithering Serpent — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/90862788708818.png" width="24" height="24"> Serpent Katana — **5%**<br><img src="icons/85864392200843.png" width="24" height="24"> Serpent Haori — **3%** |
| <img src="icons/138406794828849.png" width="48" height="48"> | **Reaper**<br><sub>Sonic Reaper Demon</sub><br><sub>🌙 night only</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/98662378990382_tile.png" width="24" height="24"> Sonido Surge — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/139977471719672.png" width="24" height="24"> Reaper’s Outfit — **3%** |
| <img src="icons/83867747088156.png" width="48" height="48"> | **Rengu**<br><sub>The Flame Hashira</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/124063778859730_tile.png" width="24" height="24"> Purgatory — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/91396072601592.png" width="24" height="24"> Flame Katana — **5%**<br><img src="icons/115748859571553.png" width="24" height="24"> Flame Slayer Uniform — **5%**<br><img src="icons/119954680288052.png" width="24" height="24"> Flame Haori Style 2 — **3%** |
| <img src="icons/71155084242970.png" width="48" height="48"> | **Saneri**<br><sub>The Wind Hashira</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/82109759217184_tile.png" width="24" height="24"> Idaten Typhoon — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/71869905947653.png" width="24" height="24"> Wind Katana — **5%**<br><img src="icons/138623870963111.png" width="24" height="24"> Wind Slayer Uniform — **5%**<br><img src="icons/80657685925324.png" width="24" height="24"> Wind Haori — **3%** |
| <img src="icons/109849104474630.png" width="48" height="48"> | **Shinora**<br><sub>The Insect Hashira</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/117921474432074_tile.png" width="24" height="24"> Illusory Light — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/107030028975847.png" width="24" height="24"> Butterfly Hair Clip — **5%**<br><img src="icons/94399366567617.png" width="24" height="24"> Insect Katana — **5%**<br><img src="icons/85069247380039.png" width="24" height="24"> Insect Haori — **3%** |
| <img src="icons/139247548136868.png" width="48" height="48"> | **Sumari**<br><sub>The Temari Demon</sub><br><sub>🌙 night only</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/70841094867944_tile.png" width="24" height="24"> Spiraling Shot — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/94914728818015.png" width="24" height="24"> Sumari's Outfit — **5%** |
| <img src="icons/89376748233580.png" width="48" height="48"> | **Tengai**<br><sub>The Sound Hashira</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/116693415036677_tile.png" width="24" height="24"> String Performance — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/106586202931711.png" width="24" height="24"> Sound Katanas — **5%**<br><img src="icons/104439531894777.png" width="24" height="24"> Sound Slayer Uniform — **5%** |
| <img src="icons/77562210024440.png" width="48" height="48"> | **Yahari**<br><sub>The Arrow Demon</sub><br><sub>🌙 night only</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/100895709337578_tile.png" width="24" height="24"> Koketsu Arrow — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/88096953430190.png" width="24" height="24"> Yahari Necklace — **5%** |
| <img src="icons/85313568844226.png" width="48" height="48"> | **Yeti Demon**<br><sub>Ancient Frost Demon</sub> | 2790 | 120s | 2025 / 600 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest)<br><img src="icons/78602976034188.png" width="20" height="20"> [Ice Chest](#ice-chest)<br><img src="icons/123841250049403.png" width="20" height="20"> [Rare Chest](#rare-chest) | <img src="icons/116834869730016.png" width="24" height="24"> Emberheart Lantern — **25%** <sub>(skill · pity 10)</sub> |
| <img src="icons/78571334992349.png" width="48" height="48"> | **Zentaro**<br><sub>The Thunder King</sub> | 3000 | 300s | 1000 / 450 | <img src="icons/104396278374710.png" width="20" height="20"> [World Events Chest](#world-events-chest) | <img src="icons/122686936817985_tile.png" width="24" height="24"> Flaming Thunder God — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/118190377843244.png" width="24" height="24"> Thunder Katana — **5%**<br><img src="icons/78008431255446.png" width="24" height="24"> Thunder Haori — **3%** |

### Bosses

| | Boss | HP | Respawn | Exp / Wen | Chest | Drops |
|:-:|---|--:|--:|--:|---|---|
| <img src="icons/89376748233580.png" width="48" height="48"> | **Duelist Hibiki**<br><sub>The Last Owner</sub> | 3000 | 1s | 500 / 250 | — | — |
| <img src="icons/136297892050152.png" width="48" height="48"> | **Fujiko**<br><sub>The Bladed Wagasa</sub><br><sub>📍 Final Selection Plains</sub> | 3200 | 180s | 700 / 315 | <img src="icons/78602976034188.png" width="20" height="20"> [Ice Chest](#ice-chest) | <img src="icons/113921345706618_tile.png" width="24" height="24"> Shade Breaker — **10%** <sub>(skill · pity 35)</sub><br><img src="icons/131249665860118.png" width="24" height="24"> Bladed Wagasa — **5%** <sub>(Lv 150)</sub><br><img src="icons/126732058787934.png" width="24" height="24"> Fujiko’s Outfit — **1.8%** <sub>(Lv 150)</sub> |
| <img src="icons/118223226717410.png" width="48" height="48"> | **Hand Demon**<br><sub>Boss</sub><br><sub>📍 Final Selection</sub> | 1310 | 120s | — / 25 | — | — |
| <img src="icons/78799362242966.png" width="48" height="48"> | **Hoyuzo**<br><sub>The Sickle Reaper</sub><br><sub>📍 Bamboo Grove</sub> | 1445 | 180s | 360 / 160 | <img src="icons/123841250049403.png" width="20" height="20"> [Rare Chest](#rare-chest) | <img src="icons/85996996726779_tile.png" width="24" height="24"> Scyther Vortex — **15%** <sub>(skill · pity 35)</sub><br><img src="icons/117708875515693.png" width="24" height="24"> Demon Horns — **50%** <sub>(×3)</sub><br><img src="icons/137660010726182.png" width="24" height="24"> Sickles — **15%** <sub>(Lv 52)</sub><br><img src="icons/83191377684888.png" width="24" height="24"> Hiyozu's Bottom — **3%** <sub>(Lv 52)</sub><br><img src="icons/88962253942170.png" width="24" height="24"> Hiyozu's Top — **3%** <sub>(Lv 52)</sub> |
| <img src="icons/127854988699543.png" width="48" height="48"> | **Kaiden**<br><sub>The Claw Ravager</sub><br><sub>📍 Bamboo Grove</sub> | 825 | 165s | 250 / 113 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | <img src="icons/115960609606998_tile.png" width="24" height="24"> Predator Claws — **15%** <sub>(skill · pity 35)</sub><br><img src="icons/79751981106074.png" width="24" height="24"> Kaiden's Bottom — **15%** <sub>(Lv 30)</sub><br><img src="icons/127724981989109.png" width="24" height="24"> Kaiden's Top — **15%** <sub>(Lv 30)</sub><br><img src="icons/85714640127883.png" width="24" height="24"> Claws — **7%** <sub>(Lv 30)</sub> |
|  | **Lost**<br><sub>The Lost Slayer</sub><br><sub>📍 Final Selection</sub> | 790 | 45s | — / 10 | <img src="icons/91756721423719.png" width="20" height="20"> [Lost Chest](#lost-chest) | <img src="icons/86214733787736.png" width="24" height="24"> Shotgun Schematic — **5%** |
| <img src="icons/118920276129806.png" width="48" height="48"> | **Mother Bear**<br><sub>Boss</sub><br><sub>📍 Bamboo Grove</sub> | 525 | 110s | 180 / 80 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | — |

### Mini bosses

| | Boss | HP | Respawn | Exp / Wen | Chest | Drops |
|:-:|---|--:|--:|--:|---|---|
| <img src="icons/84603644178937.png" width="48" height="48"> | **Flame Trainee**<br><sub>Mini Boss</sub> | 600 | 120s | 185 / 83 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | — |
| <img src="icons/84412720285589.png" width="48" height="48"> | **Insect Trainee**<br><sub>Mini Boss</sub> | 600 | 120s | 185 / 83 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | — |
| <img src="icons/114279912267702.png" width="48" height="48"> | **Reaper Trainee Kuzan**<br><sub>Mini Boss</sub> | 1530 | 120s | 230 / 104 | <img src="icons/78602976034188.png" width="20" height="20"> [Ice Chest](#ice-chest) | <img src="icons/99035825230315_tile.png" width="24" height="24"> Traversal Reap — **10%** <sub>(skill · pity 35)</sub> |
| <img src="icons/140495004689315.png" width="48" height="48"> | **Serpent Trainee**<br><sub>Mini Boss</sub> | 600 | 120s | 185 / 83 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | — |
| <img src="icons/96180371653134.png" width="48" height="48"> | **Soryu Trainee Goki**<br><sub>Mini Boss</sub> | 1050 | 120s | 220 / 99 | <img src="icons/123841250049403.png" width="20" height="20"> [Rare Chest](#rare-chest) | <img src="icons/137468625168731_tile.png" width="24" height="24"> Face Breaker — **10%** <sub>(skill · pity 35)</sub> |
| <img src="icons/103322791656200.png" width="48" height="48"> | **Sound Trainee**<br><sub>Mini Boss</sub> | 600 | 120s | 185 / 83 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | — |
| <img src="icons/132969680551373.png" width="48" height="48"> | **Stone Trainee**<br><sub>Mini Boss</sub> | 600 | 120s | 185 / 83 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | <img src="icons/126701174205506.png" width="24" height="24"> Axe and Mace — **15%** |
| <img src="icons/132888817986073.png" width="48" height="48"> | **Tai Chi Trainee Suzume**<br><sub>Mini Boss</sub> | 1050 | 120s | 220 / 99 | <img src="icons/123841250049403.png" width="20" height="20"> [Rare Chest](#rare-chest) | <img src="icons/130399582674069_tile.png" width="24" height="24"> Twin Harmony — **10%** <sub>(skill · pity 35)</sub> |
| <img src="icons/100715629980691.png" width="48" height="48"> | **Thunder Trainee**<br><sub>Mini Boss</sub> | 600 | 120s | 185 / 83 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | — |
| <img src="icons/103179547098493.png" width="48" height="48"> | **Water Trainee Sabito**<br><sub>Mini Boss</sub> | 600 | 120s | 185 / 83 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | <img src="icons/117130902329461.png" width="24" height="24"> Ghost Attendant Outfit — **2%**<br><img src="icons/106970710456678.png" width="24" height="24"> Scarred Warding Mask — **2%** |
| <img src="icons/75784714790464.png" width="48" height="48"> | **Wind Trainee**<br><sub>Mini Boss</sub> | 600 | 120s | 185 / 83 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | — |
| <img src="icons/73163370203170.png" width="48" height="48"> | **Zuko**<br><sub>Mini Boss</sub><br><sub>📍 Windy Peak</sub> | 300 | 90s | 60 / 25 | <img src="icons/120968289236022.png" width="20" height="20"> [Common Chest](#common-chest) | <img src="icons/17106414221_tile.png" width="24" height="24"> Quick Draw — **30%** <sub>(skill · pity 35)</sub><br><img src="icons/136890296113836.png" width="24" height="24"> Cutlass — **20%** <sub>(Lv 10)</sub> |

## Mob drops

Regular mobs that drop items. Every other mob drops only Exp and Wen.

| Mob | Region | Drop | Chance | Qty |
|---|---|---|--:|--:|
| Beast Born Demon 🌙 | Mistfall Harbor | <img src="icons/99964439846442.png" width="24" height="24"> Beast Core | 50% | 1 |
| Blood Hounded Demon | Mistfall Harbor | <img src="icons/117708875515693.png" width="24" height="24"> Demon Horns | 50% | 1 |
| Greater Demon | Butterfly Estate | <img src="icons/117708875515693.png" width="24" height="24"> Demon Horns | 50% | 2 |
| High Demon | Iceveil Valley | <img src="icons/117708875515693.png" width="24" height="24"> Demon Horns | 50% | 2 |
| Hoyuzo Subordinate | Bamboo Grove | <img src="icons/117708875515693.png" width="24" height="24"> Demon Horns | 50% | 1 |
| Lesser Demon | Butterfly Estate | <img src="icons/117708875515693.png" width="24" height="24"> Demon Horns | 50% | 1 |
| Mizunoto | Mistfall Harbor | <img src="icons/97613524069898.png" width="24" height="24"> Broken Nichirin Katana | 50% | 1 |

## Chests

[World Events Chest](#world-events-chest) · [Common Chest](#common-chest) · [Rare Chest](#rare-chest) · [Ice Chest](#ice-chest) · [Lost Chest](#lost-chest) · [Sealed Cache T1](#sealed-cache-t1) · [Sealed Cache T2](#sealed-cache-t2) · [Sealed Cache T3](#sealed-cache-t3) · [Snow Chest](#snow-chest) · [Ouwigahara Chest](#ouwigahara-chest) · [Ouwigahara Cache](#ouwigahara-cache) · [Ouwigahara Deep Cache](#ouwigahara-deep-cache)

### World Events Chest

<img src="icons/104396278374710.png" width="64" height="64"><br>Dropped by Akazo, Datai, Domae, Enru, Giyen, Gyorei, Gyutai, Nezura, Obari, Reaper, Rengu, Saneri, Shinora, Sumari, Tengai, Yahari, Yeti Demon, Zentaro.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/126473769642414.png" width="32" height="32"> | **Coin Pouch** | 🟪 Epic | **guaranteed** | 2–3 |  |
| <img src="icons/138070983705140.png" width="32" height="32"> | **Refinement Ore** | 🟦 Rare | **guaranteed** | 4–7 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | **Silk Thread** | ⬜ Common | **guaranteed** | 3–5 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | **Metal Scraps** | ⬜ Common | **guaranteed** | 3–5 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | Metal Scraps | ⬜ Common | 50% | 1 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | Silk Thread | ⬜ Common | 50% | 1 |  |
| <img src="icons/138070983705140.png" width="32" height="32"> | Refinement Ore | 🟦 Rare | 20% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |
| <img src="icons/95468884009960.png" width="32" height="32"> | Stylish Haori | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/133978680725240.png" width="32" height="32"> | Mythic Refinement Ore | 🟥 Mythic | 4% | 1 |  |
| <img src="icons/130325344935905.png" width="32" height="32"> | Black Dragon Armour | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/109506236104989.png" width="32" height="32"> | Black Kumo Slayers Uniform | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/110825900245097.png" width="32" height="32"> | Demonic Lantern | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/139229172107422.png" width="32" height="32"> | Flame Haori Style 1 | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/72139016011078.png" width="32" height="32"> | Flame Scarf | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/135179579646015.png" width="32" height="32"> | Kintsugi  Haori | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 2% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 2% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 2% | 1 |  |
| <img src="icons/123279997164502.png" width="32" height="32"> | Firstlight Forged Ingot | 🟥 Mythic | 2% | 1 |  |
| <img src="icons/75369074175229.png" width="32" height="32"> | Firstlight Star Ore | 🟥 Mythic | 2% | 1 |  |
| <img src="icons/126295402660428.png" width="32" height="32"> | Firstlight Weaver's Silk | 🟥 Mythic | 2% | 1 |  |
| <img src="icons/116681546794110.png" width="32" height="32"> | Nightfall Forged Ingot | 🟥 Mythic | 2% | 1 |  |
| <img src="icons/117318326785538.png" width="32" height="32"> | Nightfall Reinforced Plating | 🟥 Mythic | 2% | 1 |  |
| <img src="icons/81534939121157.png" width="32" height="32"> | Nightfall Weaver's Cloth | 🟥 Mythic | 2% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 2% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 2% | 1 |  |
| <img src="icons/115790851777096.png" width="32" height="32"> | Refinement Guard | ⬛ Impossible | 2% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 2% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 2% | 1 |  |

### Common Chest

<img src="icons/120968289236022.png" width="64" height="64"><br>Dropped by Flame Trainee, Insect Trainee, Kaiden, Mother Bear, Serpent Trainee, Sound Trainee, Stone Trainee, Thunder Trainee, Water Trainee Sabito, Wind Trainee, Zuko.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/125265576801917.png" width="32" height="32"> | Shima Koshimaki | ⬜ Common | 12% | 1 |  |
| <img src="icons/132494249847796.png" width="32" height="32"> | Black Kumo Haori | 🟦 Rare | 6% | 1 |  |
| <img src="icons/72732867408855.png" width="32" height="32"> | Chained Glasses | 🟦 Rare | 6% | 1 |  |
| <img src="icons/97910616756702.png" width="32" height="32"> | Healing Gem Necklace | ⬜ Common | 6% | 1 |  |
| <img src="icons/134970645402207.png" width="32" height="32"> | Hoshiko Kesa | 🟦 Rare | 6% | 1 |  |
| <img src="icons/119319996232487.png" width="32" height="32"> | Kasumi Yukata | 🟦 Rare | 6% | 1 |  |
| <img src="icons/105216813633697.png" width="32" height="32"> | Mask of Memories | 🟦 Rare | 6% | 1 |  |
| <img src="icons/122206016500398.png" width="32" height="32"> | Masquerade Mask | 🟦 Rare | 6% | 1 |  |
| <img src="icons/112692444001119.png" width="32" height="32"> | Mist Kumo Sodenashi | 🟦 Rare | 6% | 1 |  |
| <img src="icons/132583238133709.png" width="32" height="32"> | Monster Paper Bag | 🟦 Rare | 6% | 1 |  |
| <img src="icons/125588708952800.png" width="32" height="32"> | Mouth Dagger | 🟦 Rare | 6% | 1 |  |
| <img src="icons/86197878945285.png" width="32" height="32"> | One-Horned Imp Mask | 🟦 Rare | 6% | 1 |  |
| <img src="icons/111771166029243.png" width="32" height="32"> | Sweet Dreams Eye Mask | 🟦 Rare | 6% | 1 |  |
| <img src="icons/132496277553184.png" width="32" height="32"> | Uzumaki Yukata | 🟦 Rare | 6% | 1 |  |
| <img src="icons/72069600318258.png" width="32" height="32"> | Whispering Winds Earrings | ⬜ Common | 6% | 1 |  |
| <img src="icons/122693557587113.png" width="32" height="32"> | Crimson Necklace | 🟦 Rare | 3% | 1 |  |
| <img src="icons/126811082799013.png" width="32" height="32"> | Floral Warding Mask | 🟦 Rare | 3% | 1 |  |
| <img src="icons/119348791082772.png" width="32" height="32"> | Prayer of wind Necklace | 🟦 Rare | 3% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 2.5% | 1 | unboosted |
| <img src="icons/79306449353822.png" width="32" height="32"> | Gleam Headband | 🟪 Epic | 2% | 1 |  |
| <img src="icons/129798069104629.png" width="32" height="32"> | Monster Hood | 🟪 Epic | 2% | 1 |  |
| <img src="icons/104833904710624.png" width="32" height="32"> | Fujiko's Lantern | 🟨 Legendary | 1.5% | 1 |  |
| <img src="icons/79388833909164.png" width="32" height="32"> | Lycoris Haori | 🟨 Legendary | 1.5% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 1% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 1% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 1% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 1% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 1% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 1% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 1% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 1% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 1% | 1 |  |

### Rare Chest

<img src="icons/123841250049403.png" width="64" height="64"><br>Dropped by Hoyuzo, Soryu Trainee Goki, Tai Chi Trainee Suzume, Yeti Demon.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/83494995588527.png" width="32" height="32"> | Bandaged Mask | ⬜ Common | 12% | 1 |  |
| <img src="icons/108692269580708.png" width="32" height="32"> | Blindfolds | ⬜ Common | 12% | 1 |  |
| <img src="icons/135934319904611.png" width="32" height="32"> | Clear Wind Hakama | ⬜ Common | 12% | 1 |  |
| <img src="icons/76033909512588.png" width="32" height="32"> | Runic Eye Mask | ⬜ Common | 12% | 1 |  |
| <img src="icons/128574821851779.png" width="32" height="32"> | Star Eye Patch | ⬜ Common | 12% | 1 |  |
| <img src="icons/80244405591068.png" width="32" height="32"> | Frozen Heart | 🟪 Epic | 10% | 1 | unboosted |
| <img src="icons/97910616756702.png" width="32" height="32"> | Healing Gem Necklace | ⬜ Common | 9% | 1 |  |
| <img src="icons/72069600318258.png" width="32" height="32"> | Whispering Winds Earrings | ⬜ Common | 9% | 1 |  |
| <img src="icons/135919049184463.png" width="32" height="32"> | Spear | 🟪 Epic | 7% | 1 |  |
| <img src="icons/108893826234329.png" width="32" height="32"> | Deku Haori | 🟦 Rare | 6% | 1 |  |
| <img src="icons/103980779054366.png" width="32" height="32"> | Himawari Kesa | 🟦 Rare | 6% | 1 |  |
| <img src="icons/96995916108072.png" width="32" height="32"> | Mocking Mask | 🟦 Rare | 6% | 1 |  |
| <img src="icons/128756671314926.png" width="32" height="32"> | Stylish Mask | 🟦 Rare | 6% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |
| <img src="icons/122693557587113.png" width="32" height="32"> | Crimson Necklace | 🟦 Rare | 4.5% | 1 |  |
| <img src="icons/126811082799013.png" width="32" height="32"> | Floral Warding Mask | 🟦 Rare | 4.5% | 1 |  |
| <img src="icons/119348791082772.png" width="32" height="32"> | Prayer of wind Necklace | 🟦 Rare | 4.5% | 1 |  |
| <img src="icons/116119312634187.png" width="32" height="32"> | Battle Kimono Uniform | 🟨 Legendary | 3% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 2% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 2% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 2% | 1 |  |
| <img src="icons/113719258423604.png" width="32" height="32"> | Ice Necklace | 🟪 Epic | 2% | 1 |  |
| <img src="icons/107523437921232.png" width="32" height="32"> | Kuzushiji Kata-Aki | 🟪 Epic | 2% | 1 |  |
| <img src="icons/75336510187198.png" width="32" height="32"> | Mandala Kata-Aki | 🟪 Epic | 2% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/107287778926558.png" width="32" height="32"> | Plume Haori | 🟪 Epic | 2% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 2% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 2% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 2% | 1 |  |
| <img src="icons/130134254359853.png" width="32" height="32"> | Silent Vesture Top Hat | 🟪 Epic | 2% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 2% | 1 |  |
| <img src="icons/116759728319062.png" width="32" height="32"> | White Hooded Haori | 🟪 Epic | 2% | 1 |  |

### Ice Chest

<img src="icons/78602976034188.png" width="64" height="64"><br>Dropped by Fujiko, Reaper Trainee Kuzan, Yeti Demon.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/97910616756702.png" width="32" height="32"> | Healing Gem Necklace | ⬜ Common | 12% | 1 |  |
| <img src="icons/120552605139387.png" width="32" height="32"> | Monocle | ⬜ Common | 12% | 1 |  |
| <img src="icons/115333291673100.png" width="32" height="32"> | Monster Ears | ⬜ Common | 12% | 1 |  |
| <img src="icons/72069600318258.png" width="32" height="32"> | Whispering Winds Earrings | ⬜ Common | 12% | 1 |  |
| <img src="icons/122693557587113.png" width="32" height="32"> | Crimson Necklace | 🟦 Rare | 6% | 1 |  |
| <img src="icons/127480280950826.png" width="32" height="32"> | Crimson Wrap Hakama | 🟦 Rare | 6% | 1 |  |
| <img src="icons/114241207237492.png" width="32" height="32"> | Damask Kata-Aki | 🟦 Rare | 6% | 1 |  |
| <img src="icons/126811082799013.png" width="32" height="32"> | Floral Warding Mask | 🟦 Rare | 6% | 1 |  |
| <img src="icons/122353187279002.png" width="32" height="32"> | Hem stripe Kata-Aki | 🟦 Rare | 6% | 1 |  |
| <img src="icons/129877027147215.png" width="32" height="32"> | Lantern of Despair | 🟦 Rare | 6% | 1 |  |
| <img src="icons/119348791082772.png" width="32" height="32"> | Prayer of wind Necklace | 🟦 Rare | 6% | 1 |  |
| <img src="icons/71692292889765.png" width="32" height="32"> | Seiun Kesa | 🟦 Rare | 6% | 1 |  |
| <img src="icons/106982015407090.png" width="32" height="32"> | Summer Night Mask | 🟦 Rare | 6% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |
| <img src="icons/134071895386847.png" width="32" height="32"> | Wondering Obi Belt | 🟨 Legendary | 3% | 1 |  |
| <img src="icons/100815138511992.png" width="32" height="32"> | Abyssal Lantern | 🟪 Epic | 2% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 2% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/97946575578952.png" width="32" height="32"> | Crescent Marked Veil | 🟪 Epic | 2% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 2% | 1 |  |
| <img src="icons/83961973788156.png" width="32" height="32"> | Demonic Horns | 🟪 Epic | 2% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 2% | 1 |  |
| <img src="icons/128441086598033.png" width="32" height="32"> | Midnight Blossom Cloak | 🟪 Epic | 2% | 1 |  |
| <img src="icons/83853782985871.png" width="32" height="32"> | Moonlit Kata-Aki | 🟪 Epic | 2% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 2% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 2% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 2% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 2% | 1 |  |
| <img src="icons/94126220970662.png" width="32" height="32"> | Two-Horned Mask | 🟪 Epic | 2% | 1 |  |

### Lost Chest

<img src="icons/91756721423719.png" width="64" height="64"><br>Dropped by Lost.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/129731726532959.png" width="32" height="32"> | **Metal Scraps** | ⬜ Common | **guaranteed** | 1 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | Metal Scraps | ⬜ Common | 7.5% | 1 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | Silk Thread | ⬜ Common | 7.5% | 1 |  |
| <img src="icons/115333291673100.png" width="32" height="32"> | Monster Ears | ⬜ Common | 3.6% | 1 |  |
| <img src="icons/138070983705140.png" width="32" height="32"> | Refinement Ore | 🟦 Rare | 3% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 2.5% | 1 | unboosted |
| <img src="icons/131471886038349.png" width="32" height="32"> | Squid Beanie | 🟦 Rare | 1.8% | 1 |  |
| <img src="icons/124158363512738.png" width="32" height="32"> | Envoy of Night Mask | 🟨 Legendary | 1.5% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 1% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 1% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 1% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 1% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 1% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 1% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 1% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 1% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 1% | 1 |  |
| <img src="icons/111957355628530.png" width="32" height="32"> | Lost Cape | 🟥 Mythic | 0.9% | 1 |  |
| <img src="icons/106558617417287.png" width="32" height="32"> | Lost Lantern | 🟥 Mythic | 0.9% | 1 |  |
| <img src="icons/73624583928445.png" width="32" height="32"> | Lost Mask | 🟥 Mythic | 0.9% | 1 |  |
| <img src="icons/122392038656812.png" width="32" height="32"> | Lost Outfit | 🟥 Mythic | 0.9% | 1 |  |
| <img src="icons/133978680725240.png" width="32" height="32"> | Mythic Refinement Ore | 🟥 Mythic | 0.6% | 1 |  |
| <img src="icons/115790851777096.png" width="32" height="32"> | Refinement Guard | ⬛ Impossible | 0.3% | 1 |  |

### Sealed Cache T1

<img src="icons/120968289236022.png" width="64" height="64"><br>Sealed Chest world event, guarded by Grove Raiders and a Raid Captain.<br>Exp: share 0.1, level 25.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/85163125765933.png" width="32" height="32"> | **Coin** | ⬜ Common | **guaranteed** | 2–4 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | **Silk Thread** | ⬜ Common | **guaranteed** | 1–3 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | **Metal Scraps** | ⬜ Common | **guaranteed** | 1–3 |  |
| <img src="icons/114883479174587.png" width="32" height="32"> | Coin Stack | 🟩 Uncommon | 45% | 1–2 |  |
| <img src="icons/99563083225291.png" width="32" height="32"> | Health Regen Potion | ⬜ Common | 25% | 1 |  |
| <img src="icons/113589540074508.png" width="32" height="32"> | Stamina Regen Potion | ⬜ Common | 20% | 1 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | Metal Scraps | ⬜ Common | 12.5% | 1 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | Silk Thread | ⬜ Common | 12.5% | 1 |  |
| <img src="icons/80244405591068.png" width="32" height="32"> | Frozen Heart | 🟪 Epic | 10% | 1 | unboosted |
| <img src="icons/126436271923367.png" width="32" height="32"> | Bamboo Sandogasa | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/78164086415624.png" width="32" height="32"> | Coin Pile | 🟦 Rare | 5% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |
| <img src="icons/138070983705140.png" width="32" height="32"> | Refinement Ore | 🟦 Rare | 5% | 1 |  |
| <img src="icons/75370137621065.png" width="32" height="32"> | Golden Tentacle | 🟨 Legendary | 3% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 2% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 2% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 2% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 2% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 2% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 2% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 2% | 1 |  |
| <img src="icons/88604236534027.png" width="32" height="32"> | Scythe | 🟨 Legendary | 1.75% | 1 |  |
| <img src="icons/100763959484858.png" width="32" height="32"> | Tanto | 🟨 Legendary | 1.25% | 1 |  |
| <img src="icons/133978680725240.png" width="32" height="32"> | Mythic Refinement Ore | 🟥 Mythic | 1% | 1 |  |
| <img src="icons/115790851777096.png" width="32" height="32"> | Refinement Guard | ⬛ Impossible | 0.5% | 1 |  |

### Sealed Cache T2

<img src="icons/123841250049403.png" width="64" height="64"><br>Sealed Chest world event, guarded by Cache Lancers and a Lancer Captain.<br>Exp: share 0.1, level 65.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/114883479174587.png" width="32" height="32"> | **Coin Stack** | 🟩 Uncommon | **guaranteed** | 4–6 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | **Silk Thread** | ⬜ Common | **guaranteed** | 2–4 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | **Metal Scraps** | ⬜ Common | **guaranteed** | 2–4 |  |
| <img src="icons/78164086415624.png" width="32" height="32"> | Coin Pile | 🟦 Rare | 50% | 1 |  |
| <img src="icons/138496782986316.png" width="32" height="32"> | Health Regen Elixir | 🟩 Uncommon | 25% | 1 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | Metal Scraps | ⬜ Common | 25% | 1 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | Silk Thread | ⬜ Common | 25% | 1 |  |
| <img src="icons/96682532582437.png" width="32" height="32"> | Stamina Regen Elixir | 🟩 Uncommon | 20% | 1 |  |
| <img src="icons/80244405591068.png" width="32" height="32"> | Frozen Heart | 🟪 Epic | 10% | 1 | unboosted |
| <img src="icons/138070983705140.png" width="32" height="32"> | Refinement Ore | 🟦 Rare | 10% | 1 |  |
| <img src="icons/75370137621065.png" width="32" height="32"> | Golden Tentacle | 🟨 Legendary | 8% | 1–2 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |
| <img src="icons/138231871121567.png" width="32" height="32"> | Overdrive Earrings | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/88604236534027.png" width="32" height="32"> | Scythe | 🟨 Legendary | 3.5% | 1 |  |
| <img src="icons/100763959484858.png" width="32" height="32"> | Tanto | 🟨 Legendary | 2.5% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 2% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 2% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 2% | 1 |  |
| <img src="icons/133978680725240.png" width="32" height="32"> | Mythic Refinement Ore | 🟥 Mythic | 2% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 2% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 2% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 2% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 2% | 1 |  |
| <img src="icons/115790851777096.png" width="32" height="32"> | Refinement Guard | ⬛ Impossible | 1% | 1 |  |

### Sealed Cache T3

<img src="icons/78602976034188.png" width="64" height="64"><br>Sealed Chest world event, guarded by Cache Prowlers and a Prowler Captain.<br>Exp: share 0.1, level 150.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/114883479174587.png" width="32" height="32"> | **Coin Stack** | 🟩 Uncommon | **guaranteed** | 4–7 |  |
| <img src="icons/138070983705140.png" width="32" height="32"> | **Refinement Ore** | 🟦 Rare | **guaranteed** | 4–7 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | **Silk Thread** | ⬜ Common | **guaranteed** | 3–5 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | **Metal Scraps** | ⬜ Common | **guaranteed** | 3–5 |  |
| <img src="icons/78164086415624.png" width="32" height="32"> | Coin Pile | 🟦 Rare | 60% | 1 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | Metal Scraps | ⬜ Common | 50% | 1 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | Silk Thread | ⬜ Common | 50% | 1 |  |
| <img src="icons/138496782986316.png" width="32" height="32"> | Health Regen Elixir | 🟩 Uncommon | 25% | 1–2 |  |
| <img src="icons/126473769642414.png" width="32" height="32"> | Coin Pouch | 🟪 Epic | 20% | 1 |  |
| <img src="icons/138070983705140.png" width="32" height="32"> | Refinement Ore | 🟦 Rare | 20% | 1 |  |
| <img src="icons/96682532582437.png" width="32" height="32"> | Stamina Regen Elixir | 🟩 Uncommon | 20% | 1–2 |  |
| <img src="icons/75370137621065.png" width="32" height="32"> | Golden Tentacle | 🟨 Legendary | 12% | 2–4 |  |
| <img src="icons/80244405591068.png" width="32" height="32"> | Frozen Heart | 🟪 Epic | 10% | 1 | unboosted |
| <img src="icons/88604236534027.png" width="32" height="32"> | Scythe | 🟨 Legendary | 7% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |
| <img src="icons/100763959484858.png" width="32" height="32"> | Tanto | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/133978680725240.png" width="32" height="32"> | Mythic Refinement Ore | 🟥 Mythic | 4% | 1 |  |
| <img src="icons/73075271147224.png" width="32" height="32"> | Classic Straw Hat | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 2% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 2% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 2% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 2% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 2% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 2% | 1 |  |
| <img src="icons/115790851777096.png" width="32" height="32"> | Refinement Guard | ⬛ Impossible | 2% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 2% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 2% | 1 |  |

### Snow Chest

<img src="icons/104396278374710.png" width="64" height="64"><br>Iceveil Valley snow chest (config `snow-chest-v2`). Where it spawns is decided on the server (not verified).<br>Exp: share 0.03, level 110.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/114883479174587.png" width="32" height="32"> | **Coin Stack** | 🟩 Uncommon | **guaranteed** | 1–3 |  |
| <img src="icons/138070983705140.png" width="32" height="32"> | **Refinement Ore** | 🟦 Rare | **guaranteed** | 2–3 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | **Silk Thread** | ⬜ Common | **guaranteed** | 1–2 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | **Metal Scraps** | ⬜ Common | **guaranteed** | 1–2 |  |
| <img src="icons/78164086415624.png" width="32" height="32"> | Coin Pile | 🟦 Rare | 40% | 1 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | Metal Scraps | ⬜ Common | 17.5% | 1 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | Silk Thread | ⬜ Common | 17.5% | 1 |  |
| <img src="icons/138496782986316.png" width="32" height="32"> | Health Regen Elixir | 🟩 Uncommon | 12% | 1 |  |
| <img src="icons/96682532582437.png" width="32" height="32"> | Stamina Regen Elixir | 🟩 Uncommon | 10% | 1 |  |
| <img src="icons/126473769642414.png" width="32" height="32"> | Coin Pouch | 🟪 Epic | 7% | 1 |  |
| <img src="icons/138070983705140.png" width="32" height="32"> | Refinement Ore | 🟦 Rare | 7% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 2% | 1 | unboosted |
| <img src="icons/133978680725240.png" width="32" height="32"> | Mythic Refinement Ore | 🟥 Mythic | 1.4% | 1 |  |
| <img src="icons/115790851777096.png" width="32" height="32"> | Refinement Guard | ⬛ Impossible | 0.7% | 1 |  |
| <img src="icons/88183573980404.png" width="32" height="32"> | Arrow Orb |  | 0.667% | 1 |  |
| <img src="icons/133338246273478.png" width="32" height="32"> | Blood Manipulation Orb |  | 0.667% | 1 |  |
| <img src="icons/127380392678899.png" width="32" height="32"> | Cryokinesis Orb |  | 0.667% | 1 |  |
| <img src="icons/108233308177200.png" width="32" height="32"> | Dream Orb |  | 0.667% | 1 |  |
| <img src="icons/140312491451233.png" width="32" height="32"> | Obi Manipulation Orb |  | 0.667% | 1 |  |
| <img src="icons/114485138458837.png" width="32" height="32"> | Pyrokenesis Orb |  | 0.667% | 1 |  |
| <img src="icons/83678969512657.png" width="32" height="32"> | Reaper Orb |  | 0.667% | 1 |  |
| <img src="icons/119734055786229.png" width="32" height="32"> | Shockwave Orb |  | 0.667% | 1 |  |
| <img src="icons/72896634456437.png" width="32" height="32"> | Tamari Orb |  | 0.667% | 1 |  |

### Ouwigahara Chest

<img src="icons/78877113661703.png" width="64" height="64"><br>Ouwigahara dungeon. Opening it costs `OuwigaharaPoints` (probably the end-of-run chest; inferred).

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/126473769642414.png" width="32" height="32"> | **Coin Pouch** | 🟪 Epic | **guaranteed** | 1 |  |
| <img src="icons/86755077727133.png" width="32" height="32"> | **Silk Thread** | ⬜ Common | **guaranteed** | 10–20 |  |
| <img src="icons/129731726532959.png" width="32" height="32"> | **Metal Scraps** | ⬜ Common | **guaranteed** | 10–20 |  |
| <img src="icons/113589540074508.png" width="32" height="32"> | **Stamina Regen Potion** | ⬜ Common | **guaranteed** | 1 |  |
| <img src="icons/99563083225291.png" width="32" height="32"> | **Health Regen Potion** | ⬜ Common | **guaranteed** | 1 |  |
| <img src="icons/138070983705140.png" width="32" height="32"> | **Refinement Ore** | 🟦 Rare | **guaranteed** | 15–25 |  |
| <img src="icons/95144667971932.png" width="32" height="32"> | Black Monster Ears | 🟩 Uncommon | 12% | 1 |  |
| <img src="icons/128669195113403.png" width="32" height="32"> | Eye Sash | 🟩 Uncommon | 12% | 1 |  |
| <img src="icons/84425514730751.png" width="32" height="32"> | Mimic Necklace | 🟩 Uncommon | 12% | 1 |  |
| <img src="icons/133634850782802.png" width="32" height="32"> | Azure Necklace | 🟪 Epic | 6% | 1 |  |
| <img src="icons/70575102715062.png" width="32" height="32"> | Flame Veil | 🟪 Epic | 6% | 1 |  |
| <img src="icons/111806353450088.png" width="32" height="32"> | Haki Haori | 🟪 Epic | 6% | 1 |  |
| <img src="icons/138626155537362.png" width="32" height="32"> | Sargent’s Kesa | 🟪 Epic | 6% | 1 |  |
| <img src="icons/99162474415598.png" width="32" height="32"> | Bokashi-Zome Kata-Aki | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/104615010950432.png" width="32" height="32"> | Demonic Horns II | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/123279997164502.png" width="32" height="32"> | Firstlight Forged Ingot | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/75369074175229.png" width="32" height="32"> | Firstlight Star Ore | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/126295402660428.png" width="32" height="32"> | Firstlight Weaver's Silk | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/99427781350355.png" width="32" height="32"> | Nichirin Lantern | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/116681546794110.png" width="32" height="32"> | Nightfall Forged Ingot | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/117318326785538.png" width="32" height="32"> | Nightfall Reinforced Plating | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/81534939121157.png" width="32" height="32"> | Nightfall Weaver's Cloth | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |
| <img src="icons/101229077117493.png" width="32" height="32"> | Red Oni Mask | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/102209127089262.png" width="32" height="32"> | Silver Fang Mask | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/133339303331856.png" width="32" height="32"> | Straw Fringe Hat | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/129359931559286.png" width="32" height="32"> | Todoroki Koshimaki | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/91811116317452.png" width="32" height="32"> | Yang Fur Kesa | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/101622974081610.png" width="32" height="32"> | Azure Drape Scarf | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/128679669227577.png" width="32" height="32"> | Flame Amigasa | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/138779996049645.png" width="32" height="32"> | Fractured Web Kata-Aki | 🟥 Mythic | 3% | 1 |  |

### Ouwigahara Cache

<img src="icons/78877113661703.png" width="64" height="64"><br>Ouwigahara dungeon cache. Where it spawns is decided on the server (not verified).

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/126473769642414.png" width="32" height="32"> | **Coin Pouch** | 🟪 Epic | **guaranteed** | 1–3 | split between openers (inferred) |
| <img src="icons/85163125765933.png" width="32" height="32"> | **Coin** | ⬜ Common | **guaranteed** | 4–6 | split between openers (inferred) |
| <img src="icons/95144667971932.png" width="32" height="32"> | Black Monster Ears | 🟩 Uncommon | 12% | 1 |  |
| <img src="icons/128669195113403.png" width="32" height="32"> | Eye Sash | 🟩 Uncommon | 12% | 1 |  |
| <img src="icons/84425514730751.png" width="32" height="32"> | Mimic Necklace | 🟩 Uncommon | 12% | 1 |  |
| <img src="icons/133634850782802.png" width="32" height="32"> | Azure Necklace | 🟪 Epic | 6% | 1 |  |
| <img src="icons/70575102715062.png" width="32" height="32"> | Flame Veil | 🟪 Epic | 6% | 1 |  |
| <img src="icons/111806353450088.png" width="32" height="32"> | Haki Haori | 🟪 Epic | 6% | 1 |  |
| <img src="icons/138626155537362.png" width="32" height="32"> | Sargent’s Kesa | 🟪 Epic | 6% | 1 |  |
| <img src="icons/99162474415598.png" width="32" height="32"> | Bokashi-Zome Kata-Aki | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/104615010950432.png" width="32" height="32"> | Demonic Horns II | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/123279997164502.png" width="32" height="32"> | Firstlight Forged Ingot | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/75369074175229.png" width="32" height="32"> | Firstlight Star Ore | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/126295402660428.png" width="32" height="32"> | Firstlight Weaver's Silk | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/99427781350355.png" width="32" height="32"> | Nichirin Lantern | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/116681546794110.png" width="32" height="32"> | Nightfall Forged Ingot | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/117318326785538.png" width="32" height="32"> | Nightfall Reinforced Plating | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/81534939121157.png" width="32" height="32"> | Nightfall Weaver's Cloth | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |
| <img src="icons/101229077117493.png" width="32" height="32"> | Red Oni Mask | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/102209127089262.png" width="32" height="32"> | Silver Fang Mask | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/133339303331856.png" width="32" height="32"> | Straw Fringe Hat | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/129359931559286.png" width="32" height="32"> | Todoroki Koshimaki | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/91811116317452.png" width="32" height="32"> | Yang Fur Kesa | 🟨 Legendary | 5% | 1 |  |
| <img src="icons/101622974081610.png" width="32" height="32"> | Azure Drape Scarf | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/128679669227577.png" width="32" height="32"> | Flame Amigasa | 🟥 Mythic | 3% | 1 |  |
| <img src="icons/138779996049645.png" width="32" height="32"> | Fractured Web Kata-Aki | 🟥 Mythic | 3% | 1 |  |

### Ouwigahara Deep Cache

<img src="icons/78877113661703.png" width="64" height="64"><br>Ouwigahara dungeon, deeper cache: double the odds of the regular Cache. Where it spawns is not verified.

| | Item | Rarity | Chance | Qty | Notes |
|:-:|---|---|--:|--:|---|
| <img src="icons/126473769642414.png" width="32" height="32"> | **Coin Pouch** | 🟪 Epic | **guaranteed** | 2–4 | split between openers (inferred) |
| <img src="icons/85163125765933.png" width="32" height="32"> | **Coin** | ⬜ Common | **guaranteed** | 6–8 | split between openers (inferred) |
| <img src="icons/114883479174587.png" width="32" height="32"> | **Coin Stack** | 🟩 Uncommon | **guaranteed** | 2–3 | split between openers (inferred) |
| <img src="icons/95144667971932.png" width="32" height="32"> | Black Monster Ears | 🟩 Uncommon | 24% | 1 |  |
| <img src="icons/128669195113403.png" width="32" height="32"> | Eye Sash | 🟩 Uncommon | 24% | 1 |  |
| <img src="icons/84425514730751.png" width="32" height="32"> | Mimic Necklace | 🟩 Uncommon | 24% | 1 |  |
| <img src="icons/133634850782802.png" width="32" height="32"> | Azure Necklace | 🟪 Epic | 12% | 1 |  |
| <img src="icons/70575102715062.png" width="32" height="32"> | Flame Veil | 🟪 Epic | 12% | 1 |  |
| <img src="icons/111806353450088.png" width="32" height="32"> | Haki Haori | 🟪 Epic | 12% | 1 |  |
| <img src="icons/138626155537362.png" width="32" height="32"> | Sargent’s Kesa | 🟪 Epic | 12% | 1 |  |
| <img src="icons/99162474415598.png" width="32" height="32"> | Bokashi-Zome Kata-Aki | 🟨 Legendary | 10% | 1 |  |
| <img src="icons/104615010950432.png" width="32" height="32"> | Demonic Horns II | 🟨 Legendary | 10% | 1 |  |
| <img src="icons/99427781350355.png" width="32" height="32"> | Nichirin Lantern | 🟨 Legendary | 10% | 1 |  |
| <img src="icons/101229077117493.png" width="32" height="32"> | Red Oni Mask | 🟨 Legendary | 10% | 1 |  |
| <img src="icons/102209127089262.png" width="32" height="32"> | Silver Fang Mask | 🟨 Legendary | 10% | 1 |  |
| <img src="icons/133339303331856.png" width="32" height="32"> | Straw Fringe Hat | 🟨 Legendary | 10% | 1 |  |
| <img src="icons/129359931559286.png" width="32" height="32"> | Todoroki Koshimaki | 🟨 Legendary | 10% | 1 |  |
| <img src="icons/91811116317452.png" width="32" height="32"> | Yang Fur Kesa | 🟨 Legendary | 10% | 1 |  |
| <img src="icons/101622974081610.png" width="32" height="32"> | Azure Drape Scarf | 🟥 Mythic | 6% | 1 |  |
| <img src="icons/128679669227577.png" width="32" height="32"> | Flame Amigasa | 🟥 Mythic | 6% | 1 |  |
| <img src="icons/138779996049645.png" width="32" height="32"> | Fractured Web Kata-Aki | 🟥 Mythic | 6% | 1 |  |
| <img src="icons/123279997164502.png" width="32" height="32"> | Firstlight Forged Ingot | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/75369074175229.png" width="32" height="32"> | Firstlight Star Ore | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/126295402660428.png" width="32" height="32"> | Firstlight Weaver's Silk | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/116681546794110.png" width="32" height="32"> | Nightfall Forged Ingot | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/117318326785538.png" width="32" height="32"> | Nightfall Reinforced Plating | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/81534939121157.png" width="32" height="32"> | Nightfall Weaver's Cloth | 🟥 Mythic | 5% | 1 |  |
| <img src="icons/87183725793362.png" width="32" height="32"> | Ore | 🟥 Mythic | 5% | 1 | unboosted |

## Where to get an item

<details><summary>Every drop above, A–Z, with every place it drops from (best chance first).</summary>

| | Item | Rarity | Sources |
|:-:|---|---|---|
| <img src="icons/100815138511992.png" width="24" height="24"> | Abyssal Lantern | 🟪 Epic | Ice Chest (2%) |
| <img src="icons/72246927346753.png" width="24" height="24"> | Akazo's Bottom | 🟨 Legendary | Akazo (5%) |
| <img src="icons/123209032567019.png" width="24" height="24"> | Akazo's Top | 🟨 Legendary | Akazo (5%) |
| <img src="icons/107300958665418_tile.png" width="24" height="24"> | Annihilation Type |  | Akazo (10%) |
| <img src="icons/80796560822561_tile.png" width="24" height="24"> | Arcs of Justice |  | Gyorei (10%) |
| <img src="icons/88183573980404.png" width="24" height="24"> | Arrow Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/126701174205506.png" width="24" height="24"> | Axe and Mace | 🟨 Legendary | Stone Trainee (15%) |
| <img src="icons/101622974081610.png" width="24" height="24"> | Azure Drape Scarf | 🟥 Mythic | Ouwigahara Deep Cache (6%), Ouwigahara Chest (3%), Ouwigahara Cache (3%) |
| <img src="icons/133634850782802.png" width="24" height="24"> | Azure Necklace | 🟪 Epic | Ouwigahara Deep Cache (12%), Ouwigahara Chest (6%), Ouwigahara Cache (6%) |
| <img src="icons/119821932700197.png" width="24" height="24"> | Bamboo Muzzle | 🟥 Mythic | Nezura (3%) |
| <img src="icons/126436271923367.png" width="24" height="24"> | Bamboo Sandogasa | 🟨 Legendary | Sealed Cache T1 (5%) |
| <img src="icons/83494995588527.png" width="24" height="24"> | Bandaged Mask | ⬜ Common | Rare Chest (12%) |
| <img src="icons/116119312634187.png" width="24" height="24"> | Battle Kimono Uniform | 🟨 Legendary | Rare Chest (3%) |
| <img src="icons/99964439846442.png" width="24" height="24"> | Beast Core | 🟩 Uncommon | Beast Born Demon (50%) |
| <img src="icons/130325344935905.png" width="24" height="24"> | Black Dragon Armour | 🟥 Mythic | World Events Chest (3%) |
| <img src="icons/132494249847796.png" width="24" height="24"> | Black Kumo Haori | 🟦 Rare | Common Chest (6%) |
| <img src="icons/109506236104989.png" width="24" height="24"> | Black Kumo Slayers Uniform | 🟥 Mythic | World Events Chest (3%) |
| <img src="icons/95657999477355.png" width="24" height="24"> | Black Lotus Crown | 🟨 Legendary | Domae (5%) |
| <img src="icons/95144667971932.png" width="24" height="24"> | Black Monster Ears | 🟩 Uncommon | Ouwigahara Deep Cache (24%), Ouwigahara Chest (12%), Ouwigahara Cache (12%) |
| <img src="icons/131249665860118.png" width="24" height="24"> | Bladed Wagasa | 🟨 Legendary | Fujiko (5%) |
| <img src="icons/108692269580708.png" width="24" height="24"> | Blindfolds | ⬜ Common | Rare Chest (12%) |
| <img src="icons/133338246273478.png" width="24" height="24"> | Blood Manipulation Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/102382175922370_tile.png" width="24" height="24"> | Blood Rupture |  | Nezura (10%) |
| <img src="icons/17802518265.png" width="24" height="24"> | Blood Sickles | 🟨 Legendary | Gyutai (7%) |
| <img src="icons/117188368608461_tile.png" width="24" height="24"> | Bodhisattva |  | Domae (10%) |
| <img src="icons/99162474415598.png" width="24" height="24"> | Bokashi-Zome Kata-Aki | 🟨 Legendary | Ouwigahara Deep Cache (10%), Ouwigahara Cache (5%), Ouwigahara Chest (5%) |
| <img src="icons/97613524069898.png" width="24" height="24"> | Broken Nichirin Katana | 🟩 Uncommon | Mizunoto (50%) |
| <img src="icons/107030028975847.png" width="24" height="24"> | Butterfly Hair Clip | 🟨 Legendary | Shinora (5%) |
| <img src="icons/72732867408855.png" width="24" height="24"> | Chained Glasses | 🟦 Rare | Common Chest (6%) |
| <img src="icons/104576401654266_tile.png" width="24" height="24"> | Circular Slashes |  | Gyutai (10%) |
| <img src="icons/73075271147224.png" width="24" height="24"> | Classic Straw Hat | 🟥 Mythic | Sealed Cache T3 (3%) |
| <img src="icons/85714640127883.png" width="24" height="24"> | Claws | 🟪 Epic | Kaiden (7%) |
| <img src="icons/135934319904611.png" width="24" height="24"> | Clear Wind Hakama | ⬜ Common | Rare Chest (12%) |
| <img src="icons/85163125765933.png" width="24" height="24"> | Coin | ⬜ Common | Sealed Cache T1 (guaranteed), Ouwigahara Deep Cache (guaranteed), Ouwigahara Cache (guaranteed) |
| <img src="icons/78164086415624.png" width="24" height="24"> | Coin Pile | 🟦 Rare | Sealed Cache T3 (60%), Sealed Cache T2 (50%), Snow Chest (40%), Sealed Cache T1 (5%) |
| <img src="icons/126473769642414.png" width="24" height="24"> | Coin Pouch | 🟪 Epic | World Events Chest (guaranteed), Ouwigahara Deep Cache (guaranteed), Ouwigahara Chest (guaranteed), Ouwigahara Cache (guaranteed), Sealed Cache T3 (20%), Snow Chest (7%) |
| <img src="icons/114883479174587.png" width="24" height="24"> | Coin Stack | 🟩 Uncommon | Sealed Cache T3 (guaranteed), Ouwigahara Deep Cache (guaranteed), Sealed Cache T2 (guaranteed), Snow Chest (guaranteed), Sealed Cache T1 (45%) |
| <img src="icons/97946575578952.png" width="24" height="24"> | Crescent Marked Veil | 🟪 Epic | Ice Chest (2%) |
| <img src="icons/122693557587113.png" width="24" height="24"> | Crimson Necklace | 🟦 Rare | Ice Chest (6%), Rare Chest (4.5%), Common Chest (3%) |
| <img src="icons/127480280950826.png" width="24" height="24"> | Crimson Wrap Hakama | 🟦 Rare | Ice Chest (6%) |
| <img src="icons/127380392678899.png" width="24" height="24"> | Cryokinesis Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/136890296113836.png" width="24" height="24"> | Cutlass | 🟦 Rare | Zuko (20%) |
| <img src="icons/114241207237492.png" width="24" height="24"> | Damask Kata-Aki | 🟦 Rare | Ice Chest (6%) |
| <img src="icons/140248745348256.png" width="24" height="24"> | Datai's Outfit | 🟨 Legendary | Datai (5%) |
| <img src="icons/140303524288158_tile.png" width="24" height="24"> | Dead Calm |  | Giyen (10%) |
| <img src="icons/108893826234329.png" width="24" height="24"> | Deku Haori | 🟦 Rare | Rare Chest (6%) |
| <img src="icons/117708875515693.png" width="24" height="24"> | Demon Horns | 🟩 Uncommon | Hoyuzo (50%), Hoyuzo Subordinate (50%), Blood Hounded Demon (50%), Lesser Demon (50%), High Demon (50%), Greater Demon (50%) |
| <img src="icons/83961973788156.png" width="24" height="24"> | Demonic Horns | 🟪 Epic | Ice Chest (2%) |
| <img src="icons/104615010950432.png" width="24" height="24"> | Demonic Horns II | 🟨 Legendary | Ouwigahara Deep Cache (10%), Ouwigahara Cache (5%), Ouwigahara Chest (5%) |
| <img src="icons/110825900245097.png" width="24" height="24"> | Demonic Lantern | 🟥 Mythic | World Events Chest (3%) |
| <img src="icons/130703831803818.png" width="24" height="24"> | Domae's Bottom | 🟨 Legendary | Domae (5%) |
| <img src="icons/135859903914328.png" width="24" height="24"> | Domae's Top | 🟨 Legendary | Domae (5%) |
| <img src="icons/108233308177200.png" width="24" height="24"> | Dream Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/116834869730016.png" width="24" height="24"> | Emberheart Lantern | 🟨 Legendary | Yeti Demon (25%) |
| <img src="icons/94418128521034.png" width="24" height="24"> | Enru's Bottom | 🟨 Legendary | Enru (5%) |
| <img src="icons/106899720140800.png" width="24" height="24"> | Enru's Top | 🟨 Legendary | Enru (5%) |
| <img src="icons/124158363512738.png" width="24" height="24"> | Envoy of Night Mask | 🟨 Legendary | Lost Chest (1.5%) |
| <img src="icons/128669195113403.png" width="24" height="24"> | Eye Sash | 🟩 Uncommon | Ouwigahara Deep Cache (24%), Ouwigahara Chest (12%), Ouwigahara Cache (12%) |
| <img src="icons/137468625168731_tile.png" width="24" height="24"> | Face Breaker |  | Soryu Trainee Goki (10%) |
| <img src="icons/123279997164502.png" width="24" height="24"> | Firstlight Forged Ingot | 🟥 Mythic | Ouwigahara Cache (5%), Ouwigahara Chest (5%), Ouwigahara Deep Cache (5%), World Events Chest (2%) |
| <img src="icons/75369074175229.png" width="24" height="24"> | Firstlight Star Ore | 🟥 Mythic | Ouwigahara Cache (5%), Ouwigahara Chest (5%), Ouwigahara Deep Cache (5%), World Events Chest (2%) |
| <img src="icons/126295402660428.png" width="24" height="24"> | Firstlight Weaver's Silk | 🟥 Mythic | Ouwigahara Cache (5%), Ouwigahara Chest (5%), Ouwigahara Deep Cache (5%), World Events Chest (2%) |
| <img src="icons/128679669227577.png" width="24" height="24"> | Flame Amigasa | 🟥 Mythic | Ouwigahara Deep Cache (6%), Ouwigahara Chest (3%), Ouwigahara Cache (3%) |
| <img src="icons/139229172107422.png" width="24" height="24"> | Flame Haori Style 1 | 🟥 Mythic | World Events Chest (3%) |
| <img src="icons/119954680288052.png" width="24" height="24"> | Flame Haori Style 2 | 🟥 Mythic | Rengu (3%) |
| <img src="icons/91396072601592.png" width="24" height="24"> | Flame Katana | 🟨 Legendary | Rengu (5%) |
| <img src="icons/72139016011078.png" width="24" height="24"> | Flame Scarf | 🟥 Mythic | World Events Chest (3%) |
| <img src="icons/115748859571553.png" width="24" height="24"> | Flame Slayer Uniform | 🟨 Legendary | Rengu (5%) |
| <img src="icons/70575102715062.png" width="24" height="24"> | Flame Veil | 🟪 Epic | Ouwigahara Deep Cache (12%), Ouwigahara Chest (6%), Ouwigahara Cache (6%) |
| <img src="icons/122686936817985_tile.png" width="24" height="24"> | Flaming Thunder God |  | Zentaro (10%) |
| <img src="icons/123241521003523_tile.png" width="24" height="24"> | Flesh Monster |  | Enru (10%) |
| <img src="icons/126811082799013.png" width="24" height="24"> | Floral Warding Mask | 🟦 Rare | Ice Chest (6%), Rare Chest (4.5%), Common Chest (3%) |
| <img src="icons/138779996049645.png" width="24" height="24"> | Fractured Web Kata-Aki | 🟥 Mythic | Ouwigahara Deep Cache (6%), Ouwigahara Chest (3%), Ouwigahara Cache (3%) |
| <img src="icons/80244405591068.png" width="24" height="24"> | Frozen Heart | 🟪 Epic | Sealed Cache T3 (10%), Sealed Cache T1 (10%), Sealed Cache T2 (10%), Rare Chest (10%) |
| <img src="icons/104833904710624.png" width="24" height="24"> | Fujiko's Lantern | 🟨 Legendary | Common Chest (1.5%) |
| <img src="icons/126732058787934.png" width="24" height="24"> | Fujiko’s Outfit | 🟥 Mythic | Fujiko (1.8%) |
| <img src="icons/117130902329461.png" width="24" height="24"> | Ghost Attendant Outfit | 🟨 Legendary | Water Trainee Sabito (2%) |
| <img src="icons/79306449353822.png" width="24" height="24"> | Gleam Headband | 🟪 Epic | Common Chest (2%) |
| <img src="icons/134089215496967.png" width="24" height="24"> | Golden Kanzashi | 🟨 Legendary | Datai (5%) |
| <img src="icons/75370137621065.png" width="24" height="24"> | Golden Tentacle | 🟨 Legendary | Sealed Cache T3 (12%), Sealed Cache T2 (8%), Sealed Cache T1 (3%) |
| <img src="icons/114532020510299.png" width="24" height="24"> | Gyutai's Outfit | 🟨 Legendary | Gyutai (5%) |
| <img src="icons/111806353450088.png" width="24" height="24"> | Haki Haori | 🟪 Epic | Ouwigahara Deep Cache (12%), Ouwigahara Chest (6%), Ouwigahara Cache (6%) |
| <img src="icons/97910616756702.png" width="24" height="24"> | Healing Gem Necklace | ⬜ Common | Ice Chest (12%), Rare Chest (9%), Common Chest (6%) |
| <img src="icons/138496782986316.png" width="24" height="24"> | Health Regen Elixir | 🟩 Uncommon | Sealed Cache T2 (25%), Sealed Cache T3 (25%), Snow Chest (12%) |
| <img src="icons/99563083225291.png" width="24" height="24"> | Health Regen Potion | ⬜ Common | Ouwigahara Chest (guaranteed), Sealed Cache T1 (25%) |
| <img src="icons/122353187279002.png" width="24" height="24"> | Hem stripe Kata-Aki | 🟦 Rare | Ice Chest (6%) |
| <img src="icons/103980779054366.png" width="24" height="24"> | Himawari Kesa | 🟦 Rare | Rare Chest (6%) |
| <img src="icons/83191377684888.png" width="24" height="24"> | Hiyozu's Bottom | 🟨 Legendary | Hoyuzo (3%) |
| <img src="icons/88962253942170.png" width="24" height="24"> | Hiyozu's Top | 🟨 Legendary | Hoyuzo (3%) |
| <img src="icons/134970645402207.png" width="24" height="24"> | Hoshiko Kesa | 🟦 Rare | Common Chest (6%) |
| <img src="icons/113719258423604.png" width="24" height="24"> | Ice Necklace | 🟪 Epic | Rare Chest (2%) |
| <img src="icons/82109759217184_tile.png" width="24" height="24"> | Idaten Typhoon |  | Saneri (10%) |
| <img src="icons/117921474432074_tile.png" width="24" height="24"> | Illusory Light |  | Shinora (10%) |
| <img src="icons/85069247380039.png" width="24" height="24"> | Insect Haori | 🟥 Mythic | Shinora (3%) |
| <img src="icons/94399366567617.png" width="24" height="24"> | Insect Katana | 🟨 Legendary | Shinora (5%) |
| <img src="icons/79751981106074.png" width="24" height="24"> | Kaiden's Bottom | 🟪 Epic | Kaiden (15%) |
| <img src="icons/127724981989109.png" width="24" height="24"> | Kaiden's Top | 🟪 Epic | Kaiden (15%) |
| <img src="icons/119319996232487.png" width="24" height="24"> | Kasumi Yukata | 🟦 Rare | Common Chest (6%) |
| <img src="icons/135179579646015.png" width="24" height="24"> | Kintsugi  Haori | 🟥 Mythic | World Events Chest (3%) |
| <img src="icons/100895709337578_tile.png" width="24" height="24"> | Koketsu Arrow |  | Yahari (10%) |
| <img src="icons/107523437921232.png" width="24" height="24"> | Kuzushiji Kata-Aki | 🟪 Epic | Rare Chest (2%) |
| <img src="icons/129877027147215.png" width="24" height="24"> | Lantern of Despair | 🟦 Rare | Ice Chest (6%) |
| <img src="icons/111957355628530.png" width="24" height="24"> | Lost Cape | 🟥 Mythic | Lost Chest (0.9%) |
| <img src="icons/106558617417287.png" width="24" height="24"> | Lost Lantern | 🟥 Mythic | Lost Chest (0.9%) |
| <img src="icons/73624583928445.png" width="24" height="24"> | Lost Mask | 🟥 Mythic | Lost Chest (0.9%) |
| <img src="icons/122392038656812.png" width="24" height="24"> | Lost Outfit | 🟥 Mythic | Lost Chest (0.9%) |
| <img src="icons/79388833909164.png" width="24" height="24"> | Lycoris Haori | 🟨 Legendary | Common Chest (1.5%) |
| <img src="icons/75336510187198.png" width="24" height="24"> | Mandala Kata-Aki | 🟪 Epic | Rare Chest (2%) |
| <img src="icons/105216813633697.png" width="24" height="24"> | Mask of Memories | 🟦 Rare | Common Chest (6%) |
| <img src="icons/122206016500398.png" width="24" height="24"> | Masquerade Mask | 🟦 Rare | Common Chest (6%) |
| <img src="icons/129731726532959.png" width="24" height="24"> | Metal Scraps | ⬜ Common | Lost Chest (guaranteed), World Events Chest (guaranteed), Sealed Cache T3 (guaranteed), Sealed Cache T2 (guaranteed), Ouwigahara Chest (guaranteed), Sealed Cache T1 (guaranteed), Snow Chest (guaranteed), Sealed Cache T3 (50%), World Events Chest (50%), Sealed Cache T2 (25%), Snow Chest (17.5%), Sealed Cache T1 (12.5%), Lost Chest (7.5%) |
| <img src="icons/128441086598033.png" width="24" height="24"> | Midnight Blossom Cloak | 🟪 Epic | Ice Chest (2%) |
| <img src="icons/84425514730751.png" width="24" height="24"> | Mimic Necklace | 🟩 Uncommon | Ouwigahara Deep Cache (24%), Ouwigahara Chest (12%), Ouwigahara Cache (12%) |
| <img src="icons/112692444001119.png" width="24" height="24"> | Mist Kumo Sodenashi | 🟦 Rare | Common Chest (6%) |
| <img src="icons/96995916108072.png" width="24" height="24"> | Mocking Mask | 🟦 Rare | Rare Chest (6%) |
| <img src="icons/120552605139387.png" width="24" height="24"> | Monocle | ⬜ Common | Ice Chest (12%) |
| <img src="icons/115333291673100.png" width="24" height="24"> | Monster Ears | ⬜ Common | Ice Chest (12%), Lost Chest (3.6%) |
| <img src="icons/129798069104629.png" width="24" height="24"> | Monster Hood | 🟪 Epic | Common Chest (2%) |
| <img src="icons/132583238133709.png" width="24" height="24"> | Monster Paper Bag | 🟦 Rare | Common Chest (6%) |
| <img src="icons/83853782985871.png" width="24" height="24"> | Moonlit Kata-Aki | 🟪 Epic | Ice Chest (2%) |
| <img src="icons/125588708952800.png" width="24" height="24"> | Mouth Dagger | 🟦 Rare | Common Chest (6%) |
| <img src="icons/133978680725240.png" width="24" height="24"> | Mythic Refinement Ore | 🟥 Mythic | World Events Chest (4%), Sealed Cache T3 (4%), Sealed Cache T2 (2%), Snow Chest (1.4%), Sealed Cache T1 (1%), Lost Chest (0.6%) |
| <img src="icons/84678831045338.png" width="24" height="24"> | Nezura's Outfit | 🟨 Legendary | Nezura (5%) |
| <img src="icons/99427781350355.png" width="24" height="24"> | Nichirin Lantern | 🟨 Legendary | Ouwigahara Deep Cache (10%), Ouwigahara Cache (5%), Ouwigahara Chest (5%) |
| <img src="icons/116681546794110.png" width="24" height="24"> | Nightfall Forged Ingot | 🟥 Mythic | Ouwigahara Cache (5%), Ouwigahara Chest (5%), Ouwigahara Deep Cache (5%), World Events Chest (2%) |
| <img src="icons/117318326785538.png" width="24" height="24"> | Nightfall Reinforced Plating | 🟥 Mythic | Ouwigahara Cache (5%), Ouwigahara Chest (5%), Ouwigahara Deep Cache (5%), World Events Chest (2%) |
| <img src="icons/81534939121157.png" width="24" height="24"> | Nightfall Weaver's Cloth | 🟥 Mythic | Ouwigahara Cache (5%), Ouwigahara Chest (5%), Ouwigahara Deep Cache (5%), World Events Chest (2%) |
| <img src="icons/96191763762223_tile.png" width="24" height="24"> | Obi Charge |  | Datai (10%) |
| <img src="icons/140312491451233.png" width="24" height="24"> | Obi Manipulation Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/86197878945285.png" width="24" height="24"> | One-Horned Imp Mask | 🟦 Rare | Common Chest (6%) |
| <img src="icons/87183725793362.png" width="24" height="24"> | Ore | 🟥 Mythic | Ouwigahara Chest (5%), Ouwigahara Deep Cache (5%), Rare Chest (5%), Sealed Cache T2 (5%), Ouwigahara Cache (5%), Ice Chest (5%), Sealed Cache T1 (5%), World Events Chest (5%), Sealed Cache T3 (5%), Common Chest (2.5%), Lost Chest (2.5%), Snow Chest (2%) |
| <img src="icons/138231871121567.png" width="24" height="24"> | Overdrive Earrings | 🟨 Legendary | Sealed Cache T2 (5%) |
| <img src="icons/107287778926558.png" width="24" height="24"> | Plume Haori | 🟪 Epic | Rare Chest (2%) |
| <img src="icons/119348791082772.png" width="24" height="24"> | Prayer of wind Necklace | 🟦 Rare | Ice Chest (6%), Rare Chest (4.5%), Common Chest (3%) |
| <img src="icons/115960609606998_tile.png" width="24" height="24"> | Predator Claws |  | Kaiden (15%) |
| <img src="icons/124063778859730_tile.png" width="24" height="24"> | Purgatory |  | Rengu (10%) |
| <img src="icons/114485138458837.png" width="24" height="24"> | Pyrokenesis Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/17106414221_tile.png" width="24" height="24"> | Quick Draw |  | Zuko (30%) |
| <img src="icons/83678969512657.png" width="24" height="24"> | Reaper Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/139977471719672.png" width="24" height="24"> | Reaper’s Outfit | 🟥 Mythic | Reaper (3%) |
| <img src="icons/101229077117493.png" width="24" height="24"> | Red Oni Mask | 🟨 Legendary | Ouwigahara Deep Cache (10%), Ouwigahara Cache (5%), Ouwigahara Chest (5%) |
| <img src="icons/115790851777096.png" width="24" height="24"> | Refinement Guard | ⬛ Impossible | World Events Chest (2%), Sealed Cache T3 (2%), Sealed Cache T2 (1%), Snow Chest (0.7%), Sealed Cache T1 (0.5%), Lost Chest (0.3%) |
| <img src="icons/138070983705140.png" width="24" height="24"> | Refinement Ore | 🟦 Rare | World Events Chest (guaranteed), Sealed Cache T3 (guaranteed), Ouwigahara Chest (guaranteed), Snow Chest (guaranteed), Sealed Cache T3 (20%), World Events Chest (20%), Sealed Cache T2 (10%), Snow Chest (7%), Sealed Cache T1 (5%), Lost Chest (3%) |
| <img src="icons/76033909512588.png" width="24" height="24"> | Runic Eye Mask | ⬜ Common | Rare Chest (12%) |
| <img src="icons/138626155537362.png" width="24" height="24"> | Sargent’s Kesa | 🟪 Epic | Ouwigahara Deep Cache (12%), Ouwigahara Chest (6%), Ouwigahara Cache (6%) |
| <img src="icons/106970710456678.png" width="24" height="24"> | Scarred Warding Mask | 🟨 Legendary | Water Trainee Sabito (2%) |
| <img src="icons/88604236534027.png" width="24" height="24"> | Scythe | 🟨 Legendary | Sealed Cache T3 (7%), Sealed Cache T2 (3.5%), Sealed Cache T1 (1.75%) |
| <img src="icons/85996996726779_tile.png" width="24" height="24"> | Scyther Vortex |  | Hoyuzo (15%) |
| <img src="icons/71692292889765.png" width="24" height="24"> | Seiun Kesa | 🟦 Rare | Ice Chest (6%) |
| <img src="icons/85864392200843.png" width="24" height="24"> | Serpent Haori | 🟥 Mythic | Obari (3%) |
| <img src="icons/90862788708818.png" width="24" height="24"> | Serpent Katana | 🟨 Legendary | Obari (5%) |
| <img src="icons/113921345706618_tile.png" width="24" height="24"> | Shade Breaker |  | Fujiko (10%) |
| <img src="icons/125265576801917.png" width="24" height="24"> | Shima Koshimaki | ⬜ Common | Common Chest (12%) |
| <img src="icons/119734055786229.png" width="24" height="24"> | Shockwave Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/86214733787736.png" width="24" height="24"> | Shotgun Schematic | 🟨 Legendary | Lost (5%) |
| <img src="icons/137660010726182.png" width="24" height="24"> | Sickles | 🟪 Epic | Hoyuzo (15%) |
| <img src="icons/130134254359853.png" width="24" height="24"> | Silent Vesture Top Hat | 🟪 Epic | Rare Chest (2%) |
| <img src="icons/86755077727133.png" width="24" height="24"> | Silk Thread | ⬜ Common | World Events Chest (guaranteed), Sealed Cache T3 (guaranteed), Sealed Cache T2 (guaranteed), Ouwigahara Chest (guaranteed), Sealed Cache T1 (guaranteed), Snow Chest (guaranteed), Sealed Cache T3 (50%), World Events Chest (50%), Sealed Cache T2 (25%), Snow Chest (17.5%), Sealed Cache T1 (12.5%), Lost Chest (7.5%) |
| <img src="icons/102209127089262.png" width="24" height="24"> | Silver Fang Mask | 🟨 Legendary | Ouwigahara Deep Cache (10%), Ouwigahara Cache (5%), Ouwigahara Chest (5%) |
| <img src="icons/80622219017756_tile.png" width="24" height="24"> | Slithering Serpent |  | Obari (10%) |
| <img src="icons/98662378990382_tile.png" width="24" height="24"> | Sonido Surge |  | Reaper (10%) |
| <img src="icons/106586202931711.png" width="24" height="24"> | Sound Katanas | 🟨 Legendary | Tengai (5%) |
| <img src="icons/104439531894777.png" width="24" height="24"> | Sound Slayer Uniform | 🟨 Legendary | Tengai (5%) |
| <img src="icons/135919049184463.png" width="24" height="24"> | Spear | 🟪 Epic | Rare Chest (7%) |
| <img src="icons/70841094867944_tile.png" width="24" height="24"> | Spiraling Shot |  | Sumari (10%) |
| <img src="icons/131471886038349.png" width="24" height="24"> | Squid Beanie | 🟦 Rare | Lost Chest (1.8%) |
| <img src="icons/96682532582437.png" width="24" height="24"> | Stamina Regen Elixir | 🟩 Uncommon | Sealed Cache T3 (20%), Sealed Cache T2 (20%), Snow Chest (10%) |
| <img src="icons/113589540074508.png" width="24" height="24"> | Stamina Regen Potion | ⬜ Common | Ouwigahara Chest (guaranteed), Sealed Cache T1 (20%) |
| <img src="icons/128574821851779.png" width="24" height="24"> | Star Eye Patch | ⬜ Common | Rare Chest (12%) |
| <img src="icons/94608454664117.png" width="24" height="24"> | Stone Haori | 🟥 Mythic | Gyorei (3%) |
| <img src="icons/77727343637223.png" width="24" height="24"> | Stone Necklace | 🟨 Legendary | Gyorei (5%) |
| <img src="icons/93728198021149.png" width="24" height="24"> | Stone Slayer Uniform | 🟨 Legendary | Gyorei (5%) |
| <img src="icons/133339303331856.png" width="24" height="24"> | Straw Fringe Hat | 🟨 Legendary | Ouwigahara Deep Cache (10%), Ouwigahara Cache (5%), Ouwigahara Chest (5%) |
| <img src="icons/116693415036677_tile.png" width="24" height="24"> | String Performance |  | Tengai (10%) |
| <img src="icons/95468884009960.png" width="24" height="24"> | Stylish Haori | 🟨 Legendary | World Events Chest (5%) |
| <img src="icons/128756671314926.png" width="24" height="24"> | Stylish Mask | 🟦 Rare | Rare Chest (6%) |
| <img src="icons/94914728818015.png" width="24" height="24"> | Sumari's Outfit | 🟨 Legendary | Sumari (5%) |
| <img src="icons/106982015407090.png" width="24" height="24"> | Summer Night Mask | 🟦 Rare | Ice Chest (6%) |
| <img src="icons/111771166029243.png" width="24" height="24"> | Sweet Dreams Eye Mask | 🟦 Rare | Common Chest (6%) |
| <img src="icons/72896634456437.png" width="24" height="24"> | Tamari Orb |  | Sealed Cache T2 (2%), World Events Chest (2%), Sealed Cache T3 (2%), Rare Chest (2%), Ice Chest (2%), Sealed Cache T1 (2%), Lost Chest (1%), Common Chest (1%), Snow Chest (0.667%) |
| <img src="icons/100763959484858.png" width="24" height="24"> | Tanto | 🟨 Legendary | Sealed Cache T3 (5%), Sealed Cache T2 (2.5%), Sealed Cache T1 (1.25%) |
| <img src="icons/78008431255446.png" width="24" height="24"> | Thunder Haori | 🟥 Mythic | Zentaro (3%) |
| <img src="icons/118190377843244.png" width="24" height="24"> | Thunder Katana | 🟨 Legendary | Zentaro (5%) |
| <img src="icons/129359931559286.png" width="24" height="24"> | Todoroki Koshimaki | 🟨 Legendary | Ouwigahara Deep Cache (10%), Ouwigahara Cache (5%), Ouwigahara Chest (5%) |
| <img src="icons/99035825230315_tile.png" width="24" height="24"> | Traversal Reap |  | Reaper Trainee Kuzan (10%) |
| <img src="icons/130399582674069_tile.png" width="24" height="24"> | Twin Harmony |  | Tai Chi Trainee Suzume (10%) |
| <img src="icons/94126220970662.png" width="24" height="24"> | Two-Horned Mask | 🟪 Epic | Ice Chest (2%) |
| <img src="icons/132496277553184.png" width="24" height="24"> | Uzumaki Yukata | 🟦 Rare | Common Chest (6%) |
| <img src="icons/105471122563052.png" width="24" height="24"> | War Fans | 🟨 Legendary | Domae (7%) |
| <img src="icons/123481812741942.png" width="24" height="24"> | Water Haori | 🟥 Mythic | Giyen (3%) |
| <img src="icons/109428456454495.png" width="24" height="24"> | Water Katana | 🟨 Legendary | Giyen (5%) |
| <img src="icons/72069600318258.png" width="24" height="24"> | Whispering Winds Earrings | ⬜ Common | Ice Chest (12%), Rare Chest (9%), Common Chest (6%) |
| <img src="icons/116759728319062.png" width="24" height="24"> | White Hooded Haori | 🟪 Epic | Rare Chest (2%) |
| <img src="icons/80657685925324.png" width="24" height="24"> | Wind Haori | 🟥 Mythic | Saneri (3%) |
| <img src="icons/71869905947653.png" width="24" height="24"> | Wind Katana | 🟨 Legendary | Saneri (5%) |
| <img src="icons/138623870963111.png" width="24" height="24"> | Wind Slayer Uniform | 🟨 Legendary | Saneri (5%) |
| <img src="icons/134071895386847.png" width="24" height="24"> | Wondering Obi Belt | 🟨 Legendary | Ice Chest (3%) |
| <img src="icons/88096953430190.png" width="24" height="24"> | Yahari Necklace | 🟨 Legendary | Yahari (5%) |
| <img src="icons/91811116317452.png" width="24" height="24"> | Yang Fur Kesa | 🟨 Legendary | Ouwigahara Deep Cache (10%), Ouwigahara Cache (5%), Ouwigahara Chest (5%) |

</details>

---

<sub>Dev test NPCs (Scythe Boss, Spear Boss, Tai Chi Boss, Dummy, …) are left out. Icons are Roblox thumbnails saved locally, because thumbnail CDN links expire after 180 days.</sub>

---
title: Items
sidebar_position: 7
---

# Items

The resource does not create items. Each item below must exist in the `kora_core` shared items list (the client and catalog read labels, descriptions and images from it, and `kora_inventory` stores them).

## Special items

| Item | Config key | Behaviour |
| --- | --- | --- |
| `metaldetector` | `Config.Items.detector` | Registered as a usable item on the server. Using it starts detecting; using it again stops. Sold by the shop at `Config.Selling.detectorPrice`. |
| `clump` | `Config.Items.clump` | Can be found while detecting (level 1) and is washed at a wash spot. It is excluded from wash results. |

## Default loot table

`Config.Loot.items`: minimum skill `level`, `xp` per find. Sell value comes from `Config.Loot.sellValues` (a dash means the shop does not buy it).

| Item | Level | XP | Sell value |
| --- | --- | --- | --- |
| `clump` | 1 | 10 | 10 |
| `metalscrap` | 1 | 17 | - |
| `copper` | 1 | 17 | - |
| `aluminum` | 10 | 35 | - |
| `iron` | 20 | 45 | - |
| `bobby_pin` | 25 | 50 | 25 |
| `bottle_cap` | 30 | 50 | 20 |
| `nails` | 35 | 75 | 30 |
| `toy_car` | 40 | 143 | 50 |
| `corno` | 45 | 176 | 60 |
| `car_keys_md` | 50 | 300 | 100 |
| `steel` | 55 | 460 | - |
| `silver_ring_md` | 60 | 550 | 100 |
| `gold_ring_md` | 60 | 600 | 125 |
| `gold_chain_md` | 65 | 850 | 150 |
| `gold_bracelet_md` | 70 | 1400 | 175 |
| `diamond_earring_md` | 70 | 1500 | 200 |
| `diamond_ring_md` | 70 | 1680 | 225 |
| `gold_diamond_ring_md` | 75 | 3300 | 250 |
| `antique_coin` | 80 | 5000 | 275 |
| `ruby_ring_md` | 85 | 9000 | 300 |

Selection is uniform among the eligible entries, so rarer items are not less likely, only locked until their level.

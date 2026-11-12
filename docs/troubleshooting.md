---
title: Troubleshooting
sidebar_position: 11
---

# Troubleshooting

- **Using the detector does nothing** - the skill must be readable. If `kora_skills` has no `metaldetecting` skill, the server logs `could not read metaldetecting skill`. Using the item is also ignored for 2 seconds after a previous use.
- **"This ground is unsuitable"** - the material under the player is not in `Config.Detection.allowedGrounds`. Add the material hash if needed.
- **The detector prop is missing** - check that `Config.Detection.detectorModel` is streamed.
- **Shop ped does not appear** - the server logs `shop ped N (...) could not be created`; check `Config.Selling.shop[N].ped`. After one failure the server does not retry that shop until restart.
- **No target on the ped** - `kora_target` must be started (it is not a declared dependency).
- **Cannot sell an item** - only items in `Config.Loot.sellValues` can be sold. By default `metalscrap`, `copper`, `aluminum`, `iron` and `steel` are not sellable here.
- **"You do not have room for that find."** - the inventory is full. A failed wash returns the clump.
- **Washing gives no XP** - by design; only detecting finds award XP.

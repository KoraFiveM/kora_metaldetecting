---
title: kora_metaldetecting
sidebar_position: 1
---

# kora_metaldetecting

`kora_metaldetecting` is a metal detecting activity for Kora servers. Players buy a metal detector from a shop ped, use the item to search suitable ground, pass a `kora_lib` skillbar minigame to dig up a find, wash "clumps" at wash spots, and sell finds back to the shop. Finds are gated by a `kora_skills` skill (`metaldetecting`) and the time between finds shrinks as the skill level rises. The server decides every outcome; the client only renders the minigame and animations.

Current version: see `version` in `fxmanifest.lua`.

## Features

- **Detecting** - using the `metaldetector` item attaches a detector prop and starts a search loop. The countdown only advances while the ground material under the player is in `Config.Detection.allowedGrounds`. When it ends the player is told "You may have found something" and must pass a skillbar minigame, then dig.
- **Skill-gated loot** - a find is chosen uniformly at random from the `Config.Loot.items` entries whose `level` is at or below the player's `metaldetecting` level. Each find adds 1 item and awards the entry's `xp`.
- **Cooldown scaling** - the time between finds goes linearly from `Config.Skill.cooldown.atLevel1` seconds at level 1 to `atMaxLevel` seconds at the skill's max level.
- **Washing** - at a wash spot a player can wash one `clump` (skillbar, then a 5 second progress bar). The clump is replaced by a random find the player's level allows, never another clump. Washing awards no XP.
- **Shop** - a networked, frozen ped per `Config.Selling.shop` entry with a `kora_target` option opening the shop app: buy a detector (cash or bank) and sell finds for cash.
- **Catalog** - `/metaldetectcatalog` opens a panel with the player's level, max level and the loot table (locked/unlocked, XP, sell price).
- **Stops** - detecting stops when the item is used again, when the player dies, enters a vehicle, logs out or disconnects, or the resource stops.

## Requirements

Declared in `fxmanifest.lua`: `kora_core`, `kora_inventory`, `kora_lib`, `kora_skills`.

| Resource | Used for |
| --- | --- |
| `kora_lib` | `Kora.*` helpers: events, callbacks, minigames, NUI apps, notifications, text UI, zones, blips, animations, progress bar |
| `kora_core` | Usable item registration, item and money functions, shared item definitions |
| `kora_inventory` | Client `HasItem` checks and item images |
| `kora_skills` | The `metaldetecting` skill (`getRep`, `addRep`); it must be defined in `kora_skills` |

Used but not declared as dependencies: `kora_target` (the shop ped target, `addEntity`), and optionally `kora_clothing` (`ApplyAppearanceToPed`, only used if started and the shop has an `outfit`). `Kora.interact` zones (from `kora_lib`) provide the wash spots.

## Documentation map

- [Installation](./installation.md) - install steps, dependencies, required items and skill, and the config option reference from the original docs
- [How to use](./how-to-use.md) - the detect, find, wash, shop and catalog flow and its server-side verification
- [Commands](./commands.md) - `/metaldetectcatalog`
- [Configuration](./configuration.md) - every `Config` option with defaults and shop/wash entry fields
- [Items](./items.md) - detector, clump, loot table and sell values
- [Events and callbacks](./events.md) - net events, callbacks, client pushes and listened events with rate limits
- [Shop and catalog UI](./ui.md) - the shop, wash and catalog interfaces and the player flow
- [Database](./database.md) - database usage (none)
- [Troubleshooting](./troubleshooting.md) - common problems and caveats

This resource exposes no exports and defines no ACE permissions, so there is no API reference.

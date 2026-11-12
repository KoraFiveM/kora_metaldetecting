---
title: "Installation"
sidebar_position: 2
---


# Installation

Kora Metal Detecting lets a player dig up loot with a metal detector and wash the resulting clump for a chance at better items, with rewards gated by a `metaldetecting` skill from kora_skills. It answers to the legacy `kora_metaldetecting` export name. Every reward-granting step is authorized and verified server-side with kora_lib's minigame proof system, the same pattern used by kora_fishing.

## Install Kora Metal Detecting

1. **Add the folder** — Place `kora_metaldetecting` in your resources directory (on the Kora recipe it is `resources/[kora]/kora_metaldetecting`).

2. **Start its dependencies first** — The manifest declares `kora_core`, `kora_inventory`, `kora_lib` and `kora_skills` as dependencies. All must be started first.

   ```bash title="server.cfg"
   ensure kora_lib
   ensure kora_core
   ensure kora_inventory
   ensure kora_skills
   ensure kora_metaldetecting
   ```

3. **Register the items** — The `metaldetector` (usable) and `clump` items, plus every loot item in `Config.Loot.items` (metalscrap, copper, aluminum, iron, bobby_pin, bottle_cap, nails, toy_car, corno, car_keys_md, steel, silver_ring_md, gold_ring_md, gold_chain_md, gold_bracelet_md, diamond_earring_md, diamond_ring_md, gold_diamond_ring_md, antique_coin, ruby_ring_md), must exist in your shared item registry (`exports.kora_core:getShared('items', ...)`) with images for the catalog/shop UI to show them.

4. **Register the skill** — A `metaldetecting` skill (`Config.Skill.name`) must exist in kora_skills; `exports.kora_skills:getRep(src, 'metaldetecting')` and `:addRep(...)` are used throughout.

## Configuration (shared/config.lua)

- `Config.Items.detector` / `Config.Items.clump` — item names for the usable metal detector and the raw clump found while detecting.
- `Config.Detection.showText` — shows a textUI telling the player whether the ground under them is suitable.
- `Config.Detection.detectorModel` — prop attached to the player while detecting.
- `Config.Detection.digDuration` — ms; the client waits half this before sending the find to the server and then the full value before resuming the detection loop (purely a client-side animation/pacing value).
- `Config.Detection.distance` — default proximity radius (metres) used wherever a shop/wash distance isn't separately configured.
- `Config.Detection.minigame` — `{ attempts, zoneSize, speed, timeLimit }` passed straight to `Kora.minigames.authorizeSkillCheck(src, skillName, 'skillbar', ...)` for both finding and washing.
- `Config.Detection.allowedGrounds` — list of ground material hashes the detector will register a find on; checked independently on both client (for the "suitable ground" text and cooldown countdown) and server (`isAllowedGround`, re-validated from the `ground` argument the client reports).
- `Config.Skill.name` — the kora_skills skill name used for progression and the cooldown curve.
- `Config.Skill.cooldown.atLevel1` / `atMaxLevel` — seconds between finds at skill level 1 vs. the skill's max level; `cooldownForLevel()` linearly interpolates between them (validated at load: both must be positive and `atMaxLevel <= atLevel1`).
- `Config.Loot.items` — array of `{ item, level, xp }`; a find or wash can only award an item once the player's metaldetecting level is at or above its `level`. Loaded at config time with an assertion that `level` is a positive integer and `xp` is positive.
- `Config.Loot.sellValues` — `{ [item] = price }` cash price when selling that item at the shop; also used to build the sellable list in both the shop and the catalog UI.
- `Config.Selling.detectorPrice` — cash/bank price of a metal detector at the shop.
- `Config.Selling.interactionDistance` — proximity radius for shop and wash-spot interactions.
- `Config.Selling.shop` — array of `{ coords, ped, blip }` vendor locations; each spawns a ped with a `kora_target` option that opens the shop NUI.
- `Config.Selling.wash` — array of `{ coords, blip }` clump-washing spots; each gets a circle interaction zone (`Kora.interact.addCircleZone`) offering "Wash metal clump".

## Requirements

Declared in `fxmanifest.lua`: `kora_core`, `kora_inventory`, `kora_lib`, `kora_skills`.

| Resource | Used for |
| --- | --- |
| `kora_lib` | `Kora.*` helpers: events, callbacks, minigames, NUI apps, notifications, text UI, zones, blips, animations, progress bar |
| `kora_core` | Usable item registration, item and money functions, shared item definitions |
| `kora_inventory` | Client `HasItem` checks and item images |
| `kora_skills` | The `metaldetecting` skill (`getRep`, `addRep`); it must be defined in `kora_skills` |

Used but not declared as dependencies: `kora_target` (the shop ped target, `addEntity`), and optionally `kora_clothing` (`ApplyAppearanceToPed`, only used if started and the shop has an `outfit`). `Kora.interact` zones (from `kora_lib`) provide the wash spots. Start `kora_target` before `kora_metaldetecting` as well if you want the shop ped target.

## Additional setup notes

- No SQL import is needed (see [Database](./database.md)).
- The detector prop model (`Config.Detection.detectorModel`, default `bostra_detector`) must be streamed by your server.
- The resource exposes no exports and defines no ACE permissions.
- Every option, with its default, is listed in [Configuration](./configuration.md); the item list and loot table are in [Items](./items.md).

## Testing

`tests/checklist-activities.feature` holds manual QA scenarios for `kora_qa` (registered with `qa_feature` in `fxmanifest.lua`).

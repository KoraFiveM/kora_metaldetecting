---
title: Configuration
sidebar_position: 6
---

# Configuration

All options are in `shared/config.lua` (shared by client and server). Invalid loot, shop, outfit or cooldown values fail an `assert` when the resource loads.

## Items

| Option | Default | Description |
| --- | --- | --- |
| `Config.Items.detector` | `metaldetector` | Usable detector item; also the item sold by the shop. |
| `Config.Items.clump` | `clump` | Item washed at wash spots. |

## Detection

| Option | Default | Description |
| --- | --- | --- |
| `Config.Detection.showText` | `true` | Show the text UI telling the player if the ground is suitable. |
| `Config.Detection.detectorModel` | `bostra_detector` | Prop model attached to the player's hand. Must be streamed by the server. |
| `Config.Detection.digDuration` | `7000` | Milliseconds. The dig animation plays for half of it before the find is submitted, then the client waits the full value before resuming the search. |
| `Config.Detection.distance` | `5.0` | Default distance for the server proximity helper. The detecting and wash/shop checks pass their own distance, so this is only a fallback. |
| `Config.Detection.minigame` | see below | Skillbar parameters passed to `Kora.minigames.authorizeSkillCheck`, used for both finds and washing. |
| `Config.Detection.allowedGrounds` | 13 material hashes | Ground material hashes (from a downward shape test) on which the countdown runs. |

`Config.Detection.minigame` defaults: `attempts = 2`, `zoneSize = 0.24`, `speed = 0.5`, `timeLimit = 10000`.

## Skill

| Option | Default | Description |
| --- | --- | --- |
| `Config.Skill.name` | `metaldetecting` | `kora_skills` skill name used for level and XP. |
| `Config.Skill.cooldown.atLevel1` | `55` | Seconds between finds at level 1. |
| `Config.Skill.cooldown.atMaxLevel` | `5` | Seconds between finds at max level. Must be positive and not above `atLevel1`. |

## Loot

| Option | Description |
| --- | --- |
| `Config.Loot.items` | List of `{ item, level, xp }`. `level` is a positive integer, `xp` a positive number. See [Items](./items.md). |
| `Config.Loot.sellValues` | Map of item name to cash price per unit. Only items listed here can be sold to the shop. |

## Selling

| Option | Default | Description |
| --- | --- | --- |
| `Config.Selling.detectorPrice` | `500` | Detector price (cash or bank). |
| `Config.Selling.interactionDistance` | `5.0` | Max distance, checked on the server, from a shop or wash spot for buying, selling and washing. |
| `Config.Selling.shop` | one entry | Shop ped locations. |
| `Config.Selling.wash` | three entries | Wash spots. |

Shop entry fields:

| Field | Description |
| --- | --- |
| `coords` | `vector4` (x, y, z, heading). |
| `ped` | Ped model name (required, non-empty). |
| `outfit` | Optional `{ components = { [id] = { d, t } }, props = { [id] = { d, t } } }`. Applied through `kora_clothing` if started, otherwise directly. |
| `scenario` | Scenario the ped plays. |
| `zOffset` | Added to `coords.z` when the server creates the ped. Default `1.0`. |
| `spawnDistance` | Radius within which clients set up the ped and its target. Default `50.0`. |
| `target` | `{ label, icon }` for the `kora_target` option. |
| `blip` | `{ sprite, color, scale, name, shortRange, category }`; `enabled = false` hides it. |

Wash entry fields: `coords` (`vector3`) and `blip` (same format). Each wash spot also gets an interaction circle zone of radius 1.5 with the option "Wash metal clump".

The shop index in events is the position of the entry in `Config.Selling.shop`; the wash index is the position in `Config.Selling.wash`.

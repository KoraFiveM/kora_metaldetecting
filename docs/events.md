---
title: Events and callbacks
sidebar_position: 8
---

# Events and callbacks

The resource exposes no exports. Everything below is internal to its client/server flow. Do not trigger the server events from other resources: they are rate limited, check proximity or minigame proofs, and silently ignore invalid requests.

The only command, `/metaldetectcatalog`, is documented in [Commands](./commands.md).

## Server callbacks

| Callback | Arguments | Returns | Behaviour |
| --- | --- | --- | --- |
| `kora_metaldetecting:server:beginFind` | `ground` | authorization or `false` | Requires an active detector, an allowed ground, no cooldown, the detector item and a readable skill. Issues a skillbar authorization. Rate limit 4 per 10 s. |
| `kora_metaldetecting:server:beginWash` | `washIndex` | authorization or `false` | Requires being near the wash spot and owning a clump. Issues a skillbar authorization. Rate limit 4 per 10 s. |

## Server events

| Event | Payload | Behaviour |
| --- | --- | --- |
| `kora_metaldetecting:server:stoppedDetecting` | none | Stops detecting and clears the player's state. Rate limit 3 per 5 s. |
| `kora_metaldetecting:server:completedFind` | `ground`, `proof`, `authorization` | Validates the minigame proof, picks loot for the player's level, adds the item, awards XP, restarts the cooldown and notifies level-ups. Rate limit 4 per 10 s. |
| `kora_metaldetecting:server:washedClump` | `washIndex`, `proof`, `authorization` | Validates the proof, removes one clump and adds a random non-clump find. If the find cannot be added the clump is returned. Rate limit 4 per 10 s. |
| `kora_metaldetecting:server:purchasedDetector` | `shopIndex`, `account` | `account` is `cash` or `bank`. Requires being near the shop. Charges `detectorPrice`, adds the detector, refunds if there is no room. Rate limit 2 per 5 s. |
| `kora_metaldetecting:server:soldLoot` | `shopIndex`, `item`, `amount` | Requires being near the shop and a `sellValues` price. Removes `amount` of the item and pays cash. Rate limit 8 per 5 s. |

## Client events (pushed by the server)

| Event | Payload | Behaviour |
| --- | --- | --- |
| `kora_metaldetecting:client:startedDetecting` | `cooldownSeconds` | Equips the detector and starts the search loop. Refused in a vehicle or when dead. |
| `kora_metaldetecting:client:stoppedDetecting` | none | Cleans up locally without telling the server back. |
| `kora_metaldetecting:client:foundLoot` | `item`, `cooldownSeconds` | Shows "You found ..." and updates the cooldown. |

## Listened external events

| Event | Side | Use |
| --- | --- | --- |
| `QBCore:Server:OnPlayerUnload` | server | Clears the player's state. |
| `kora_core:server:playerDropped` | server | Clears the player's state. |
| `QBCore:Client:OnPlayerUnload` | client | Closes the shop/catalog apps and removes shop ped targets. |
| `onResourceStop` / `onClientResourceStop` | both | Deletes shop peds (server); stops detecting and removes targets (client). |

Entity state bag key `kora_metaldetecting:shopPed` carries the shop ped's display definition (index, model, outfit, scenario, spawn distance, target label and icon) to clients in scope. It never carries prices.

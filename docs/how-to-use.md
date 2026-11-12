---
title: "How to use"
sidebar_position: 3
---


# How to use

The full flow is: equip the detector → walk until a find triggers → play a skill-check minigame → the server verifies and grants loot → optionally wash a clump at a wash spot for a second roll. Finding and washing both require a server-issued, single-use proof token before any reward is granted — a modified client cannot skip the minigame or replay a result for free loot.

## Starting and stopping detection

The detector is a usable item (`Core:createUseable(Config.Items.detector, ...)`). Using it while already detecting stops it; otherwise the server checks the player has a loaded skill record, sets `activeDetectors[src] = true`, computes the starting cooldown with `cooldownForLevel(skill.level, skill.maxLevel)`, and pushes `kora_metaldetecting:client:startedDetecting` with that cooldown. The client then attaches the detector prop, plays a walking animation, and loops: every second it checks the ground material under the player against `Config.Detection.allowedGrounds`, shows/updates the "suitable ground" textUI, and only counts down the cooldown while standing on allowed ground. Death or entering a vehicle interrupts detecting immediately (`Kora.cache.onChange('vehicle'|'isDead', ...)`) and tells the server via `kora_metaldetecting:server:stoppedDetecting`.

## Finding a clump (current, verified flow)

Once the cooldown elapses on valid ground, the client notifies "You may have found something" and calls `playFind(ground)`:

- 1. Client calls `Kora.callback.trigger('kora_metaldetecting:server:beginFind', ground)`. Server-side, `kora_metaldetecting:server:beginFind` re-checks that the player is actively detecting, the reported `ground` hash is in `Config.Detection.allowedGrounds`, the per-player cooldown has elapsed, the player still owns a detector, and the skill record loads. Only then does it call `Kora.minigames.authorizeSkillCheck(src, Config.Skill.name, 'skillbar', Config.Detection.minigame)`, store the returned `authorization` in `pendingFinds[src]`, and return it to the client. Any failed check returns `false` and the client aborts the find silently.
- 2. Client plays the `skillbar` minigame locally with that authorization: `Kora.minigames.play('skillbar', nil, authorization)`. It only proceeds if the result reports `success` and includes a `proof` string.
- 3. Client plays a short digging animation/wait, then fires the net event `kora_metaldetecting:server:completedFind(ground, proof, authorization)`.
- 4. Server-side, `kora_metaldetecting:server:completedFind` re-checks detecting state, ground and cooldown again, then requires `proof` to be a string, `authorization` to equal the stored `pendingFinds[src]` (so a stale or foreign authorization is rejected), and `Kora.minigames.consumeProof(src, proof, 'skillbar', authorization)` to succeed. `pendingFinds[src]` is cleared once the proof has been accepted (a rejected attempt returns early and leaves it in place until the next `beginFind` overwrites it, the player unloads or drops, or detecting stops), and `consumeProof` is a one-shot check — it only verifies and finalizes a token kora_lib itself issued and tracks, so the exact token format and its consumption bookkeeping live inside kora_lib, not this resource. Only after that does `chooseLoot(level, false)` pick a random eligible item (uniformly at random among the items unlocked at or below the player's skill level; clumps are allowed here, unlike a wash) and `Core:addItem` grants it, followed by skill XP via `exports.kora_skills:addRep`.
- A failed `addItem` (e.g. full inventory) stops before any XP is granted and notifies the player, without refunding anything (nothing was removed yet). The find cooldown is only reset after a successful grant.

## Washing a clump (current, verified flow)

Mirrors the find flow with the same authorize → play → consumeProof pattern, scoped to a configured wash spot instead of a ground check:

- `kora_metaldetecting:server:beginWash(washIndex)` requires the player to be within `Config.Selling.interactionDistance` of `Config.Selling.wash[washIndex]` and to own at least one clump, then authorizes the same `skillbar` minigame and stores the authorization in `pendingWashes[src]`.
- The client plays the minigame, then runs a 5-second progress bar ("Washing clump...") before firing `kora_metaldetecting:server:washedClump(washIndex, proof, authorization)`.
- The server re-validates distance and clump ownership, then requires the same proof/authorization match against `pendingWashes[src]` and a successful `Kora.minigames.consumeProof(src, proof, 'skillbar', authorization)` before removing one clump and granting loot via `chooseLoot(level, true)` — the `wash = true` flag excludes plain clumps from the reward pool, so washing cannot just return another clump. If granting the reward item fails (e.g. full inventory), the clump already removed is refunded back to the player and nothing else happens.

## Shop and catalog UI

- The vendor ped (per `Config.Selling.shop` entry) opens a `Kora.nui` app (`kora_metaldetecting:shop`) with Buy and Sell tabs. Buying triggers `kora_metaldetecting:server:purchasedDetector(shopIndex, account)` (cash or bank); selling triggers `kora_metaldetecting:server:soldLoot(shopIndex, item, amount)`, both of which re-check proximity to the shop server-side and are rate-limited.
- The `/metaldetectcatalog` command opens a read-only catalog app listing every configured find, locked/unlocked at the player's current skill level, its XP and (if sellable) its sell price.

## More detail

- [Shop and catalog UI](./ui.md) - the player-facing walkthrough of the shop, detecting, washing and catalog panels.
- [Items](./items.md) - the loot table, levels, XP and sell values.
- [Commands](./commands.md) and [Events](./events.md) - the command, callbacks and net events used above, with rate limits.
- [Troubleshooting](./troubleshooting.md) - common problems.

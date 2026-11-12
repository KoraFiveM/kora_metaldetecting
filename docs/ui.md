---
title: Shop and catalog UI
sidebar_position: 9
---

# Shop and catalog UI

## Shop

Walk to a shop ped and use its target option (default "Open Metal Detector Shop"). Shop peds are created and frozen by the server and made invincible by clients that have them in range. The app `kora_metaldetecting:shop` has two views:

- **Buy** - the detector with two buttons, "Pay Cash" and "Pay Card" (bank), each with a confirmation. The window closes afterwards.
- **Sell** - lists the sellable items (those in `Config.Loot.sellValues`) the player currently holds, with the price each. "Sell" asks for a whole amount (1 to 100 in the form) and pays cash. The list refreshes after each sale.

## Detecting

1. Use the `metaldetector` item. A detector prop is attached and a walking animation plays.
2. Walk on suitable ground; a text UI shows whether the ground is suitable (if `showText` is on). The countdown only runs on suitable ground.
3. At zero: "You may have found something", then pass the skillbar, then the dig animation plays and the find is added.
4. Repeat. Use the item again, die, or enter a vehicle to stop.

## Washing

Use "Wash metal clump" at a wash spot with a clump in your inventory: pass the skillbar, then wait for the 5 second progress bar (cancellable). On success the clump is replaced by another find.

## Catalog

`/metaldetectcatalog` opens a panel with "Your Level", "Max Level" and every loot entry sorted by level, marked unlocked or locked, with its XP per find and sell price if any. Escape closes it.

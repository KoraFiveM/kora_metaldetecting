---
title: Database
sidebar_position: 10
---

# Database

The resource defines no tables, runs no SQL and ships no SQL file. All state (active detectors, cooldowns, pending finds and washes) is kept in server memory and cleared when the player unloads, drops, or the resource restarts. Items, money and skill progress are stored by `kora_core`, `kora_inventory` and `kora_skills`.

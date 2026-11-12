---
title: "Commands"
sidebar_position: 4
---


# Commands

Kora Metal Detecting registers one client-side command.

## Built-in commands

### `metaldetectcatalog`

Opens the read-only "Metal Detecting Catalog" NUI app showing every configured find, which are locked/unlocked at your current level, and their sell prices.

| Field | Details |
| --- | --- |
| Context | In-game · client command |
| Arguments | No arguments. |
| Access | Any player. |

**Example**

```text
/metaldetectcatalog
```

**Result**

Opens the `kora_metaldetecting:catalog` NUI app.

The command is registered in `client/catalog.lua` with `RegisterCommand` and has no permission check. See [Events and callbacks](./events.md) for the net events and callbacks the resource uses.

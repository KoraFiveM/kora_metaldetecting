# kora_metaldetecting agent guide

`kora_metaldetecting` is a Kora metal detecting activity: players buy a detector from a shop ped, search suitable ground with a `kora_lib` skillbar minigame, wash clumps and sell finds, with progression through `kora_skills`. Layout: `fxmanifest.lua`, `shared/config.lua` (config and validation), `server/main.lua` (authority: detecting, loot, purchase, sale, wash, shop ped), `client/main.lua` (detector loop, wash), `client/catalog.lua` (`/metaldetectcatalog`), `client/shop.lua` (shop app and ped target) and `tests/` (kora_qa feature files).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first for an overview of features, configuration, commands, exports, events and database usage.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.

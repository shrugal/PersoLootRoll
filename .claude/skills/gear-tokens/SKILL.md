---
name: gear-tokens
description: Update the class set token lists in Data/Items.lua from wago.tools DB2 data, verified against Wowhead tooltips. Use when a new raid tier ships, or when tokens are missing from Self.GEAR_TOKENS or Self.OMNI_TOKENS.
---

# Gear tokens

`Self.GEAR_TOKENS` in [Data/Items.lua](../../../Data/Items.lua) maps a class set token item to the slot it
turns into, and `Self.OMNI_TOKENS` does the same for tokens that grant any set slot. Neither list can be
generated in game like the trinket and instance lists, because the game gives no slot for a token item.

The slot is available outside the game. A modern token is a "Use:" item, and its spell description names
the slot: "Synthesize a soulbound Manaforge Omega set head item appropriate for your class." That gives
a chain from the spell text back to the token item.

## Source

Three DB2 tables from wago.tools, joined by the script in `scripts/gen_gear_tokens.py`:

1. `Spell`, filtered to descriptions containing "a soulbound", for the spell ID and the slot word.
2. `ItemEffect`, for the item effect that casts that spell.
3. `ItemXItemEffect`, for the item that carries the effect.

Every derived token is then checked against its Wowhead tooltip, which drops unreleased placeholder
items and catches a join that went wrong.

## Procedure

Run the script from the repository root:

```sh
python .claude/skills/gear-tokens/scripts/gen_gear_tokens.py
```

It reads the live build from the client's `.build.info`, downloads the three tables, compares the result
against the current `Self.GEAR_TOKENS`, verifies anything new on Wowhead and prints the Lua block to add.
Useful flags:

- `--build 12.1.0.69814` pins a build instead of reading `.build.info`.
- `--all` prints the whole table rather than only the missing entries, for a full regeneration.
- `--no-verify` skips the Wowhead check when that site is unreachable.

Then:

1. Paste the printed block at the bottom of `Self.GEAR_TOKENS`, keeping the `-- T<number>: <raid>` comment
   format and the existing order, which is ascending item ID.
2. Take the tier number from the previous block and add one. The script prints the drop source of the first
   new token, which names the raid.
3. Add the tier's omni token by hand, as described below.
4. Append a bullet to [CHANGES.md](../../../CHANGES.md), for example
   `Add class set tokens for The Voidspire`.

## Omni tokens

An omni token has no use effect, so the join never finds it. Each tier has one, and its item ID sits
next to the twenty class tokens, either just after them or just before. Its tooltip has no "Use:" line
and points at the Catalyst NPC instead. Confirm the ID and name with:

```sh
curl -s "https://nether.wowhead.com/tooltip/item/249367?locale=0"
```

Then add it to `Self.OMNI_TOKENS` with all five slots, matching the entries already there.

## Limits

- The two oldest tiers in the list, item IDs 191002 to 191021 and 196586 to 196605, use the older wording
  "Create a soulbound ... Class Set item", which has no slot in it. The script cannot derive those, and it
  leaves them alone. Their slot is in the item name instead.
- Weapon tokens are not in either list. They are recognised by expansion and item subtype in
  `Item:IsWeaponToken`.
- A filtered CSV request against a large table such as `ItemSparse` times out with a 504. The three tables
  used here are small enough.

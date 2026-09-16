---
name: journal-lists
description: Update the instance and trinket lists in Data/ from wago.tools DB2 data and Wowhead spec lists, instead of the in-game /plr instances and /plr trinkets scans. Use after a content patch adds instances or trinkets.
---

# Instance and trinket lists

`Self.INSTANCES` in [Data/Instances.lua](../../../Data/Instances.lua) and `Self.TRINKETS` in
[Data/Items.lua](../../../Data/Items.lua) are normally produced in game by `/plr instances` and
`/plr trinkets`, which walk the Encounter Journal. Both can be derived outside the game from the
same data. The class set token lists are a separate job, see the `gear-tokens` skill.

Run the scripts from the repository root. Each reads the live build from the client's `.build.info`,
compares against the list in the file and prints only what is missing, in the format the in-game
exporter uses.

## Instances

```sh
python .claude/skills/journal-lists/scripts/gen_instances.py
```

`JournalTierXInstance` is the instance-to-tier mapping, and sorting `JournalTier` by its `Expansion`
column gives the tier numbers the addon uses, Classic 1 through Midnight 12. The last tier is
"Current Season", which repeats instances from earlier tiers, so the script skips it the same way
`EJ_GetNumTiers() - 1` does in game. `JournalInstance` supplies the names for the comments.

This reproduces the list exactly. Checked against the list as scanned in April 2026, all 208 entries
matched with no mismatches and nothing missing, so `--all` output can replace the table wholesale.

## Trinkets

```sh
python .claude/skills/journal-lists/scripts/gen_trinkets.py --check          # compare, change nothing
python .claude/skills/journal-lists/scripts/gen_trinkets.py --tier 12        # additions from Midnight instances
```

Two steps:

1. The pool of journal trinkets is `JournalEncounterItem` joined to `Item` on `InventoryType` 12.
2. The spec set per trinket comes from `ItemSpecOverride`, which the script turns into the attribute
   and role mask with the same rules as `Self.UpdateInstanceTrinkets`, using the six reference specs
   of `Self.TRINKET_SPECS`.

A trinket that fits every attribute or every role is not restricted by it, so its mask comes out as 0
and the script drops it, which is what the in-game scanner does as well.

Checked against a fresh `/plr trinkets` scan on 2026-09-16: **all 818 listed trinkets that have
override rows derive to exactly the scanned value.** That check included nine entries where the two
had disagreed before the rescan, and the scan moved every one of them to the derived value, so the
old list was stale rather than the derivation wrong.

Flags: `--check` compares and changes nothing, `--tier N` limits additions to instances of that
expansion tier or higher, `--build` pins a build, and `--wowhead` is described below.

### Always pass --tier for additions

The pool is a superset of the list, 1253 against 1016. Most of the surplus are trinkets with no
restriction, which drop out at mask 0, but roughly fifteen are legacy items the journal no longer
shows in game even though their DB2 rows are still there. Without `--tier` the script offers those as
additions and they come straight back after a scan has removed them. The gating columns on
`JournalEncounterItem`, `DifficultyMask` and `WorldStateExpressionID`, do not separate them cleanly,
so the tier filter is the reliable guard. `--tier 12` is Midnight.

For the same reason, treat removals as an in-game decision. The script never proposes them.

### Trinkets without override rows

198 listed trinkets have no `ItemSpecOverride` rows, nearly all of them pre-Legion. The game falls
back to the `ItemSpec` rules against the item's stats there, which would mean reimplementing those
rules and pulling stats out of `ItemSparse`, and `ItemSparse` rejects filtered requests with a 504.

`--wowhead` reads the `"specs"` array off the Wowhead item page for those instead. Keep it for small
runs: Wowhead starts answering 403 after a few hundred requests, and the block lasts a while. It also
lost to `ItemSpecOverride` on several entries that the rescan later confirmed, so it is a fallback
for items that have no override rows, not a second opinion on the ones that do. The script stops the
lookups as soon as it sees a refusal.

New content is well covered without it. Of the 39 trinkets the September 2026 rescan added, 33 had
override rows and all 33 matched; the six that did not were old items reissued through timewalking.

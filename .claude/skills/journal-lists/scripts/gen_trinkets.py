#!/usr/bin/env python3
"""Derive Self.TRINKETS of Data/Items.lua from wago.tools DB2 data.

The in-game scanner asks the Encounter Journal which of six reference specs each trinket shows up
for, and turns that into the attribute and role mask. Offline, the pool of journal trinkets comes
from JournalEncounterItem joined to Item, and the spec set per trinket comes from ItemSpecOverride.
The mask is then built exactly as Data/Items.lua does it.

Trinkets without ItemSpecOverride rows cannot be resolved this way. They are reported separately,
and --wowhead tries to read their spec list off the Wowhead item page instead.
"""

import argparse
import collections
import sys
import time

import gen_instances
import wago

TRINKET_SLOT = "12"

STR, AGI, INT, HEAL, TANK, MELEE, RANGED = 1, 2, 4, 16, 32, 64, 128

# The reference specs of Self.TRINKET_SPECS: Arms, Assassination, Arcane, Marksmanship, Holy, Protection
REFERENCE = {71: STR, 259: AGI, 62: INT, 254: RANGED, 257: HEAL, 73: TANK}


def mask(specs):
    """The category of a trinket, following Self.UpdateInstanceTrinkets."""
    seen = sum(flag for spec, flag in REFERENCE.items() if spec in specs)

    attribute = (seen & STR) \
        + (AGI if seen & AGI or seen & RANGED else 0) \
        + (INT if seen & INT or seen & HEAL else 0)
    role = (seen & TANK) + (seen & HEAL) \
        + (MELEE if seen & STR or seen & AGI else 0) \
        + (RANGED if seen & RANGED or seen & INT else 0)

    # A trinket that fits every attribute or every role is not restricted by it
    attribute = 0 if attribute == STR + AGI + INT else attribute
    role = 0 if role == TANK + HEAL + MELEE + RANGED else role
    return attribute + role


def journal_trinkets(build):
    """Every trinket the Encounter Journal lists as loot."""
    trinkets = {int(row["ID"]) for row in wago.table("Item", build) if row["InventoryType"] == TRINKET_SLOT}
    journal = {int(row["ItemID"]) for row in wago.table("JournalEncounterItem", build)}
    return sorted(trinkets & journal)


def spec_overrides(build):
    """Item id -> spec ids, for the items that have explicit spec rows."""
    overrides = collections.defaultdict(set)
    for row in wago.table("ItemSpecOverride", build):
        overrides[int(row["ItemID"])].add(int(row["SpecID"]))
    return overrides


def item_tiers(build):
    """Item id -> the expansion tier of the instance it drops in, highest one if there are several."""
    instances, _ = gen_instances.derive(build)
    encounters = {
        int(row["ID"]): instances.get(int(row["JournalInstanceID"]), 0)
        for row in wago.table("JournalEncounter", build)
    }
    tiers = {}
    for row in wago.table("JournalEncounterItem", build):
        item, tier = int(row["ItemID"]), encounters.get(int(row["JournalEncounterID"]), 0)
        tiers[item] = max(tiers.get(item, 0), tier)
    return tiers


def lua_line(item, category, name):
    return "    [%06d] = %d, %s-- %s" % (item, category, " " * (3 - len(str(category))), name or "?")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", help="client build, e.g. 12.1.0.69814")
    parser.add_argument("--tier", type=int, help="only offer additions from instances of this expansion tier or higher")
    parser.add_argument("--check", action="store_true", help="report listed trinkets whose category differs, changing nothing")
    parser.add_argument("--wowhead", action="store_true", help="also resolve trinkets without override rows via Wowhead")
    parser.add_argument("--limit", type=int, help="stop after this many Wowhead lookups")
    parser.add_argument("--sleep", type=float, default=2.0, help="pause between Wowhead requests (default 2s)")
    args = parser.parse_args()

    build = args.build or wago.client_build()
    if not build:
        parser.error("no build given and no .build.info found, pass --build")
    print("build %s" % build, file=sys.stderr)

    pool = journal_trinkets(build)
    overrides = spec_overrides(build)
    current = wago.lua_table("Data/Items.lua", "TRINKETS")
    unresolved = [item for item in pool if item not in overrides]
    print("%d journal trinkets, %d listed, %d without override rows" % (
        len(pool), len(current), len(unresolved)), file=sys.stderr)

    derived = {item: mask(overrides[item]) for item in pool if item in overrides}

    if args.wowhead:
        targets = [i for i in unresolved if args.check or i not in current]
        if args.limit:
            targets = targets[:args.limit]
        print("looking up %d trinkets on Wowhead" % len(targets), file=sys.stderr)
        for number, item in enumerate(targets, start=1):
            if number > 1 and args.sleep:
                time.sleep(args.sleep)
            page = wago.item_page(item)
            if not page:
                print("  Wowhead refused [%06d], it rate limits after a few hundred requests" % item, file=sys.stderr)
                break
            derived[item] = mask(wago.item_specs(page))

    if args.check:
        differ = sorted(i for i in current if i in derived and current[i] != derived[i])
        for item in differ:
            print("DIFFERS [%06d] listed %d, derived %d" % (item, current[item], derived[item]), file=sys.stderr)
        missing = sorted(i for i in current if i not in derived)
        print("%d of %d checked entries differ, %d could not be derived" % (
            len(differ), len(current) - len(missing), len(missing)), file=sys.stderr)

    tiers = item_tiers(build) if args.tier else {}

    lines = []
    for item in sorted(set(derived) - set(current)):
        if not derived[item]:  # useful to everyone, the in-game scanner drops these too
            continue
        if args.tier and tiers.get(item, 0) < args.tier:
            continue
        name = wago.item_name(item)
        if not name:
            print("  skipped [%06d]: no such item on Wowhead" % item, file=sys.stderr)
            continue
        lines.append(lua_line(item, derived[item], name))

    still_missing = [i for i in unresolved if i not in current and i not in derived]
    if still_missing:
        print("%d journal trinkets have no override rows and are not listed, run with --wowhead or scan in game:" % len(still_missing), file=sys.stderr)
        print("  " + ", ".join(str(i) for i in still_missing[:20]) + (" ..." if len(still_missing) > 20 else ""), file=sys.stderr)

    if lines:
        print("\n".join(lines))
    else:
        print("nothing to add", file=sys.stderr)


if __name__ == "__main__":
    main()

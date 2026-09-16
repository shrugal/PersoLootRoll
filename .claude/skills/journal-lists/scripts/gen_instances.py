#!/usr/bin/env python3
"""Derive Self.INSTANCES of Data/Instances.lua from wago.tools DB2 data.

The in-game exporter walks the Encounter Journal tiers and writes down the tier of every instance.
JournalTierXInstance holds the same mapping, and sorting JournalTier by its Expansion column gives
the tier numbers the addon uses. The last tier is "Current Season", which repeats instances from
earlier tiers, so it is skipped exactly like `EJ_GetNumTiers() - 1` does in game.
"""

import argparse
import sys

import wago


def derive(build):
    """Instance id -> tier number, and instance id -> name."""
    tiers = sorted(wago.table("JournalTier", build), key=lambda row: int(row["Expansion"]))
    index = {row["ID"]: number for number, row in enumerate(tiers, start=1)}
    names = {int(row["ID"]): row["Name_lang"] for row in wago.table("JournalInstance", build)}

    instances = {}
    for row in wago.table("JournalTierXInstance", build):
        tier = index[row["JournalTierID"]]
        if tier == len(tiers):  # "Current Season"
            continue
        instance = int(row["JournalInstanceID"])
        instances[instance] = max(instances.get(instance, 0), tier)
    return instances, names


def lua_line(instance, tier, name):
    return "    [%04d] = %d, %s-- %s" % (instance, tier, " " * (2 - len(str(tier))), name or "?")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", help="client build, e.g. 12.1.0.69814")
    parser.add_argument("--all", action="store_true", help="print the whole table, not just what changed")
    args = parser.parse_args()

    build = args.build or wago.client_build()
    if not build:
        parser.error("no build given and no .build.info found, pass --build")
    print("build %s" % build, file=sys.stderr)

    instances, names = derive(build)
    current = wago.lua_table("Data/Instances.lua", "INSTANCES")
    print("derived %d instances, %d listed" % (len(instances), len(current)), file=sys.stderr)

    for instance in sorted(set(instances) & set(current)):
        if current[instance] != instances[instance]:
            print("CHANGED [%04d] %s: listed %d, derived %d" % (
                instance, names.get(instance, "?"), current[instance], instances[instance]), file=sys.stderr)
    for instance in sorted(set(current) - set(instances)):
        print("GONE [%04d] listed as tier %d, no longer in the journal" % (
            instance, current[instance]), file=sys.stderr)

    wanted = instances if args.all else {i: t for i, t in instances.items() if i not in current}
    if not wanted:
        print("nothing to add", file=sys.stderr)
        return
    print("\n".join(lua_line(i, wanted[i], names.get(i)) for i in sorted(wanted)))


if __name__ == "__main__":
    main()

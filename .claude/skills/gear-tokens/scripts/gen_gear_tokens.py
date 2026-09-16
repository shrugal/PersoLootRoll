#!/usr/bin/env python3
"""Derive the Self.GEAR_TOKENS entries of Data/Items.lua from wago.tools DB2 data.

A class set token is a "Use:" item whose spell description names the slot it grants. Joining
Spell -> ItemEffect -> ItemXItemEffect therefore gives item id -> slot for every modern token.
Each new token is verified against its Wowhead tooltip before it is printed.
"""

import argparse
import csv
import io
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

CSV_URL = "https://wago.tools/db2/{table}/csv"
TOOLTIP_URL = "https://nether.wowhead.com/tooltip/item/{id}?locale=0"
ITEM_URL = "https://www.wowhead.com/item={id}"
AGENT = {"User-Agent": "Mozilla/5.0"}

# Slot word in the spell description -> constant in Data/Items.lua
SLOTS = {
    "head": "TYPE_HEAD",
    "shoulder": "TYPE_SHOULDER",
    "chest": "TYPE_CHEST",
    "hand": "TYPE_HAND",
    "hands": "TYPE_HAND",
    "leg": "TYPE_LEGS",
    "legs": "TYPE_LEGS",
}

SLOT_RE = re.compile(r"(?:set|Class) (\w+) item", re.I)
TIER_RE = re.compile(r"soulbound (.*?) (?:set|Class) \w+ item", re.I)


def repo_root():
    return Path(__file__).resolve().parents[4]


def client_build():
    """Read the installed client version from the WoW client's .build.info."""
    for folder in repo_root().parents:
        info = folder / ".build.info"
        if not info.exists():
            continue
        rows = list(csv.DictReader(info.read_text(encoding="utf-8").splitlines(), delimiter="|"))
        for row in rows:
            for key, value in row.items():
                if key.startswith("Version!") and value:
                    return value
    return None


def fetch(url, params=None):
    if params:
        url += "?" + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers=AGENT)
    with urllib.request.urlopen(request, timeout=300) as response:
        return response.read().decode("utf-8", "replace")


def fetch_table(table, build, **filters):
    params = {"build": build}
    params.update({"filter[%s]" % key: value for key, value in filters.items()})
    print("  downloading %s" % table, file=sys.stderr)
    return list(csv.DictReader(io.StringIO(fetch(CSV_URL.format(table=table), params))))


def token_spells(build):
    """Spell id -> (slot constant, tier name) for every token spell."""
    spells = {}
    for row in fetch_table("Spell", build, Description_lang="a soulbound"):
        slot = SLOT_RE.search(row["Description_lang"])
        if not slot or slot.group(1).lower() not in SLOTS:
            continue
        tier = TIER_RE.search(row["Description_lang"])
        spells[row["ID"]] = (SLOTS[slot.group(1).lower()], tier.group(1) if tier else "")
    return spells


def token_items(build):
    """Item id -> (slot constant, tier name) for every token item."""
    spells = token_spells(build)
    effects = {
        row["ID"]: spells[row["SpellID"]]
        for row in fetch_table("ItemEffect", build)
        if row["SpellID"] in spells
    }
    return {
        int(row["ItemID"]): effects[row["ItemEffectID"]]
        for row in fetch_table("ItemXItemEffect", build)
        if row["ItemEffectID"] in effects
    }


def current_tokens():
    """Item id -> slot constant, as listed in Data/Items.lua right now."""
    source = (repo_root() / "Data" / "Items.lua").read_text(encoding="utf-8")
    block = source.split("Self.GEAR_TOKENS = {")[1].split("\n}")[0]
    return {
        int(match.group(1)): match.group(2)
        for match in re.finditer(r"\[0*(\d+)\]\s*=\s*Self\.(TYPE_\w+)", block)
    }


def tooltip(item_id):
    try:
        return json.loads(fetch(TOOLTIP_URL.format(id=item_id)))
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError):
        return {}


def verify(item_id, slot):
    """Check that Wowhead knows the item and agrees about the slot."""
    data = tooltip(item_id)
    name = data.get("name")
    if not name or name == "None":
        return None, "no such item"
    text = re.sub("<[^>]+>", " ", data.get("tooltip", ""))
    found = SLOT_RE.search(text)
    if not found or SLOTS.get(found.group(1).lower()) != slot:
        return name, "tooltip says %s" % (found.group(0) if found else "nothing about a slot")
    return name, None


def drop_source(item_id):
    try:
        page = fetch(ITEM_URL.format(id=item_id))
    except (urllib.error.URLError, TimeoutError):
        return None
    found = re.search(r"Dropped by: ([^<\"]+)", page)
    return found.group(1).strip() if found else None


def tiers_of(tokens, gap=1000):
    """Group tokens into tiers. The newest tiers have no name in the spell description, so a jump
    in item ids starts a new tier as well."""
    groups = []
    for item in sorted(tokens):
        name = tokens[item][1]
        if groups and groups[-1][0] == name and item - groups[-1][1][-1] <= gap:
            groups[-1][1].append(item)
        else:
            groups.append((name, [item]))
    return groups


def lua_block(tokens, groups):
    lines = []
    for name, ids in groups:
        lines.append("    -- T?: %s" % (name or "?"))
        lines += ["    [%d] = Self.%s," % (item, tokens[item][0]) for item in ids]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", help="client build, e.g. 12.1.0.69814")
    parser.add_argument("--all", action="store_true", help="print every token, not just the missing ones")
    parser.add_argument("--no-verify", action="store_true", help="skip the Wowhead check")
    args = parser.parse_args()

    build = args.build or client_build()
    if not build:
        parser.error("no build given and no .build.info found, pass --build")
    print("build %s" % build, file=sys.stderr)

    tokens = token_items(build)
    current = current_tokens()
    print("derived %d tokens, %d already listed" % (len(tokens), len(current)), file=sys.stderr)

    for item, (slot, _) in sorted(tokens.items()):
        if item in current and current[item] != slot:
            print("MISMATCH [%d]: listed as %s, derived %s" % (item, current[item], slot), file=sys.stderr)

    wanted = tokens if args.all else {i: t for i, t in tokens.items() if i not in current}
    if not wanted:
        print("nothing to add", file=sys.stderr)
        return

    if not args.no_verify:
        print("verifying %d tokens on Wowhead" % len(wanted), file=sys.stderr)
        for item in sorted(wanted):
            name, problem = verify(item, wanted[item][0])
            if problem:
                print("  dropped [%d] %s: %s" % (item, name or "?", problem), file=sys.stderr)
                del wanted[item]
            else:
                print("  ok [%d] %s" % (item, name), file=sys.stderr)

    if not wanted:
        print("nothing left after verification", file=sys.stderr)
        return

    groups = tiers_of(wanted)
    for name, ids in groups:
        print("tier %s drops from %s (%s)" % (
            name or "unnamed", drop_source(ids[0]) or "unknown", ITEM_URL.format(id=ids[0])), file=sys.stderr)

    print(lua_block(wanted, groups))


if __name__ == "__main__":
    main()

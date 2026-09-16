"""Shared helpers for the journal-lists scripts: wago.tools downloads and Lua table parsing."""

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
ITEM_URL = "https://www.wowhead.com/item={id}"
TOOLTIP_URL = "https://nether.wowhead.com/tooltip/item/{id}?locale=0"
AGENT = {"User-Agent": "Mozilla/5.0"}


def repo_root():
    """The addon folder, four levels above this script."""
    return Path(__file__).resolve().parents[4]


def client_build():
    """The installed client version, from the WoW client's .build.info."""
    for folder in repo_root().parents:
        info = folder / ".build.info"
        if not info.exists():
            continue
        for row in csv.DictReader(info.read_text(encoding="utf-8").splitlines(), delimiter="|"):
            for key, value in row.items():
                if key.startswith("Version!") and value:
                    return value
    return None


def fetch(url, params=None, timeout=300):
    if params:
        url += "?" + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers=AGENT)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read().decode("utf-8", "replace")


def table(name, build, **filters):
    """Download a DB2 table from wago.tools as a list of dicts."""
    params = {"build": build}
    params.update({"filter[%s]" % key: value for key, value in filters.items()})
    print("  downloading %s" % name, file=sys.stderr)
    return list(csv.DictReader(io.StringIO(fetch(CSV_URL.format(table=name), params))))


def lua_table(path, name):
    """Read a `Self.<name> = { [id] = value, ... }` table from a Lua file as {int: int}.

    The exporters print the same assignment as a string, so the last match is the real table.
    """
    source = (repo_root() / path).read_text(encoding="utf-8")
    block = source.split("Self.%s = {" % name)[-1].split("\n}")[0]
    return {
        int(match.group(1)): int(match.group(2))
        for match in re.finditer(r"\[0*(\d+)\]\s*=\s*(\d+)", block)
    }


def item_page(item_id, timeout=60):
    try:
        return fetch(ITEM_URL.format(id=item_id), timeout=timeout)
    except (urllib.error.URLError, TimeoutError):
        return ""


def item_name(item_id, page=None):
    """The English item name, from the page data if it is there, otherwise the tooltip."""
    if page:
        found = re.search(r'"%d":\{"name_enus":"([^"]+)"' % item_id, page)
        if found:
            return found.group(1)
    try:
        name = json.loads(fetch(TOOLTIP_URL.format(id=item_id), timeout=60)).get("name")
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError):
        return None
    return None if name in (None, "None") else name


def item_specs(page):
    """The spec ids Wowhead lists for an item, which is what the journal loot filter goes by."""
    found = re.search(r'"specs":\[([0-9,]*)\]', page)
    return {int(spec) for spec in found.group(1).split(",") if spec} if found else set()

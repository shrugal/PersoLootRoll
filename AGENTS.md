# AGENTS.md

This repo is a World of Warcraft addon written in Lua, built on the Ace3 framework and AceGUI widgets. The entrypoint and file load order are controlled by the TOC, which pulls in one XML include file per folder.

## Project structure

- Root
  - [PersoLootRoll.toc](PersoLootRoll.toc): load order and addon metadata.
  - [Init.lua](Init.lua): global namespace setup, Ace3 addon and module registration.
  - [README.md](README.md): project description, feature list, command reference and build/test instructions.
  - [CHANGELOG.md](CHANGELOG.md), [CHANGES.md](CHANGES.md): release history and notes.
  - [Test.lua](Test.lua): standalone Lua harness that stubs the WoW API so the test suite can run outside the game.
  - [.idehelper.lua](.idehelper.lua): EmmyLua annotations for external classes the language server cannot see.
- Libs/
  - Ace3 (AceAddon, AceComm, AceConfig, AceConsole, AceDB, AceEvent, AceGUI, AceHook, AceLocale, AceSerializer, AceTimer), LibStub, CallbackHandler, LibDataBroker, LibDBIcon.
  - Git submodules and packager externals: LibUtil, LibRealmInfo, LibDataBroker-1.1, WoWUnit.
- Util/
  - [Util/Util.lua](Util/Util.lua): the `Addon.Util` namespace, which inherits everything from LibUtil (`Tbl`, `Str`, `Num`, `Fn`, `Bool`, `Misc`) and adds WoW helpers for groups, instances and loot methods.
  - [Util/Comm.lua](Util/Comm.lua): addon message protocol, chat output and whisper handling.
  - [Util/Locale.lua](Util/Locale.lua): picks the language for a realm or unit so messages reach players in their own language.
  - [Util/Unit.lua](Util/Unit.lua): unit names, realms, classes, specs and group membership.
  - [Util/Counter.lua](Util/Counter.lua), [Util/Registrar.lua](Util/Registrar.lua): data structures. The registrar is a keyed store that fires events on every change and backs extension points like GUI player columns.
- Locale/
  - One file per language, `enUS` first as the fallback. Entries are plain `L["KEY"] = "..."` assignments.
- Data/
  - [Data/Instances.lua](Data/Instances.lua): generated instance list plus the exporter behind `/plr instances`.
  - [Data/Items.lua](Data/Items.lua): item types, gear tokens, class restrictions and the generated trinket list, plus the Dungeon Journal scanner behind `/plr trinkets`.
- Models/
  - [Models/Item.lua](Models/Item.lua): item wrapper that loads link info and decides whether an item is useful for a unit.
  - [Models/Roll.lua](Models/Roll.lua): the central roll object with its status, bids, votes, timers and the full roll lifecycle.
- Core/
  - [Core/Addon.lua](Core/Addon.lua): main addon object, logging, versioning, addon state machine and slash commands.
  - [Core/Events.lua](Core/Events.lua): game event handlers and incoming addon messages.
  - [Core/Hooks.lua](Core/Hooks.lua): hooks into Blizzard frames, group loot rolls, chat links and tooltips.
  - [Core/Options.lua](Core/Options.lua): AceConfig options tables, SavedVariables defaults, migrations, minimap button and addon compartment entry.
- Modules/
  - [Modules/Inspect.lua](Modules/Inspect.lua): inspect queue and cache for other players' gear.
  - [Modules/Session.lua](Modules/Session.lua): masterloot sessions, council setup and rule negotiation.
  - [Modules/Trade.lua](Modules/Trade.lua): trade window automation for handing over won items.
- Plugins/
  - Integrations with other loot addons: [Plugins/EPGP.lua](Plugins/EPGP.lua), [Plugins/PersonalLootHelper.lua](Plugins/PersonalLootHelper.lua), [Plugins/RCLootCouncil.lua](Plugins/RCLootCouncil.lua).
- GUI/
  - [GUI/GUI.lua](GUI/GUI.lua): shared widget helpers, tooltips, dropdowns and the player column registrar.
  - [GUI/Rolls.lua](GUI/Rolls.lua): the rolls overview window and the roll frames.
  - [GUI/Actions.lua](GUI/Actions.lua): the pending actions list.
  - [GUI/Widgets](GUI/Widgets): custom AceGUI widgets.
- Tests/
  - [Tests/Common.lua](Tests/Common.lua): shared helpers and fixtures.
  - Unit tests under [Tests/Unit](Tests/Unit), mirroring the source folder layout.

## Dependencies and toolkits

- World of Warcraft API
  - Blizzard UI: loot and group loot frames, Encounter Journal, inspect, trade, tooltips, Settings and the addon compartment.
  - SavedVariables: `PersoLootRollDB` (AceDB profiles), `PersoLootRollIconDB` (minimap button position), `PersoLootRollML` (last masterlooter), `PersoLootRollDebug` (debug mode toggle).
- Ace3
  - The addon object mixes in AceConsole, AceComm, AceSerializer, AceEvent, AceTimer and AceHook. Modules are created with `Addon:NewModule` and the custom `Module` prototype in [Init.lua](Init.lua).
  - Options run through AceConfig, AceConfigDialog and AceDBOptions. All UI is built with AceGUI, there are almost no XML frame definitions.
- Optional addon integrations (declared in TOC)
  - Pawn for stat weights, EPGPNext for EP/GP handling, WoWUnit for in-game tests.
  - Protocol level compatibility with PersonalLootHelper and RCLootCouncil, so groups running those addons still see bids and awards.
- Localization
  - AceLocale with `enUS` as the fallback. Chat messages also exist per language, so PLR can whisper players in the language of their realm.

## Feature overview

- Goal: bring Need/Greed back to personal loot and make asking for, giving away and trading items as automatic as possible.
- Rolling
  - Detects tradable items dropping for group members and offers a Need/Greed/Pass window when the item might be an upgrade.
  - Offers a Keep/Greed/Give Away window for items you loot yourself, announces the give away in chat and picks a winner.
  - Filters candidates by item level, class and spec restrictions, trinket suitability, transmog and Pawn scores, so players are only asked when it makes sense.
- Communication
  - Addon messages between PLR users keep rolls in sync without chat spam, with whisper fallback for players without the addon.
  - Customizable whisper and group chat messages, automatic answers to incoming requests and whisper suppression.
- Masterloot
  - One player takes the masterlooter role, sets rules, custom answers and a loot council, and awards items to bidders.
- Actions and trading
  - Pending actions (ask, bid, trade) are listed on screen with buttons to complete them, and the trade window is filled automatically.
- Commands
  - `/plr` opens the rolls window. See the command list in [README.md](README.md) for the rest, including `/plr log` for bug reports and the `trinkets` and `instances` data generators.

## Coding style and conventions

- Lua + EmmyLua annotations
  - Frequent use of `---@class`, `---@type`, `---@param`, `---@return`, and `---@field` on model classes.
  - Types that the language server cannot infer belong in [.idehelper.lua](.idehelper.lua).
- Namespacing
  - Every file starts with `local Name = ...` and `local Addon = select(2, ...)`, then binds the namespaces it needs in one line: `local Comm, GUI, Util = Addon.Comm, Addon.GUI, Addon.Util`.
  - The file's own namespace is always bound as `local Self = Addon.<Name>`, declared with a matching `---@class`.
  - Namespace tables are created up front in [Init.lua](Init.lua), so load order stays flexible.
  - The public global is `PLR`, and `Addon.ABBR` is `"PLR"`.
- Functions and data
  - Plain namespace functions use `function Self.Name(...)`. Method style `function Self:Name(...)` is reserved for the addon object, Ace3 modules and model instances.
  - Constants are uppercase fields on the namespace (`Self.TIMEOUT`, `Self.BID_NEED`), with a list of all valid values next to them where one is useful (`Self.BIDS`).
  - Models are created with `setmetatable(t, Meta)` where `local Meta = { __index = Self }`.
- Formatting
  - 4-space indentation, no trailing semicolons.
  - Section separators are a comment block of dashed lines with the centered section name, as in [Core/Addon.lua](Core/Addon.lua).
- UI
  - Build UI with AceGUI and the helpers in [GUI/GUI.lua](GUI/GUI.lua). Add new columns through `GUI.PlayerColumns` instead of editing the table layout directly.
- Text shown to players
  - Never hardcode player-facing text. Add a key to [Locale/enUS.lua](Locale/enUS.lua) and use `L["KEY"]`. Other languages are maintained by translators on CurseForge.

## Testing

- The suite runs in two places from the same files: in game through the WoWUnit addon, and on the command line through [Test.lua](Test.lua), which stubs the WoW API.
- Run `lua Test.lua` to test the working copy, or `lua Test.lua -b` to test a finished build in `.release/`.
- CI runs `lua Test.lua` on every push and `lua Test.lua -b` for release tags.
- Tests live in [Tests/Unit](Tests/Unit), mirroring the source layout, and are registered in [Tests/tests.xml](Tests/tests.xml). The folder is loaded only from the `#@do-not-package@` block of the TOC, so it never ships.

## Releases

- Changelog files
  - [CHANGES.md](CHANGES.md) holds the notes for the *next* release only. The packager ships it verbatim as the release description on every site (`manual-changelog` in [.pkgmeta](.pkgmeta)), so write it for players, not for developers.
  - [CHANGELOG.md](CHANGELOG.md) is the full history and always lags one release behind.
  - Append a bullet to the bottom of CHANGES.md in the same commit as the change itself.
  - In the first commit after a tag, move the CHANGES.md content into CHANGELOG.md as a new `Version <tag>` section at the top, then replace CHANGES.md with the entries for the next release. The tagged commit itself does not touch either file.
- Changelog writing style
  - See "Writing texts for humans" below, it applies here
  - Section format: `Version 25.02`, blank line, `- ` bullets, blank line before the next section. No markdown headings, no trailing periods.
  - Minor versions are zero-padded to two digits (`25.09`, `25.10`), major bumps use `.00` (`26.00`).
  - Imperative mood, capitalized: `Add ...`, `Fix ...`, `Improve ...`, `Update ...`, `Show ...`, `Make ...`, `Allow ...`, `Don't ...`. Older entries use past tense; don't copy that.
  - Order within a section: additions, then changes and improvements, then fixes, then `Internal: ...` bullets for refactors with no visible effect.
  - Describe the visible behavior, not the implementation: "Fix error when bidding on items without an owner", not "Add nil check in Roll:Bid".
  - Game patch compatibility bumps get their own bullet instead of being folded into another one, even when the release also contains other changes: `Update ToC version for patch 12.0.5`.
- Triggering a release
  - Releases are driven entirely by git tags pushed to `origin`, there is no manual upload step.
  - Tag names must match `^\d(\.?\d+)*((-(next|ptr|live))?(-(debug|alpha|beta|stable))?\d+)?$` (`25.02`, `25.03-beta1`, `26.00-alpha1`), otherwise the build, test and deploy jobs don't run.
  - The tag becomes the addon version: [PersoLootRoll.toc](PersoLootRoll.toc) carries `## Version: @project-version@`, which the packager substitutes. The `#@do-not-package@` block at the end of the TOC keeps local checkouts on `0-dev0`.
  - Release type follows the tag name: `alpha`/`debug` -> alpha, `beta`/`next`/`ptr` -> beta, anything else -> full release. An untagged build is always alpha.
- Cutting a release
  - ALWAYS ask before the final step (push) of a release, even when asked to create a release
  - Check that CHANGES.md covers every user-visible change since the last tag, in the style above.
  - Bump `## Interface:` in [PersoLootRoll.toc](PersoLootRoll.toc) if the release targets a new game patch.
  - Commit, tag that commit with the bare version number, and push both: `git push origin master --tags`.
  - Only increase the major version when specifically asked to, usually increase the minor version.
  - Watch the GitLab pipeline. The test job runs against the built package, then the five deploy jobs publish to CurseForge, WoWInterface, Wago, GitHub and GitLab.
  - In the next commit, roll CHANGES.md into CHANGELOG.md under the tag just pushed.

## Practical guidance for agents

- Respect load order when adding files. Add the file to the XML include of its folder, and add new folders to [PersoLootRoll.toc](PersoLootRoll.toc).
- Declare a new namespace or module in [Init.lua](Init.lua) before using it anywhere else.
- When adding settings, extend `Self.DEFAULTS` and the options tables in [Core/Options.lua](Core/Options.lua) together, and add a migration step if an existing key changes shape.
- When integrating with other addons, gate everything on an availability check and follow the existing plugin modules in [Plugins](Plugins).
- The lists in [Data](Data) are generated in game. Regenerate them with `/plr trinkets` and `/plr instances` after a content patch instead of editing them by hand.
- Run the test suite with `lua Test.lua` before committing changes to `Util`, `Models` or `Core`.
- Upstream source and issue tracker live at https://gitlab.com/shrugal/PersoLootRoll, with release info and wiki pages on CurseForge.
- A documentation of the World of Warcraft API can be found at https://warcraft.wiki.gg/wiki/World_of_Warcraft_API

## Writing texts for humans (comments, docs, changelogs)

- **Write complete sentences**, not parts stitched together with "-" or ";". No em dashes and no
  semicolons: a clause worth setting apart is worth its own sentence, and where the aside is a list,
  a colon does the job. En dashes stay in ranges (`4–20 minutes`, `Name A–Z`) — a dash is never a
  stand-in for a missing value ("Not known" says that instead).
- **Focus on what is or what should be done**. Don't explain the reason unless it's relevant for decisions
  the user has to make. Don't mention what potential alternatives have not been realized.
- **Don't list every option**, just the most relevant/common/likely ones.
- **Banned outright**, because they read as filler or as jargon a reader cannot act on: honest(ly),
  genuine(ly), load-bearing, footgun, blast radius, circuit breaker, gate(d), critical(ly), clean(ly),
  precise(ly), robust, seamless(ly), comprehensive(ly), bespoke, delve, nuanced, multifaceted, pivotal,
  leverage. Also banned as sentence frames: "measured rather than assumed", "shown rather than hidden",
  "worth noting", "important to remember", "exactly as designed".

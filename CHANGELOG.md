Version 24.02

- Fix usages of some removed global constants

Version 24.01

- Add evoker class info
- Fix usages of some removed global methods
- Update ToC version
- Updated instance and trinket lists

Version 24

- Updated ToC version for patch 10.0
- Update Ace3 libraries
- Fix GUI bugs from 10.0 changes
- Update instance and trinket lists

Version 23.03

- Updated ToC version for patch 9.2.5

Version 23.02

- Updated ToC version for patch 9.2
- Updated instance and tricket lists
- Added support for T29 armor tokens

Version 23.01

- Updated ToC version for patch 9.1.5

Version 23

- Updated ToC version for patch 9.1
- Updated instance and trinket lists

Version 22.07

- Updated toc version for patch 9.0.5
- Updated russion and italian translation (Thanks Voopie and Wildlord!)
- Updated trinket list
- Updated LibRealmInfo

Version 22.06

- Added option to disable all filters and show all usable loot
- Added options to enable addon and chat messages in outdoor zones, disabled by default
- Improved calculating min ilvl for a slot during leveling
- Improved calculating min ilvl for weapon slots
- Take dual-wiedling into account for appropriate classes and specs
- Fixed sometimes showing rolls twice in groups with other PLR users
- Fixed handling of some ranged weapons
- Fixed offering melee weapons to BM and MM hunters
- Fixed error when disabling addon
- Fixed not taking items in the main bag into account

Version 22.05

- Support for Shadowlands weapon tokens
- Updated Shadowlands trinket list

Version 22.04

- Updated TOC version for patch 9.0.2
- Updated Ace3 libs to latest stable version
- Updated LibRealmInfo

Version 22.03

- Use build-in transmog collection system to detect missing appearances
- Update weapon restrictions for Deathknights and Monks
- Always allow trading if noone else needs the item
- Check popup data before using it to prevent conflicts with other popups

Version 22.02

- Require items to have higher item-level than whats currently equipped in legacy runs
- Fixed starting scheduled rolls without checking them first sometimes
- Fixed considering some armor items as pets
- Fixed sometimes not using concise announcements when we should
- Fixed following detection in German clients

Version 22.01

- Replaced access to removed friend-list functions

Version 22

- Updated TOC version to 9.0.1
- Updated instance and trinket lists for Shadowlands
- Updated Ace3 to latest version
- Properly handle shadowlands conduits and legendaries
- Added support for rolling on and checking for missing pets
- Added option to roll on missing transmog items, not just missing appearances
- Added info message when entering old instances with all collectible filters turned off
- Added option to enable/disable chat messages in legacy runs
- Added suppressing whispers and announcements by shift-clicking the bid button
- Removed PLR prefix from concise announcements
- Improved handling of item links in difference languages
- Use the build-in legacy loot detection instead of a custom implementation
- Updated legacy-run detection for new player levels
- Cleaned up error messages in log
- Reordered item filter options
- Disable addon in horrific visions (a bit late I guess :/)
- Fixed trinket list generation
- Fixed frames with missing backdrops
- Fixed considering some non-equippable items transmoggable
- Fixed considering legion relics useful for players above legion max level
- Fixed access to removed constants
- Some small player level related fixes

Version 21.04

- Use concise announcements for groups up to 10 players in legacy runs (was 5).
- French translation completed, big thanks to Llathala (EU-Hyjal)!
- Some esES and zhCN translation updates.

Version 21.03

- More detailed info messages when not whispering players
- Fixed updating whisper ask option when target or group filter changes
- Fixed filtering items before they've been loaded (CurseForge#16)
- Internal: Added and updated some unit tests

Version 21.02

- Updated legacy loot detection for legion dungeons

Version 21.01

- Fixed Unit.ConnectedRealm for realms without connections (CurseForge#15)

Version 21

- Added proper whisper handling across connected realms (#14)

Version 20.01

- Fixed wrong Util.In references in Util.Str (#13)
- Internal: Added unit tests for Util.Str

Version 20

- Updated interface version for 8.3
- Updated instance and trinket lists for 8.3
- Reduced default extra timeout per item from 10 to 5
- Fixed rolls window layout update after filtering
- Some minor bugfixes
- Internal: Moved utility functions into external LibUtil library
- Internal: Some more unit tests

Version 19

- Added item filter on the left side of the roll overview window
- Added unit testing, they won't be included in releases but should help detect bugs early
- Updated readme
- Includes updated translations

Version 18.06

- Updated interface version for 8.2.5

Version 18.05

- Added prompt asking whether to enable automatic whispering on first bid
- Added info message when masterloot offers are rejected due to missing permission
- Added warning about freezing screen when showing the log
- Made rolls window background a bit darker to improve readability
- Unresolved rolls owned or bid on by the player are now shown in the actions list as "wait" entries
- Moved chat message pattern generation to `RegisterEvents()` to take modifications by other addons into account

Version 18.04

- Fixed error when mousing over entries in the rolls window since 8.2

Version 18.03

- Updated TOC version to 8.2
- Updated instance and trinket lists

Version 18.02

- Fixed answering whispers when not using ML mode or "allow keep" ML option is enabled
- Fixed whisper handler when giving away multiple items

Version 18.01

- Fixed processing and showing whispers and answers multiple times
- Answer bids from the same player and for the same roll just once
- Includes updated zhTW translations

Version 18

- Added ML option to only start rolls manually
- Added ML option to run rolls in-order (one by one)
- Added roll start button to rolls window and moved some other buttons around
- Added rate limit of 10 errors/sec to error handler
- Debounced roll window updates after roll changes to prevent flickering
- The roll hide/show button is now always shown, regardless of roll status
- Instances one expansion below the player are now considered transmog runs
- Added many missing annotations in the code and removed unused imports and local variables
- Fixed some minor bugs found through static analysis
- Fixed item column overflowing in rolls window

Version 17.03

- Fixed trying to import/export ML settings without guild/community selected
- Added missing language files for esMX, itIT, frFR and ptBR (though most of them don't have translations yet)
- Includes updated zhCN and frFR translations

Version 17.02

- Added ignoring crafted loot
- Fixed Unit.IsUnit for non-string parameters (CurseForge#11)
- Fixed Locale.GetLanguageName for missing language code translations (CurseForge#12)

Version 17.01

- Added some more debug messages for UI interactions
- Added handler to log LUA errors caused by the addon
- Reduced LOG_MAX_ENTRIES from 1000 to 500, because showing the log takes a lot of time with many entries
- Fixed missplaced table row backgrounds and highlights when the content is scrolled in the main window
- Some cleanup

Version 17

- Replaced multiselect message options with dropdowns to free up some space
- When awarding loot in the rolls window the button text now turns to "Confirm" on the 1st click and then actually awards the item on the 2nd click
- Added option to make group announcements concise when there are just a few items and eligible players (e.g. in 5-mans)
- Added some more answer messages for bids via whisper
- Added message lines for when someone wins his/her own item
- Added ML option to allow players to keep their own loot
- Added ML option to start rolls when whispered with a key word
- Added ML option to start rolls for all users without addon
- Added masterloot settings option to ML dropdown in roles window
- EPGP tab is now always shown, added a warning for when "EPGP Next" addon is missing
- Added checking min. required char level for items, incl. an option to adjust the threshold
- Updated ilvl threshold options and wording
- Skip Pawn checking when determining the usefulness of trinkets
- Updated LibRealmInfo to current version
- Updated trinket list
- Fixed log exporting when LibRealmInfo doesn't give us any realm data
- Fixed item class restriction parsing
- Fixed missing transmog not being considered on lower level items
- Fixed checking transmogs of rings, trinkets and necks
- Fixed being able to roll on canceled rolls
- Fixed automatically answering players we currently want an item from as well
- Fixed showing the same whipser line twice in the actions window
- Fixed bug when checking whether a roll can be awarded randomly in the Rolls GUI
- A bunch of other bugfixes
- Switched to automatically packaging releases
- Up to date localizations are now downloaded when packaging

Version 16.05

- Fixed trying to send group messages when not in a group

Version 16.04

- Fixed rolls window now updating when scroll bar is shown or hidden
- Fixed actions window not showing when loot has been awarded
- Fixed roll duplication in ML mode
- Fixed player link brackets in info messages
- Item link parsing now correctly takes numBonusIds into account
- Updated esES and zhCN translations

Version 16.03

- Fixed Util.TblRandomKey for empty tables
- Fixed Util.TblCopyXYZ methods not producing a continually indexed list when k is false

Version 16.02

- Fixed Roll.Find for when owner is nil
- Fixed Roll awarding methods
- Fixed rolls not showing up on the rolls window
- Fixed updating status after trading when in ML mode

Version 16.01

- Updated translations
- Fixed Addon.UnitIsTracking not using the new Addon.GetCompAddonUser function
- Fixed Rolls.ROLL_START function parameters
- Changed module event handlers to always implicitly accept the self parameter

Version 16

- Major internal refactoring:
  - Moved non-core functionality (Session, Inspect, Trade and GUI) into separate Ace3 modules with their own lifecyles and event-handling
  - Moved PLH integration into separate Ace3 plugin module
  - Moved config to separate Options file
  - Changed PLH user checks and version storage to a generic system for compatible addons
  - Files in subfolders are now loaded using xml files
  - Internal events now use the AceEvent messaging API instead of a separate event bus for every class
  - Added documentation for internal events
  - Updated addon lifecycle to use use proper Ace3 enable/disable events and go through different states (disabled, enabled, active, tracking) one after the other
  - Events and Hooks now use the Addon namespace and are unregistered when disabling the addon
- Extensibility:
  - Added ability for plugins to register custom player columns in the rolls window
  - Added ability for plugins to register custom options
  - Added ability for plugins to register custom roll award methods
- Added EPGP plugin:
  - Added EP, GP and PR columns to rolls window, as well as sorting eligible players by PR value
  - Added awarding by PR value
  - Added crediting GP when awarding loot in ML mode
  - Added tab to masterloot options to enable/disable EPGP integration and set GP weights for different bids
- Added work-in-progress version of RCLootCouncil integration plugin (disabled for now)
- Added ability to start test rolls (/plr test or button at the top right corner of the rolls window)
- Added row backgrounds to rolls in the rolls window
- Increased actions window min. size
- A ML is now always considered being on his/her own council
- Updated trinket and instance lists for 8.1, /plr trinketsand /plr instances now work regardless of whether debug is enabled
- Replaced the removed ChatFrame_SendSmartTell with ChatFrame_SendTell
- Updated TOC version for 8.1

Version 15.04

- Fixed isTradable overwrite in Item:GetBasicInfo
- Item owners can now always roll on their own items (without ML)

Version 15.03

- Fixed bug in Util.TblList (#8)
- Prefer running rolls when matching links posted in grp chat to rolls (#8)
- Added some debug messages to roll methods

Version 15.02

- Fixed disabled state not being send on version check
- Fixed roll status validation for chill-mode rolls
- Updated debug log formatting
- Added some logging around random rolls in chat
- Changed some logging calls to put the biggest data entries last for improved readability
- Removed whisper message content in debug calls

Version 15.01

- Fixed chill-mode not working for loot from non-users
- Fixed rolls popping up while addon is disabled

Version 15

- Added enabling/disabling based on group type
- Added Spanish and Simplified Chinese translations
- Added partial Russian translation (~80%)
- Added option to disable ask variants
- Added an optional "chill mode": Removes the countdown while deciding to share loot, items show up for others only after that decision, and own rolls have double the normal timeout once they started
- Increased timeouts:
  - Increased base roll timeout from 15 to 20
  - Increased roll timeout per item from 5 to 10
  - Increased roll clear timeout from 600 to 1200
  - Increased max base timeout in ML mode from 120 to 300
  - Increased max timeout per item in ML mode from 30 to 60
- Added Disenchant support:
  - Added support for rolling disenchant on items
  - Added option to allow disenchant bids on own items or when masterlooting
  - Added disenchanter list in masterloot options
  - Added option to automatically roll disenchant on unusable items if allowed
  - Added new message lines for disenchanting
  - Added proper reason messages for the roll window
- The order of arguments for the "roll" command doesn't matter anymore
- Added error messages to the "roll" command for wrong timeout or owner
- Updated "roll" command logic to prevent creating rolls that will be rejected by others
- The "Bid" command now creates rolls if it can't find them, works for bids specified by their names (e.g. "Need") as well as custom masterloot bids, and it defaults to "Need" when no bid is given
- Updated readme file
- Fixed masterloot rules widgets widths problems caused by the scroll bar
- Added connected realm indentifier generation, to be used for profile+realm configs
- Version messages now contain the full version string, incl. channel and revision
- Replaced deprecated VERSION_ASK event with the new CHECK event
- Added eligible count to roll status and added check before declaring interest on pending rolls
- Updated deDE and zhTW translations
- Fixed Util.IsCommunityGroup when GetRaidRosterInfo is nil
- Fixed pending rolls showing for non-owners
- Fixed chat button right click to open message options
- Fixed toggle-all button not working
- Fixed bug in custom answers dropdown (#7)
- Minor fixes

Version 14

- Added visible random roll results to every non-pass bid
- Session.RefreshRules is now debounced by 1 sec
- Readded refreshing the session when changing relevant options
- Units can now only bid when they haven't already, or when they did and want ot pass
- Added option to double ilvl threshold for rings
- Fixed council selection by community rank
- Fixed custom roll answers being rejected as invalid
- Fixed votes tooltip not showing
- Minor refactoring

Version 13

- Announce and whisper settings can now be based on whether or not the player is in a WoW-Community group or the target is in one of the player's WoW-Communities
- The need button is now changed into a keep button when rolling on our own loot without masterlooter
- The pass button is now changed into a give-away button when rolling on our own loot without masterlooter
- Added option to only roll on items that Pawn considers an upgrade
- Added not whispering DND players
- Trading PUG players is now only possible after asking them first
- Changed the default ilvl threshold to 15, because main stats are much more important since 8.0
- Removed unused AceTab and AceBucket libs
- Added 4 more variants for the bid whisper message, one of which will be picked at random when asking others for loot
- Recent chat is now colored according to the users chat color settings
- Made azerite gear tradeable after build 27404
- Groups now only need >50% of one guild/community to be considered guild/community groups
- Renamed Masterloot module to Session
- Made addon options its own module and options are now registered as callbacks that return the real options tables on demand
- Added ability to import and export masterloot settings to/from community and guild descriptions
- Added option to enable auto-awarding when in masterloot mode
- Auto-awarding now also takes council votes into account
- Changed char whitelists to profile+realm option
- Updated options migrations
- As always: Updated translations, bugfixes and minor tweaks

Version 12.04

- Fixed roll message matching for some locales
- Fixed taint when clicking chat links while in combat (#4)
- Fixed missing function param in SetLootRollItem hook (#5)

Version 12.01

- Fixed debug state not being preserved through reload/logout
- Fixed bug caused by string version number

Version 12

- Added separate options to en/disable asking for loot and announcing rolls
- Asking for loot is enabled by default for now, but will be disabled in the next version, except when updating from a prior version
- Added texture checking to inspection and fixed some bugs with it
- Added option to make bids public outside of masterloot mode
- Added integration with "Personal Loot Helper", so PLR users can roll on items from and offer items to PLH - users
- Added Instance scanning from the DJ and a resulting instance list
- Added legacy loot mode detection and common (green) items are now handled by the addon when it's active
- Added exporting trinket data from the dungeon journal, resulting in a massive trinket list update
- Improved string escaping of tooltip links
- Updated migration and version logic
- Weapon ilvls for the player are now calculated and cached per spec and slot
- Azerite armor will be ignored because it is not tradable
- Made debug mode a saved var that can be toggled with /plr debug
- Players can now pass on loot after the roll ended
- If the winner passes on loot then a new winner is determined
- Added error messages for voting and bidding
- Optimized loot event to prevent unnecessary roll creations
- Bugfixes and translation updates

Version 11

- Updated Ace3 libs to latest stable version
- Added "Apocalypse Drive" to trinket list
- Added support for more complex version strings (e.g. "11-beta3"), but won't use them on the wire until everybody had time to update
- Vote is now a required roll action that shows up in the actions window
- Added dropdown menu for award and vote actions to make it easier to choose a winner
- Some minor GUI refactoring
- Added workaround for Blizz's epic item color bug
- Fixed not being able to whisper people without the addon
- Minor bugfixes

Version 10

- Updated interface version to 80000
- Updated Ace3 libs to r1175-alpha
- Added workaroud for SendAddonMessage's diconnect bug
- Heirlooms now use the ilvl they can scale to for comparisons with other items
- Servers in Asian regions now have appropriate default languages instead of enUS
- Added enUS as UI fallback language, in addition to the region default language
- Clients with enGB locale now use the enUS chat lines
- Added option to only react to items/rolls from the current masterlooter
- Added option to not share any loot
- Added unit menu option again, hopefully without causing taint
- Added awarding as required roll action that shows up in the actions window
- Rearranged options home page a bit
- Improved Enable/Disable addon logic
- Enabled/Disabled state is now communicated between clients and used to determine if a player is currently using the addon
- The loot won alert should always show now, except when rolling need on own item
- Fixed eligible player ordering in rolls window
- Fixed global variable leak
- Fixed timewalking detection and removed it from the item scaling check

Version 9

- Updated interface version to 70300
- Added an actions window to show pending actions such as trade or whisper
- Added recording of whisper chats with winner/owner of items
- Added a whisper button to Actions and Rolls windows that also shows recorded whispers on mouseover
- Added support for item level scaling in low-level content and while timewalking
- Added ilvl threshold scaling for low-level chars
- Added support for argument reordering in translation lines
- Added zhTW translation (big thanks to BNSSNB!)
- Update other translations and made importing from CurseForge easier in the future
- Updated whisper reaction, answer and suppression logic
- Whispers from other addon users are now ignored
- Only handle outgoing whispers when tracking and only to other party members
- Roll visibility is now stored inside the roll, to make it consistent across GUIs
- Renamed masterlooter saved var to make it consistent with the other vars
- Fixed bug caused by previous renaming of lang-lines
- Removed upper() call on Rolls window headers
- Minor Trade refactoring
- Replaced custom realm list with LibRealmInfo
- Moved options table registration to OnEnable so realm data is available
- PLR rolls ids are now negative numbers instead of strings prefixed with "PLR" to prevent errors when other addons try to pass them to GameTooltip:SetLootRollItem on their own (unhooked) GameTootlip instances. Now those calls will just silently fail.
- Fixed bug causing no items to be added to the trade window when trading with players from other realms
- Fixed bug where rolls appeared for legendary and heirloom items
- Fixed bug where the game menu won't show up anymore after clicking the "Move" button in the options
- Fixed internal events for more than one listener
- Hopefully fixed item label formatting once and for all
- Minor bugfixes

Version 8

- Added whisper message suppression while giving away loot
- Added a group-wide whisper limit of 2 per item to prevent spamming players not using the addon
- Added an empty message to the rolls window
- Added roll frame highlighting for own items
- Updated last-chatted logic
- Rearranged and simplified options interface
- Removed UnitMenu hooks and UnitMenu on right-click in rolls window to prevent taint
- Moved remaining dropdown menus to AceGUI implementations
- Trinket list update
- Fixed LibDBIcon import (thanks to wagg1)
- Fixed bid links for non-ascii unit names
- Minor bugfixes and translation updates

Version 7

- Add a hide/show button to hide specific rolls in the list
- Changed "Canceled" to "Hidden" filter, filtering in/out canceled, pending and hidden rolls.
- Embedded CallbackHandler into Roll and Masterloot
- GUI Updates are now triggered by events, rather than direct method calls
- Moved masterloot council options into it's own tab
- Changed table layout slightly to be more in-line with the upcoming AceGUI version

Beta 6

- Fixed bug where players could be added, but not removed from the masterlooter whitelist.
- Updated the version tooltip to better distinguish between players with/without the addon
- Fixed workaround for ElvUI bug causing group loot frames to appear on top of each other
- Hopefully fixed taint caused by early dropdown initialization
- Fixed leaking "unit" variable into global namespace
- Added a table pool to reduce memory usage when using temp tables
- Fixed preview of equipped items for relics and when there is no min slot level (because of missing links or non-unique relics)
- Fixed item position detection and trading
- Inspection now includes the player, to streamline the access to equipped item links
- Refactored GUI update code to make it more readable and straightforward
- Some translation updates

Beta 5

- Moved some options around, made more use of tabbed UI (for masterloot+masterlooter and messages options)
- Added options to customize the messages the addon sends to other players
- Added toggle to enable/disable the double ilvl threshold for trinkets
- Bugfixes and translation updates

Beta 4

- Fixed options migration bug causing the options page to throw an error once after updating
- Added time remaining to rolls list and chat roll result to bids list in the overview window

Beta 3

- Custom answers for 'need' and 'greed' can now be specified in the 'Masterlooter' options and accessed with a right-click on the corresponding roll button
- Bids are now color-coded in the rolls overview window
- Fixed rolls overview window frama strata, so it's no longer above everything else
- Moved some options around internally and added ability to migrate options from one version to another
- Added version label and tooltip in the upper right corner of the rolls overview window
- Added item icons to rolls overview window details list
- Updated trinkets list

Beta 2

- Masterlooting is now tracked for all players with the addon
- Added ilvl threshold option
- Added custom timeout option when masterlooting
- Added an option to pick the specs the player cares about
- Fixed bug where item attribute amounts where wrong
- Added transmog options to also check if the player has an item's appearance unlocked when deciding to roll on it or not
- Added option to add members of a certain guild rank to the council, in addition to guild master and officers
- Made masterloot and council whitelists realmfaction options
- Translation updates and bugfixes

Beta 1

- First beta release

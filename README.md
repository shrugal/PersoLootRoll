# PersoLootRoll
A World of Warcraft addon to share and roll on items when using personal loot.

### Features
- Uses Blizzards build in group loot roll windows to roll on tradable personal loot.
- Rolls on other player's loot by whispering/rolling in chat or (if the other person has the addon) in the background.
- Offers loot you don't need to others, and handles accepting bids, picking a winner and trading automatically.
- Figures out what you and others can use, so you only have to decide when it actually makes sense.
- Masterloot mode.
- Most things (like whispers, announces etc.) can be turned on/off based on the type of group (raid/party, guildgroup, LFR) or target (friend, guildmember).

### Rolling
The idea of the addon is to use the build in roll frames (that are used for group loot etc.),
and make them work for personal loot as well. This means that whenever someone in your party/raid
gets an item the addon will figure out if you could use it (based on armor/weapon type, attributes,
equipped ilvl etc.), and pop up a roll window for you to decide whether you want it or not. If
you want it and the other person doesn't have the addon as well, then it ask for the item through
whisper chat and rolls for it if the person posts it in group chat. If the other person also has the
addon, then all this happens in the background without any chat messages.

If you loot an item that someone else could use, then it will show you the same roll window, and
offer it to your group if you don't roll "Need" on it. It then accepts bids via whispers, rolls
in chat or in the background if the other person is also using the addon, and after a certain
timeout (based on # or items looted) it will pick a winner and inform everybody about it. If you
want to decide yourself you can also right-click on other player's unit frames to directly give
them an item that is being rolled for, ending the roll instantly.

### Trading
Once you won loot from someone or someone won loot from you, the addon will give you a link in chat
that you can click on to start following and trading the owner/winner of the item. It will then
automatically put won items into the trade window, so you only have to click accept.

### Inspecting
Whenever you join a group the addon will start inspecting the other group members, to figure out which
items you loot would be interesting for them, and which items they looted should be tradable. The inspection
process is done in a way that it shouldn't interfere with your gameplay (e.g. it pauses during boss fights),
and there is a 30 ilvls (60 ilvls for trinkets) threshold in place so the addon doesn't ignore stuff that is
lower than what you have but e.g. has better stats or a gem slot.

### Masterloot
When you (or someone else) becomes masterlooter, all loot will be distributed by that person. You will get
a notice about who's items you won or who won your items, so you can trade them to the right person.
The masterlooter will see an overview window off all rolls and can view bids and distribute loot from there.

## Commands
Use /plr or /PersoLootRoll to open the options window, manually start rolling for items in your bag etc.

- `/plr`: Open rolls window
- `/plr roll [item]* (<timeout> <owner>)`: Start a roll for one or more item(s)
- `/plr bid <owner> ([item])`: Bid for an item from another player
- `/plr options`: Open options window
- `/plr config`: Change settings through the command line
- `/plr help`: Print this help message

*Legend: `[..]` = item link, `*` = one or more times, `(..)` = optional*

## Roadmap
These are the things I have planed currently, but feel free to add a ticket here on GitHub to suggest a feature that you would like to see!

- More translations: Sadly I only speak German and English, so if you speak another language (or find errors in my
  translations :P) then please create a pull request here on GitHub and I will gladly add your translation!
- Only suggest items for specific specs
- Transmog mode: Check appearance instead of stats, ilvl, ...
- Block (and maybe answer) all trades, whispers etc. for a few seconds after looting an item
- Customize messages the addon sends to other players

# PersoLootRoll
A World of Warcraft addon to share and roll on items when using personal loot.

Get it from [Curse](https://www.curseforge.com/wow/addons/persolootroll) or [WoWInterface](http://www.wowinterface.com/downloads/info24667-PersoLootRoll.html)!

## Features

### <span style="color: red">Roll on tradable personal loot from others</span>
Whenever an item that might be an upgrade for you but not for the owner drops for someone in your group you will get a good old Need-Greed-Pass window (remember
those? :P) to decide if you want the item or not. If you choose "Need" or "Greed", then it will send your bid to the item owner if he/she uses PLR as well, or
add it to a list of all items you want (see below), so you can easily ask the owner and start trading. You can also enable whispering automatically whenever you
roll on an item, with some restrictions to prevent spam.

<p align="center">
  <img src="https://imgur.com/GzgQjvk.jpg">
</p>

### <span style="color: red">Give away loot you don't want</span>
You also get a similar Keep-Greed-GiveAway window when you loot something that you can trade and your party members might be interested in. If you choose
something other than "Keep" then PLR offers the item to your group, handles accepting bids via addon/roll/whisper, picks a winner and assists you in trading the
item.

<p align="center">
  <img src="https://imgur.com/8CkGcVE.jpg">
</p>

### <span style="color: red">Assists you in sharing or getting the loot</span>
You will get a handy list with pending actions (e.g. asking someone for loot you want, trading, awarding or voting on loot) and buttons for completing them. It
will also show you recent chats with the owner or winner of an item when you hover over the "Chat" button, start following and trading the owner/winner when you
click the "Trade" button and automatically put won items into the trade window.

<p align="center">
  <img src="https://imgur.com/3eXcSaX.jpg">
</p>

### <span style="color: red">Smart decisions about what items are useful</span>
Many factors are checked before you are asked to roll on or give away an item, e.g. if it is or should be tradable, what you and others have equipped, class
restrictions, trinket type, and so on. It will only ask you to decide when it actually makes sense, while making sure that you don't miss any loot you might be
interested in.

### <span style="color: red">Works for PUGs, organized groups and even masterlooting</span>
It works great for randomly giving away loot in PUGs and organized groups, but it also has a masterloot mode where one person decides who should get which item.
The masterlooter can also configure things like custom answers and a loot council.

<p align="center">
  <img src="https://imgur.com/njPScmx.jpg">
</p>

### <span style="color: red">Can be configured to your liking</span>
Just about everything can be easily tweaked in the options menu. This includes whether or not to send messages to other players and customizing them, what items
are considered "useful" (e.g. only certain specs or transmog missing) and which parts of the UI you want to see. See
[this Wiki page](https://wow.curseforge.com/projects/persolootroll/pages/options) for details.

### <span style="color: red">Works with other addons</span>
This includes the popular loot roll addon Personal Loot Helper, [Pawn](https://wow.curseforge.com/projects/persolootroll/pages/options#title-2) to only roll on
stuff that actually has your preferred stats, and [EPGP](https://wow.curseforge.com/projects/persolootroll/pages/options/masterloot#title-4) to give away loot
based on PR value or credit GP for awarded items.

## Details

### Rolling on loot
The core idea of PLR is to make sharing loot as easy as possible by reusing the group-loot roll windows that have been in WoW since Classic, and making them
work for Personal Loot as well.

Whenever someone in your group loots something PLR checks if it might be useful to you (e.g. it's an upgrade or you have "Check transmog appearance" enabled and
don't have the transmog yet) and then shows you a roll window for it. If you choose "Need" or "Greed" for that item, then PLR will do the following things:

- If the owner uses PLR as well, then it sends him/her your bid as an addon-message in the background, waits for the roll to end and adds a trade entry to your
actions list if you win the item.
- If the owner doesn't use PLR, then it checks whether the item link has been posted to group chat (e.g. "[item-link] roll") and
/rolls for it if that is the case. If it hasn't been posted yet then PLR adds an entry to your actions list to ask the owner for the item, and if you enabled
"Ask for loot" and the owner hasn't been asked by two other PLR users already then it will also send a whisper message to the owner reading "Do you need that
[item-link]?".

If you get something that others in your group might be interested in, then PLR will show you a similar Keep-Greed-GiveAway window. If you choose "Keep" then
PLR will let other PLR users know that your item is not for trade, and it will answer incoming whisper requests with "I need that myself". If you select "Greed"
or "Give Away" however, then PLR will do the following things:

- Send an addon-message to other PLR users, so they know that the item is up for trade.
- If there are players not using PLR in your group, then it will also post
an advertisement to chat reading "Giving away [item-link] -> /w me or /roll 101." This number "101" at the end will count up for every item currently being
given away by you or other PLR users, so the next item advertisement will be /roll 102, then 103 and so on. This way multiple rolls can happen in chat at the
same time.

PLR will then accept bids from other players in the form of addon-messages from other PLR users, whisper messages or /rolls in chat. Your party
members can /roll 100 if your item was the last one being posted to chat, and they can also subtract 50 to indicate a "Greed" roll, so /roll 50 instead of 100,
51 instead of 101 and so on. You can also choose to automatically suppress and/or answer incoming whisper requests.

After a few seconds (depending on the number of looted items) the roll ends and PLR picks a winner, posts the result to group chat, whispers the winner and adds
a trade entry to your actions list. When you click the "Trade" button in that entry PLR will start following the winner (if in range), open a trade window and
put the won item into the window, so you only have to click "Accept". 

### Masterloot
You can open the overview window by clicking on the minimap icon, and then search for or become a masterlooter by clicking the button in the lower right corner.
When you decide to become a masterlooter other PLR users in your group will get a message, asking them to accept you as their masterlooter.

If they accept, then all loot they get will be distributed by you, so other players' bids on items will go to you, and once a roll has ended you can decide by
hand who should get it. The item owner will get an entry on his/her actions list and a notice in chat, instructing him/her to trade the item to the winner. As a
masterlooter you can also define custom bid answers and declare other players as your loot council, so they will see bids as you do and can vote on who should
get the loot.  

More details on how to customize the masterloot mode can be found on [this Wiki page](https://wow.curseforge.com/projects/persolootroll/pages/options/masterloot).

## Commands
Use /plr or /PersoLootRoll to open the rolls overview window, manually start rolling for items in your bag etc.

- `/plr`: Open rolls window
- `/plr help`: Print this help message
- `/plr roll [item]* (<owner> <timeout>)`: Start a roll for one or more item(s)
- `/plr bid [item] (<owner> <bid>)`: Bid for an item from another player
- `/plr trade (<player>)` Trade with the given player or your current target
- `/plr test` Start a test roll (only you will see it)
- `/plr options`: Open options window
- `/plr config`: Change settings through the command line
- `/plr log` Show log

Development commands:
- `/plr debug` Toggle debug mode
- `/plr trinkets` Generate and show a new list of trinkets
- `/plr instances` Generate and show a new list of instances

*Legend: `[..]` = item link, `*` = one or more times, `(..)` = optional*

## Translation
PLR is translated (incl. chat messages) to

- English: 100%
- German: 100%
- Traditional Chinese: 100% (by [BNSSNB](https://wow.curseforge.com/members/BNSSNB))
- Simplified Chinese: 100% (by [yasen](https://wow.curseforge.com/members/yasen))
- Spanish: 80% (by [isaracho](https://wow.curseforge.com/members/isaracho) and [jolugon](https://wow.curseforge.com/members/jolugon))
- Russian: 60% (by [nomorecezz](https://wow.curseforge.com/members/nomorecezz))

 If you want to help translate it to your language or correct translation errors you found then please visit the
 [Curseforge Translation section](https://wow.curseforge.com/projects/persolootroll/localization) and also check out
 [this wiki page](https://wow.curseforge.com/projects/persolootroll/pages/translation) for some tips.

## Development
This project is fully open-source and the source code can be found on [GitLab](https://gitlab.com/shrugal/PersoLootRoll). To test out new features there are also beta versions available. Please report any
bugs you find with these versions should you be brave enough to install them, so the stable releases will be as bug-free as possible.

### Bugs and Features
Please create a new entry on the [issue tracker](https://gitlab.com/shrugal/PersoLootRoll/issues) you encounter any bugs or want to suggest a feature.

### Roadmap
These are the things I have planed currently:

[![Feature Requests](http://feathub.com/shrugal/PersoLootRoll?format=svg)](http://feathub.com/shrugal/PersoLootRoll)

You can vote on feature request [here](http://feathub.com/shrugal/PersoLootRoll).

### Build
To build a package from source you need to copy `.release/.env.example` to `.release/.env`, fill in the relevant infos (projects IDs and API tokens) and then
run `.release/release.sh`. The completed file(s) will be available in the `.release` folder. More information about possible arguments to the
release script can be found [here](https://gitlab.com/shrugal/wow-packager).

### Donate
Click on the "Donate" button if you want to support the development of this addon or just buy me a beer. Always appreciated, never required!

[![Donate](http://www.wowinterface.com/images/paypalSM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=H3EE7MDA5XFCW)

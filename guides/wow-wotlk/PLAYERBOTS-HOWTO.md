# WoW WotLK Playerbots Interaction Guide

This guide covers the day-to-day ways to interact with the WotLK Playerbots
server installed by Dad's MMO Lab. It applies to the AzerothCore WotLK server
with `mod-playerbots`, installed under `~/wow-server-playerbots/`.

Playerbots are mostly controlled from inside the game with chat commands. Some
management commands use normal GM command syntax and start with `.playerbots`.

Optional UI addon: this repo also includes **Playerbot Commander**, a WotLK
3.3.5a client addon that puts the chat commands below behind buttons, dropdowns,
and a custom command box. Install it from
`guides/wow-wotlk/PlayerbotCommander/Client Files/Interface/AddOns/PlayerbotCommander`
and open it in-game with `/pbc` or `/pbots`.

---

## Quick Start

1. Start the Playerbots server.
2. Log into your WotLK 3.3.5a client.
3. Wait 5-10 minutes after server startup for random bots to populate naturally.
4. Use whispers, party chat, or raid chat to command bots.
5. Use `.playerbots ...` commands when you want to add or remove altbots.

Useful server commands:

```bash
cd ~/wow-server-playerbots && docker compose up -d
cd ~/wow-server-playerbots && docker compose logs -f ac-worldserver
```

Attach to the worldserver console when you need server-side commands:

```bash
docker attach $(docker ps --format '{{.Names}}' | grep worldserver | head -1)
```

Exit the attached console with **Ctrl+P then Ctrl+Q**. Do not press Ctrl+C,
because that can stop the server.

---

## Two Kinds of Playerbots

| Type | What they are | Best use |
|---|---|---|
| Random bots | Automatically generated bots that roam, quest, gear themselves, and make the world feel populated | Living-world population, world PvP feel, finding ambient groups |
| Altbots | Characters you created first, then log in as controlled bots | Long-term companions, dungeon teams, raid groups, progression play |

Random bots handle most of their own setup. Altbots often need setup commands
for gear, talents, spells, glyphs, and maintenance.

### Random Bot Autonomy And Party Control

Random bots normally run their own world-life behavior: they wander, grind,
pick quests, travel, and behave like ambient players. When a random bot accepts
your group invite, the server makes you its master, resets its strategies, and
puts it into party-helper behavior.

If you want an invited random bot to keep acting autonomously while it is still
in your group, you can add its random-bot RPG strategies back:

```text
/w Botname nc -follow,+grind,+new rpg
```

That can make the bot wander away from you, because it is no longer purely
following party-control behavior.

To put that bot back into normal follow-party behavior:

```text
/w Botname nc !
/w Botname nc -grind,-new rpg,+follow,-lfg,-bg
/w Botname follow
```

If the bot still behaves oddly, force the normal invite path again:

```text
/w Botname leave
/invite Botname
/w Botname follow
```

---

## How To Send Commands

### Whisper One Bot

Use this when you want one bot to obey.

```text
/w Botname follow
/w Botname attack
/w Botname stay
/w Botname summon
```

### Command Your Party

Use party chat to command bots grouped with you.

```text
/p follow
/p attack
/p stay
/p summon
```

### Command Your Raid

Use raid chat for raid-sized bot groups.

```text
/r follow
/r attack
/r stay
```

### Ask A Bot For Help

Whisper a bot:

```text
/w Botname help
```

You can also check server-side command discovery as a GM:

```text
.commands
.help playerbot
.help playerbots
```

---

## Adding And Removing Altbots

Altbots are characters that already exist on an account and can be logged in as
bots. These commands are usually entered in-game by a GM character.

| Action | Command |
|---|---|
| Log in named altbots | `.playerbots bot add Name1,Name2,Name3` |
| Log in every altbot on an account | `.playerbots bot addaccount ACCOUNTNAME` |
| Log out named altbots | `.playerbots bot remove Name1,Name2,Name3` |
| Log in all altbots in your party or raid | `.playerbots bot add *` |
| Log out all altbots in your party or raid | `.playerbots bot remove *` |
| List available altbots | `.playerbots bot list` |

After adding altbots, invite them to your group if they are not already grouped.
Bots normally accept party and raid invites automatically.

---

## Adding Ready-Made Class Bots

Use AddClass bots when you want a leveled, geared party member without creating
and leveling a character by hand. The server reserves a pool of same-faction
characters for this command.

| Action | Command |
|---|---|
| Add any available class bot | `.playerbots bot addclass warrior` |
| Add a specific gender | `.playerbots bot addclass priest female` |
| Reinitialize bot from your level and gear | `.playerbots bot init=auto Botname` |
| Reinitialize bot with rare gear | `.playerbots bot init=rare Botname` |
| Reinitialize bot with epic gear | `.playerbots bot init=epic Botname` |

Supported classes are `warrior`, `paladin`, `hunter`, `rogue`, `priest`,
`shaman`, `mage`, `warlock`, `druid`, and `dk`. Death Knights require your
character to be high enough for heroic character creation.

Typical flow:

```text
.playerbots bot addclass priest
.playerbots bot init=auto Botname
/invite Botname
/w Botname maintenance
/w Botname talents spec list
```

If you do not know the generated bot name, use `.playerbots bot list` after
adding the class bot.

---

## Core Party Commands

These are the commands you will use constantly.

| Command | What it does |
|---|---|
| `follow` | Bot runs toward you |
| `flee` | Bot runs toward you and ignores everything else |
| `stay` | Bot stays where it is |
| `summon` | Bot teleports/summons to you, depending on server config |
| `attack` | Bot attacks your selected target |
| `grind` | Bot attacks visible enemies freely |
| `release` | Dead bot releases spirit |
| `revive` | Bot revives near a spirit healer |
| `leave` | Bot leaves the party |
| `give leader` | Bot passes party or raid lead to you |
| `lfg` | Bot joins your group and tries to fill an open role |
| `lfg 5` | Bot joins/fills a 5-player group |
| `reset` | Reset current bot action, such as moving or casting |
| `reset botAI` | Reset bot AI settings |

Examples:

```text
/p follow
/p attack
/w Healerbot stay
/w Tankbot give leader
```

---

## Targeting Groups Of Bots

You can prefix some commands with role, group, or class filters.

Examples:

```text
/r @tank attack
/r @heal follow
/r @ranged stay
/r @group1 follow
/r @group2 attack
/r @mage stay
```

Common filters:

| Filter | Targets |
|---|---|
| `@tank` | Tank bots |
| `@heal` | Healer bots |
| `@dps` | DPS bots |
| `@ranged` | Ranged bots |
| `@rangeddps` | Ranged DPS bots |
| `@meleedps` | Melee DPS bots |
| `@group1`, `@group2`, etc. | Raid subgroups |
| `@warrior`, `@paladin`, etc. | A class |

Some grouped forms are also accepted, such as `@group2-5` or `@group1,4`.

---

## Combat Strategies

Bots decide what to do based on strategies. Combat strategies use `co`.

| Command | Meaning |
|---|---|
| `co ?` | Show current combat strategies |
| `co +tank` | Add tank behavior |
| `co +dps` | Add DPS behavior |
| `co +heal` | Add healer behavior |
| `co +assist` | Focus one target at a time |
| `co +aoe` | Allow multi-target damage |
| `co +boost` | Use big cooldowns |
| `co -boost` | Stop using big cooldowns |
| `co +threat` | DPS avoids pulling threat |
| `co +cc` | Enable crowd control behavior |
| `co +avoid aoe` | Avoid many harmful ground effects |
| `co !` | Reset combat strategies |

Examples:

```text
/w Tankbot co +tank,+tank assist,+pull
/w Healerbot co +heal,-healer dps
/p co +assist,+threat,-aoe
/p co +boost
/p co -boost
```

Tank-oriented helpers:

| Strategy | Use |
|---|---|
| `tank assist` | Tank pulls enemies off others |
| `pull` | Tank pulls with a ranged skill |
| `pull back` | Tank pulls and returns to the pull point |
| `tank face` | Tank turns the target away from ranged players |

---

## Non-Combat Strategies

Non-combat strategies use `nc`.

| Command | Meaning |
|---|---|
| `nc ?` | Show current non-combat strategies |
| `nc +loot` | Enable looting |
| `nc -loot` | Disable looting |
| `nc +food` | Eat/drink behavior |
| `nc +pvp` | Enable PvP mode behavior |
| `nc !` | Reset non-combat strategies |
| `nc -follow,+grind,+new rpg` | Let an invited random bot resume autonomous random-bot behavior |
| `nc -grind,-new rpg,+follow,-lfg,-bg` | Return an autonomous random bot to normal party-follow behavior |

Examples:

```text
/p nc +loot
/p nc -loot
/w Botname nc -follow,+grind,+new rpg
/w Botname nc !
/w Botname nc -grind,-new rpg,+follow,-lfg,-bg
/w Priestbot nc +rshadow
/w Paladinbot nc +bdps,+barmor
```

---

## Loot And Items

Loot commands are usually sent through party chat.

| Command | What it does |
|---|---|
| `ll all` | Loot everything |
| `ll normal` | Loot everything except bind-on-pickup items |
| `ll gray` | Loot only gray items |
| `ll quest` | Loot only quest items |
| `ll skill` | Loot profession-gathered items |
| `ll [item]` | Add an item to the loot list |
| `ll -[item]` | Remove an item from the loot list |
| `roll` | Bots roll for available loot |
| `roll [item]` | Bots roll for the linked item if it is useful |

Bot inventory commands:

| Command | What it does |
|---|---|
| `stats` | Show inventory, gold, XP, and other stats |
| `[item]` | Bot reports how many it has and related quest status |
| `e [item]` | Equip item |
| `ue [item]` | Unequip item |
| `u [item]` | Use item |
| `s *` | Sell all gray items |
| `s vendor` | Sell all sellable vendor trash |
| `2g 3s 5c` | Bot gives you that amount of money |

Item links work best. Shift-click an item into chat after typing the command.

---

## Quests

Bots can interact with quest givers and report quest progress.

| Command | What it does |
|---|---|
| `quests` | Show quest summary |
| `quests all` | List all quests in the bot's quest log |
| `accept [quest]` | Accept a selected quest |
| `accept *` | Accept all quests at the selected quest giver |
| `drop [quest]` | Abandon a quest |
| `[quest]` | Show quest/objective status |
| `talk` | Talk to selected NPC, often for turn-ins |
| `r [item]` | Choose a quest reward |
| `u [game object]` | Use a game object |

Bots also react to some things you do. When you accept a quest, talk to a quest
giver, use a meeting stone, use a dungeon portal, mount, unmount, or start a
ready check, grouped bots usually try to follow along.

Quest sync depends on server config and is not always perfect. Dad's MMO Lab
enables these settings in `~/wow-server-playerbots/docker-compose.override.yml`
for Playerbots installs:

```yaml
AC_AI_PLAYERBOT_SYNC_QUEST_WITH_PLAYER: "1"
AC_AI_PLAYERBOT_AUTO_DO_QUESTS: "1"
AC_QUESTS_IGNORE_AUTO_ACCEPT: "1"
```

After changing those values, restart the server:

```bash
cd ~/wow-server-playerbots && docker compose down && docker compose up -d
```

If bots still miss a quest interaction, use party chat:

```text
/p accept *
/p talk
```

---

## Spells, Talents, Gear, And Maintenance

Use these mainly for altbots and AddClass bots.

| Command | What it does |
|---|---|
| `maintenance` | Learn available spells/skills, supplement consumables, enchant gear, and repair |
| `autogear` | Automatically gear the bot based on server config limits |
| `talents` | Show current spec |
| `talents spec list` | Show specs available for that class |
| `talents spec [spec name]` | Force a spec |
| `talents apply <link>` | Apply a talent link |
| `glyphs` | Show equipped glyphs |
| `glyph equip [GlyphID1 ...]` | Equip glyphs by ID |
| `spells` | Show bot spells |
| `cast [spell_name]` | Make a bot cast a spell |
| `cast [spell_name] on [PlayerName]` | Cast on a specific player |
| `trainer` | Show what the bot can learn from selected trainer |
| `trainer learn` | Learn from selected trainer |

Common setup flow for a new altbot:

```text
/w Botname maintenance
/w Botname autogear
/w Botname talents spec list
/w Botname talents spec protection
/w Botname glyphs
```

---

## Marked Targets And Saved Positions

Playerbots support raid target icons and simple positioning commands.

| Command | What it does |
|---|---|
| `rti skull` | Prioritize the skull-marked target |
| `rti cross` | Prioritize the cross-marked target |
| `rti cc moon` | Use moon as crowd-control target |
| `attack rti target` | Attack the bot's assigned raid-icon target |
| `focus heal +PlayerName` | Add a focused healing target |
| `focus heal -PlayerName` | Remove a focused healing target |
| `focus heal ?` | Show focused healing targets |
| `focus heal clear` | Clear focused healing targets |

RTSC commands are for saving locations and sending bots there.

| Command | What it does |
|---|---|
| `rtsc` | Enable RTSC and grant the `aedm` targeting spell |
| `rtsc cancel` | Disable RTSC |
| `rtsc save 1` | Save a clicked location as slot 1 |
| `rtsc go 1` | Send bots to saved location 1 |
| `rtsc unsave 1` | Clear saved location 1 |
| `rtsc go save` | Send bots back to saved RTSC positions |

Example:

```text
/r @tank rtsc go 1
/r @ranged rtsc go 2
/r rti skull
/r attack rti target
```

---

## Pet Commands

For hunter and warlock bots:

| Command | What it does |
|---|---|
| `pet aggressive` | Set pet aggressive |
| `pet defensive` | Set pet defensive |
| `pet passive` | Set pet passive |
| `pet stance` | Show current stance |
| `pet attack` | Pet attacks selected target |
| `pet follow` | Pet follows master |
| `pet stay` | Pet stays |

Hunter tame helpers:

| Command | What it does |
|---|---|
| `tame` | Show tame help |
| `tame name "name"` | Summon a tameable pet by name |
| `tame id "id"` | Summon by creature ID |
| `tame family "family"` | Summon from a pet family |
| `tame rename "new name"` | Rename current pet |

---

## Handy Macros

Create normal WoW macros with these commands.

### All Bots Follow

```text
/p follow
```

### Attack My Target

```text
/p attack
```

### Stop And Stay

```text
/p stay
```

### Boss Pull Mode

```text
/p co +assist,+threat,-aoe,-boost
/w Tankbot co +tank,+tank assist,+pull
```

### Burn Phase

```text
/p co +boost,+aoe
```

### Loot After Fight

```text
/p nc +loot
/p ll normal
```

---

## Console-Only Playerbot Commands

These are typed in the worldserver console after `docker attach`, without a
leading dot.

| Command | What it does |
|---|---|
| `playerbot rndbot stats` | Print random bot counts by level, class, etc. |
| `playerbot rndbot reload` | Reload `playerbots.conf` |
| `playerbot rndbot update` | Trigger a random-bot update tick |
| `playerbot rndbot init` | Re-roll random bots after config changes |
| `playerbot rndbot clear` | Reset random bots back to starting level |
| `playerbot rndbot level` | Level up all random bots by 1 |
| `playerbot rndbot refresh` | Revive, reset AI, and reroll gear while keeping level |
| `playerbot rndbot teleport` | Teleport random bots to level-appropriate areas |
| `playerbot pmon toggle` | Toggle performance monitor |
| `playerbot pmon stack` | Show cumulative performance stats |
| `playerbot pmon tick` | Show average cycle performance |
| `playerbot pmon reset` | Reset performance monitor |

Avoid `playerbot rndbot revive`; upstream documentation currently notes that it
can duplicate random bots.

---

## Troubleshooting

### Bots Are Missing After Startup

Wait 5-10 minutes. Random bots do not all appear instantly after the worldserver
becomes ready.

### A Bot Ignores Commands

Try, in order:

```text
/w Botname reset
/w Botname follow
/w Botname reset botAI
```

Then kick/reinvite the bot, teleport away and back, or restart the server.

If this happened after enabling autonomous random-bot behavior with
`nc -follow,+grind,+new rpg`, reset the non-combat strategy bucket first:

```text
/w Botname nc !
/w Botname nc -grind,-new rpg,+follow,-lfg,-bg
/w Botname follow
```

### A Command Does Not Work

The playerbot module changes over time and server configs can disable some
features. Ask the bot for help and check GM help:

```text
/w Botname help
.help playerbots
.commands
```

### Bots Do Not Automatically Accept Or Turn In Quests

Make sure the quest-sync settings are enabled in
`~/wow-server-playerbots/docker-compose.override.yml`:

```yaml
AC_AI_PLAYERBOT_SYNC_QUEST_WITH_PLAYER: "1"
AC_AI_PLAYERBOT_AUTO_DO_QUESTS: "1"
AC_QUESTS_IGNORE_AUTO_ACCEPT: "1"
```

Then restart the stack:

```bash
cd ~/wow-server-playerbots && docker compose down && docker compose up -d
```

Bots must be grouped, nearby, eligible for the quest, and have quest-log space.
Some quests still require manual help:

```text
/p accept *
/p talk
/p r [reward item link]
```

### Altbot Is Weak Or Missing Spells

Run:

```text
/w Botname maintenance
/w Botname autogear
/w Botname talents spec list
```

### Bots Pull Too Much

Use more controlled strategies:

```text
/p co +assist,-aoe,-grind
/p stay
/w Tankbot attack
```

### Bots Will Not Loot

Enable looting and choose a loot list:

```text
/p nc +loot
/p ll normal
```

---

## Upstream References

- Dad's MMO Lab WotLK guide: `guides/wow-wotlk/WoW-WotLK-HOWTO.md`
- Local GM guide: `guides/WoW-GM-HOWTO.md`
- Upstream module: <https://github.com/mod-playerbots/mod-playerbots>
- Upstream Playerbot Commands wiki: <https://github.com/mod-playerbots/mod-playerbots/wiki/Playerbot-Commands>

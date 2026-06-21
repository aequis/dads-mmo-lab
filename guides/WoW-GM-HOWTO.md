# Dad's MMO Lab - WoW GM How-To

This guide is for your local World of Warcraft servers after you have granted your
account GM level 3. It covers the day-to-day things a GM can do in-game and from
the server console.

The exact command list depends on the core:

| Server | Core | Main prompt/container |
|---|---|---|
| Vanilla | CMaNGOS Classic | `vanilla-mangosd`, prompt `mangos>` |
| Burning Crusade | CMaNGOS TBC | `tbc-mangosd`, prompt `mangos>` |
| Wrath of the Lich King | AzerothCore | `ac-worldserver`, prompt `AC>` |

Most commands below work on both CMaNGOS and AzerothCore, but always trust your
server's built-in help first.

---

## GM Basics

### Enable GM Mode In-Game

Log into your GM account, then type in chat:

```text
.gm on
```

Useful related commands:

```text
.gm off
.gm chat on
.gm visible on
.gm fly on
```

What they do:

| Command | Effect |
|---|---|
| `.gm on` | Enables GM mode for your character |
| `.gm off` | Turns GM mode off |
| `.gm chat on` | Makes GM chat/name styling visible |
| `.gm visible on` | Makes you visible while in GM mode |
| `.gm fly on` | Enables GM flight, if supported by your core |

Some scripted systems check whether GM mode is active, not just whether your
account has GM rank. If a GM-only NPC, addon, or script says you do not have
permission, run `.gm on` first.

### Find Commands On Your Server

These are the most important commands to remember:

```text
.commands
.help COMMAND
```

Examples:

```text
.help teleport
.help additem
.help npc
.help lookup
```

If a command in this guide does not work, use `.commands` and `.help` to check
the exact spelling for your core.

---

## Server Console

You can run many account/server commands from the world server console.

### Attach To The Console

WotLK / AzerothCore:

```bash
docker attach $(docker ps --format '{{.Names}}' | grep worldserver | head -1)
```

TBC:

```bash
docker attach tbc-mangosd
```

Vanilla:

```bash
docker attach vanilla-mangosd
```

Exit safely with **Ctrl+P**, then **Ctrl+Q**.

Do not press **Ctrl+C** while attached. That can stop the server process.

### Console Command Format

In-game GM commands usually start with a dot:

```text
.gm on
.additem 6948
```

In the server console, commands usually do not use the leading dot:

```text
account create USERNAME PASSWORD
account set gmlevel USERNAME 3 -1
server info
```

---

## Account Management

### Create A New Account

From the server console:

```text
account create USERNAME PASSWORD
```

### Make An Account GM

For full local admin access:

```text
account set gmlevel USERNAME 3 -1
```

GM level `3` is full administrator access. The `-1` realm value means all realms.

### Change A Password

Try one of these, depending on core:

```text
account set password USERNAME NEWPASSWORD NEWPASSWORD
account password USERNAME NEWPASSWORD NEWPASSWORD
```

Use console help if your server rejects the syntax:

```text
help account
```

---

## Character Quality Of Life

### Level Up

Level yourself by a number of levels:

```text
.levelup 10
```

Set or modify level, depending on core support:

```text
.modify level 80
```

### Money

Add money to yourself:

```text
.modify money 100000000
```

Money is usually measured in copper:

| Copper | In-game value |
|---:|---:|
| `100` | 1 silver |
| `10000` | 1 gold |
| `100000000` | 10,000 gold |

### Health, Mana, Rage, Energy

Common examples:

```text
.modify hp 999999
.modify mana 999999
.modify rage 100
.modify energy 100
```

### Speed

Common movement modifiers:

```text
.modify speed 3
.modify swim 3
.modify fly 3
```

Use moderate values. Very high speeds can make clients or scripted encounters
act strangely.

### Repair, Revive, Save

```text
.repairitems
.revive
.save
```

Some cores use slightly different command names. Check `.help repair` or
`.help revive` if needed.

---

## Items

### Look Up An Item

```text
.lookup item hearthstone
.lookup item frostmourne
.lookup item netherweave bag
```

The server returns item IDs. Use those IDs with `.additem`.

### Add An Item

```text
.additem ITEM_ID
.additem ITEM_ID COUNT
```

Examples:

```text
.additem 6948
.additem 21841 4
```

### Remove An Item

Common forms:

```text
.removeitem ITEM_ID COUNT
.item remove ITEM_ID COUNT
```

Use `.help removeitem` or `.help item` for your exact core.

---

## Spells And Skills

### Learn A Spell

```text
.learn SPELL_ID
```

### Unlearn A Spell

```text
.unlearn SPELL_ID
```

### Learn Everything For Your Class

Depending on core:

```text
.learn all_myclass
.learn all my class
```

### Max Skills

Common options:

```text
.maxskill
.setskill SKILL_ID VALUE MAX_VALUE
```

Use lookup/help for the exact skill command syntax on your core.

---

## Teleporting And Movement

### Teleport To Named Locations

Look up available teleport locations:

```text
.lookup tele stormwind
.lookup tele dalaran
.lookup tele shattrath
```

Teleport:

```text
.tele stormwind
.tele dalaran
.tele shattrath
```

### Go To Coordinates

Coordinate commands vary by core. Common forms:

```text
.go xyz X Y Z MAP_ID
.go X Y Z MAP_ID
```

Example pattern:

```text
.go xyz -8833.38 628.62 94.00 0
```

### Teleport Players

Bring a player to you:

```text
.namego PLAYERNAME
```

Go to a player:

```text
.goname PLAYERNAME
```

Summon commands may also be available:

```text
.summon PLAYERNAME
```

---

## NPCs And Creatures

### Look Up Creatures

```text
.lookup creature hogger
.lookup creature thrall
.lookup creature arthas
```

### Spawn An NPC

Target the ground/area where you want the NPC and run:

```text
.npc add CREATURE_ID
```

Some cores use:

```text
.npc add spawn CREATURE_ID
```

### Delete A Spawned NPC

Target the NPC:

```text
.npc delete
```

### Move Or Respawn NPCs

Common commands:

```text
.npc move
.respawn
.npc info
```

Use `.npc info` on a selected creature to inspect its ID, spawn GUID, faction,
level, and flags.

---

## Quests

### Look Up A Quest

```text
.lookup quest deadmines
.lookup quest onyxia
```

### Add Or Complete A Quest

Common forms:

```text
.quest add QUEST_ID
.quest complete QUEST_ID
.quest remove QUEST_ID
```

Some cores use command groups such as:

```text
.quest start QUEST_ID
.quest reward QUEST_ID
```

Use `.help quest` to confirm.

---

## Game Objects

Game objects are doors, chests, meeting stones, herbs, ore nodes, portals, and
similar world objects.

### Look Up Game Objects

```text
.lookup object mailbox
.lookup object chest
.lookup object portal
```

### Spawn A Game Object

```text
.gobject add GAMEOBJECT_ID
```

### Delete A Game Object

Target or stand near the object:

```text
.gobject delete
```

Some cores use `.gameobject` instead of `.gobject`.

---

## Server Administration

### Announcements

Broadcast a message:

```text
.announce Server restart in 5 minutes.
```

GM-only announcement:

```text
.gm announce Testing a GM-only message.
```

### Save Players

```text
.saveall
```

### Server Info

```text
.server info
```

From the console, this may be:

```text
server info
```

### Shutdown Or Restart

Use with care, especially if someone else is connected.

```text
.server shutdown 60
.server restart 60
```

From the console:

```text
server shutdown 60
server restart 60
```

Cancel if supported:

```text
.server shutdown cancel
.server restart cancel
```

---

## Playerbot Notes

The repo's WoW servers are tuned for solo play with Playerbots. Bot commands
depend heavily on the exact bot module and expansion.

Good discovery commands:

```text
.commands
.help bot
.help playerbot
```

Common interaction patterns:

| Action | How |
|---|---|
| Invite a bot | Target or whisper the bot, then use the bot module's invite command |
| Give orders | Whisper bot commands directly to the bot |
| Reset a stuck bot | Kick/reinvite, teleport away and back, or restart the server |
| Wait for population | Bots can take 5-10 minutes after startup to appear naturally |

If bot-specific commands are missing, the module may expose behavior through
chat whispers rather than normal GM commands.

---

## Practical GM Recipes

### Make A Fresh Testing Character

```text
.gm on
.levelup 79
.modify money 100000000
.maxskill
.save
```

Then use `.lookup item NAME` and `.additem ITEM_ID` for gear.

### Jump To A Dungeon Entrance

```text
.lookup tele scarlet
.tele scarletmonastery
```

If the teleport name is different, use the result from `.lookup tele`.

### Spawn A Vendor Or NPC

```text
.lookup creature repair
.npc add CREATURE_ID
.npc info
.saveall
```

### Debug A Broken Quest

```text
.lookup quest QUEST_NAME
.quest complete QUEST_ID
.quest reward QUEST_ID
```

If the quest state becomes weird, remove it and add it again:

```text
.quest remove QUEST_ID
.quest add QUEST_ID
```

### Get Unstuck

```text
.gm on
.tele stormwind
```

For Horde:

```text
.tele orgrimmar
```

---

## Safety Tips

- Prefer `.lookup` before spawning or adding things.
- Run `.saveall` before major experiments.
- Use `.npc info` before deleting NPCs.
- Avoid spawning lots of permanent NPCs in cities unless you are testing.
- Restarting the world server is often cleaner than trying to undo many test
  changes one by one.
- If something looks core-specific, check `.help COMMAND` before assuming the
  syntax.

---

## Quick Reference

```text
.gm on
.commands
.help COMMAND
.lookup item NAME
.additem ITEM_ID COUNT
.lookup creature NAME
.npc add CREATURE_ID
.npc delete
.lookup quest NAME
.quest complete QUEST_ID
.lookup tele NAME
.tele LOCATION
.namego PLAYERNAME
.goname PLAYERNAME
.modify money COPPER
.levelup LEVELS
.save
.saveall
```


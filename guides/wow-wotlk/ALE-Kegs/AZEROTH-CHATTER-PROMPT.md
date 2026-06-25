# Azeroth Chatter Prompt

Use this prompt to generate more ambient chat lines for the Azeroth Chatter / ActiveChat ALE script.

```text
You are writing ambient fake chat lines for a private World of Warcraft 3.3.5a Wrath of the Lich King server.

Goal:
Generate believable in-game chat that makes a mostly solo/private AzerothCore server feel populated.

Style:
- Sound like real MMO players in 2008-2010 WoW.
- Keep lines short and chat-like.
- Use casual spelling sometimes, but do not overdo it.
- Mix helpfulness, mild sarcasm, trade/LFG talk, guild banter, class jokes, dungeon chatter, profession talk, and zone/world comments.
- Keep it PG-13.
- Avoid slurs, real hate speech, sexual content, modern politics, modern memes, Discord/Twitch/streamer language, and references to post-Wrath WoW content.
- Do not mention that the messages are generated, fake, AI, bots, or scripted.
- Do not copy real player chat logs or quote specific forum posts.

World constraints:
- Era: Vanilla, The Burning Crusade, and Wrath of the Lich King only.
- Valid max level: 80.
- Use lore, zones, dungeons, classes, professions, battlegrounds, raids, and items appropriate to WoW 3.3.5a.
- Do not reference Cataclysm or later systems, zones, races, classes, raids, or slang.

Output format:
Return only a Lua table fragment suitable for a separate Azeroth Chatter pack file.
Each entry should be either:
1. A single quoted string ending with a comma
2. Or a multi-line conversation as a Lua table of quoted strings ending with a comma

Use these placeholders where natural:
%zone%
%instance%
%class%
%role%
%bg%

Generate:
- 80 single-line world chat messages
- 30 short LFG/trade-style messages
- 25 guild-chat style messages
- 20 two-to-four-line conversations

Examples of acceptable style:
"lf1m %instance% need %role%",
"anyone seen the rare in %zone% today?",
{"any enchanter on?", "depends what u need", "crusader if mats are cheap", "lol good luck"},

Now generate fresh original lines.
```

## Dad's MMO Lab Flavor

Add this block near the `Style` section when you want the chatter to fit the relaxed Dad's MMO Lab tone:

```text
The server is relaxed and cozy, with adult players who have limited time. Include occasional dad-friendly lines about short play sessions, kids waking up, spouse aggro, snack breaks, and needing to log soon, but keep it subtle and not every line.
```

## Stricter Lua Safety

Add this block near the `Output format` section if the model tends to return text that needs cleanup:

```text
Lua safety:
- Use double quotes for every string.
- Escape any internal double quotes.
- Do not use apostrophe-heavy contractions if they make the line awkward.
- Do not include backslashes unless escaping quotes.
- Do not wrap the answer in Markdown.
```

## Adding Generated Lines To Azeroth Chatter

Default rule: add every generated batch as a separate Lua pack file. Do not paste a generated batch directly into `data/chatter.lua` or `data/chatter_data.lua` unless the user explicitly asks for a direct merge.

The installer deploys Azeroth Chatter under the server's ALE Lua scripts directory:

```text
$SERVER_DIR/env/dist/etc/modules/lua_scripts/AzerothChatter/
```

On Dad's MMO Lab installs, `wow-manage.sh` renames the upstream `data/chatter.lua` file to:

```text
$SERVER_DIR/env/dist/etc/modules/lua_scripts/AzerothChatter/data/chatter_data.lua
```

This avoids a duplicate-basename conflict with `logic/chatter.lua`.

The ALE Scripts menu can re-sync Azeroth Chatter from the cloned source directory. For changes that survive reconfigure, always update the source clone first:

```text
$SERVER_DIR/ale_scripts/activechat/AzerothChatter/
```

Then mirror the same pack and loader change into the deployed copy:

```text
$SERVER_DIR/env/dist/etc/modules/lua_scripts/AzerothChatter/
```

### Preferred: Add New Chatter As Separate Pack Files

Keep each generation run in its own Lua file and have Azeroth Chatter load that file. This is easier to review, remove, and regenerate than pasting every batch into the large main chatter file.

Use a unique basename for every generated file. Do not create repeated files named `chatter.lua`, `extra.lua`, or `pack.lua` in different folders. Good names:

```text
AzerothChatter/data/chatter_packs/chatter_pack_001.lua
AzerothChatter/data/chatter_packs/chatter_pack_dad_lfg_001.lua
AzerothChatter/data/chatter_packs/chatter_pack_2026_06_24_1530.lua
```

Each pack file should return a plain Lua table:

```lua
return {
  "lf1m %instance% need %role%",
  "anyone seen the rare in %zone% today?",
  {"any mage for water?", "tips appreciated", "conjuring is my cardio"},
}
```

To install a generated pack:

1. Create the source pack file:

   ```text
   $SERVER_DIR/ale_scripts/activechat/AzerothChatter/data/chatter_packs/chatter_pack_<unique_name>.lua
   ```

2. Copy the same pack file to the deployed directory:

   ```text
   $SERVER_DIR/env/dist/etc/modules/lua_scripts/AzerothChatter/data/chatter_packs/chatter_pack_<unique_name>.lua
   ```

3. Add a small loader hook to the source `data/chatter.lua`, after the main `chatter` table is defined and before the one final `return chatter`.

   If the file currently says `return {`, convert it to:

   ```lua
   local chatter = {
   ```

   Then add this near the end:

   ```lua
   local ok, pack = pcall(require, "data.chatter_packs.chatter_pack_<unique_name>")
   if ok and type(pack) == "table" then
     for _, entry in ipairs(pack) do
       if type(entry) == "string" then
         table.insert(chatter.shared.lines, entry)
       elseif type(entry) == "table" then
         if entry.chain ~= nil then
           table.insert(chatter.shared.groups, entry)
         else
           table.insert(chatter.shared.groups, { chain = entry })
         end
       end
     end
   end

   return chatter
   ```

   This matches the current typed Azeroth Chatter structure: single strings are added to `shared.lines`; conversation arrays are wrapped as group `chain` entries in `shared.groups`.
   If multiple packs are enabled, add each pack hook above the same final `return chatter`; do not add more than one `return chatter`.

4. Copy the updated source data file to the deployed renamed file:

   ```text
   cp "$SERVER_DIR/ale_scripts/activechat/AzerothChatter/data/chatter.lua" \
      "$SERVER_DIR/env/dist/etc/modules/lua_scripts/AzerothChatter/data/chatter_data.lua"
   ```

5. Validate both files with Lua before reloading ALE. Example:

   ```text
   lua -e 'package.path = "/path/to/AzerothChatter/?.lua;" .. package.path; local t = assert(loadfile("/path/to/AzerothChatter/data/chatter.lua"))(); print(type(t), #(t.shared.lines), #(t.shared.groups))'
   ```

6. In-game, reload ALE:

   ```text
   .reload ale
   ```

7. Watch world or guild chat for a few minutes and check the worldserver console for Lua errors.

If a generated batch feels off, remove or comment out its loader hook and reload ALE.

### Fallback: Direct Paste Into The Main Chatter File

Only use this fallback when the user explicitly asks for the generated lines to be merged directly into the main chatter data file.

1. Open the deployed chatter data file:

   ```text
   $SERVER_DIR/env/dist/etc/modules/lua_scripts/AzerothChatter/data/chatter_data.lua
   ```

2. Find the existing Lua tables that contain chat strings or grouped conversation entries.

3. Paste the generated entries inside the matching table, before that table's closing `}`.

4. Make sure every entry is comma-separated. A valid single line looks like:

   ```lua
   "lf1m %instance% need %role%",
   ```

5. A valid grouped conversation looks like:

   ```lua
   {"any mage for water?", "tips appreciated", "conjuring is my cardio"},
   ```

6. Also update the source copy so the change survives reconfigure:

   ```text
   $SERVER_DIR/ale_scripts/activechat/AzerothChatter/data/chatter.lua
   ```

7. Save the file.

8. In-game, reload ALE:

   ```text
   .reload ale
   ```

9. Watch world or guild chat for a few minutes and check the worldserver console for Lua errors.

## Keeping Changes Through Reconfigure

The ALE Scripts menu can re-sync Azeroth Chatter from the cloned source directory. If you edit only the deployed `chatter_data.lua`, a later reconfigure may overwrite your additions.

For longer-lived changes, also update the cloned source copy before reconfiguring:

```text
$SERVER_DIR/ale_scripts/activechat/AzerothChatter/data/chatter.lua
```

After reconfiguring, Dad's MMO Lab will deploy it and rename it to `chatter_data.lua` automatically.

## Quick Review Checklist

- No Cataclysm-or-later references.
- No real player names, copied logs, slurs, or personal information.
- Lines are short enough to feel like chat.
- Placeholders are spelled exactly: `%zone%`, `%instance%`, `%class%`, `%role%`, `%bg%`.
- Every generated batch lives in a uniquely named separate pack file unless the user explicitly requested a direct merge.
- Source and deployed copies are both updated.
- Lua table syntax is still valid after adding the pack and loader hook.

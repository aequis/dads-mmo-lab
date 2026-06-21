local ADDON_NAME = "PlayerbotCommander"
local PBC = {}

PlayerbotCommanderDB = PlayerbotCommanderDB or {}

local CHANNELS = {
  { key = "AUTO", label = "Auto Group", icon = "INV_Misc_GroupNeedMore", desc = "Send to raid if you are in one, party if grouped, otherwise say." },
  { key = "PARTY", label = "Party", icon = "INV_Misc_GroupLooking", desc = "Always send bot commands to party chat." },
  { key = "RAID", label = "Raid", icon = "INV_Misc_GroupLooking", desc = "Always send bot commands to raid chat." },
  { key = "WHISPER", label = "Whisper", icon = "INV_Letter_15", desc = "Whisper commands to the bot named in the Target box." },
  { key = "SAY", label = "Say", icon = "INV_Misc_Note_02", desc = "Send commands to say chat." },
}

local FILTERS = {
  { key = "", label = "All Bots" },
  { key = "@tank", label = "Tanks" },
  { key = "@heal", label = "Healers" },
  { key = "@dps", label = "DPS" },
  { key = "@ranged", label = "Ranged" },
  { key = "@rangeddps", label = "Ranged DPS" },
  { key = "@meleedps", label = "Melee DPS" },
  { key = "@group1", label = "Group 1" },
  { key = "@group2", label = "Group 2" },
  { key = "@group3", label = "Group 3" },
  { key = "@group4", label = "Group 4" },
  { key = "@group5", label = "Group 5" },
  { key = "@warrior", label = "Warrior" },
  { key = "@paladin", label = "Paladin" },
  { key = "@hunter", label = "Hunter" },
  { key = "@rogue", label = "Rogue" },
  { key = "@priest", label = "Priest" },
  { key = "@deathknight", label = "Death Knight" },
  { key = "@shaman", label = "Shaman" },
  { key = "@mage", label = "Mage" },
  { key = "@warlock", label = "Warlock" },
  { key = "@druid", label = "Druid" },
}

local CATEGORIES = {
  {
    key = "core",
    label = "Core",
    icon = "Ability_Tracking",
    commands = {
      { text = "Follow", cmd = "follow" },
      { text = "Flee", cmd = "flee" },
      { text = "Stay", cmd = "stay" },
      { text = "Summon", cmd = "summon" },
      { text = "Attack", cmd = "attack" },
      { text = "Grind", cmd = "grind" },
      { text = "Release", cmd = "release" },
      { text = "Revive", cmd = "revive" },
      { text = "Leave Party", cmd = "leave" },
      { text = "Give Leader", cmd = "give leader" },
      { text = "LFG", cmd = "lfg" },
      { text = "LFG 5", cmd = "lfg 5" },
      { text = "Reset", cmd = "reset" },
      { text = "Reset Bot AI", cmd = "reset botAI" },
      { text = "Help", cmd = "help", noFilter = true },
    },
  },
  {
    key = "combat",
    label = "Combat",
    icon = "Ability_DualWield",
    commands = {
      { text = "Show Combat", cmd = "co ?" },
      { text = "Add Tank", cmd = "co +tank" },
      { text = "Add DPS", cmd = "co +dps" },
      { text = "Add Heal", cmd = "co +heal" },
      { text = "Assist", cmd = "co +assist" },
      { text = "AOE On", cmd = "co +aoe" },
      { text = "AOE Off", cmd = "co -aoe" },
      { text = "Boost On", cmd = "co +boost" },
      { text = "Boost Off", cmd = "co -boost" },
      { text = "Threat Care", cmd = "co +threat" },
      { text = "Crowd Control", cmd = "co +cc" },
      { text = "Avoid AOE", cmd = "co +avoid aoe" },
      { text = "Reset Combat", cmd = "co !" },
      { text = "Tank Assist", cmd = "co +tank,+tank assist" },
      { text = "Tank Pull", cmd = "co +tank,+tank assist,+pull" },
      { text = "Pull Back", cmd = "co +pull back" },
      { text = "Tank Face", cmd = "co +tank face" },
      { text = "Boss Pull", cmd = "co +assist,+threat,-aoe,-boost" },
      { text = "Burn Phase", cmd = "co +boost,+aoe" },
    },
  },
  {
    key = "noncombat",
    label = "Noncombat",
    icon = "Spell_Holy_Devotion",
    commands = {
      { text = "Show Noncombat", cmd = "nc ?" },
      { text = "Loot On", cmd = "nc +loot" },
      { text = "Loot Off", cmd = "nc -loot" },
      { text = "Food/Drink", cmd = "nc +food" },
      { text = "PVP On", cmd = "nc +pvp" },
      { text = "Reset Noncombat", cmd = "nc !" },
      { text = "Priest Shadow Buffs", cmd = "nc +rshadow" },
      { text = "Paladin DPS/Aura", cmd = "nc +bdps,+barmor" },
    },
  },
  {
    key = "loot",
    label = "Loot",
    icon = "INV_Misc_Bag_10",
    commands = {
      { text = "Loot All", cmd = "ll all" },
      { text = "Loot Normal", cmd = "ll normal" },
      { text = "Loot Gray", cmd = "ll gray" },
      { text = "Loot Quest", cmd = "ll quest" },
      { text = "Loot Skill", cmd = "ll skill" },
      { text = "Roll", cmd = "roll" },
      { text = "Sell Gray", cmd = "s *" },
      { text = "Sell Vendor Trash", cmd = "s vendor" },
      { text = "Stats", cmd = "stats" },
      { text = "Equip Item", cmd = "e %s", needsParam = true, paramLabel = "item link/name" },
      { text = "Unequip Item", cmd = "ue %s", needsParam = true, paramLabel = "item link/name" },
      { text = "Use Item", cmd = "u %s", needsParam = true, paramLabel = "item link/name" },
      { text = "Add Loot Item", cmd = "ll %s", needsParam = true, paramLabel = "item link/name" },
      { text = "Remove Loot Item", cmd = "ll -%s", needsParam = true, paramLabel = "item link/name" },
      { text = "Roll Item", cmd = "roll %s", needsParam = true, paramLabel = "item link/name" },
      { text = "Give Money", cmd = "%s", needsParam = true, paramLabel = "2g 3s 5c" },
    },
  },
  {
    key = "quests",
    label = "Quests",
    icon = "INV_Misc_Note_01",
    commands = {
      { text = "Quest Summary", cmd = "quests" },
      { text = "All Quests", cmd = "quests all" },
      { text = "Accept All", cmd = "accept *" },
      { text = "Talk", cmd = "talk" },
      { text = "Accept Quest", cmd = "accept %s", needsParam = true, paramLabel = "quest link/name" },
      { text = "Drop Quest", cmd = "drop %s", needsParam = true, paramLabel = "quest link/name" },
      { text = "Quest Status", cmd = "%s", needsParam = true, paramLabel = "quest link/name" },
      { text = "Choose Reward", cmd = "r %s", needsParam = true, paramLabel = "reward item link/name" },
      { text = "Use Game Object", cmd = "u %s", needsParam = true, paramLabel = "object name" },
    },
  },
  {
    key = "setup",
    label = "Setup",
    icon = "Trade_BlackSmithing",
    commands = {
      { text = "Maintenance", cmd = "maintenance" },
      { text = "Auto Gear", cmd = "autogear" },
      { text = "Talents", cmd = "talents" },
      { text = "Spec List", cmd = "talents spec list" },
      { text = "Glyphs", cmd = "glyphs" },
      { text = "Spells", cmd = "spells" },
      { text = "Trainer", cmd = "trainer" },
      { text = "Trainer Learn", cmd = "trainer learn" },
      { text = "Set Spec", cmd = "talents spec %s", needsParam = true, paramLabel = "spec name" },
      { text = "Apply Talents", cmd = "talents apply %s", needsParam = true, paramLabel = "talent link" },
      { text = "Equip Glyphs", cmd = "glyph equip %s", needsParam = true, paramLabel = "GlyphID1 GlyphID2" },
      { text = "Cast Spell", cmd = "cast %s", needsParam = true, paramLabel = "spell name" },
      { text = "Cast On Player", cmd = "cast %s on %t", needsParam = true, paramLabel = "spell name", needsTarget = true },
    },
  },
  {
    key = "targets",
    label = "Targets",
    icon = "Ability_Hunter_SniperShot",
    commands = {
      { text = "RTI Skull", cmd = "rti skull" },
      { text = "RTI Cross", cmd = "rti cross" },
      { text = "CC Moon", cmd = "rti cc moon" },
      { text = "Attack RTI Target", cmd = "attack rti target" },
      { text = "Focus Heal List", cmd = "focus heal ?" },
      { text = "Focus Heal Clear", cmd = "focus heal clear" },
      { text = "Focus Heal Add", cmd = "focus heal +%s", needsParam = true, paramLabel = "player name" },
      { text = "Focus Heal Remove", cmd = "focus heal -%s", needsParam = true, paramLabel = "player name" },
      { text = "RTSC Enable", cmd = "rtsc" },
      { text = "RTSC Cancel", cmd = "rtsc cancel" },
      { text = "RTSC Save Slot", cmd = "rtsc save %s", needsParam = true, paramLabel = "1" },
      { text = "RTSC Go Slot", cmd = "rtsc go %s", needsParam = true, paramLabel = "1" },
      { text = "RTSC Unsave Slot", cmd = "rtsc unsave %s", needsParam = true, paramLabel = "1" },
      { text = "RTSC Go Saved", cmd = "rtsc go save" },
    },
  },
  {
    key = "pets",
    label = "Pets",
    icon = "Ability_Hunter_BeastCall",
    commands = {
      { text = "Pet Aggressive", cmd = "pet aggressive" },
      { text = "Pet Defensive", cmd = "pet defensive" },
      { text = "Pet Passive", cmd = "pet passive" },
      { text = "Pet Stance", cmd = "pet stance" },
      { text = "Pet Attack", cmd = "pet attack" },
      { text = "Pet Follow", cmd = "pet follow" },
      { text = "Pet Stay", cmd = "pet stay" },
      { text = "Tame Help", cmd = "tame" },
      { text = "Tame Name", cmd = "tame name \"%s\"", needsParam = true, paramLabel = "name" },
      { text = "Tame ID", cmd = "tame id \"%s\"", needsParam = true, paramLabel = "creature ID" },
      { text = "Tame Family", cmd = "tame family \"%s\"", needsParam = true, paramLabel = "family" },
      { text = "Tame Rename", cmd = "tame rename \"%s\"", needsParam = true, paramLabel = "new name" },
    },
  },
  {
    key = "gm",
    label = "GM",
    icon = "INV_Misc_Key_03",
    gm = true,
    commands = {
      { text = "Add Class", cmd = ".playerbots bot addclass %s", needsParam = true, paramLabel = "warrior/paladin/hunter/rogue/priest/shaman/mage/warlock/druid/dk" },
      { text = "Add Class Male", cmd = ".playerbots bot addclass %s male", needsParam = true, paramLabel = "class" },
      { text = "Add Class Female", cmd = ".playerbots bot addclass %s female", needsParam = true, paramLabel = "class" },
      { text = "Init Bot Auto", cmd = ".playerbots bot init=auto %s", needsParam = true, paramLabel = "Botname" },
      { text = "Init Bot Rare", cmd = ".playerbots bot init=rare %s", needsParam = true, paramLabel = "Botname" },
      { text = "Init Bot Epic", cmd = ".playerbots bot init=epic %s", needsParam = true, paramLabel = "Botname" },
      { text = "Add Bot(s)", cmd = ".playerbots bot add %s", needsParam = true, paramLabel = "Name1,Name2 or *" },
      { text = "Remove Bot(s)", cmd = ".playerbots bot remove %s", needsParam = true, paramLabel = "Name1,Name2 or *" },
      { text = "Add Account", cmd = ".playerbots bot addaccount %s", needsParam = true, paramLabel = "ACCOUNTNAME" },
      { text = "List Altbots", cmd = ".playerbots bot list" },
      { text = "Help Playerbots", cmd = ".help playerbots" },
      { text = "Help Playerbot", cmd = ".help playerbot" },
      { text = "Commands", cmd = ".commands" },
    },
  },
}

local COMMAND_DESCRIPTIONS = {
  ["Follow"] = "Bots run back to you and follow your movement.",
  ["Flee"] = "Bots run toward you and avoid fighting while regrouping.",
  ["Stay"] = "Bots stop moving and hold their current position.",
  ["Summon"] = "Teleports or summons bots to you, depending on server config.",
  ["Attack"] = "Bots attack your current target or the target implied by the command.",
  ["Grind"] = "Bots freely attack nearby valid enemies.",
  ["Release"] = "Dead bots release spirit.",
  ["Revive"] = "Dead bots revive near a spirit healer when possible.",
  ["Leave Party"] = "Bots leave your party or raid.",
  ["Give Leader"] = "The bot passes party or raid leader to you.",
  ["LFG"] = "Bot tries to join/fill your group with an appropriate role.",
  ["LFG 5"] = "Bot tries to build or fill a 5-player dungeon group.",
  ["Reset"] = "Clears a stuck current bot action, movement, or cast.",
  ["Reset Bot AI"] = "Resets the bot AI state more aggressively.",
  ["Help"] = "Asks a bot to list available bot commands.",

  ["Show Combat"] = "Shows the bot's active combat strategies.",
  ["Add Tank"] = "Adds tank behavior.",
  ["Add DPS"] = "Adds damage-dealer behavior.",
  ["Add Heal"] = "Adds healer behavior.",
  ["Assist"] = "Makes bots focus targets together instead of splitting damage.",
  ["AOE On"] = "Allows area damage and multi-target combat behavior.",
  ["AOE Off"] = "Prevents area damage when you need controlled pulls.",
  ["Boost On"] = "Allows bots to use major cooldowns and burst tools.",
  ["Boost Off"] = "Prevents bots from spending major cooldowns.",
  ["Threat Care"] = "Makes DPS bots try harder not to pull threat.",
  ["Crowd Control"] = "Enables crowd-control behavior where supported.",
  ["Avoid AOE"] = "Makes bots try to avoid harmful ground effects.",
  ["Reset Combat"] = "Clears active combat strategies.",
  ["Tank Assist"] = "Tank bots try to pull enemies off group members.",
  ["Tank Pull"] = "Tank bots pull enemies and establish control.",
  ["Pull Back"] = "Tank pulls and returns to the pull point.",
  ["Tank Face"] = "Tank turns the target away from the group.",
  ["Boss Pull"] = "Controlled boss mode: assist, reduce threat issues, avoid AOE and burst.",
  ["Burn Phase"] = "Burst mode: enables boost cooldowns and AOE.",

  ["Show Noncombat"] = "Shows active non-combat strategies.",
  ["Loot On"] = "Enables bot looting behavior.",
  ["Loot Off"] = "Disables bot looting behavior.",
  ["Food/Drink"] = "Allows bots to eat or drink when needed.",
  ["PVP On"] = "Enables PvP-oriented non-combat behavior.",
  ["Reset Noncombat"] = "Clears active non-combat strategies.",
  ["Priest Shadow Buffs"] = "Asks priest bots to use shadow-related non-combat behavior.",
  ["Paladin DPS/Aura"] = "Asks paladin bots to use DPS and armor/aura behavior.",

  ["Loot All"] = "Bots loot everything they can.",
  ["Loot Normal"] = "Bots loot most items while avoiding bind-on-pickup trouble.",
  ["Loot Gray"] = "Bots loot only gray vendor-trash items.",
  ["Loot Quest"] = "Bots loot quest items.",
  ["Loot Skill"] = "Bots loot profession or gathering items.",
  ["Roll"] = "Bots roll for currently available loot.",
  ["Sell Gray"] = "Bots sell all gray items.",
  ["Sell Vendor Trash"] = "Bots sell sellable vendor trash.",
  ["Stats"] = "Bots report inventory, money, XP, and related stats.",
  ["Equip Item"] = "Bot equips the item from the Param box.",
  ["Unequip Item"] = "Bot unequips the item from the Param box.",
  ["Use Item"] = "Bot uses the item from the Param box.",
  ["Add Loot Item"] = "Adds the Param item to the bot loot list.",
  ["Remove Loot Item"] = "Removes the Param item from the bot loot list.",
  ["Roll Item"] = "Bots roll for the Param item if useful.",
  ["Give Money"] = "Bot gives you the money amount in Param, such as 2g 3s 5c.",

  ["Quest Summary"] = "Bots show a summary of quest status.",
  ["All Quests"] = "Bots list all quests in their quest log.",
  ["Accept All"] = "Bots accept all available quests from your selected quest giver.",
  ["Talk"] = "Bots talk to your selected NPC, often for turn-ins.",
  ["Accept Quest"] = "Bots accept the quest named or linked in Param.",
  ["Drop Quest"] = "Bots abandon the quest named or linked in Param.",
  ["Quest Status"] = "Bots report status for the quest in Param.",
  ["Choose Reward"] = "Bots choose the quest reward item in Param.",
  ["Use Game Object"] = "Bots use the game object named in Param.",

  ["Maintenance"] = "Bots learn available spells/skills, repair, enchant, and restock where supported.",
  ["Auto Gear"] = "Bots automatically equip better gear based on server rules.",
  ["Talents"] = "Bots show their current talent/spec state.",
  ["Spec List"] = "Bots list specs available for their class.",
  ["Glyphs"] = "Bots show equipped glyphs.",
  ["Spells"] = "Bots list known spells.",
  ["Trainer"] = "Bots show what they can learn from your selected trainer.",
  ["Trainer Learn"] = "Bots learn available trainer skills.",
  ["Set Spec"] = "Forces the bot spec named in Param.",
  ["Apply Talents"] = "Applies the talent link from Param.",
  ["Equip Glyphs"] = "Equips glyph IDs listed in Param.",
  ["Cast Spell"] = "Bot casts the spell named in Param.",
  ["Cast On Player"] = "Bot casts the Param spell on the player in Target.",

  ["RTI Skull"] = "Bots prioritize the skull-marked target.",
  ["RTI Cross"] = "Bots prioritize the cross-marked target.",
  ["CC Moon"] = "Bots use moon as the crowd-control target.",
  ["Attack RTI Target"] = "Bots attack their assigned raid-icon target.",
  ["Focus Heal List"] = "Shows focused healing targets.",
  ["Focus Heal Clear"] = "Clears focused healing targets.",
  ["Focus Heal Add"] = "Adds the player in Param as a focused healing target.",
  ["Focus Heal Remove"] = "Removes the player in Param from focused healing.",
  ["RTSC Enable"] = "Enables RTSC positioning and grants the targeting spell.",
  ["RTSC Cancel"] = "Disables RTSC positioning.",
  ["RTSC Save Slot"] = "Saves a clicked location to the Param slot.",
  ["RTSC Go Slot"] = "Sends bots to the saved Param slot.",
  ["RTSC Unsave Slot"] = "Clears the saved Param slot.",
  ["RTSC Go Saved"] = "Sends bots back to their saved RTSC positions.",

  ["Pet Aggressive"] = "Sets hunter/warlock bot pets to aggressive.",
  ["Pet Defensive"] = "Sets hunter/warlock bot pets to defensive.",
  ["Pet Passive"] = "Sets hunter/warlock bot pets to passive.",
  ["Pet Stance"] = "Shows the pet's current stance.",
  ["Pet Attack"] = "Orders bot pets to attack.",
  ["Pet Follow"] = "Orders bot pets to follow their master.",
  ["Pet Stay"] = "Orders bot pets to stay.",
  ["Tame Help"] = "Shows tame command help.",
  ["Tame Name"] = "Summons a tameable pet by name from Param.",
  ["Tame ID"] = "Summons a tameable pet by creature ID from Param.",
  ["Tame Family"] = "Summons a tameable pet from the family in Param.",
  ["Tame Rename"] = "Renames the current pet to the Param value.",

  ["Add Class"] = "Adds an available same-faction AddClass bot by class, leveled and prepared for quick party formation.",
  ["Add Class Male"] = "Adds an available male AddClass bot from the class in Param.",
  ["Add Class Female"] = "Adds an available female AddClass bot from the class in Param.",
  ["Init Bot Auto"] = "Reinitializes the named AddClass bot to your current level with a gear score limit based on your gear.",
  ["Init Bot Rare"] = "Reinitializes the named AddClass bot to your current level with rare-quality gear.",
  ["Init Bot Epic"] = "Reinitializes the named AddClass bot to your current level with epic-quality gear.",
  ["Add Bot(s)"] = "Logs in named altbots from Param, or * for all relevant altbots.",
  ["Remove Bot(s)"] = "Logs out named altbots from Param, or * for grouped altbots.",
  ["Add Account"] = "Logs in every altbot on the account named in Param.",
  ["List Altbots"] = "Lists available altbots.",
  ["Help Playerbots"] = "Shows server help for the playerbots command group.",
  ["Help Playerbot"] = "Shows server help for playerbot commands.",
  ["Commands"] = "Lists available server commands for your GM rank.",
}

local CATEGORY_DESCRIPTIONS = {
  core = "Movement, regrouping, attack, reset, LFG, and basic party-control commands.",
  combat = "Combat strategies for tanking, healing, assisting, threat, AOE, pulls, and burst phases.",
  noncombat = "Out-of-combat behavior such as looting, eating/drinking, PvP mode, and class support strategies.",
  loot = "Loot rules, rolling, selling trash, inventory stats, item use, item equip, and money transfer commands.",
  quests = "Quest log checks, accepting/dropping quests, talking to NPCs, choosing rewards, and object use.",
  setup = "Altbot maintenance, auto-gearing, talents, glyphs, spells, trainer learning, and direct spell casts.",
  targets = "Raid target icons, focused healing, RTSC saved positions, and bot movement to marked locations.",
  pets = "Hunter/warlock pet stances, pet orders, tame helpers, pet lookup, and pet rename commands.",
  gm = "GM-only altbot login/logout/list commands plus server help and command discovery.",
}

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0[PBC]|r " .. msg)
end

local function Trim(value)
  if not value then return "" end
  return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function GetChatEditBox()
  return DEFAULT_CHAT_FRAME.editBox or ChatFrameEditBox or ChatFrame1EditBox
end

local function RunSlashCommand(command)
  local editBox = GetChatEditBox()
  if not editBox then
    Print("Could not find the chat edit box for: " .. command)
    return
  end

  editBox:SetText(command)
  ChatEdit_SendText(editBox, 0)
end

local function ResolveChannel()
  local channel = PlayerbotCommanderDB.channel or "AUTO"
  if channel ~= "AUTO" then return channel end
  if GetNumRaidMembers and GetNumRaidMembers() > 0 then return "RAID" end
  if GetNumPartyMembers and GetNumPartyMembers() > 0 then return "PARTY" end
  return "SAY"
end

local function FormatCommand(entry)
  local command = entry.cmd
  local param = Trim(PBC.paramBox:GetText())
  local target = Trim(PBC.targetBox:GetText())

  if entry.needsParam and param == "" then
    Print("Enter " .. (entry.paramLabel or "a value") .. " first.")
    return nil
  end

  if entry.needsTarget and target == "" then
    Print("Enter a target player first.")
    return nil
  end

  if entry.needsParam then
    command = string.gsub(command, "%%s", function() return param end)
  end

  if entry.needsTarget then
    command = string.gsub(command, "%%t", function() return target end)
  end

  local filter = PlayerbotCommanderDB.filter or ""
  if filter ~= "" and not entry.noFilter and not entry.gm then
    command = filter .. " " .. command
  end

  return command
end

local function SendBotCommand(entry)
  local command = FormatCommand(entry)
  if not command then return end

  if entry.gm or string.sub(command, 1, 1) == "." then
    RunSlashCommand(command)
    Print("Ran " .. command)
    return
  end

  local channel = ResolveChannel()
  if channel == "WHISPER" then
    local target = Trim(PBC.targetBox:GetText())
    if target == "" then
      Print("Enter a bot name for whisper mode.")
      return
    end
    SendChatMessage(command, "WHISPER", nil, target)
    Print("Whispered " .. target .. ": " .. command)
    return
  end

  SendChatMessage(command, channel)
  Print("Sent to " .. string.lower(channel) .. ": " .. command)
end

local function OpenMacroText(command)
  local channel = PlayerbotCommanderDB.channel or "AUTO"
  local prefix = "/p "
  if channel == "RAID" then prefix = "/r " end
  if channel == "SAY" then prefix = "/s " end
  if channel == "WHISPER" then
    local target = Trim(PBC.targetBox:GetText())
    if target == "" then target = "Botname" end
    prefix = "/w " .. target .. " "
  end

  local editBox = GetChatEditBox()
  if editBox then
    editBox:Show()
    editBox:SetFocus()
    editBox:SetText(prefix .. command)
  end
end

local function AddLabel(parent, text, x, y)
  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  label:SetText(text)
  return label
end

local function SaveFramePosition(frame)
  local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
  PlayerbotCommanderDB.position = {
    point = point or "CENTER",
    relativePoint = relativePoint or "CENTER",
    x = xOfs or 0,
    y = yOfs or 0,
  }
end

local function IconPath(icon)
  return "Interface\\Icons\\" .. (icon or "INV_Misc_QuestionMark")
end

local function GuessCommandIcon(entry, category)
  local cmd = string.lower(entry.cmd or "")
  local text = string.lower(entry.text or "")

  if category and category.gm then return "INV_Misc_Key_03" end
  if string.find(cmd, "follow") then return "Ability_Tracking" end
  if string.find(cmd, "flee") then return "Ability_Rogue_Sprint" end
  if string.find(cmd, "stay") then return "Spell_Nature_TimeStop" end
  if string.find(cmd, "summon") then return "Spell_Arcane_Blink" end
  if string.find(cmd, "attack") then return "Ability_DualWield" end
  if string.find(cmd, "grind") then return "Ability_Warrior_Cleave" end
  if string.find(cmd, "release") then return "Spell_Shadow_Twilight" end
  if string.find(cmd, "revive") then return "Spell_Holy_Resurrection" end
  if string.find(cmd, "leave") then return "Ability_Rogue_FeignDeath" end
  if string.find(cmd, "leader") then return "INV_BannerPVP_02" end
  if string.find(cmd, "lfg") then return "INV_Misc_GroupLooking" end
  if string.find(cmd, "reset") then return "Ability_Hunter_Readiness" end
  if string.find(cmd, "help") or string.find(cmd, "%?") then return "INV_Misc_QuestionMark" end
  if string.find(cmd, "tank") then return "Ability_Warrior_DefensiveStance" end
  if string.find(cmd, "heal") then return "Spell_Holy_FlashHeal" end
  if string.find(cmd, "dps") then return "Ability_Warrior_BattleShout" end
  if string.find(cmd, "assist") then return "Ability_Hunter_SniperShot" end
  if string.find(cmd, "aoe") then return "Spell_Fire_FlameBolt" end
  if string.find(cmd, "boost") then return "Ability_Warrior_InnerRage" end
  if string.find(cmd, "threat") then return "Ability_Warrior_Challange" end
  if string.find(cmd, "cc") then return "Spell_Frost_ChainsOfIce" end
  if string.find(cmd, "avoid") then return "Ability_Rogue_Evasion" end
  if string.find(cmd, "pull") then return "Ability_Marksmanship" end
  if string.find(cmd, "loot") or string.find(cmd, "ll ") then return "INV_Misc_Bag_10" end
  if string.find(cmd, "roll") then return "INV_Misc_Dice_01" end
  if string.find(cmd, "s %*") or string.find(cmd, "vendor") then return "INV_Misc_Coin_01" end
  if string.find(cmd, "stats") then return "INV_Misc_Note_06" end
  if string.find(text, "equip") then return "INV_Chest_Chain_05" end
  if string.find(text, "use") then return "INV_Misc_Gear_01" end
  if string.find(text, "money") then return "INV_Misc_Coin_05" end
  if string.find(cmd, "quest") or string.find(cmd, "accept") or string.find(cmd, "drop") then return "INV_Misc_Note_01" end
  if string.find(cmd, "talk") then return "INV_Misc_Head_Human_01" end
  if string.find(text, "reward") then return "INV_Box_01" end
  if string.find(cmd, "maintenance") then return "Trade_BlackSmithing" end
  if string.find(cmd, "autogear") then return "INV_Chest_Plate05" end
  if string.find(cmd, "talents") then return "Ability_Marksmanship" end
  if string.find(cmd, "glyph") then return "INV_Glyph_MajorDeathKnight" end
  if string.find(cmd, "spell") or string.find(cmd, "cast") then return "Spell_Nature_WispSplode" end
  if string.find(cmd, "trainer") then return "Ability_Repair" end
  if string.find(cmd, "rti") then return "Ability_Hunter_SniperShot" end
  if string.find(cmd, "focus") then return "Spell_Holy_FlashHeal" end
  if string.find(cmd, "rtsc") then return "INV_Misc_Map_01" end
  if string.find(cmd, "pet") then return "Ability_Hunter_BeastCall" end
  if string.find(cmd, "tame") then return "Ability_Hunter_BeastTaming" end

  return category and category.icon or "INV_Misc_QuestionMark"
end

local function AddIconButton(parent, icon, size)
  local button = CreateFrame("Button", nil, parent)
  button:SetWidth(size)
  button:SetHeight(size)

  button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
  local normal = button:GetNormalTexture()
  normal:SetAllPoints(button)

  button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
  local pushed = button:GetPushedTexture()
  pushed:SetAllPoints(button)

  button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  local highlight = button:GetHighlightTexture()
  highlight:SetBlendMode("ADD")
  highlight:SetAllPoints(button)

  local texture = button:CreateTexture(nil, "ARTWORK")
  texture:SetTexture(IconPath(icon))
  texture:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
  texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
  texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  button.icon = texture

  return button
end

local function UpdateChannelButtons()
  if not PBC.channelButtons then return end
  local selected = PlayerbotCommanderDB.channel or "AUTO"
  for _, button in ipairs(PBC.channelButtons) do
    if button.channelKey == selected then
      button:SetAlpha(1)
      button:LockHighlight()
    else
      button:SetAlpha(0.45)
      button:UnlockHighlight()
    end
  end
end

local function SelectChannel(channel)
  PlayerbotCommanderDB.channel = channel.key
  UpdateChannelButtons()
end

local function UpdateCategoryButtons()
  if not PBC.categoryButtons then return end
  local selected = PlayerbotCommanderDB.category or "core"
  for _, button in ipairs(PBC.categoryButtons) do
    if button.categoryKey == selected then
      button:SetAlpha(1)
      button:LockHighlight()
      button.selectedBorder:Show()
    else
      button:SetAlpha(0.72)
      button:UnlockHighlight()
      button.selectedBorder:Hide()
    end
  end
end

local function AddEditBox(parent, width)
  local box = CreateFrame("EditBox", nil, parent)
  box:SetAutoFocus(false)
  box:SetWidth(width)
  box:SetHeight(24)
  box:SetFontObject(ChatFontNormal)
  box:SetTextInsets(7, 7, 0, 0)
  box:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  box:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
  box:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  return box
end

local function InitDropdown(dropdown, width, items, currentGetter, setter)
  dropdown:SetWidth(width)
  UIDropDownMenu_SetWidth(dropdown, width)
  UIDropDownMenu_Initialize(dropdown, function()
    for _, item in ipairs(items) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = item.label
      info.value = item.key
      info.checked = currentGetter() == item.key
      info.func = function(self)
        setter(self.value)
        UIDropDownMenu_SetSelectedValue(dropdown, self.value)
        UIDropDownMenu_SetText(dropdown, item.label)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
end

local function GetLabel(items, key)
  for _, item in ipairs(items) do
    if item.key == key then return item.label end
  end
  return key
end

local function DrawCommands(category)
  for _, child in ipairs(PBC.commandButtons) do
    child:Hide()
  end
  PBC.commandButtons = {}

  PBC.categoryTitle:SetText(category.label)

  local xStart, yStart = 17, -124
  local iconSize, gap = 32, 3
  local columns = 10

  for i, entry in ipairs(category.commands) do
    local col = (i - 1) % columns
    local row = math.floor((i - 1) / columns)
    local button = AddIconButton(PBC.frame, GuessCommandIcon(entry, category), iconSize)
    button:SetPoint("TOPLEFT", PBC.frame, "TOPLEFT", xStart + (col * (iconSize + gap)), yStart - (row * (iconSize + gap)))
    button:SetScript("OnClick", function(self, mouseButton)
      local command = FormatCommand(entry)
      if not command then return end
      if mouseButton == "RightButton" and not entry.gm then
        OpenMacroText(command)
      else
        SendBotCommand(entry)
      end
    end)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(entry.text, 1, 0.82, 0)
      if COMMAND_DESCRIPTIONS[entry.text] then
        GameTooltip:AddLine(COMMAND_DESCRIPTIONS[entry.text], 0.9, 0.9, 0.9, 1)
      end
      GameTooltip:AddLine("Command: " .. entry.cmd, 0.45, 0.75, 1)
      if entry.needsParam then
        GameTooltip:AddLine("Uses the parameter box: " .. (entry.paramLabel or "value"), 0.7, 0.7, 0.7)
      end
      if entry.needsTarget then
        GameTooltip:AddLine("Uses the target box too.", 0.7, 0.7, 0.7)
      end
      if not entry.gm then
        GameTooltip:AddLine("Right-click to place macro text in chat.", 0.7, 0.7, 0.7)
      end
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    table.insert(PBC.commandButtons, button)
  end
end

local function SelectCategory(category)
  PlayerbotCommanderDB.category = category.key
  UpdateCategoryButtons()
  DrawCommands(category)
end

local function CreateFrameUI()
  PlayerbotCommanderDB.channel = PlayerbotCommanderDB.channel or "AUTO"
  PlayerbotCommanderDB.filter = PlayerbotCommanderDB.filter or ""
  PlayerbotCommanderDB.category = PlayerbotCommanderDB.category or "core"

  local frame = CreateFrame("Frame", "PlayerbotCommanderFrame", UIParent)
  PBC.frame = frame
  frame:SetWidth(374)
  frame:SetHeight(246)
  frame:SetClampedToScreen(true)
  if PlayerbotCommanderDB.position then
    frame:SetPoint(
      PlayerbotCommanderDB.position.point or "CENTER",
      UIParent,
      PlayerbotCommanderDB.position.relativePoint or "CENTER",
      PlayerbotCommanderDB.position.x or 0,
      PlayerbotCommanderDB.position.y or 0
    )
  else
    frame:SetPoint("CENTER")
  end
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self)
  end)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  frame:SetScript("OnShow", function()
    PlayerbotCommanderDB.shown = true
  end)
  frame:SetScript("OnHide", function()
    PlayerbotCommanderDB.shown = false
  end)
  frame:Hide()

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -14)
  title:SetText("Playerbot Commander")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

  AddLabel(frame, "Channel", 18, -40)
  PBC.channelButtons = {}
  for i, channel in ipairs(CHANNELS) do
    local button = AddIconButton(frame, channel.icon, 24)
    button.channelKey = channel.key
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 70 + ((i - 1) * 26), -34)
    button:SetScript("OnClick", function() SelectChannel(channel) end)
    button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(channel.label, 1, 0.82, 0)
      GameTooltip:AddLine(channel.desc, 0.9, 0.9, 0.9, 1)
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    table.insert(PBC.channelButtons, button)
  end
  UpdateChannelButtons()

  AddLabel(frame, "Filter", 205, -40)
  local filterDrop = CreateFrame("Frame", "PlayerbotCommanderFilterDropDown", frame, "UIDropDownMenuTemplate")
  filterDrop:SetPoint("TOPLEFT", frame, "TOPLEFT", 240, -31)
  InitDropdown(filterDrop, 80, FILTERS, function()
    return PlayerbotCommanderDB.filter or ""
  end, function(value)
    PlayerbotCommanderDB.filter = value
  end)
  UIDropDownMenu_SetSelectedValue(filterDrop, PlayerbotCommanderDB.filter)
  UIDropDownMenu_SetText(filterDrop, GetLabel(FILTERS, PlayerbotCommanderDB.filter))

  AddLabel(frame, "Target", 18, -68)
  PBC.targetBox = AddEditBox(frame, 106)
  PBC.targetBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 62, -60)

  AddLabel(frame, "Param", 190, -68)
  PBC.paramBox = AddEditBox(frame, 120)
  PBC.paramBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 230, -60)

  local tabStrip = CreateFrame("Frame", nil, frame)
  tabStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -84)
  tabStrip:SetWidth(302)
  tabStrip:SetHeight(36)
  tabStrip:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  tabStrip:SetBackdropColor(0, 0, 0, 0.55)
  tabStrip:SetBackdropBorderColor(0.55, 0.45, 0.25, 0.9)

  PBC.categoryButtons = {}
  local catX, catY = 20, -89
  for i, category in ipairs(CATEGORIES) do
    local button = AddIconButton(frame, category.icon, 30)
    button.categoryKey = category.key
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", catX + ((i - 1) * 32), catY)
    button.selectedBorder = button:CreateTexture(nil, "OVERLAY")
    button.selectedBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.selectedBorder:SetBlendMode("ADD")
    button.selectedBorder:SetWidth(48)
    button.selectedBorder:SetHeight(48)
    button.selectedBorder:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.selectedBorder:Hide()
    button:SetScript("OnClick", function() SelectCategory(category) end)
    button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(category.label, 1, 0.82, 0)
      if CATEGORY_DESCRIPTIONS[category.key] then
        GameTooltip:AddLine(CATEGORY_DESCRIPTIONS[category.key], 0.9, 0.9, 0.9, 1)
      end
      GameTooltip:AddLine(#category.commands .. " commands", 0.45, 0.75, 1)
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    category.button = button
    table.insert(PBC.categoryButtons, button)
  end

  PBC.categoryTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  PBC.categoryTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 316, -92)
  PBC.categoryTitle:SetText("Commands")
  PBC.categoryTitle:Hide()

  PBC.gmNote = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  PBC.gmNote:SetPoint("TOPLEFT", frame, "TOPLEFT", 316, -106)
  PBC.gmNote:SetWidth(48)
  PBC.gmNote:SetText("GM")
  PBC.gmNote:Hide()

  local customLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  customLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 31)
  customLabel:SetText("Custom")

  PBC.customBox = AddEditBox(frame, 252)
  PBC.customBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 68, 24)

  local sendCustom = AddIconButton(frame, "Spell_ChargePositive", 26)
  sendCustom:SetPoint("LEFT", PBC.customBox, "RIGHT", 5, 0)
  sendCustom:SetScript("OnClick", function()
    local cmd = Trim(PBC.customBox:GetText())
    if cmd == "" then return end
    SendBotCommand({ cmd = cmd })
  end)
  sendCustom:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Send Custom Command", 1, 0.82, 0)
    GameTooltip:AddLine("Sends the text from the custom command box.", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  sendCustom:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 11)
  hint:SetText("Right-click: stage chat. Shift-click links into Param.")

  PBC.commandButtons = {}
  local selected = CATEGORIES[1]
  for _, category in ipairs(CATEGORIES) do
    if category.key == PlayerbotCommanderDB.category then
      selected = category
      break
    end
  end
  SelectCategory(selected)
end

SLASH_PLAYERBOTCOMMANDER1 = "/pbc"
SLASH_PLAYERBOTCOMMANDER2 = "/pbots"
SlashCmdList.PLAYERBOTCOMMANDER = function()
  if not PBC.frame then CreateFrameUI() end
  if PBC.frame:IsShown() then
    PBC.frame:Hide()
  else
    PBC.frame:Show()
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
  if addon == ADDON_NAME then
    if PlayerbotCommanderDB.shown == nil then
      PlayerbotCommanderDB.shown = true
    end
    local shouldShow = PlayerbotCommanderDB.shown
    CreateFrameUI()
    if shouldShow then
      PBC.frame:Show()
    end
    Print("loaded. Type /pbc or /pbots.")
  end
end)

# Playerbots Rogue Follow-Master Stealth Patch

This patch teaches rogue playerbots to mirror the master's stealth state out of combat and prevents idle AI actions from breaking that mirrored stealth while the master is still stealthed.

Patch file:

```text
/Users/nesadi/projects/dads-mmo-lab/patches/playerbots/playerbots-rogue-follow-master-stealth.patch
```

## Behavior

- If the master has `stealth` or `prowl`, a non-combat rogue bot will cast `stealth` when possible.
- If the master leaves `stealth` or `prowl`, a stealthed rogue bot will unstealth while out of combat.
- While the master remains stealthed or prowled, rogue bot unstealth triggers are suppressed.
- Direct `UnstealthAction` execution is also blocked while the master remains stealthed or prowled.
- Poison, sharpening stone, weightstone, and oil refresh actions no longer remove stealth when the bot is preserving the master's stealth state.

The imbue guard matters because rogue poison upkeep can run as an idle action. Without the guard, the bot may appear to unstealth randomly even when no enemy is nearby.

## Files Touched

- `src/Ai/Class/Rogue/RogueTriggers.cpp`
- `src/Ai/Class/Rogue/RogueTriggers.h`
- `src/Ai/Class/Rogue/RogueAiObjectContext.cpp`
- `src/Ai/Class/Rogue/Strategy/GenericRogueNonCombatStrategy.cpp`
- `src/Ai/Class/Rogue/Action/RogueActions.cpp`
- `src/Ai/Base/Actions/ImbueAction.cpp`

## Applying After Pulling Upstream

Run these commands from the playerbots module root:

```bash
cd /Users/nesadi/wow-server-playerbots/modules/mod-playerbots
git apply --check /Users/nesadi/projects/dads-mmo-lab/patches/playerbots/playerbots-rogue-follow-master-stealth.patch
git apply /Users/nesadi/projects/dads-mmo-lab/patches/playerbots/playerbots-rogue-follow-master-stealth.patch
```

Then rebuild and restart the worldserver from the server checkout:

```bash
cd /Users/nesadi/wow-server-playerbots
docker compose build ac-worldserver
docker compose up -d --no-deps --force-recreate ac-worldserver
```

## Checking An Already-Patched Tree

If the patch is already applied, this should succeed:

```bash
cd /Users/nesadi/wow-server-playerbots/modules/mod-playerbots
git apply --check --reverse /Users/nesadi/projects/dads-mmo-lab/patches/playerbots/playerbots-rogue-follow-master-stealth.patch
```

If `git apply --check` fails after an upstream pull, inspect the failing hunks with:

```bash
cd /Users/nesadi/wow-server-playerbots/modules/mod-playerbots
git apply --reject /Users/nesadi/projects/dads-mmo-lab/patches/playerbots/playerbots-rogue-follow-master-stealth.patch
```

Resolve any `.rej` files by reintroducing the same ideas in the updated code:

- Add an `IsMasterStealthed` helper where rogue stealth triggers/actions need it.
- Register and use `follow master stealth` and `follow master unstealth` triggers in rogue non-combat strategy.
- Keep unstealth inactive while the master is stealthed.
- Skip imbue refreshes that would remove stealth while preserving master stealth.

After resolving conflicts, rebuild and restart the worldserver.

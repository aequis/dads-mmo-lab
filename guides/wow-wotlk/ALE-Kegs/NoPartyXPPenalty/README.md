# No Party XP Penalty

An Eluna Lua script for AzerothCore WotLK 3.3.5a that removes the group XP penalty when killing mobs. Each grouped player receives the full XP they would earn as if killing the mob solo, with two additional modifications:

1. **Exponential scaling (1.05x per level)** for mobs above the player's level (vanilla WoW caps the bonus at +4 levels; this script removes that cap)
2. **Per-kill XP cap** at 1/10 of the XP required for the player's current level (minimum 10 kills to level, no matter how high the mob)

## How it works

### The problem

In vanilla WotLK group XP mechanics:

- XP is calculated based on the **highest-level group member**, not the individual player
- The total is split proportionally by level among group members
- If a mob is gray to any group member, XP is further halved for everyone

This means a level 5 player grouped with a level 20 player killing level 5 mobs would earn roughly **~7 XP** instead of the **70 XP** they'd earn solo — a ~90% penalty.

### The fix

The script hooks `PLAYER_EVENT_ON_GIVE_XP` (Eluna event 12) and recalculates XP using the **individual player's level** against the mob's level, ignoring group composition entirely. The XP formula is ported directly from AzerothCore's C++ source (`src/server/game/Miscellaneous/Formulas.h` and `Formulas.cpp`).

### Exponential scaling

Vanilla WoW caps the higher-level mob XP bonus at +4 levels above the player. This script removes that cap and replaces the linear scaling factor `(20 + levelDiff)` with an exponential `20 * 1.05^levelDiff`. This rewards fighting mobs above your level more generously, which matters for the power-leveling scenario (being carried by a higher-level character).

Comparison for a level 5 player (2,800 XP to next level):

| Mob Level | Diff | Vanilla (capped at +4) | Linear (uncapped) | Exp 1.05 (this script) |
|-----------|------|------------------------|-------------------|------------------------|
| 5         | 0    | 70                     | 70                | 70                     |
| 10        | +5   | 84                     | 88                | 90                     |
| 20        | +15  | 84                     | 123               | 146                    |
| 40        | +35  | 84                     | 193               | 387                    |
| 80        | +75  | 84                     | 333               | 23,494 (capped to 280) |

### Per-kill cap

Without a cap, the exponential scaling would allow a low-level player to gain multiple levels from a single high-level mob kill. The cap limits each kill to 1/10 of the XP required for the player's current level, guaranteeing it takes at least **10 kills** to level up regardless of mob level.

## Power-leveling reference

### Kills per level when boosted by a level 80 character killing level 80 mobs

| Player Level | XP/Kill | Cap (1/10) | Effective | XP to Level | Kills/Level |
|-------------|---------|------------|-----------|-------------|-------------|
| 5           | 23,494  | 280        | 280       | 2,800       | 10          |
| 10          | 19,169  | 760        | 760       | 7,600       | 10          |
| 20          | 12,702  | 2,320      | 2,320     | 23,200      | 10          |
| 30          | 8,371   | 4,740      | 4,740     | 47,400      | 10          |
| 40          | 5,491   | 9,070      | 5,491     | 90,700      | 17          |
| 50          | 3,587   | 14,750     | 3,587     | 147,500     | 42          |
| 60          | 2,335   | 49,400     | 2,335     | 494,000     | 212         |
| 70          | 1,515   | 152,380    | 1,515     | 1,523,800   | 1,006       |
| 75          | 1,219   | 160,420    | 1,219     | 1,604,200   | 1,316       |

The cap only matters at levels 1-35 (where the exponential would otherwise give absurd XP). From level 40+, the raw XP is below the cap so it has no effect.

### Dungeon clears per level (boosted by a level 80 in level 80 dungeons)

| Dungeon              | Mobs | Player Lv 50 | Player Lv 60 | Player Lv 70 | Player Lv 75 |
|----------------------|------|-------------|-------------|-------------|-------------|
| Forge of Souls       | 42   | 2.0 levels  | 0.4 levels  | 12 runs     | 16 runs     |
| Halls of Reflection  | 43   | 2.1 levels  | 0.4 levels  | 12 runs     | 16 runs     |
| Utgarde Pinnacle     | 91   | 3.5 levels  | 0.7 levels  | 7 runs      | 10 runs     |
| Halls of Stone       | 99   | 3.4 levels  | 0.7 levels  | 8 runs      | 10 runs     |
| Halls of Lightning   | 169  | 7.0 levels  | 1.4 levels  | 4 runs      | 5 runs      |
| Pit of Saron         | 178  | 7.6 levels  | 1.5 levels  | 4 runs      | 5 runs      |

The 70-79 range is significantly slower due to the massive XP requirements (1.5M+ per level) combined with the shrinking level gap to the mobs (only +5 to +10 at that point, so the exponential barely helps).

## Configuration

The `EXP_BASE` constant at the top of the script controls the exponential scaling factor. Comparison of different values:

| EXP_BASE | Behavior |
|----------|----------|
| 1.00     | Linear scaling (equivalent to vanilla formula without the +4 cap) |
| 1.02     | Barely noticeable difference from linear |
| 1.03     | Similar to linear at small gaps, ~2x at +75 levels |
| 1.05     | **(current)** Meaningful bonus at mid-range gaps, ~39x at +75 |

## Installation

1. Copy `NoPartyXPPenalty.lua` to the server's Eluna scripts directory:
   ```
   env/dist/etc/modules/lua_scripts/NoPartyXPPenalty.lua
   ```
2. Reload scripts with `reload eluna` in the worldserver console, or restart the worldserver
3. Confirm it loaded by checking the server log for: `>> No Party XP Penalty loaded (1.05 exp scaling, 1/10 level cap).`

## Technical details

- Hooks: `PLAYER_EVENT_ON_GIVE_XP` (Eluna event 12)
- Only modifies kill XP when the player is in a group — solo XP and quest/exploration XP are untouched
- The XP formula is ported from `src/server/game/Miscellaneous/Formulas.h` and `Formulas.cpp`
- Content level (which determines the base XP constant: 45/235/580) is approximated from map ID and mob level, since the DBC lookup used by the C++ code isn't available in Lua
- Elite detection uses `victim:GetRank()` (rank 1 = elite, 2 = rare elite, 3 = world boss) for the 2x XP multiplier
- The `math.max(soloXP, amount)` safety net ensures the script never reduces XP below what the default group calculation would give

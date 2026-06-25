# BattlePass Playerbot Guard Patch

## Problem

When running AzerothCore with Playerbots, the bots fire the same player events as real players (login, logout, creature kills, quest completions, etc.). This causes several issues with the BattlePass system:

1. **Bots progress battle pass** - Playerbots would earn XP and complete challenges
2. **High event volume** - Bots generate many more events than human players
3. **Missing API methods** - Some bot/quest objects lack the full Player API, causing errors

## Fix

This patch adds a `BattlePass.IsEligiblePlayer(player)` function that filters out:

- Non-player entities (`player:IsPlayer()` returns false)
- Playerbots (checks `IsPlayerBot`, `IsPlayerbot`, `IsBot` methods)
- Sessionless entities (`player:GetSession()` returns nil)

All event handlers are updated to use `IsEligiblePlayer(player)` instead of just `IsEnabled()`.

## Implementation

```lua
function BattlePass.IsEligiblePlayer(player)
    if not BattlePass.IsEnabled() then
        return false
    end
    if not player then
        return false
    end

    -- Check if actually a player
    if player.IsPlayer then
        local ok, result = pcall(function() return player:IsPlayer() end)
        if ok and not result then
            return false
        end
    end

    -- Check for playerbot methods
    for _, method in ipairs({ "IsPlayerBot", "IsPlayerbot", "IsBot" }) do
        if player[method] then
            local ok, result = pcall(function() return player[method](player) end)
            if ok and result then
                return false
            end
        end
    end

    -- Check for valid session
    if player.GetSession then
        local ok, result = pcall(function() return player:GetSession() end)
        if ok and result == nil then
            return false
        end
    end

    return true
end
```

## Events Patched

- `OnPlayerLogin`
- `OnPlayerLogout`
- `OnCreatureKill`
- `OnQuestComplete`
- `OnPlayerLevelChange`
- `OnHonorableKill`
- `OnBattlegroundEnd`
- `AwardCustomExp`

## Files Modified

- `06_BP_Events.lua` - Added IsEligiblePlayer function and updated all event handlers

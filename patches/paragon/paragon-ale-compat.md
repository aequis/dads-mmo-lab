# Paragon ALE Compatibility Patch

## Problem

The Paragon Anniversary ALE script uses `player:GetData("Paragon")` and `player:SetData("Paragon", value)` to store per-player paragon state. However, this ALE build doesn't support the Player:GetData/SetData methods in the same way, causing errors.

Additionally, the bundled Mediator library uses `unpack()` which was renamed to `table.unpack()` in Lua 5.2+, causing compatibility issues.

## Fix

This patch makes three changes:

### 1. Player State Cache (paragon_hook.lua)

Adds a local `PlayerParagonState` table that caches paragon values keyed by player GUID. Replaces all `player:GetData("Paragon")` calls with `GetPlayerParagon(player)` and `player:SetData()` calls with `SetPlayerParagon(player, value)`.

```lua
local PlayerParagonState = {}

local function GetPlayerParagon(player)
    local key = player:GetGUIDLow()
    return PlayerParagonState[key]
end

local function SetPlayerParagon(player, paragon)
    local key = player:GetGUIDLow()
    PlayerParagonState[key] = paragon
end
```

### 2. State Cleanup (paragon_hook.lua)

Adds `ClearPlayerParagon(player)` call after `OnAfterPlayerStatSave` to prevent memory leaks when players log out.

### 3. Lua unpack Compatibility (mediator.lua)

Adds `local unpack = table.unpack or unpack` to handle both Lua 5.1 and 5.2+ environments.

### 4. Target Level Module (paragon_target_level.lua)

Updates `target:GetData("Paragon")` calls to use the exported `ParagonHook.GetPlayerParagon(target)` function.

## Files Modified

- `paragon_hook.lua` - State cache system and cleanup
- `lib/Mediator/mediator.lua` - Lua unpack compatibility
- `modules/paragon_target_level.lua` - Use exported getter function

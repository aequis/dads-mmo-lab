# Challenge Modes OnPlayerResurrect API Fix

## Problem

The `mod-challenge-modes` module uses an outdated `OnPlayerResurrect` hook signature that doesn't match the current AzerothCore API. This causes compilation errors when building the worldserver.

The module uses:
```cpp
void OnPlayerResurrect(Player* player, float restore_percent, bool applySickness)
```

But the current AzerothCore API expects:
```cpp
void OnPlayerResurrect(Player* player, float /*restore_percent*/, bool& /*applySickness*/)
```

Key differences:
1. `bool` changed to `bool&` (reference instead of value)
2. Parameters are unused in this module, so they should be commented out

## Fix

This patch updates the `OnPlayerResurrect` signature in `ChallengeModes.cpp` to match the current AC API:

```cpp
// Before:
void OnPlayerResurrect(Player* player, float restore_percent, bool applySickness)

// After:
void OnPlayerResurrect(Player* player, float /*restore_percent*/, bool& /*applySickness*/)
```

This change occurs at two locations in the file (lines ~448 and ~641).

## Files Modified

- `src/ChallengeModes.cpp` - Updated OnPlayerResurrect signature (2 occurrences)

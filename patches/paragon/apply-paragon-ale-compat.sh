#!/usr/bin/env bash
# Paragon ALE Compatibility Patch
# Adds player state caching (replaces Player:GetData/SetData) and Lua unpack compat
#
# Usage: source this file, then call apply_paragon_ale_compat "/path/to/paragon/dir"

apply_paragon_ale_compat() {
    local paragon_dir="$1"
    local hook_file="$paragon_dir/paragon_hook.lua"
    local target_file="$paragon_dir/modules/paragon_target_level.lua"
    local mediator_file="$paragon_dir/lib/Mediator/mediator.lua"

    [ -f "$hook_file" ] || return 0

    if ! command -v perl >/dev/null 2>&1; then
        print_warning "perl not found; cannot apply Paragon ALE compatibility patch automatically."
        print_info "If Paragon throws Player:GetData errors, patch paragon_hook.lua manually."
        return 0
    fi

    # Check if already patched
    if grep -q "PlayerParagonState" "$hook_file"; then
        print_info "Paragon ALE compatibility patch already present"
        return 0
    fi

    # Add player state cache functions after PRIVATE FUNCTIONS header
    perl -0pi -e 's/(-- =+\n-- PRIVATE FUNCTIONS\n-- =+\n)/$1\nlocal PlayerParagonState = {}\n\nlocal function GetPlayerStateKey(player)\n    if not player then\n        return nil\n    end\n\n    if player.GetGUIDLow then\n        return player:GetGUIDLow()\n    end\n\n    return nil\nend\n\nlocal function GetPlayerParagon(player)\n    local key = GetPlayerStateKey(player)\n    if not key then\n        return nil\n    end\n\n    return PlayerParagonState[key]\nend\n\nlocal function SetPlayerParagon(player, paragon)\n    local key = GetPlayerStateKey(player)\n    if not key then\n        return false\n    end\n\n    PlayerParagonState[key] = paragon\n    return true\nend\n\nlocal function ClearPlayerParagon(player)\n    local key = GetPlayerStateKey(player)\n    if key then\n        PlayerParagonState[key] = nil\n    end\nend\n\nHook.GetPlayerParagon = GetPlayerParagon\nHook.SetPlayerParagon = SetPlayerParagon\nHook.ClearPlayerParagon = ClearPlayerParagon\n/s' "$hook_file"

    # Replace GetData/SetData calls with our cache functions
    perl -0pi -e 's/player:GetData\("Paragon"\)/GetPlayerParagon(player)/g; s/player:SetData\("Paragon", paragon\)/SetPlayerParagon(player, paragon)/g' "$hook_file"

    # Add cleanup call after OnAfterPlayerStatSave
    if ! grep -q "ClearPlayerParagon(player)" "$hook_file"; then
        perl -0pi -e 's/(Mediator\.On\("OnAfterPlayerStatSave", \{\n\s*arguments = \{ player, paragon \},\n\s*\}\)\n)/$1\n    ClearPlayerParagon(player)\n/s' "$hook_file"
    fi

    # Patch target level module
    if [ -f "$target_file" ]; then
        perl -0pi -e 's/target:GetData\("Paragon"\)/ParagonHook.GetPlayerParagon and ParagonHook.GetPlayerParagon(target)/g' "$target_file"
    fi

    # Add Lua unpack compatibility
    if [ -f "$mediator_file" ] && ! grep -q "local unpack = table.unpack or unpack" "$mediator_file"; then
        perl -0pi -e 's/local Object = Object or require\("classic"\)/local Object = Object or require("classic")\nlocal unpack = table.unpack or unpack/' "$mediator_file"
    fi

    print_success "Patched Paragon for ALE — state cache + Lua unpack compatibility"
}

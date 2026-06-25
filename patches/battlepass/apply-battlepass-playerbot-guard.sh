#!/usr/bin/env bash
# BattlePass Playerbot Guard Patch
# Filters out playerbots from BattlePass events
#
# Usage: source this file, then call apply_battlepass_playerbot_guard "/path/to/battlepass/dir"

apply_battlepass_playerbot_guard() {
    local bp_dir="$1"
    local events_file="$bp_dir/06_BP_Events.lua"

    if [ ! -f "$events_file" ]; then
        print_warning "BattlePass events file not found: $events_file"
        return 1
    fi

    # Check if already patched
    if grep -q "BattlePass.IsEligiblePlayer" "$events_file" 2>/dev/null; then
        print_info "BattlePass playerbot guard already present"
        return 0
    fi

    if ! command -v perl >/dev/null 2>&1; then
        print_warning "perl not found; cannot apply BattlePass playerbot guard patch"
        return 1
    fi

    # Add IsEligiblePlayer function
    perl -0pi -e 's|(BattlePass = BattlePass or \{\}\nBattlePass\.Events = BattlePass\.Events or \{\}\n)|$1\n-- Only real player sessions should progress Battle Pass. Playerbots can fire\n-- high-volume player events and some quest objects lack the full player API.\nfunction BattlePass.IsEligiblePlayer(player)\n    if not BattlePass.IsEnabled() then\n        return false\n    end\n\n    if not player then\n        return false\n    end\n\n    local ok, result\n\n    if player.IsPlayer then\n        ok, result = pcall(function() return player:IsPlayer() end)\n        if ok and not result then\n            return false\n        end\n    end\n\n    for _, method in ipairs({ "IsPlayerBot", "IsPlayerbot", "IsBot" }) do\n        if player[method] then\n            ok, result = pcall(function() return player[method](player) end)\n            if ok and result then\n                return false\n            end\n        end\n    end\n\n    if player.GetSession then\n        ok, result = pcall(function() return player:GetSession() end)\n        if ok and result == nil then\n            return false\n        end\n    end\n\n    return true\nend\n|s' "$events_file"

    # Replace IsEnabled checks with IsEligiblePlayer in event handlers
    perl -0pi -e '
        s|(local function OnPlayerLogin\(event, player\)\n)    if not BattlePass\.IsEnabled\(\) then|$1    if not BattlePass.IsEligiblePlayer(player) then|s;
        s|(local function OnPlayerLogout\(event, player\)\n)    if not BattlePass\.IsEnabled\(\) then|$1    if not BattlePass.IsEligiblePlayer(player) then|s;
        s|(local function OnCreatureKill\(event, player, creature\)\n)    if not BattlePass\.IsEnabled\(\) then|$1    if not BattlePass.IsEligiblePlayer(player) then|s;
        s|(local function OnQuestComplete\(event, player, quest\)\n)    if not BattlePass\.IsEnabled\(\) then|$1    if not BattlePass.IsEligiblePlayer(player) then|s;
        s|(local function OnPlayerLevelChange\(event, player, oldLevel\)\n)    if not BattlePass\.IsEnabled\(\) then|$1    if not BattlePass.IsEligiblePlayer(player) then|s;
        s|(local function OnHonorableKill\(event, player, victim\)\n)    if not BattlePass\.IsEnabled\(\) then|$1    if not BattlePass.IsEligiblePlayer(player) then|s;
        s|(function BattlePass\.Events\.OnBattlegroundEnd\(player, isWinner\)\n)    if not BattlePass\.IsEnabled\(\) then|$1    if not BattlePass.IsEligiblePlayer(player) then|s;
        s|(function BattlePass\.Events\.AwardCustomExp\(player, amount, reason\)\n)    if not BattlePass\.IsEnabled\(\) then|$1    if not BattlePass.IsEligiblePlayer(player) then|s;
        s|if player and player:IsInWorld\(\) then|if BattlePass.IsEligiblePlayer(player) then|g;
    ' "$events_file"

    print_success "Patched BattlePass to ignore playerbots/non-player sessions"
}

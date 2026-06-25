#!/usr/bin/env bash
# Challenge Modes OnPlayerResurrect API Fix
# Updates function signature to match current AzerothCore API
#
# Usage: source this file, then call apply_challenge_modes_resurrect_api "/path/to/mod-challenge-modes"

apply_challenge_modes_resurrect_api() {
    local cm_dir="$1"
    local cm_src="$cm_dir/src/ChallengeModes.cpp"

    if [ ! -f "$cm_src" ]; then
        return 0
    fi

    # Check if already patched
    if grep -q "bool& /\*applySickness\*/" "$cm_src" 2>/dev/null; then
        print_info "ChallengeModes resurrect API patch already present"
        return 0
    fi

    # Check if patch is needed
    if ! grep -q "float restore_percent, bool applySickness" "$cm_src"; then
        print_info "ChallengeModes: expected pattern not found (may already be patched differently)"
        return 0
    fi

    print_step "Patching OnPlayerResurrect signature in ChallengeModes.cpp..."
    sed -i 's/float restore_percent, bool applySickness/float \/*restore_percent*\/, bool\& \/*applySickness*\//g' "$cm_src"

    local patch_count
    patch_count=$(grep -c "bool& /\*applySickness\*/" "$cm_src" 2>/dev/null || echo "0")
    if [ "$patch_count" -ge 1 ]; then
        print_success "Patched $patch_count occurrence(s) — module now matches current AC API"
    else
        print_warning "Patch may not have applied cleanly — verify ChallengeModes.cpp manually"
        print_info "Lines 448 and 641: change 'float restore_percent, bool applySickness'"
        print_info "  to: 'float /*restore_percent*/, bool& /*applySickness*/'"
    fi
}

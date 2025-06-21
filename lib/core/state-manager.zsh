#!/usr/bin/env zsh
# Enhanced state management for z-skk
# Provides centralized state transitions with validation and logging

# State transition validation
typeset -gA Z_SKK_VALID_TRANSITIONS=(
    # From ASCII mode
    ["ascii->hiragana"]="1"
    ["ascii->katakana"]="1"
    ["ascii->zenkaku"]="1"
    ["ascii->abbrev"]="1"

    # From Hiragana mode
    ["hiragana->ascii"]="1"
    ["hiragana->katakana"]="1"
    ["hiragana->zenkaku"]="1"
    ["hiragana->abbrev"]="1"

    # From other modes
    ["katakana->hiragana"]="1"
    ["katakana->ascii"]="1"
    ["zenkaku->hiragana"]="1"
    ["zenkaku->ascii"]="1"
    ["abbrev->hiragana"]="1"
    ["abbrev->ascii"]="1"
)

# State transition with validation
z-skk-state-transition() {
    local from="$1"
    local to="$2"
    local reason="${3:-user-request}"

    # Validate transition
    local transition_key="${from}->${to}"
    if [[ -z "${Z_SKK_VALID_TRANSITIONS[$transition_key]}" ]]; then
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "warn" "Invalid state transition: $from -> $to"
        fi
        return 1
    fi

    # Store previous state
    Z_SKK_PREVIOUS_MODE="$from"

    # Execute transition
    Z_SKK_MODE="$to"

    # Emit state transition event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "state:transition" "$from" "$to" "$reason"
    fi

    # Log transition
    if (( ${+functions[_z-skk-log-error]} )); then
        _z-skk-log-error "info" "State transition: $from -> $to ($reason)"
    fi

    return 0
}

# Get current state snapshot
z-skk-get-state-snapshot() {
    local state_data=""

    # Core state
    state_data+="mode:$Z_SKK_MODE|"
    state_data+="converting:$Z_SKK_CONVERTING|"
    state_data+="buffer:$Z_SKK_BUFFER|"
    state_data+="romaji:$Z_SKK_ROMAJI_BUFFER|"

    # Candidate state
    state_data+="candidate_index:$Z_SKK_CANDIDATE_INDEX|"
    state_data+="candidates:${#Z_SKK_CANDIDATES[@]}|"

    # Okurigana state
    if [[ -n "$Z_SKK_OKURIGANA_MODE" ]]; then
        state_data+="okurigana_mode:$Z_SKK_OKURIGANA_MODE|"
        state_data+="okurigana_prefix:$Z_SKK_OKURIGANA_PREFIX|"
        state_data+="okurigana_suffix:$Z_SKK_OKURIGANA_SUFFIX|"
    fi

    echo "$state_data"
}

# Restore state from snapshot
z-skk-restore-state-snapshot() {
    local snapshot="$1"

    # Parse and restore state
    local IFS='|'
    local -a parts=("${(@s/|/)snapshot}")

    for part in "${parts[@]}"; do
        if [[ -n "$part" ]]; then
            local key="${part%%:*}"
            local value="${part#*:}"

            case "$key" in
                "mode")
                    Z_SKK_MODE="$value"
                    ;;
                "converting")
                    Z_SKK_CONVERTING="$value"
                    ;;
                "buffer")
                    Z_SKK_BUFFER="$value"
                    ;;
                "romaji")
                    Z_SKK_ROMAJI_BUFFER="$value"
                    ;;
                "candidate_index")
                    Z_SKK_CANDIDATE_INDEX="$value"
                    ;;
                "okurigana_mode")
                    Z_SKK_OKURIGANA_MODE="$value"
                    ;;
                "okurigana_prefix")
                    Z_SKK_OKURIGANA_PREFIX="$value"
                    ;;
                "okurigana_suffix")
                    Z_SKK_OKURIGANA_SUFFIX="$value"
                    ;;
            esac
        fi
    done

    # Emit state restoration event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "state:restored" "$snapshot"
    fi
}

# Validate current state consistency
z-skk-validate-state() {
    local errors=()

    # Check mode validity
    case "$Z_SKK_MODE" in
        ascii|hiragana|katakana|zenkaku|abbrev)
            # Valid modes
            ;;
        *)
            errors+=("Invalid mode: $Z_SKK_MODE")
            ;;
    esac

    # Check converting state consistency
    if [[ "$Z_SKK_CONVERTING" -gt 0 ]] && [[ "$Z_SKK_MODE" != "hiragana" ]]; then
        errors+=("Converting state inconsistent with mode: $Z_SKK_MODE")
    fi

    # Check buffer consistency
    if [[ "$Z_SKK_CONVERTING" -eq 0 ]] && [[ -n "$Z_SKK_BUFFER" ]]; then
        errors+=("Buffer not empty in non-converting state")
    fi

    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        if (( ${+functions[_z-skk-log-error]} )); then
            for error in "${errors[@]}"; do
                _z-skk-log-error "warn" "State validation: $error"
            done
        fi
        return 1
    fi

    return 0
}

# Safe state reset with validation
z-skk-safe-state-reset() {
    local preserve_mode="${1:-0}"

    # Store current state for rollback
    local current_snapshot
    current_snapshot=$(z-skk-get-state-snapshot)

    # Reset state
    if [[ "$preserve_mode" -eq 0 ]]; then
        Z_SKK_MODE="ascii"
    fi

    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""
    Z_SKK_CANDIDATE_INDEX=0
    Z_SKK_CANDIDATES=()

    # Reset okurigana state
    Z_SKK_OKURIGANA_MODE=0
    Z_SKK_OKURIGANA_PREFIX=""
    Z_SKK_OKURIGANA_SUFFIX=""
    Z_SKK_OKURIGANA_ROMAJI=""

    # Validate new state
    if ! z-skk-validate-state; then
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "error" "State reset resulted in invalid state, rolling back"
        fi
        z-skk-restore-state-snapshot "$current_snapshot"
        return 1
    fi

    # Emit reset event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "state:reset" "$preserve_mode"
    fi

    return 0
}
#!/usr/bin/env zsh
# Centralized state management for z-skk

# State transition functions for Z_SKK_CONVERTING
# Values:
# 0 - Normal input mode
# 1 - Pre-conversion mode (after uppercase, showing ▽)
# 2 - Candidate selection mode (after space, showing ▼)
# 3 - Registration mode

# Set conversion state with validation and event emission
z-skk-set-converting-state() {
    local new_state="$1"
    local old_state="$Z_SKK_CONVERTING"

    # Validate state
    if [[ ! "$new_state" =~ ^[0-3]$ ]]; then
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "error" "Invalid converting state: $new_state"
        fi
        return 1
    fi

    # Skip if no change
    if [[ "$new_state" == "$old_state" ]]; then
        return 0
    fi

    # Update state
    Z_SKK_CONVERTING="$new_state"

    # Emit state change event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "converting-state-changed" "$old_state" "$new_state"
    fi

    # Log state transition
    if (( ${+functions[_z-skk-log]} )); then
        _z-skk-log "debug" "Converting state: $old_state -> $new_state"
    fi

    return 0
}

# Convenience functions for common state transitions
z-skk-start-pre-conversion() {
    z-skk-set-converting-state 1
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""
    Z_SKK_CANDIDATES=()
    Z_SKK_CANDIDATE_INDEX=0
}

z-skk-start-candidate-selection() {
    z-skk-set-converting-state 2
}

z-skk-start-registration-mode() {
    z-skk-set-converting-state 3
}

z-skk-end-conversion() {
    z-skk-set-converting-state 0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""
    Z_SKK_CANDIDATES=()
    Z_SKK_CANDIDATE_INDEX=0
    Z_SKK_OKURIGANA=""
    Z_SKK_OKURIGANA_MODE=0
}

# State query functions
z-skk-is-converting() {
    [[ $Z_SKK_CONVERTING -gt 0 ]]
}

z-skk-is-pre-converting() {
    [[ $Z_SKK_CONVERTING -eq 1 ]]
}

z-skk-is-selecting-candidate() {
    [[ $Z_SKK_CONVERTING -eq 2 ]]
}

z-skk-is-registering() {
    [[ $Z_SKK_CONVERTING -eq 3 ]]
}

# Mode state management
z-skk-set-mode() {
    local new_mode="$1"
    local old_mode="$Z_SKK_MODE"

    # Validate mode
    case "$new_mode" in
        ascii|hiragana|katakana|zenkaku|abbrev)
            ;;
        *)
            if (( ${+functions[_z-skk-log-error]} )); then
                _z-skk-log-error "warn" "Invalid mode: $new_mode"
            fi
            return 1
            ;;
    esac

    # Skip if no change
    if [[ "$new_mode" == "$old_mode" ]]; then
        return 0
    fi

    # Update mode
    Z_SKK_MODE="$new_mode"

    # Reset conversion state when changing modes
    z-skk-end-conversion

    # Reset mode-specific state
    if [[ "$old_mode" == "abbrev" ]]; then
        # Reset abbrev state when leaving abbrev mode
        if [[ -v Z_SKK_ABBREV_BUFFER ]]; then
            Z_SKK_ABBREV_BUFFER=""
        fi
        if [[ -v Z_SKK_ABBREV_ACTIVE ]]; then
            Z_SKK_ABBREV_ACTIVE=0
        fi
    fi

    # Emit mode change event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "mode-changed" "$old_mode" "$new_mode"
    fi

    # Log mode change
    if (( ${+functions[_z-skk-log]} )); then
        _z-skk-log "info" "Mode changed: $old_mode -> $new_mode"
    fi

    # Update display
    if (( ${+functions[z-skk-update-mode-display]} )); then
        z-skk-update-mode-display
    fi

    return 0
}

# Buffer state management
z-skk-append-to-buffer() {
    local text="$1"
    Z_SKK_BUFFER+="$text"

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "buffer-changed" "$Z_SKK_BUFFER"
    fi
}

z-skk-clear-buffer() {
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "buffer-cleared"
    fi
}

# Romaji buffer management
z-skk-set-romaji-buffer() {
    local new_buffer="$1"
    Z_SKK_ROMAJI_BUFFER="$new_buffer"

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "romaji-buffer-changed" "$new_buffer"
    fi
}

z-skk-append-to-romaji-buffer() {
    local char="$1"
    Z_SKK_ROMAJI_BUFFER+="$char"

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "romaji-buffer-changed" "$Z_SKK_ROMAJI_BUFFER"
    fi
}

# Okurigana state management
z-skk-start-okurigana-mode() {
    Z_SKK_OKURIGANA_MODE=1
    Z_SKK_OKURIGANA=""

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "okurigana-mode-started"
    fi
}

z-skk-end-okurigana-mode() {
    Z_SKK_OKURIGANA_MODE=0

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "okurigana-mode-ended"
    fi
}

z-skk-set-okurigana() {
    local okurigana="$1"
    Z_SKK_OKURIGANA="$okurigana"

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "okurigana-changed" "$okurigana"
    fi
}

# Candidate state management
z-skk-set-candidates() {
    local -a candidates=("$@")
    Z_SKK_CANDIDATES=("${candidates[@]}")
    Z_SKK_CANDIDATE_INDEX=0

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "candidates-changed" "${#candidates[@]}"
    fi
}

z-skk-set-candidate-index() {
    local new_index="$1"
    local max_index=$(( ${#Z_SKK_CANDIDATES[@]} - 1 ))

    # Validate index
    if [[ $new_index -lt 0 ]]; then
        new_index=0
    elif [[ $new_index -gt $max_index ]]; then
        new_index=$max_index
    fi

    Z_SKK_CANDIDATE_INDEX=$new_index

    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "candidate-index-changed" "$new_index"
    fi
}

# Special input mode state
z-skk-set-code-input-mode() {
    local enabled="$1"
    Z_SKK_CODE_INPUT_MODE="$enabled"

    if [[ "$enabled" == "1" ]]; then
        Z_SKK_CODE_INPUT_BUFFER=""
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit "code-input-started"
        fi
    else
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit "code-input-ended"
        fi
    fi
}

# State snapshot and restore (for undo functionality)
typeset -gA Z_SKK_STATE_SNAPSHOT

z-skk-save-state-snapshot() {
    Z_SKK_STATE_SNAPSHOT=(
        mode "$Z_SKK_MODE"
        converting "$Z_SKK_CONVERTING"
        buffer "$Z_SKK_BUFFER"
        romaji_buffer "$Z_SKK_ROMAJI_BUFFER"
        okurigana "$Z_SKK_OKURIGANA"
        okurigana_mode "$Z_SKK_OKURIGANA_MODE"
        candidate_index "$Z_SKK_CANDIDATE_INDEX"
    )

    # Save candidates array separately
    Z_SKK_STATE_SNAPSHOT[candidates]="${(j:,:)Z_SKK_CANDIDATES}"
}

z-skk-restore-state-snapshot() {
    if [[ ${#Z_SKK_STATE_SNAPSHOT} -eq 0 ]]; then
        return 1
    fi

    Z_SKK_MODE="${Z_SKK_STATE_SNAPSHOT[mode]}"
    Z_SKK_CONVERTING="${Z_SKK_STATE_SNAPSHOT[converting]}"
    Z_SKK_BUFFER="${Z_SKK_STATE_SNAPSHOT[buffer]}"
    Z_SKK_ROMAJI_BUFFER="${Z_SKK_STATE_SNAPSHOT[romaji_buffer]}"
    Z_SKK_OKURIGANA="${Z_SKK_STATE_SNAPSHOT[okurigana]}"
    Z_SKK_OKURIGANA_MODE="${Z_SKK_STATE_SNAPSHOT[okurigana_mode]}"
    Z_SKK_CANDIDATE_INDEX="${Z_SKK_STATE_SNAPSHOT[candidate_index]}"

    # Restore candidates array
    if [[ -n "${Z_SKK_STATE_SNAPSHOT[candidates]}" ]]; then
        Z_SKK_CANDIDATES=("${(@s:,:)Z_SKK_STATE_SNAPSHOT[candidates]}")
    else
        Z_SKK_CANDIDATES=()
    fi

    return 0
}

# State validation
z-skk-validate-state() {
    local errors=0

    # Check converting state
    if [[ ! "$Z_SKK_CONVERTING" =~ ^[0-3]$ ]]; then
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "error" "Invalid converting state: $Z_SKK_CONVERTING"
        fi
        ((errors++))
    fi

    # Check mode
    case "$Z_SKK_MODE" in
        ascii|hiragana|katakana|zenkaku|abbrev)
            ;;
        *)
            if (( ${+functions[_z-skk-log-error]} )); then
                _z-skk-log-error "warn" "Invalid mode: $Z_SKK_MODE"
            fi
            ((errors++))
            ;;
    esac

    # Check candidate index
    if [[ ${#Z_SKK_CANDIDATES[@]} -gt 0 ]] &&
       [[ $Z_SKK_CANDIDATE_INDEX -ge ${#Z_SKK_CANDIDATES[@]} ]]; then
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "error" "Candidate index out of bounds: $Z_SKK_CANDIDATE_INDEX >= ${#Z_SKK_CANDIDATES[@]}"
        fi
        ((errors++))
    fi

    return $errors
}

# Initialize state module
_z-skk-init-state() {
    # Register event handlers if events module is loaded
    if (( ${+functions[z-skk-on]} )); then
        # Log state changes
        z-skk-on "converting-state-changed" '_z-skk-log "debug" "State changed: $2 -> $3"'
        z-skk-on "mode-changed" '_z-skk-log "info" "Mode changed: $2 -> $3"'
    fi
}

# Auto-initialize if sourced directly
if [[ "${funcstack[1]}" == "_z-skk-init-state" ]]; then
    _z-skk-init-state
fi
#!/usr/bin/env zsh
# Display API for z-skk - Centralized buffer manipulation

# Display state
typeset -g Z_SKK_DISPLAY_BUFFER=""
typeset -g Z_SKK_DISPLAY_CURSOR_POS=0

# Initialize display API
z-skk-display-init() {
    Z_SKK_DISPLAY_BUFFER="$LBUFFER$RBUFFER"
    Z_SKK_DISPLAY_CURSOR_POS=${#LBUFFER}
}

# Append text to display buffer
z-skk-display-append() {
    local text="$1"
    local at_cursor="${2:-1}"  # Default: insert at cursor

    if [[ "$at_cursor" -eq 1 ]]; then
        # Insert at cursor position
        LBUFFER+="$text"
    else
        # Append to end
        RBUFFER+="$text"
    fi

    # Emit event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "display:appended" "$text"
    fi
}

# Safe redraw operation with error handling
z-skk-display-safe-redraw() {
    local force="${1:-0}"

    # Only redraw if in interactive context and not in CI
    if [[ -n "$ZLE_LINE_ABORTED" ]] || [[ -n "$CI" ]] || [[ -z "$WIDGET" ]]; then
        if [[ "$force" -eq 1 ]]; then
            if (( ${+functions[z-skk-log]} )); then
                z-skk-log "warn" "Forced redraw in non-interactive context"
            fi
        else
            return 0
        fi
    fi

    # Attempt redraw with error handling
    if ! zle -f redraw 2>/dev/null; then
        if (( ${+functions[z-skk-log]} )); then
            z-skk-log "warn" "Failed to redraw line"
        fi
        return 1
    fi

    # Emit redraw event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "display:redrawn" "$force"
    fi

    return 0
}

# Update conversion display with marker
z-skk-display-update-marker() {
    local marker="$1"
    local content="$2"
    local clear_previous="${3:-1}"

    # Clear previous marker if requested
    if [[ "$clear_previous" -eq 1 ]]; then
        z-skk-display-clear-marker "▽" ""
        z-skk-display-clear-marker "▼" ""
    fi

    # Add new marker
    z-skk-add-marker "$marker" "$content"

    # Safe redraw
    z-skk-display-safe-redraw

    # Emit marker update event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "display:marker-updated" "$marker" "$content"
    fi
}

# Clear specific marker from display
z-skk-display-clear-marker() {
    local marker="$1"
    local replacement="$2"

    # Use existing clear-marker function
    z-skk-clear-marker "$marker" "$replacement"

    # Emit marker clear event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "display:marker-cleared" "$marker"
    fi
}

# Batch display operations (prevents multiple redraws)
z-skk-display-batch-start() {
    typeset -g Z_SKK_DISPLAY_BATCH_MODE=1
}

z-skk-display-batch-end() {
    typeset -g Z_SKK_DISPLAY_BATCH_MODE=0
    z-skk-display-safe-redraw
}

# Enhanced append that respects batch mode
z-skk-display-append-batched() {
    local text="$1"
    local at_cursor="${2:-1}"

    z-skk-display-append "$text" "$at_cursor"

    # Only redraw if not in batch mode
    if [[ "${Z_SKK_DISPLAY_BATCH_MODE:-0}" -eq 0 ]]; then
        z-skk-display-safe-redraw
    fi
}

# Insert text at specific position
z-skk-display-insert() {
    local text="$1"
    local position="${2:-$Z_SKK_DISPLAY_CURSOR_POS}"

    local before="${LBUFFER:0:$position}"
    local after="${LBUFFER:$position}$RBUFFER"

    LBUFFER="$before$text"
    RBUFFER="$after"

    # Emit event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "display:inserted" "$text" "$position"
    fi
}

# Clear display buffer
z-skk-display-clear() {
    LBUFFER=""
    RBUFFER=""

    # Emit event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "display:cleared"
    fi
}

# Clear part of display
z-skk-display-clear-range() {
    local start="$1"
    local length="$2"

    local before="${LBUFFER:0:$start}"
    local after="${LBUFFER:$(($start + $length))}$RBUFFER"

    LBUFFER="$before"
    RBUFFER="$after"
}

# Replace text in display
z-skk-display-replace() {
    local old_text="$1"
    local new_text="$2"

    # Replace in LBUFFER
    if [[ "$LBUFFER" == *"$old_text"* ]]; then
        LBUFFER="${LBUFFER//$old_text/$new_text}"
    elif [[ "$RBUFFER" == *"$old_text"* ]]; then
        RBUFFER="${RBUFFER//$old_text/$new_text}"
    fi

    # Emit event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "display:replaced" "$old_text" "$new_text"
    fi
}

# Remove last n characters from cursor position
z-skk-display-backspace() {
    local count="${1:-1}"

    if [[ ${#LBUFFER} -ge $count ]]; then
        LBUFFER="${LBUFFER:0:-$count}"
    else
        LBUFFER=""
    fi

    # Emit event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "display:backspace" "$count"
    fi
}

# Get current display content
z-skk-display-get-content() {
    echo "$LBUFFER$RBUFFER"
}

# Get content before cursor
z-skk-display-get-before-cursor() {
    echo "$LBUFFER"
}

# Get content after cursor
z-skk-display-get-after-cursor() {
    echo "$RBUFFER"
}

# Save display state
typeset -gA Z_SKK_DISPLAY_SNAPSHOT

z-skk-display-save-state() {
    Z_SKK_DISPLAY_SNAPSHOT=(
        lbuffer "$LBUFFER"
        rbuffer "$RBUFFER"
        cursor_pos "$Z_SKK_DISPLAY_CURSOR_POS"
    )
}

# Restore display state
z-skk-display-restore-state() {
    if [[ ${#Z_SKK_DISPLAY_SNAPSHOT} -gt 0 ]]; then
        LBUFFER="${Z_SKK_DISPLAY_SNAPSHOT[lbuffer]}"
        RBUFFER="${Z_SKK_DISPLAY_SNAPSHOT[rbuffer]}"
        Z_SKK_DISPLAY_CURSOR_POS="${Z_SKK_DISPLAY_SNAPSHOT[cursor_pos]}"
    fi
}

# Update display with marker
z-skk-display-with-marker() {
    local marker="$1"
    local content="$2"
    local suffix="${3:-}"

    # Clear any existing marker first
    z-skk-clear-marker "$marker" ""

    # Add new marker and content
    z-skk-add-marker "$marker" "$content" "$suffix"

    # Force redraw
    z-skk-safe-redraw
}

# Remove marker from display
z-skk-display-remove-marker() {
    local marker="$1"
    local content="${2:-}"

    z-skk-clear-marker "$marker" "$content"
    z-skk-safe-redraw
}

# Display conversion candidates
z-skk-display-candidates() {
    local -a candidates=("$@")
    local current_index="${Z_SKK_CANDIDATE_INDEX:-0}"

    if [[ ${#candidates[@]} -gt 0 ]]; then
        local candidate="${candidates[$((current_index + 1))]}"
        z-skk-display-with-marker "▼" "$candidate"
    fi
}

# Display pre-conversion state
z-skk-display-pre-conversion() {
    local buffer="$1"
    local romaji="${2:-}"

    local display_text="$buffer$romaji"
    z-skk-display-with-marker "▽" "$display_text"
}

# Clear all markers
z-skk-display-clear-all-markers() {
    z-skk-display-remove-marker "▽"
    z-skk-display-remove-marker "▼"
    z-skk-display-remove-marker "["
}

# Initialize display API when sourced
if [[ "${funcstack[1]}" == "z-skk-display-init" ]]; then
    z-skk-display-init
fi
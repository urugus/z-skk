#!/usr/bin/env zsh
# Buffer management utilities for z-skk
# Centralized buffer operations to eliminate code duplication

# Set main conversion buffer
z-skk-buffer-set() {
    local content="$1"
    Z_SKK_BUFFER="$content"

    # Emit buffer change event if event system is available
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit buffer:set "$content"
    fi
}

# Append to main conversion buffer
z-skk-buffer-append() {
    local content="$1"
    Z_SKK_BUFFER+="$content"

    # Emit buffer change event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit buffer:append "$content"
    fi
}

# Clear main conversion buffer
z-skk-buffer-clear() {
    local old_content="$Z_SKK_BUFFER"
    Z_SKK_BUFFER=""

    # Emit buffer change event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit buffer:clear "$old_content"
    fi
}

# Remove last character from main buffer (handles multi-byte characters)
z-skk-buffer-backspace() {
    if [[ -n "$Z_SKK_BUFFER" ]]; then
        local removed_char="${Z_SKK_BUFFER: -1}"
        Z_SKK_BUFFER="${Z_SKK_BUFFER%?}"

        # Emit buffer change event
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit buffer:backspace "$removed_char"
        fi

        return 0
    fi
    return 1
}

# Set romaji buffer
z-skk-romaji-buffer-set() {
    local content="$1"
    Z_SKK_ROMAJI_BUFFER="$content"

    # Emit romaji buffer change event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit romaji-buffer:set "$content"
    fi
}

# Append to romaji buffer
z-skk-romaji-buffer-append() {
    local content="$1"
    Z_SKK_ROMAJI_BUFFER+="$content"

    # Emit romaji buffer change event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit romaji-buffer:append "$content"
    fi
}

# Clear romaji buffer
z-skk-romaji-buffer-clear() {
    local old_content="$Z_SKK_ROMAJI_BUFFER"
    Z_SKK_ROMAJI_BUFFER=""

    # Emit romaji buffer change event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit romaji-buffer:clear "$old_content"
    fi
}

# Remove last character from romaji buffer
z-skk-romaji-buffer-backspace() {
    if [[ -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
        local removed_char="${Z_SKK_ROMAJI_BUFFER: -1}"
        Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%?}"

        # Emit romaji buffer change event
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit romaji-buffer:backspace "$removed_char"
        fi

        return 0
    fi
    return 1
}

# Get current buffer state as a single structure
z-skk-buffer-get-state() {
    echo "main:$Z_SKK_BUFFER|romaji:$Z_SKK_ROMAJI_BUFFER|converting:$Z_SKK_CONVERTING"
}

# Restore buffer state from structure
z-skk-buffer-restore-state() {
    local state="$1"

    # Parse state string
    local main_part="${state#*main:}"
    main_part="${main_part%%\|*}"

    local romaji_part="${state#*romaji:}"
    romaji_part="${romaji_part%%\|*}"

    local converting_part="${state#*converting:}"

    # Restore state
    z-skk-buffer-set "$main_part"
    z-skk-romaji-buffer-set "$romaji_part"
    Z_SKK_CONVERTING="$converting_part"

    # Emit state restoration event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit buffer:state-restored "$state"
    fi
}

# Clear all buffers and reset state
z-skk-buffer-reset-all() {
    local old_state
    old_state=$(z-skk-buffer-get-state)

    z-skk-buffer-clear
    z-skk-romaji-buffer-clear
    Z_SKK_CONVERTING=0

    # Emit reset event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit buffer:reset-all "$old_state"
    fi
}

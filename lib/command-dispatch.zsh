#!/usr/bin/env zsh
# Command dispatch tables for z-skk

# Hiragana mode special key commands
typeset -gA Z_SKK_HIRAGANA_COMMANDS=(
    [l]="z-skk-ascii-mode"
    [L]="z-skk-ascii-mode"
    [/]="z-skk-start-abbrev-mode"
    [q]="z-skk-katakana-mode"
    [X]="z-skk-convert-previous-to-katakana"
    ["@"]="z-skk-insert-date"
    [";"]="z-skk-code-input"
    [">"]="z-skk-start-suffix-input"
    ["?"]="z-skk-start-prefix-input"
)

# Katakana mode special key commands
typeset -gA Z_SKK_KATAKANA_COMMANDS=(
    [q]="z-skk-hiragana-mode"
    [l]="z-skk-ascii-mode"
    [L]="z-skk-ascii-mode"
)

# Candidate selection commands
typeset -gA Z_SKK_CANDIDATE_COMMANDS=(
    [" "]="z-skk-next-candidate"
    [x]="z-skk-previous-candidate"
    [$'\x07']="z-skk-cancel-conversion"     # C-g
    [$'\r']="z-skk-confirm-candidate"       # Enter
)

# Pre-conversion commands
typeset -gA Z_SKK_PRECONVERSION_COMMANDS=(
    [" "]="z-skk-start-conversion"
    [$'\x07']="z-skk-cancel-conversion"     # C-g
    [$'\r']="z-skk-cancel-conversion"       # Enter (confirm as-is)
)

# Generic command dispatcher
# Usage: z-skk-dispatch-command <table_name> <key> [default_action]
z-skk-dispatch-command() {
    local table_name="$1"
    local key="$2"
    local default_action="${3:-}"

    # Build command table name
    local table_var="Z_SKK_${table_name}_COMMANDS"

    # Look up command using eval
    local command
    eval "command=\${${table_var}[$key]:-}"

    if [[ -n "$command" ]]; then
        # Execute command
        if (( ${+functions[$command]} )); then
            "$command"
            return 0
        else
            _z-skk-log-error "warn" "Command function not found: $command"
            return 1
        fi
    elif [[ -n "$default_action" ]]; then
        # Execute default action
        if [[ "$default_action" == "return:1" ]]; then
            return 1
        elif (( ${+functions[$default_action]} )); then
            "$default_action" "$key"
            return 0
        else
            eval "$default_action"
            return $?
        fi
    else
        # No command found
        return 1
    fi
}

# Simplified special key handler for hiragana mode
_z-skk-handle-hiragana-special-key-simple() {
    local key="$1"

    if z-skk-dispatch-command "HIRAGANA" "$key"; then
        zle -R
        return 0
    fi

    return 1
}

# Simplified candidate selection handler
_z-skk-handle-candidate-selection-key-simple() {
    local key="$1"

    # Try dispatch first
    if z-skk-dispatch-command "CANDIDATE" "$key"; then
        return 0
    fi

    # Default: confirm and process new key
    z-skk-confirm-candidate
    _z-skk-handle-hiragana-input "$key"
    return 0
}

# Simplified pre-conversion handler
_z-skk-handle-pre-conversion-key-simple() {
    local key="$1"

    z-skk-dispatch-command "PRECONVERSION" "$key" "return:1"
}
#!/usr/bin/env zsh
# Lazy loading infrastructure for z-skk

# Track loaded optional modules
typeset -gA Z_SKK_LOADED_MODULES=()

# Lazy load a module
# Usage: z-skk-lazy-load <module_name>
z-skk-lazy-load() {
    local module="$1"

    # Check if already loaded
    if [[ -n "${Z_SKK_LOADED_MODULES[$module]}" ]]; then
        return 0
    fi

    # Load the module
    local module_file="${Z_SKK_DIR}/lib/${module}.zsh"
    if [[ -f "$module_file" ]]; then
        if z-skk-safe-source "$module_file"; then
            Z_SKK_LOADED_MODULES[$module]=1
            _z-skk-log-error "info" "Lazy loaded module: $module"
            return 0
        else
            _z-skk-log-error "error" "Failed to lazy load module: $module"
            return 1
        fi
    else
        _z-skk-log-error "warn" "Module not found for lazy loading: $module"
        return 1
    fi
}

# Define lazy-loaded function stubs
# These will load the actual module when first called

# Dictionary I/O functions
z-skk-load-dictionary() {
    z-skk-lazy-load "dictionary-io" && z-skk-load-dictionary "$@"
}

z-skk-save-dictionary() {
    z-skk-lazy-load "dictionary-io" && z-skk-save-dictionary "$@"
}

# Registration functions
z-skk-start-registration() {
    z-skk-lazy-load "registration" && z-skk-start-registration "$@"
}

z-skk-register-word() {
    z-skk-lazy-load "registration" && z-skk-register-word "$@"
}

z-skk-cancel-registration() {
    z-skk-lazy-load "registration" && z-skk-cancel-registration "$@"
}

z-skk-is-registering() {
    z-skk-lazy-load "registration" && z-skk-is-registering "$@"
}

# Special keys functions
z-skk-convert-previous-to-katakana() {
    z-skk-lazy-load "special-keys" && z-skk-convert-previous-to-katakana "$@"
}

z-skk-insert-date() {
    z-skk-lazy-load "special-keys" && z-skk-insert-date "$@"
}

z-skk-start-code-input() {
    z-skk-lazy-load "special-keys" && z-skk-start-code-input "$@"
}

z-skk-start-suffix-input() {
    z-skk-lazy-load "special-keys" && z-skk-start-suffix-input "$@"
}

z-skk-start-prefix-input() {
    z-skk-lazy-load "special-keys" && z-skk-start-prefix-input "$@"
}

# Okurigana functions
z-skk-start-okurigana() {
    z-skk-lazy-load "okurigana" && z-skk-start-okurigana "$@"
}

z-skk-check-okurigana-start() {
    z-skk-lazy-load "okurigana" && z-skk-check-okurigana-start "$@"
}

z-skk-reset-okurigana() {
    z-skk-lazy-load "okurigana" && z-skk-reset-okurigana "$@"
}

# Input modes functions
z-skk-start-abbrev-mode() {
    z-skk-lazy-load "input-modes" && z-skk-start-abbrev-mode "$@"
}

_z-skk-handle-abbrev-input() {
    z-skk-lazy-load "input-modes" && _z-skk-handle-abbrev-input "$@"
}

_z-skk-handle-zenkaku-input() {
    z-skk-lazy-load "input-modes" && _z-skk-handle-zenkaku-input "$@"
}
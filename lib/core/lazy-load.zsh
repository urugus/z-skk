#!/usr/bin/env zsh
# Lazy loading infrastructure for z-skk

# Track loaded optional modules
typeset -gA Z_SKK_LOADED_MODULES=()
typeset -gA Z_SKK_LOADING_MODULES=()

# Lazy load a module
# Usage: z-skk-lazy-load <module_name>
z-skk-lazy-load() {
    local module="$1"

    # Check if already loaded
    if [[ -n "${Z_SKK_LOADED_MODULES[$module]}" ]]; then
        return 0
    fi

    # Prevent infinite recursion
    if [[ -n "${Z_SKK_LOADING_MODULES[$module]}" ]]; then
        _z-skk-log-error "error" "Circular dependency detected: $module"
        return 1
    fi

    # Mark as loading
    typeset -g Z_SKK_LOADING_MODULES[$module]=1

    # Load the module
    local module_dir="${Z_SKK_MODULE_DIRS[$module]:-}"
    local module_file

    # Determine module file path
    if [[ -n "$module_dir" ]]; then
        module_file="${Z_SKK_DIR}/lib/${module_dir}/${module}.zsh"
    else
        # Fallback to flat structure for backward compatibility
        module_file="${Z_SKK_DIR}/lib/${module}.zsh"
    fi
    if [[ -f "$module_file" ]]; then
        if z-skk-safe-source "$module_file"; then
            Z_SKK_LOADED_MODULES[$module]=1
            unset "Z_SKK_LOADING_MODULES[$module]"
            # Only log lazy loading in debug mode
            [[ -n "${Z_SKK_DEBUG:-}" ]] && _z-skk-log-error "info" "Lazy loaded module: $module"
            return 0
        else
            unset "Z_SKK_LOADING_MODULES[$module]"
            _z-skk-log-error "error" "Failed to lazy load module: $module"
            return 1
        fi
    else
        unset "Z_SKK_LOADING_MODULES[$module]"
        _z-skk-log-error "warn" "Module not found for lazy loading: $module"
        return 1
    fi
}

# Define lazy-loaded function stubs
# These will load the actual module when first called

# Dictionary I/O functions are now loaded at startup, not lazy-loaded

# Registration functions
z-skk-start-registration() {
    z-skk-lazy-load "registration" && z-skk-start-registration "$@"
}

z-skk-confirm-registration() {
    z-skk-lazy-load "registration" && z-skk-confirm-registration "$@"
}

z-skk-cancel-registration() {
    z-skk-lazy-load "registration" && z-skk-cancel-registration "$@"
}

z-skk-is-registering() {
    z-skk-lazy-load "registration" && z-skk-is-registering "$@"
}

z-skk-registration-input() {
    z-skk-lazy-load "registration" && z-skk-registration-input "$@"
}

z-skk-update-registration-display() {
    z-skk-lazy-load "registration" && z-skk-update-registration-display "$@"
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
z-skk-set-mode() {
    z-skk-lazy-load "input-modes" && z-skk-set-mode "$@"
}

z-skk-convert-romaji-to-katakana() {
    z-skk-lazy-load "input-modes" && z-skk-convert-romaji-to-katakana "$@"
}

z-skk-start-abbrev-mode() {
    z-skk-lazy-load "input-modes" && z-skk-activate-abbrev "$@"
}

_z-skk-handle-abbrev-input() {
    z-skk-lazy-load "input-modes" && z-skk-process-abbrev-input "$@"
}

_z-skk-handle-zenkaku-input() {
    z-skk-lazy-load "input-modes" && z-skk-process-zenkaku-input "$@"
}
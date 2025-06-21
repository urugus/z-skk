#!/usr/bin/env zsh
# Standardized error handling for z-skk

# Error log level
typeset -g Z_SKK_ERROR_LEVEL="${Z_SKK_ERROR_LEVEL:-warn}"

# Log an error message
_z-skk-log-error() {
    local level="$1"
    local message="$2"

    case "$level" in
        error)
            print "z-skk: ERROR: $message" >&2
            ;;
        warn)
            [[ "$Z_SKK_ERROR_LEVEL" == "warn" || "$Z_SKK_ERROR_LEVEL" == "info" ]] && \
                print "z-skk: WARN: $message" >&2
            ;;
        info)
            [[ "$Z_SKK_ERROR_LEVEL" == "info" ]] && \
                print "z-skk: INFO: $message" >&2
            ;;
    esac
}

# Unified error handler for operations
z-skk-safe-operation() {
    local operation_name="$1"
    local operation_func="$2"
    shift 2

    # Execute operation with error handling
    if ! "$operation_func" "$@" 2>/dev/null; then
        _z-skk-log-error "warn" "Failed to execute $operation_name"
        return 1
    fi

    return 0
}

# Safe function call with fallback
z-skk-safe-call() {
    local func_name="$1"
    local fallback_func="$2"
    shift 2

    if (( ${+functions[$func_name]} )); then
        "$func_name" "$@"
    elif [[ -n "$fallback_func" ]] && (( ${+functions[$fallback_func]} )); then
        "$fallback_func" "$@"
    else
        _z-skk-log-error "warn" "Function $func_name not available and no fallback provided"
        return 1
    fi
}

# Safe array access
z-skk-safe-array-get() {
    local array_name="$1"
    local index="$2"
    local default_value="$3"

    # Use indirect reference to access array
    local -n array_ref="$array_name"

    if [[ -n "${array_ref[$index]}" ]]; then
        echo "${array_ref[$index]}"
    else
        echo "$default_value"
    fi
}

# Safe source a file with error handling
z-skk-safe-source() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        _z-skk-log-error "warn" "File not found: $file"
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        _z-skk-log-error "error" "Cannot read file: $file"
        return 1
    fi

    source "$file" || {
        _z-skk-log-error "error" "Failed to source: $file"
        return 1
    }

    return 0
}

# Safe ZLE operation
z-skk-safe-zle() {
    local widget="$1"
    shift

    # Check if we're in ZLE context
    if [[ -z "$WIDGET" ]]; then
        _z-skk-log-error "warn" "ZLE operation outside widget context: $widget"
        return 1
    fi

    # Check if widget exists
    if ! (( ${+widgets[$widget]} )); then
        _z-skk-log-error "error" "Widget not found: $widget"
        return 1
    fi

    zle "$widget" "$@" || {
        _z-skk-log-error "error" "ZLE operation failed: $widget"
        return 1
    }

    return 0
}

# Validate input parameters
z-skk-validate-params() {
    local param_count=$1
    local actual_count=$2
    local function_name=$3

    if [[ $actual_count -lt $param_count ]]; then
        _z-skk-log-error "error" "$function_name: Expected at least $param_count parameters, got $actual_count"
        return 1
    fi

    return 0
}

# Error recovery strategies
typeset -gA Z_SKK_ERROR_RECOVERY=(
    [conversion]="z-skk-reset core:1 romaji:1 display:1"
    [registration]="z-skk-reset registration:1 display:1"
    [display]="z-skk-reset display:1"
    [input]="z-skk-reset romaji:1"
    [dictionary]="z-skk-reset core:1"
    [mode]="z-skk-reset core:1 romaji:1"
    [special]="z-skk-reset special:1 display:1"
)

# Enhanced safe operation wrapper
# Usage: z-skk-safe-operation <operation_name> <command> [args...]
z-skk-safe-operation() {
    local operation_name="$1"
    shift

    local exit_code=0

    # Execute the operation
    {
        "$@"
        exit_code=$?
    } always {
        if [[ $exit_code -ne 0 ]]; then
            # Log the error
            _z-skk-log-error "warn" "Error during $operation_name"

            # Execute recovery strategy if defined
            local recovery="${Z_SKK_ERROR_RECOVERY[$operation_name]:-}"
            if [[ -n "$recovery" ]]; then
                # Execute recovery command
                eval "$recovery" 2>/dev/null || true
            else
                # Default recovery
                z-skk-reset core:1 2>/dev/null || true
            fi
        fi
    }

    return $exit_code
}

# Safe execution with return value
# Usage: result=$(z-skk-safe-call <operation_name> <command> [args...])
z-skk-safe-call() {
    local operation_name="$1"
    shift

    local result
    local exit_code

    # Capture output and exit code
    result=$("$@" 2>/dev/null)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "$result"
        return 0
    else
        # Log error if logging is available
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "warn" "Failed to execute: $operation_name"
        fi

        # Execute recovery if needed
        local recovery="${Z_SKK_ERROR_RECOVERY[$operation_name]:-}"
        if [[ -n "$recovery" ]]; then
            eval "$recovery" 2>/dev/null || true
        fi

        return 1
    fi
}

# Safe state transition
# Usage: z-skk-safe-transition <from_state> <to_state> <transition_function>
z-skk-safe-transition() {
    local from_state="$1"
    local to_state="$2"
    local transition_func="$3"
    shift 3

    # Verify current state
    if [[ "${Z_SKK_STATE:-normal}" != "$from_state" ]] && [[ "$from_state" != "any" ]]; then
        _z-skk-log-error "warn" "Invalid state transition: ${Z_SKK_STATE:-normal} -> $to_state"
        return 1
    fi

    # Save current state
    local saved_state="${Z_SKK_STATE:-normal}"

    # Attempt transition
    if z-skk-safe-operation "state_transition" "$transition_func" "$@"; then
        Z_SKK_STATE="$to_state"
        return 0
    else
        # Restore previous state on failure
        Z_SKK_STATE="$saved_state"
        return 1
    fi
}

# Batch error handling for multiple operations
# Usage: z-skk-batch-safe op1:cmd1 op2:cmd2 ...
z-skk-batch-safe() {
    local failed=0
    local op cmd

    for spec in "$@"; do
        if [[ "$spec" =~ ^([^:]+):(.+)$ ]]; then
            op="${match[1]}"
            cmd="${match[2]}"

            if ! z-skk-safe-operation "$op" eval "$cmd"; then
                ((failed++))
            fi
        fi
    done

    return $((failed > 0 ? 1 : 0))
}

# Critical section wrapper
# Usage: z-skk-critical <operation_name> <command> [args...]
z-skk-critical() {
    local operation_name="$1"
    shift

    # Disable error recovery temporarily
    local saved_errexit="${options[errexit]:-off}"
    setopt local_options no_errexit

    # Execute critical operation
    local result
    "$@"
    result=$?

    # Restore errexit option
    [[ "$saved_errexit" == "on" ]] && setopt errexit

    if [[ $result -ne 0 ]]; then
        _z-skk-log-error "error" "Critical failure in $operation_name"
        # Perform full reset on critical failure
        z-skk-reset all display:1 2>/dev/null || true
    fi

    return $result
}

# Reset to safe state on error
z-skk-error-reset() {
    local context="${1:-unknown}"

    _z-skk-log-error "warn" "Resetting due to error in: $context"

    # Reset all state using reset.zsh
    if (( ${+functions[z-skk-reset]} )); then
        z-skk-reset all
    else
        # Fallback if reset.zsh not available
        Z_SKK_BUFFER=""
        Z_SKK_CONVERTING=0
        Z_SKK_CANDIDATES=()
        Z_SKK_CANDIDATE_INDEX=0
        [[ -v Z_SKK_ROMAJI_BUFFER ]] && Z_SKK_ROMAJI_BUFFER=""
    fi

    # Switch to ASCII mode (safest)
    Z_SKK_MODE="ascii"

    # Update display if possible
    if (( ${+functions[z-skk-update-display]} )); then
        z-skk-update-display
    fi

    return 0
}
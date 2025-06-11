#!/usr/bin/env zsh
# Standardized error handling for z-skk

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

    local result
    local exit_code

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

            return 1
        fi
    }

    return 0
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
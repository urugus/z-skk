#!/usr/bin/env zsh
# Event system for loose coupling between z-skk modules

# Event handlers registry
typeset -gA Z_SKK_EVENT_HANDLERS=()

# Register an event handler
# Usage: z-skk-on <event_name> <handler_function>
z-skk-on() {
    local event="$1"
    local handler="$2"

    # Validate handler function exists
    if ! (( ${+functions[$handler]} )); then
        _z-skk-log-error "warn" "Event handler function not found: $handler"
        return 1
    fi

    # Add handler to the event's handler list
    if [[ -n "${Z_SKK_EVENT_HANDLERS[$event]}" ]]; then
        Z_SKK_EVENT_HANDLERS[$event]+=" $handler"
    else
        Z_SKK_EVENT_HANDLERS[$event]="$handler"
    fi

    _z-skk-log-error "info" "Registered handler $handler for event $event"
    return 0
}

# Unregister an event handler
# Usage: z-skk-off <event_name> <handler_function>
z-skk-off() {
    local event="$1"
    local handler="$2"

    if [[ -z "${Z_SKK_EVENT_HANDLERS[$event]}" ]]; then
        return 0
    fi

    # Remove handler from the list
    local handlers=(${=Z_SKK_EVENT_HANDLERS[$event]})
    local new_handlers=()

    for h in "${handlers[@]}"; do
        if [[ "$h" != "$handler" ]]; then
            new_handlers+=("$h")
        fi
    done

    if [[ ${#new_handlers[@]} -eq 0 ]]; then
        unset "Z_SKK_EVENT_HANDLERS[$event]"
    else
        Z_SKK_EVENT_HANDLERS[$event]="${new_handlers[*]}"
    fi

    return 0
}

# Emit an event
# Usage: z-skk-emit <event_name> [args...]
z-skk-emit() {
    local event="$1"
    shift

    # Check if there are any handlers for this event
    if [[ -z "${Z_SKK_EVENT_HANDLERS[$event]}" ]]; then
        return 0
    fi

    # Call each handler
    local handlers=(${=Z_SKK_EVENT_HANDLERS[$event]})
    local handler

    for handler in "${handlers[@]}"; do
        if (( ${+functions[$handler]} )); then
            # Use safe operation to prevent handler errors from breaking the event chain
            z-skk-safe-operation "event:$event:$handler" "$handler" "$@"
        else
            _z-skk-log-error "warn" "Event handler no longer exists: $handler"
        fi
    done

    return 0
}

# Common events used by z-skk modules
# These serve as documentation and can be referenced by modules

# Mode change events
# z-skk-emit mode:changed <old_mode> <new_mode>

# Conversion events
# z-skk-emit conversion:started <buffer>
# z-skk-emit conversion:completed <result>
# z-skk-emit conversion:cancelled

# Registration events
# z-skk-emit registration:started <reading>
# z-skk-emit registration:completed <reading> <word>
# z-skk-emit registration:cancelled

# Dictionary events
# z-skk-emit dictionary:loaded <dict_type>
# z-skk-emit dictionary:saved <dict_type>
# z-skk-emit dictionary:updated <reading> <word>

# Input events
# z-skk-emit input:received <key>
# z-skk-emit input:processed <key> <result>

# Display events
# z-skk-emit display:updated
# z-skk-emit display:cleared
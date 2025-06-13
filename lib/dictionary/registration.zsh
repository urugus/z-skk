#!/usr/bin/env zsh
# Dictionary registration functionality for z-skk

# Registration mode state
typeset -g Z_SKK_REGISTERING=0      # 0: not registering, 1: registering
typeset -g Z_SKK_REGISTER_READING=""  # Reading being registered
typeset -g Z_SKK_REGISTER_CANDIDATE="" # New candidate being entered

# Start registration mode
z-skk-start-registration() {
    local reading="$1"

    if [[ -z "$reading" ]]; then
        return 1
    fi

    # Set registration mode
    Z_SKK_REGISTERING=1
    Z_SKK_REGISTER_READING="$reading"
    Z_SKK_REGISTER_CANDIDATE=""

    # Clear any existing display
    z-skk-clear-marker "▽" ""

    # Show registration marker with closing bracket
    z-skk-add-marker "▼" "${reading}[]"

    return 0
}

# Process input in registration mode
z-skk-registration-input() {
    local key="$1"

    if [[ $Z_SKK_REGISTERING -ne 1 ]]; then
        return 1
    fi

    # Handle special keys
    case "$key" in
        $'\n'|$'\r')  # Enter - confirm registration
            z-skk-confirm-registration
            return 0
            ;;
        $'\x07')  # C-g - cancel registration
            z-skk-cancel-registration
            return 0
            ;;
        $'\x7f'|$'\b')  # Backspace
            if [[ -n "$Z_SKK_REGISTER_CANDIDATE" ]]; then
                Z_SKK_REGISTER_CANDIDATE="${Z_SKK_REGISTER_CANDIDATE[1,-2]}"
                z-skk-update-registration-display
            fi
            return 0
            ;;
        *)
            # Add character to candidate
            Z_SKK_REGISTER_CANDIDATE+="$key"
            z-skk-update-registration-display
            return 0
            ;;
    esac
}

# Update registration display
z-skk-update-registration-display() {
    if [[ $Z_SKK_REGISTERING -eq 1 ]]; then
        # Build current display string
        local current_display="${Z_SKK_REGISTER_READING}[${Z_SKK_REGISTER_CANDIDATE}]"

        # Update display using common utilities
        z-skk-clear-marker "▼" ""
        z-skk-add-marker "▼" "$current_display"
    fi
}

# Confirm and save registration
z-skk-confirm-registration() {
    if [[ $Z_SKK_REGISTERING -ne 1 || -z "$Z_SKK_REGISTER_CANDIDATE" ]]; then
        z-skk-cancel-registration
        return 1
    fi

    # Clear display
    z-skk-clear-marker "▼" ""

    # Add to dictionary
    z-skk-add-user-entry "$Z_SKK_REGISTER_READING" "$Z_SKK_REGISTER_CANDIDATE"

    # Save dictionary
    z-skk-save-user-dictionary

    # Insert the registered word
    LBUFFER+="$Z_SKK_REGISTER_CANDIDATE"

    # Reset registration state
    Z_SKK_REGISTERING=0
    Z_SKK_REGISTER_READING=""
    Z_SKK_REGISTER_CANDIDATE=""

    # Reset conversion state
    z-skk-reset-state

    return 0
}

# Cancel registration
z-skk-cancel-registration() {
    if [[ $Z_SKK_REGISTERING -eq 1 ]]; then
        # Clear display
        z-skk-clear-marker "▼" ""

        # Insert the original reading as-is
        LBUFFER+="$Z_SKK_REGISTER_READING"
    fi

    # Reset registration state
    Z_SKK_REGISTERING=0
    Z_SKK_REGISTER_READING=""
    Z_SKK_REGISTER_CANDIDATE=""

    # Reset conversion state
    z-skk-reset-state

    return 0
}

# Check if in registration mode
z-skk-is-registering() {
    [[ $Z_SKK_REGISTERING -eq 1 ]]
}
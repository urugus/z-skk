#!/usr/bin/env zsh
# Dictionary file I/O for z-skk

# Dictionary file paths
typeset -g Z_SKK_USER_JISYO_PATH="${SKK_JISYO_PATH:-${HOME}/.skk-jisyo}"
typeset -g Z_SKK_SYSTEM_JISYO_PATH="${SKK_SYSTEM_JISYO_PATH:-}"

# Personal dictionary (runtime modifications)
typeset -gA Z_SKK_USER_DICTIONARY=()

# Parse SKK dictionary line
# Format: よみ /候補1/候補2;annotation2/候補3/
_z-skk-parse-dict-line() {
    local line="$1"
    local reading candidates
    # Skip empty lines
    [[ -z "$line" ]] && return 1

    # Skip comments (lines starting with ;;)
    [[ "$line" == ";;"* ]] && return 1

    # Skip lines with only whitespace
    [[ "$line" =~ ^[[:space:]]+$ ]] && return 1

    # Parse line: reading /candidate1/candidate2/
    # Use simple pattern matching instead of regex
    local parts=(${(s: :)line})
    if [[ ${#parts[@]} -ge 2 && "${parts[2]}" == "/"* && "${parts[-1]}" == *"/" ]]; then
        reading="${parts[1]}"
        # Reconstruct candidates part
        shift parts
        candidates="${parts[*]}"
        # Remove leading / and trailing /
        candidates="${candidates#/}"
        candidates="${candidates%/}"
        # Return reading and candidates
        print -r -- "$reading"
        print -r -- "$candidates"
        return 0
    fi

    return 1
}

# Load dictionary from file
z-skk-load-dictionary-file() {
    local dict_file="$1"
    local -A target_dict
    local line reading candidates
    # Validate file
    if [[ ! -f "$dict_file" ]]; then
        _z-skk-log-error "warn" "Dictionary file not found: $dict_file"
        return 1
    fi

    if [[ ! -r "$dict_file" ]]; then
        _z-skk-log-error "error" "Cannot read dictionary file: $dict_file"
        return 1
    fi

    # Read file line by line
    local count=0
    while IFS= read -r line; do
        local parsed=($(_z-skk-parse-dict-line "$line"))
        if [[ ${#parsed[@]} -eq 2 ]]; then
            reading="${parsed[1]}"
            candidates="${parsed[2]}"
            # Add to dictionary
            if [[ -n "${Z_SKK_DICTIONARY[$reading]}" ]]; then
                # Merge with existing entries
                Z_SKK_DICTIONARY[$reading]="${Z_SKK_DICTIONARY[$reading]}/${candidates}"
            else
                Z_SKK_DICTIONARY[$reading]="$candidates"
            fi

            ((count++))
        fi
    done < "$dict_file"

    _z-skk-log-error "info" "Loaded $count entries from $dict_file"
    return 0
}

# Save user dictionary to file
z-skk-save-user-dictionary() {
    local dict_file="${Z_SKK_USER_JISYO_PATH}"
    local reading candidates
    local temp_file="${dict_file}.tmp.$$"
    # Create directory if needed
    local dict_dir="${dict_file:h}"
    if [[ ! -d "$dict_dir" ]]; then
        mkdir -p "$dict_dir" || {
            _z-skk-log-error "error" "Cannot create directory: $dict_dir"
            return 1
        }
    fi

    # Write header
    {
        print ";; -*- mode: fundamental; coding: utf-8 -*-"
        print ";; z-skk user dictionary"
        print ";; Generated at $(date '+%Y-%m-%d %H:%M:%S')"
        print ""
        # Write entries sorted by reading
        for reading in ${(ko)Z_SKK_USER_DICTIONARY}; do
            candidates="${Z_SKK_USER_DICTIONARY[$reading]}"
            print -r -- "$reading /$candidates/"
        done
    } > "$temp_file" || {
        _z-skk-log-error "error" "Cannot write to temporary file"
        rm -f "$temp_file"
        return 1
    }

    # Atomic move
    mv -f "$temp_file" "$dict_file" || {
        _z-skk-log-error "error" "Cannot save dictionary file"
        rm -f "$temp_file"
        return 1
    }

    return 0
}

# Initialize dictionary loading
z-skk-init-dictionary-loading() {
    # Load user dictionary if exists
    if [[ -f "$Z_SKK_USER_JISYO_PATH" ]]; then
        z-skk-load-dictionary-file "$Z_SKK_USER_JISYO_PATH"
    fi

    # Load system dictionary if specified
    if [[ -n "$Z_SKK_SYSTEM_JISYO_PATH" && -f "$Z_SKK_SYSTEM_JISYO_PATH" ]]; then
        z-skk-load-dictionary-file "$Z_SKK_SYSTEM_JISYO_PATH"
    fi

    return 0
}

# Add entry to user dictionary
z-skk-add-user-entry() {
    local reading="$1"
    local candidate="$2"
    if [[ -z "$reading" || -z "$candidate" ]]; then
        return 1
    fi

    # Add to runtime dictionary
    if [[ -n "${Z_SKK_USER_DICTIONARY[$reading]}" ]]; then
        # Check if already exists
        if [[ "${Z_SKK_USER_DICTIONARY[$reading]}" != *"$candidate"* ]]; then
            Z_SKK_USER_DICTIONARY[$reading]="${candidate}/${Z_SKK_USER_DICTIONARY[$reading]}"
        fi
    else
        Z_SKK_USER_DICTIONARY[$reading]="$candidate"
    fi

    # Also add to main dictionary for immediate use
    if [[ -n "${Z_SKK_DICTIONARY[$reading]}" ]]; then
        if [[ "${Z_SKK_DICTIONARY[$reading]}" != *"$candidate"* ]]; then
            Z_SKK_DICTIONARY[$reading]="${candidate}/${Z_SKK_DICTIONARY[$reading]}"
        fi
    else
        Z_SKK_DICTIONARY[$reading]="$candidate"
    fi

    return 0
}
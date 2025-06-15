#!/usr/bin/env zsh
# Dictionary file I/O for z-skk

# Dictionary file paths
# Note: SKK_JISYO_PATH and SKK_SYSTEM_JISYO_PATH are external environment variables
# that users can set to customize dictionary locations
typeset -g Z_SKK_USER_JISYO_PATH="${SKK_JISYO_PATH:-${HOME}/.skk-jisyo}"
typeset -g Z_SKK_SYSTEM_JISYO_PATH="${SKK_SYSTEM_JISYO_PATH:-}"

# Personal dictionary (runtime modifications)
typeset -gA Z_SKK_USER_DICTIONARY
Z_SKK_USER_DICTIONARY=()

# Parse SKK dictionary line
# Format: よみ /候補1/候補2;annotation2/候補3/
# Okuri-ari format: よみX /候補1/候補2/ where X is a romaji letter for okurigana
_z-skk-parse-dict-line() {
    local line="$1"
    local reading candidates
    local is_okurigana=0
    local okurigana_marker=""

    # Skip empty lines
    [[ -z "$line" ]] && return 1

    # Skip comments (lines starting with ;;)
    [[ "$line" == ";;"* ]] && return 1

    # Skip lines with only whitespace (avoid regex for better compatibility)
    local trimmed="${line//[[:space:]]/}"
    [[ -z "$trimmed" ]] && return 1

    # Parse line: reading /candidate1/candidate2/
    # Find the first space to split reading from candidates
    local space_pos="${line[(i) ]}"
    if [[ $space_pos -le ${#line} ]]; then
        reading="${line[1,$((space_pos-1))]}"
        local rest="${line[$((space_pos+1)),-1]}"

        # Trim spaces from rest
        rest="${rest## }"
        rest="${rest%% }"

        # Check if rest starts with / and ends with /
        if [[ "$rest" == "/"*"/" ]]; then
            # Check for okuri-ari entries (reading ends with romaji letter)
            # Use pattern matching instead of regex for better compatibility
            local last_char="${reading[-1]}"
            if [[ "$last_char" == [a-z] ]] && [[ ${#reading} -gt 1 ]]; then
                # Simple check: if reading has hiragana followed by romaji
                is_okurigana=1
                okurigana_marker="$last_char"
                # For now, store the full reading including marker
                # The conversion system will handle okuri-ari lookups
            fi

            # Remove leading / and trailing /
            candidates="${rest#/}"
            candidates="${candidates%/}"

            # Return reading and candidates
            print -r -- "$reading"
            print -r -- "$candidates"
            return 0
        fi
    fi

    return 1
}

# Load dictionary from file
z-skk-load-dictionary-file() {
    local dict_file="$1"
    local -A target_dict
    local line reading candidates

    # Ensure debug function exists
    if ! (( ${+functions[z-skk-debug]} )); then
        z-skk-debug() { [[ "${Z_SKK_DEBUG:-0}" == "1" ]] && print "z-skk DEBUG: $*" >&2 ; }
    fi

    # Validate file
    if [[ ! -f "$dict_file" ]]; then
        _z-skk-log-error "warn" "Dictionary file not found: $dict_file"
        return 1
    fi

    if [[ ! -r "$dict_file" ]]; then
        _z-skk-log-error "error" "Cannot read dictionary file: $dict_file"
        return 1
    fi

    # Read file line by line with proper encoding handling
    local count=0
    local max_errors=${Z_SKK_MAX_PARSE_ERRORS:-100}  # Configurable, default 100
    local max_entries=${Z_SKK_MAX_LOAD_ENTRIES:-5000}  # Limit entries for performance
    local error_count=0

    # Try to read file with error handling and timeout protection
    # Use a simple file read instead of process substitution to avoid potential hangs
    if [[ -r "$dict_file" ]]; then
        # Read file into array first (more reliable than process substitution)
        local -a file_lines=()
        z-skk-debug "Reading dictionary file: $dict_file"
        file_lines=("${(@f)$(< "$dict_file" 2>/dev/null)}")
        z-skk-debug "Read ${#file_lines[@]} lines from dictionary"
        # Process lines
        for line in "${file_lines[@]}"; do
            # Skip if we've hit too many errors or loaded enough entries
            if ((error_count >= max_errors)); then
                _z-skk-log-error "warn" "Too many parse errors, stopping dictionary load"
                break
            fi

            if ((count >= max_entries)); then
                z-skk-debug "Reached max entries limit ($max_entries), stopping dictionary load"
                break
            fi

            # Skip empty lines quickly
            [[ -z "$line" || "$line" == ";;"* || "${line// /}" == "" ]] && continue

            # Fast inline parsing instead of function call
            local space_pos="${line[(i) ]}"
            if [[ $space_pos -le ${#line} ]]; then
                reading="${line[1,$((space_pos-1))]}"
                local rest="${line[$((space_pos+1)),-1]}"

                # Trim and check format
                rest="${rest## }"
                rest="${rest%% }"

                if [[ "$rest" == "/"*"/" ]]; then
                    # Extract candidates
                    candidates="${rest#/}"
                    candidates="${candidates%/}"

                    # Simple assignment for new entries (most common case)
                    if [[ -z "${Z_SKK_DICTIONARY[$reading]}" ]]; then
                        Z_SKK_DICTIONARY[$reading]="$candidates"
                    else
                        # Only do complex merging for duplicates
                        Z_SKK_DICTIONARY[$reading]="${Z_SKK_DICTIONARY[$reading]}/${candidates}"
                    fi
                    ((count++))
                fi
            else
                ((error_count++))
            fi
        done
    fi

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
    # Track loading status
    typeset -g Z_SKK_DICTIONARY_LOADED=0

    # Ensure error logging is available
    if ! (( ${+functions[_z-skk-log-error]} )); then
        # Define a simple fallback
        _z-skk-log-error() { print "z-skk: $2" >&2 ; }
    fi

    # Ensure debug logging is available for troubleshooting
    if ! (( ${+functions[z-skk-debug]} )); then
        z-skk-debug() { [[ "${Z_SKK_DEBUG:-0}" == "1" ]] && print "z-skk DEBUG: $*" >&2 ; }
    fi

    local load_success=1

    z-skk-debug "Dictionary paths: user=$Z_SKK_USER_JISYO_PATH, system=$Z_SKK_SYSTEM_JISYO_PATH"

    # Check if cache is enabled (default: enabled)
    local use_cache="${Z_SKK_USE_CACHE:-1}"

    # Load user dictionary if exists
    if [[ -f "$Z_SKK_USER_JISYO_PATH" ]]; then
        z-skk-debug "User dictionary file exists, loading..."
        _z-skk-log-error "info" "Loading user dictionary: $Z_SKK_USER_JISYO_PATH"
        if [[ "$use_cache" == "1" ]] && (( ${+functions[z-skk-load-dictionary-with-cache]} )); then
            if ! z-skk-load-dictionary-with-cache "$Z_SKK_USER_JISYO_PATH"; then
                _z-skk-log-error "warn" "Failed to load user dictionary"
                load_success=0
            fi
        else
            if ! z-skk-load-dictionary-file "$Z_SKK_USER_JISYO_PATH"; then
                _z-skk-log-error "warn" "Failed to load user dictionary"
                load_success=0
            fi
        fi
        z-skk-debug "User dictionary load complete"
    else
        _z-skk-log-error "info" "User dictionary not found: $Z_SKK_USER_JISYO_PATH"
    fi

    # Load system dictionary if specified
    if [[ -n "$Z_SKK_SYSTEM_JISYO_PATH" && -f "$Z_SKK_SYSTEM_JISYO_PATH" ]]; then
        z-skk-debug "System dictionary file exists, loading..."
        _z-skk-log-error "info" "Loading system dictionary: $Z_SKK_SYSTEM_JISYO_PATH"
        if [[ "$use_cache" == "1" ]] && (( ${+functions[z-skk-load-dictionary-with-cache]} )); then
            if ! z-skk-load-dictionary-with-cache "$Z_SKK_SYSTEM_JISYO_PATH"; then
                _z-skk-log-error "warn" "Failed to load system dictionary"
                load_success=0
            fi
        else
            if ! z-skk-load-dictionary-file "$Z_SKK_SYSTEM_JISYO_PATH"; then
                _z-skk-log-error "warn" "Failed to load system dictionary"
                load_success=0
            fi
        fi
        z-skk-debug "System dictionary load complete"
    fi

    # Mark as loaded even if some dictionaries failed
    Z_SKK_DICTIONARY_LOADED=1
    z-skk-debug "Dictionary initialization complete"

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
        # Check if exact candidate already exists
        local -a existing_candidates=("${(@s:/:)Z_SKK_USER_DICTIONARY[$reading]}")
        local found=0
        for cand in "${existing_candidates[@]}"; do
            if [[ "$cand" == "$candidate" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            Z_SKK_USER_DICTIONARY[$reading]="${candidate}/${Z_SKK_USER_DICTIONARY[$reading]}"
        fi
    else
        Z_SKK_USER_DICTIONARY[$reading]="$candidate"
    fi

    # Also add to main dictionary for immediate use
    if [[ -n "${Z_SKK_DICTIONARY[$reading]}" ]]; then
        # Check if exact candidate already exists
        local -a existing_candidates=("${(@s:/:)Z_SKK_DICTIONARY[$reading]}")
        local found=0
        for cand in "${existing_candidates[@]}"; do
            if [[ "$cand" == "$candidate" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            Z_SKK_DICTIONARY[$reading]="${candidate}/${Z_SKK_DICTIONARY[$reading]}"
        fi
    else
        Z_SKK_DICTIONARY[$reading]="$candidate"
    fi

    return 0
}
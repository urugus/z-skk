#!/usr/bin/env zsh
# Dictionary cache mechanism for z-skk

# Cache configuration
typeset -g Z_SKK_CACHE_DIR="${Z_SKK_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/z-skk}"
typeset -g Z_SKK_CACHE_VERSION="1.0"

# Get cache file path for a dictionary
_z-skk-get-cache-path() {
    local dict_path="$1"
    local cache_name="${dict_path:t}.cache"
    print -r -- "$Z_SKK_CACHE_DIR/$cache_name"
}

# Check if cache is valid
_z-skk-is-cache-valid() {
    local dict_path="$1"
    local cache_path="$2"

    # Cache doesn't exist
    [[ ! -f "$cache_path" ]] && return 1

    # Dictionary doesn't exist (shouldn't happen, but check anyway)
    [[ ! -f "$dict_path" ]] && return 1

    # Check if dictionary is newer than cache
    if [[ "$dict_path" -nt "$cache_path" ]]; then
        z-skk-debug "Dictionary $dict_path is newer than cache"
        return 1
    fi

    # Verify cache header
    local header
    read -r header < "$cache_path" 2>/dev/null
    if [[ "$header" != "Z_SKK_CACHE_v${Z_SKK_CACHE_VERSION}" ]]; then
        z-skk-debug "Cache version mismatch: $header"
        return 1
    fi

    return 0
}

# Save dictionary to cache
_z-skk-save-cache() {
    local dict_path="$1"
    local cache_path="$2"
    local -A dict_to_save

    # Create cache directory if needed
    [[ ! -d "$Z_SKK_CACHE_DIR" ]] && mkdir -p "$Z_SKK_CACHE_DIR"

    # Determine which dictionary entries to save based on the source file
    local dict_name="${dict_path:t}"
    local temp_file="${cache_path}.tmp.$$"

    {
        # Write header
        print "Z_SKK_CACHE_v${Z_SKK_CACHE_VERSION}"
        print "# Generated from: $dict_path"
        print "# Generated at: $(date '+%Y-%m-%d %H:%M:%S')"
        print "# Entries: ${#Z_SKK_DICTIONARY[@]}"
        print ""

        # Write dictionary entries in a format that's fast to parse
        # Format: reading<TAB>candidates
        for reading in ${(k)Z_SKK_DICTIONARY}; do
            print -r -- "${reading}	${Z_SKK_DICTIONARY[$reading]}"
        done
    } > "$temp_file"

    # Atomic move
    mv -f "$temp_file" "$cache_path" || {
        rm -f "$temp_file"
        return 1
    }

    z-skk-debug "Saved cache to $cache_path"
    return 0
}

# Load dictionary from cache
_z-skk-load-cache() {
    local cache_path="$1"
    local line reading candidates
    local count=0

    # Skip header lines
    local in_header=1

    while IFS=$'\t' read -r reading candidates; do
        # Skip header
        if [[ $in_header -eq 1 ]]; then
            if [[ -z "$reading" ]]; then
                in_header=0
            elif [[ "$reading" == "#"* || "$reading" == "Z_SKK_CACHE_v"* ]]; then
                continue
            else
                in_header=0
            fi
        fi

        # Skip empty lines
        [[ -z "$reading" ]] && continue

        # Add to dictionary
        if [[ -z "${Z_SKK_DICTIONARY[$reading]}" ]]; then
            Z_SKK_DICTIONARY[$reading]="$candidates"
        else
            # Merge candidates
            Z_SKK_DICTIONARY[$reading]="${Z_SKK_DICTIONARY[$reading]}/${candidates}"
        fi
        ((count++))
    done < "$cache_path"

    z-skk-debug "Loaded $count entries from cache"
    return 0
}

# Load dictionary with cache support
z-skk-load-dictionary-with-cache() {
    local dict_file="$1"
    local cache_path

    # Validate dictionary file
    if [[ ! -f "$dict_file" ]]; then
        _z-skk-log-error "warn" "Dictionary file not found: $dict_file"
        return 1
    fi

    if [[ ! -r "$dict_file" ]]; then
        _z-skk-log-error "error" "Cannot read dictionary file: $dict_file"
        return 1
    fi

    # Get cache path
    cache_path="$(_z-skk-get-cache-path "$dict_file")"
    z-skk-debug "Cache path: $cache_path"

    # Check if cache is valid
    if _z-skk-is-cache-valid "$dict_file" "$cache_path"; then
        z-skk-debug "Loading from cache: $cache_path"
        if _z-skk-load-cache "$cache_path"; then
            _z-skk-log-error "info" "Loaded dictionary from cache: $dict_file"
            return 0
        else
            z-skk-debug "Failed to load cache, falling back to dictionary"
        fi
    fi

    # Load from dictionary file
    z-skk-debug "Loading from dictionary: $dict_file"
    if z-skk-load-dictionary-file "$dict_file"; then
        # Save to cache for next time
        _z-skk-save-cache "$dict_file" "$cache_path"
        return 0
    fi

    return 1
}

# Clear all caches
z-skk-clear-cache() {
    if [[ -d "$Z_SKK_CACHE_DIR" ]]; then
        rm -rf "$Z_SKK_CACHE_DIR"
        _z-skk-log-error "info" "Cleared dictionary cache"
    fi
}
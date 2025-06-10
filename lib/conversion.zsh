#!/usr/bin/env zsh
# Romaji to kana conversion functionality

# Romaji input buffer
typeset -g Z_SKK_ROMAJI_BUFFER=""

# Romaji to Hiragana conversion table
typeset -gA Z_SKK_ROMAJI_TO_HIRAGANA=(
    # Vowels
    [a]="あ"  [i]="い"  [u]="う"  [e]="え"  [o]="お"

    # K-row
    [ka]="か" [ki]="き" [ku]="く" [ke]="け" [ko]="こ"
    [kya]="きゃ" [kyu]="きゅ" [kyo]="きょ"

    # G-row
    [ga]="が" [gi]="ぎ" [gu]="ぐ" [ge]="げ" [go]="ご"
    [gya]="ぎゃ" [gyu]="ぎゅ" [gyo]="ぎょ"

    # S-row
    [sa]="さ" [shi]="し" [su]="す" [se]="せ" [so]="そ"
    [sha]="しゃ" [shu]="しゅ" [sho]="しょ"

    # Z-row
    [za]="ざ" [ji]="じ" [zu]="ず" [ze]="ぜ" [zo]="ぞ"
    [ja]="じゃ" [ju]="じゅ" [jo]="じょ"

    # T-row
    [ta]="た" [chi]="ち" [tsu]="つ" [te]="て" [to]="と"
    [cha]="ちゃ" [chu]="ちゅ" [cho]="ちょ"

    # D-row
    [da]="だ" [di]="ぢ" [du]="づ" [de]="で" [do]="ど"

    # N-row
    [na]="な" [ni]="に" [nu]="ぬ" [ne]="ね" [no]="の"
    [nya]="にゃ" [nyu]="にゅ" [nyo]="にょ"

    # H-row
    [ha]="は" [hi]="ひ" [hu]="ふ" [he]="へ" [ho]="ほ"
    [fu]="ふ"  # Alternative for 'hu'
    [hya]="ひゃ" [hyu]="ひゅ" [hyo]="ひょ"

    # B-row
    [ba]="ば" [bi]="び" [bu]="ぶ" [be]="べ" [bo]="ぼ"
    [bya]="びゃ" [byu]="びゅ" [byo]="びょ"

    # P-row
    [pa]="ぱ" [pi]="ぴ" [pu]="ぷ" [pe]="ぺ" [po]="ぽ"
    [pya]="ぴゃ" [pyu]="ぴゅ" [pyo]="ぴょ"

    # M-row
    [ma]="ま" [mi]="み" [mu]="む" [me]="め" [mo]="も"
    [mya]="みゃ" [myu]="みゅ" [myo]="みょ"

    # Y-row
    [ya]="や" [yu]="ゆ" [yo]="よ"

    # R-row
    [ra]="ら" [ri]="り" [ru]="る" [re]="れ" [ro]="ろ"
    [rya]="りゃ" [ryu]="りゅ" [ryo]="りょ"

    # W-row
    [wa]="わ" [wi]="ゐ" [we]="ゑ" [wo]="を"

    # N
    [n]="ん" [nn]="ん"

    # Special characters
    [-]="ー"
    [,]="、"
    [.]="。"
)

# Result of conversion
typeset -g Z_SKK_CONVERTED=""

# Romaji prefix cache for performance
typeset -gA Z_SKK_ROMAJI_PREFIX_CACHE=()

# Build romaji prefix cache
_z-skk-build-romaji-prefix-cache() {
    local key prefix
    Z_SKK_ROMAJI_PREFIX_CACHE=()

    # Build cache of all possible prefixes
    for key in ${(k)Z_SKK_ROMAJI_TO_HIRAGANA}; do
        for (( i=1; i<=${#key}; i++ )); do
            prefix="${key:0:$i}"
            Z_SKK_ROMAJI_PREFIX_CACHE[$prefix]=1
        done
    done
}

# Check if a string could be the start of a valid romaji sequence
z-skk-is-partial-romaji() {
    local input="$1"

    # Build cache on first use
    if [[ ${#Z_SKK_ROMAJI_PREFIX_CACHE} -eq 0 ]]; then
        _z-skk-build-romaji-prefix-cache
    fi

    # Fast lookup using cache
    [[ -n "${Z_SKK_ROMAJI_PREFIX_CACHE[$input]}" ]]
}

# Convert romaji in buffer to hiragana
z-skk-convert-romaji() {
    Z_SKK_CONVERTED=""

    # Empty buffer
    if [[ -z "$Z_SKK_ROMAJI_BUFFER" ]]; then
        return 0
    fi

    # Special handling for single 'n' - don't convert if it could be part of na, ni, etc.
    if [[ "$Z_SKK_ROMAJI_BUFFER" == "n" ]] && z-skk-is-partial-romaji "n"; then
        return 0
    fi

    # Exact match found
    if [[ -n "${Z_SKK_ROMAJI_TO_HIRAGANA[$Z_SKK_ROMAJI_BUFFER]}" ]]; then
        Z_SKK_CONVERTED="${Z_SKK_ROMAJI_TO_HIRAGANA[$Z_SKK_ROMAJI_BUFFER]}"
        Z_SKK_ROMAJI_BUFFER=""
        return 0
    fi

    # Check if it could be a partial match
    if z-skk-is-partial-romaji "$Z_SKK_ROMAJI_BUFFER"; then
        # Keep buffer as is, waiting for more input
        return 0
    fi

    # No match possible - try to convert the longest prefix
    local i
    for (( i=${#Z_SKK_ROMAJI_BUFFER}; i>0; i-- )); do
        local prefix="${Z_SKK_ROMAJI_BUFFER:0:$i}"
        if [[ -n "${Z_SKK_ROMAJI_TO_HIRAGANA[$prefix]}" ]]; then
            Z_SKK_CONVERTED="${Z_SKK_ROMAJI_TO_HIRAGANA[$prefix]}"
            Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER:$i}"
            return 0
        fi
    done

    # No conversion possible - output first character as-is
    Z_SKK_CONVERTED="${Z_SKK_ROMAJI_BUFFER:0:1}"
    Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER:1}"
}

# Process romaji input and update buffer
z-skk-process-romaji-input() {
    local key="$1"

    # Add key to romaji buffer
    Z_SKK_ROMAJI_BUFFER+="$key"

    # Try to convert
    if z-skk-convert-romaji; then
        # If we got a conversion, insert it
        if [[ -n "$Z_SKK_CONVERTED" ]]; then
            if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
                # Add to conversion buffer instead of direct insert
                Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
            else
                LBUFFER+="$Z_SKK_CONVERTED"
            fi
        fi
    fi
}


# Update conversion display with marker
z-skk-update-conversion-display() {
    local display_text=""

    if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        # Show ▽ marker with conversion buffer
        display_text="${Z_SKK_BUFFER}"

        # Add any remaining romaji buffer
        if [[ -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
            display_text+="$Z_SKK_ROMAJI_BUFFER"
        fi

        # Update the display
        z-skk-add-marker "▽" "$display_text"
    fi
}

# Look up candidates for a reading
_z-skk-lookup-candidates() {
    local reading="$1"
    local entry

    if entry=$(z-skk-lookup "$reading"); then
        # Split candidates
        local -a candidates=()
        candidates=("${(@f)$(z-skk-split-candidates "$entry")}")

        if [[ ${#candidates[@]} -gt 0 ]]; then
            print -r -- "${candidates[@]}"
            return 0
        fi
    fi

    return 1
}

# Prepare candidates for selection (remove annotations)
_z-skk-prepare-candidates() {
    local -a raw_candidates=("$@")
    local -a clean_candidates=()
    local candidate

    for candidate in "${raw_candidates[@]}"; do
        clean_candidates+=($(z-skk-get-candidate-word "$candidate"))
    done

    print -r -- "${clean_candidates[@]}"
}

# Switch to candidate selection mode
_z-skk-switch-to-selection-mode() {
    Z_SKK_CANDIDATE_INDEX=0
    Z_SKK_CONVERTING=2  # 2 means selecting candidates
    z-skk-update-candidate-display
}

# Start actual conversion (Space key pressed)
z-skk-start-conversion() {
    if [[ $Z_SKK_CONVERTING -ne 1 || -z "$Z_SKK_BUFFER" ]]; then
        return 1
    fi

    # Error recovery wrapper
    {
        # Look up candidates
        local -a raw_candidates=()
        if raw_candidates=($(_z-skk-lookup-candidates "$Z_SKK_BUFFER")); then
            # Prepare candidates for selection
            Z_SKK_CANDIDATES=($(_z-skk-prepare-candidates "${raw_candidates[@]}"))

            # Switch to selection mode
            _z-skk-switch-to-selection-mode
            return 0
        fi

        # No candidates found - start registration mode
        z-skk-start-registration "$Z_SKK_BUFFER"

    } always {
        # Error recovery
        if [[ $? -ne 0 ]]; then
            _z-skk-log-error "warn" "Error during conversion start"
            z-skk-cancel-conversion
        fi
    }
}

# Update candidate display with ▼ marker
z-skk-update-candidate-display() {
    if [[ $Z_SKK_CONVERTING -eq 2 && ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]; then
        # Show ▼ marker with current candidate
        local current_candidate="${Z_SKK_CANDIDATES[$((Z_SKK_CANDIDATE_INDEX + 1))]}"
        z-skk-add-marker "▼" "$current_candidate"
    fi
}

# Navigate candidates
_z-skk-navigate-candidate() {
    local direction="$1"  # "next" or "previous"

    if [[ $Z_SKK_CONVERTING -eq 2 && ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]; then
        # Clear current display
        local current_candidate="${Z_SKK_CANDIDATES[$((Z_SKK_CANDIDATE_INDEX + 1))]}"
        z-skk-clear-marker "▼" "$current_candidate"

        # Move index based on direction
        if [[ "$direction" == "next" ]]; then
            Z_SKK_CANDIDATE_INDEX=$(( (Z_SKK_CANDIDATE_INDEX + 1) % ${#Z_SKK_CANDIDATES[@]} ))
        else  # previous
            if [[ $Z_SKK_CANDIDATE_INDEX -eq 0 ]]; then
                Z_SKK_CANDIDATE_INDEX=$(( ${#Z_SKK_CANDIDATES[@]} - 1 ))
            else
                Z_SKK_CANDIDATE_INDEX=$(( Z_SKK_CANDIDATE_INDEX - 1 ))
            fi
        fi

        # Update display
        z-skk-update-candidate-display
    fi
}

# Move to next candidate
z-skk-next-candidate() {
    _z-skk-navigate-candidate "next"
}

# Move to previous candidate
z-skk-previous-candidate() {
    _z-skk-navigate-candidate "previous"
}

# Confirm current candidate
z-skk-confirm-candidate() {
    if [[ $Z_SKK_CONVERTING -eq 2 && ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]; then
        # Clear display
        local current_candidate="${Z_SKK_CANDIDATES[$((Z_SKK_CANDIDATE_INDEX + 1))]}"
        z-skk-clear-marker "▼" "$current_candidate"

        # Insert the selected candidate
        LBUFFER+="$current_candidate"

        # Reset state
        Z_SKK_CONVERTING=0
        Z_SKK_BUFFER=""
        Z_SKK_CANDIDATES=()
        Z_SKK_CANDIDATE_INDEX=0
    fi
}

# Cancel conversion and output as-is
z-skk-cancel-conversion() {
    if [[ $Z_SKK_CONVERTING -ge 1 ]]; then
        # Clear any display
        if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
            local display_content="${Z_SKK_BUFFER}${Z_SKK_ROMAJI_BUFFER}"
            z-skk-clear-marker "▽" "$display_content"
            # Insert the buffer content as-is
            LBUFFER+="$Z_SKK_BUFFER"
        elif [[ $Z_SKK_CONVERTING -eq 2 ]]; then
            local current_candidate="${Z_SKK_CANDIDATES[$((Z_SKK_CANDIDATE_INDEX + 1))]}"
            z-skk-clear-marker "▼" "$current_candidate"
            # Insert the original buffer content
            LBUFFER+="$Z_SKK_BUFFER"
        fi

        # Reset conversion state
        Z_SKK_CONVERTING=0
        Z_SKK_BUFFER=""
        Z_SKK_CANDIDATES=()
        Z_SKK_CANDIDATE_INDEX=0
    fi
}

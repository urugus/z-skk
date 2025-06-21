#!/usr/bin/env zsh
# Backspace operation handlers - Split from keybindings.zsh for better maintainability

# Handle backspace in registration mode
z-skk-backspace-in-registration() {
    z-skk-registration-input $'\x7f'
}

# Handle backspace in candidate selection mode (converting=2)
z-skk-backspace-in-candidate-selection() {
    # Go back to pre-conversion mode
    Z_SKK_CONVERTING=1
    Z_SKK_CANDIDATE_INDEX=0

    # Restore pre-conversion display
    local prefix="${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}"
    LBUFFER="${prefix}▽${Z_SKK_BUFFER}${Z_SKK_OKURIGANA:+*$Z_SKK_OKURIGANA}"

    # Emit state transition event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "backspace:candidate-to-conversion"
    fi
}

# Handle backspace in pre-conversion mode (converting=1)
z-skk-backspace-in-conversion() {
    # Handle okurigana removal first
    if [[ -n "$Z_SKK_OKURIGANA" ]]; then
        z-skk-backspace-remove-okurigana
        return
    fi

    # Handle main buffer removal
    if [[ -n "$Z_SKK_BUFFER" ]]; then
        z-skk-backspace-remove-from-buffer
        return
    fi

    # If buffer is empty, cancel conversion
    z-skk-backspace-cancel-conversion
}

# Remove okurigana suffix
z-skk-backspace-remove-okurigana() {
    Z_SKK_OKURIGANA=""
    local prefix="${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}"
    LBUFFER="${prefix}▽${Z_SKK_BUFFER}"

    # Emit okurigana removal event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "backspace:okurigana-removed"
    fi
}

# Remove last character from conversion buffer with romaji mapping
z-skk-backspace-remove-from-buffer() {
    # Handle multi-byte characters properly
    local last_char="${Z_SKK_BUFFER: -1}"

    # Use buffer manager if available
    if (( ${+functions[z-skk-buffer-backspace]} )); then
        z-skk-buffer-backspace
    else
        Z_SKK_BUFFER="${Z_SKK_BUFFER%?}"
    fi

    # Convert back to romaji and add to romaji buffer
    local romaji_equivalent
    romaji_equivalent=$(z-skk-hiragana-to-romaji "$last_char")

    # Use romaji buffer manager if available
    if (( ${+functions[z-skk-romaji-buffer-set]} )); then
        z-skk-romaji-buffer-set "$romaji_equivalent"
    else
        Z_SKK_ROMAJI_BUFFER="$romaji_equivalent"
    fi

    # Update display
    local prefix="${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}"
    LBUFFER="${prefix}▽${Z_SKK_BUFFER}${Z_SKK_ROMAJI_BUFFER}"

    # Emit buffer character removal event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "backspace:character-removed" "$last_char" "$romaji_equivalent"
    fi
}

# Cancel conversion mode entirely
z-skk-backspace-cancel-conversion() {
    # Reset conversion state
    if (( ${+functions[z-skk-buffer-reset-all]} )); then
        z-skk-buffer-reset-all
    else
        Z_SKK_CONVERTING=0
        Z_SKK_BUFFER=""
        Z_SKK_ROMAJI_BUFFER=""
    fi

    # Clear display markers
    if (( ${+functions[z-skk-display-clear-marker]} )); then
        z-skk-display-clear-marker "▽" ""
    else
        z-skk-clear-marker "▽" ""
    fi

    # Emit conversion cancellation event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "backspace:conversion-cancelled"
    fi
}

# Handle normal backspace (not in conversion mode)
z-skk-backspace-normal() {
    # Use default backspace behavior
    zle .backward-delete-char

    # Emit normal backspace event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "backspace:normal"
    fi
}

# Hiragana to romaji conversion mapping
z-skk-hiragana-to-romaji() {
    local char="$1"

    # Initialize mapping if not already done
    if [[ ${#_Z_SKK_HIRAGANA_TO_ROMAJI[@]} -eq 0 ]]; then
        z-skk-init-hiragana-to-romaji-map
    fi

    # Return mapped value or empty string
    echo "${_Z_SKK_HIRAGANA_TO_ROMAJI[$char]:-}"
}

# Initialize hiragana to romaji mapping (extracted from original keybindings.zsh)
z-skk-init-hiragana-to-romaji-map() {
    # Declare mapping if not already declared
    if ! (( ${+_Z_SKK_HIRAGANA_TO_ROMAJI} )); then
        typeset -gA _Z_SKK_HIRAGANA_TO_ROMAJI
    fi

    # Basic mappings
    _Z_SKK_HIRAGANA_TO_ROMAJI=(
        [あ]="a"    [い]="i"    [う]="u"    [え]="e"    [お]="o"
        [か]="ka"   [き]="ki"   [く]="ku"   [け]="ke"   [こ]="ko"
        [が]="ga"   [ぎ]="gi"   [ぐ]="gu"   [げ]="ge"   [ご]="go"
        [さ]="sa"   [し]="shi"  [す]="su"   [せ]="se"   [そ]="so"
        [ざ]="za"   [じ]="ji"   [ず]="zu"   [ぜ]="ze"   [ぞ]="zo"
        [た]="ta"   [ち]="chi"  [つ]="tsu"  [て]="te"   [と]="to"
        [だ]="da"   [ぢ]="di"   [づ]="du"   [で]="de"   [ど]="do"
        [な]="na"   [に]="ni"   [ぬ]="nu"   [ね]="ne"   [の]="no"
        [は]="ha"   [ひ]="hi"   [ふ]="fu"   [へ]="he"   [ほ]="ho"
        [ば]="ba"   [び]="bi"   [ぶ]="bu"   [べ]="be"   [ぼ]="bo"
        [ぱ]="pa"   [ぴ]="pi"   [ぷ]="pu"   [ぺ]="pe"   [ぽ]="po"
        [ま]="ma"   [み]="mi"   [む]="mu"   [め]="me"   [も]="mo"
        [や]="ya"   [ゆ]="yu"   [よ]="yo"
        [ら]="ra"   [り]="ri"   [る]="ru"   [れ]="re"   [ろ]="ro"
        [わ]="wa"   [ゐ]="wi"   [ゑ]="we"   [を]="wo"   [ん]="n"
        [ー]="-"    [っ]="t"
    )

    # Emit initialization event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit "hiragana-romaji-map:initialized" "${#_Z_SKK_HIRAGANA_TO_ROMAJI[@]}"
    fi
}

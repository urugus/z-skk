#!/usr/bin/env zsh
# Input mode management for z-skk

# Note: Z_SKK_MODE_NAMES is defined in modes.zsh

# Mode setter wrapper (for compatibility)
# The actual implementation is now in state.zsh

# Note: z-skk-toggle-kana is defined in modes.zsh

# Katakana conversion table
typeset -gA Z_SKK_ROMAJI_TO_KATAKANA=(
    # Single vowels
    [a]="ア" [i]="イ" [u]="ウ" [e]="エ" [o]="オ"
    # K-row
    [ka]="カ" [ki]="キ" [ku]="ク" [ke]="ケ" [ko]="コ"
    [kya]="キャ" [kyu]="キュ" [kyo]="キョ"
    # S-row
    [sa]="サ" [si]="シ" [shi]="シ" [su]="ス" [se]="セ" [so]="ソ"
    [sha]="シャ" [shu]="シュ" [sho]="ショ"
    [sya]="シャ" [syu]="シュ" [syo]="ショ"
    # T-row
    [ta]="タ" [ti]="チ" [chi]="チ" [tu]="ツ" [tsu]="ツ" [te]="テ" [to]="ト"
    [cha]="チャ" [chu]="チュ" [cho]="チョ"
    [tya]="チャ" [tyu]="チュ" [tyo]="チョ"
    # N-row
    [na]="ナ" [ni]="ニ" [nu]="ヌ" [ne]="ネ" [no]="ノ"
    [nya]="ニャ" [nyu]="ニュ" [nyo]="ニョ"
    # Special N
    [n]="ン" [nn]="ン"
)

# ASCII to Zenkaku (full-width) conversion
# Note: z-skk-convert-to-zenkaku is now defined in conversion-tables.zsh

# Convert romaji to katakana directly
z-skk-convert-romaji-to-katakana() {
    local romaji="$1"
    local hiragana=$(z-skk-romaji-to-hiragana "$romaji")
    if [[ -n "$hiragana" ]]; then
        z-skk-hiragana-to-katakana "$hiragana"
    fi
}

# Handle special keys in katakana mode
z-skk-handle-katakana-special() {
    local key="$1"
    case "$key" in
        q)
            # Return to hiragana mode
            z-skk-set-mode "hiragana"
            ;;
        l|L)
            # Switch to ASCII mode
            z-skk-set-mode "ascii"
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

# Process katakana input (for compatibility)
z-skk-process-katakana-input() {
    local key="$1"

    # Add key to romaji buffer
    Z_SKK_ROMAJI_BUFFER+="$key"

    # Try to convert romaji to hiragana first
    z-skk-convert-romaji

    if [[ -n "$Z_SKK_CONVERTED" ]]; then
        # Convert hiragana to katakana
        local katakana=$(z-skk-hiragana-to-katakana "$Z_SKK_CONVERTED")

        if [[ -n "$katakana" ]]; then
            if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
                # Add to conversion buffer instead of direct insert
                Z_SKK_BUFFER+="$katakana"
            else
                if (( ${+functions[z-skk-display-append]} )); then
                    z-skk-display-append "$katakana"
                else
                    LBUFFER+="$katakana"
                fi
            fi

            # Emit input processed event
            if (( ${+functions[z-skk-emit]} )); then
                z-skk-emit input:processed "$key" "$katakana"
            fi
        fi
    fi
}

# Abbrev mode state
typeset -g Z_SKK_ABBREV_BUFFER=""
typeset -g Z_SKK_ABBREV_ACTIVE=0

# Activate abbrev mode
z-skk-activate-abbrev() {
    Z_SKK_ABBREV_ACTIVE=1
    Z_SKK_ABBREV_BUFFER=""
    z-skk-set-mode "abbrev"
}

# Deactivate abbrev mode
z-skk-deactivate-abbrev() {
    Z_SKK_ABBREV_ACTIVE=0
    Z_SKK_ABBREV_BUFFER=""
    # Return to hiragana mode instead of ascii when deactivating abbrev
    z-skk-set-mode "hiragana"
}

# Process abbrev input
z-skk-process-abbrev-input() {
    local key="$1"

    # Space triggers conversion
    if [[ "$key" == " " ]] && [[ -n "$Z_SKK_ABBREV_BUFFER" ]]; then
        # Save abbreviation before deactivating
        local abbrev="$Z_SKK_ABBREV_BUFFER"
        # Clear LBUFFER to prepare for marker display
        LBUFFER="${LBUFFER%$abbrev}"
        # Deactivate abbrev mode first
        z-skk-deactivate-abbrev
        # Then start conversion with the saved abbreviation
        Z_SKK_BUFFER="$abbrev"
        z-skk-set-converting-state 1
        # Update display with conversion marker
        z-skk-update-conversion-display
        return 0
    fi

    # Add to buffer
    Z_SKK_ABBREV_BUFFER+="$key"
    LBUFFER+="$key"
}

# Update mode display in RPROMPT
z-skk-update-mode-display() {
    if [[ "${Z_SKK_SHOW_MODE_IN_PROMPT:-1}" -eq 1 ]]; then
        case "$Z_SKK_MODE" in
            hiragana)
                Z_SKK_MODE_INDICATOR="[あ]"
                ;;
            katakana)
                Z_SKK_MODE_INDICATOR="[ア]"
                ;;
            ascii)
                Z_SKK_MODE_INDICATOR="[_A]"
                ;;
            zenkaku)
                Z_SKK_MODE_INDICATOR="[Ａ]"
                ;;
            abbrev)
                Z_SKK_MODE_INDICATOR="[aA]"
                ;;
            *)
                Z_SKK_MODE_INDICATOR=""
                ;;
        esac

        # Update RPROMPT
        if [[ -n "$Z_SKK_MODE_INDICATOR" ]]; then
            RPROMPT="${Z_SKK_MODE_INDICATOR}${Z_SKK_ORIGINAL_RPROMPT}"
        else
            RPROMPT="$Z_SKK_ORIGINAL_RPROMPT"
        fi

        # Just redraw, don't reset the entire prompt
        # reset-prompt can cause newlines in some terminals
        if (( ${+functions[z-skk-safe-redraw]} )); then
            z-skk-safe-redraw
        elif zle; then
            zle -R
        fi
    fi
}

# Handle special keys in zenkaku mode
z-skk-handle-zenkaku-special() {
    local key="$1"
    case "$key" in
        C-j)
            # Return to hiragana mode
            z-skk-set-mode "hiragana"
            ;;
        l|L)
            # Switch to ASCII mode
            z-skk-set-mode "ascii"
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

# Process zenkaku input
z-skk-process-zenkaku-input() {
    local key="$1"

    # Convert to zenkaku and insert
    local zenkaku=$(z-skk-convert-to-zenkaku "$key")

    if z-skk-is-pre-converting; then
        Z_SKK_BUFFER+="$zenkaku"
    else
        LBUFFER+="$zenkaku"
    fi
}
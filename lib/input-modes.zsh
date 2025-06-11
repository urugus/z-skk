#!/usr/bin/env zsh
# Input mode implementations for z-skk

# Romaji to Katakana conversion table
typeset -gA Z_SKK_ROMAJI_TO_KATAKANA=(
    # Vowels
    [a]="ア"  [i]="イ"  [u]="ウ"  [e]="エ"  [o]="オ"

    # K-row
    [ka]="カ" [ki]="キ" [ku]="ク" [ke]="ケ" [ko]="コ"
    [kya]="キャ" [kyu]="キュ" [kyo]="キョ"

    # G-row
    [ga]="ガ" [gi]="ギ" [gu]="グ" [ge]="ゲ" [go]="ゴ"
    [gya]="ギャ" [gyu]="ギュ" [gyo]="ギョ"

    # S-row
    [sa]="サ" [shi]="シ" [su]="ス" [se]="セ" [so]="ソ"
    [sha]="シャ" [shu]="シュ" [sho]="ショ"

    # Z-row
    [za]="ザ" [ji]="ジ" [zu]="ズ" [ze]="ゼ" [zo]="ゾ"
    [ja]="ジャ" [ju]="ジュ" [jo]="ジョ"

    # T-row
    [ta]="タ" [chi]="チ" [tsu]="ツ" [te]="テ" [to]="ト"
    [cha]="チャ" [chu]="チュ" [cho]="チョ"

    # D-row
    [da]="ダ" [di]="ヂ" [du]="ヅ" [de]="デ" [do]="ド"

    # N-row
    [na]="ナ" [ni]="ニ" [nu]="ヌ" [ne]="ネ" [no]="ノ"
    [nya]="ニャ" [nyu]="ニュ" [nyo]="ニョ"

    # H-row
    [ha]="ハ" [hi]="ヒ" [hu]="フ" [he]="ヘ" [ho]="ホ"
    [fu]="フ"  # Alternative for 'hu'
    [hya]="ヒャ" [hyu]="ヒュ" [hyo]="ヒョ"

    # B-row
    [ba]="バ" [bi]="ビ" [bu]="ブ" [be]="ベ" [bo]="ボ"
    [bya]="ビャ" [byu]="ビュ" [byo]="ビョ"

    # P-row
    [pa]="パ" [pi]="ピ" [pu]="プ" [pe]="ペ" [po]="ポ"
    [pya]="ピャ" [pyu]="ピュ" [pyo]="ピョ"

    # M-row
    [ma]="マ" [mi]="ミ" [mu]="ム" [me]="メ" [mo]="モ"
    [mya]="ミャ" [myu]="ミュ" [myo]="ミョ"

    # Y-row
    [ya]="ヤ" [yu]="ユ" [yo]="ヨ"

    # R-row
    [ra]="ラ" [ri]="リ" [ru]="ル" [re]="レ" [ro]="ロ"
    [rya]="リャ" [ryu]="リュ" [ryo]="リョ"

    # W-row
    [wa]="ワ" [wi]="ヰ" [we]="ヱ" [wo]="ヲ"

    # N
    [n]="ン" [nn]="ン"
)

# ASCII to Zenkaku (full-width) conversion
z-skk-convert-to-zenkaku() {
    local char="$1"

    # Use table-based conversion if available
    if (( ${+Z_SKK_ASCII_TO_ZENKAKU} )); then
        echo "${Z_SKK_ASCII_TO_ZENKAKU[$char]:-$char}"
    else
        # Fallback to case statement if table not loaded
        local zenkaku=""
        case "$char" in
            0) zenkaku="０" ;;
            1) zenkaku="１" ;;
            A) zenkaku="Ａ" ;;
            a) zenkaku="ａ" ;;
            " ") zenkaku="　" ;;
            *) zenkaku="$char" ;;
        esac
        echo "$zenkaku"
    fi
}

# Abbrev mode state
typeset -g Z_SKK_ABBREV_BUFFER=""
typeset -g Z_SKK_ABBREV_ACTIVE=0

# Convert romaji to katakana
z-skk-convert-romaji-to-katakana() {
    local romaji="$1"
    local result=""

    # Special handling for single 'n' - don't convert if it could be part of na, ni, etc.
    if [[ "$romaji" == "n" ]] && z-skk-is-partial-romaji "n"; then
        echo ""
        return 0
    fi

    # Check exact match first
    if [[ -n "${Z_SKK_ROMAJI_TO_KATAKANA[$romaji]}" ]]; then
        echo "${Z_SKK_ROMAJI_TO_KATAKANA[$romaji]}"
        Z_SKK_ROMAJI_BUFFER=""
        return 0
    fi

    # Check if it's a partial match
    if z-skk-is-partial-romaji "$romaji"; then
        # Return empty to indicate waiting for more input
        echo ""
        return 0
    fi

    # Try to convert the longest prefix
    local i
    for (( i=${#romaji}; i>0; i-- )); do
        local prefix="${romaji:0:$i}"
        if [[ -n "${Z_SKK_ROMAJI_TO_KATAKANA[$prefix]}" ]]; then
            echo "${Z_SKK_ROMAJI_TO_KATAKANA[$prefix]}"
            # Store remaining for next conversion
            Z_SKK_ROMAJI_BUFFER="${romaji:$i}"
            return 0
        fi
    done

    # No conversion possible - return the first character as-is
    echo "${romaji:0:1}"
    Z_SKK_ROMAJI_BUFFER="${romaji:1}"
}

# Process katakana input
z-skk-process-katakana-input() {
    local key="$1"

    # Add key to romaji buffer
    Z_SKK_ROMAJI_BUFFER+="$key"

    # Try to convert
    local converted=$(z-skk-convert-romaji-to-katakana "$Z_SKK_ROMAJI_BUFFER")

    if [[ -n "$converted" ]]; then
        # Insert converted text
        if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
            Z_SKK_BUFFER+="$converted"
        else
            LBUFFER+="$converted"
        fi
        # Reset romaji buffer after successful conversion
        # (it's already set by z-skk-convert-romaji-to-katakana if there's remaining)
    fi
}

# Process zenkaku input
z-skk-process-zenkaku-input() {
    local key="$1"

    # Convert to zenkaku and insert
    local zenkaku=$(z-skk-convert-to-zenkaku "$key")
    LBUFFER+="$zenkaku"
}

# Start abbreviation mode
z-skk-start-abbrev-mode() {
    Z_SKK_ABBREV_BUFFER=""
    Z_SKK_ABBREV_ACTIVE=1
    Z_SKK_MODE="abbrev"
}

# Process abbreviation input
z-skk-process-abbrev-input() {
    local key="$1"

    # Space completes abbreviation
    if [[ "$key" == " " ]]; then
        z-skk-complete-abbrev
        return
    fi

    # C-g cancels
    if [[ "$key" == $'\x07' ]]; then
        z-skk-cancel-abbrev
        return
    fi

    # Add to abbreviation buffer
    Z_SKK_ABBREV_BUFFER+="$key"
    LBUFFER+="$key"
}

# Complete abbreviation
z-skk-complete-abbrev() {
    if [[ -z "$Z_SKK_ABBREV_BUFFER" ]]; then
        return 1
    fi

    # Start conversion with abbrev buffer
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="$Z_SKK_ABBREV_BUFFER"

    # Clear abbrev buffer from display
    local abbrev_len=${#Z_SKK_ABBREV_BUFFER}
    LBUFFER="${LBUFFER:0:-$abbrev_len}"

    # Reset abbrev state
    Z_SKK_ABBREV_BUFFER=""
    Z_SKK_ABBREV_ACTIVE=0

    # Update display with conversion marker
    z-skk-update-conversion-display
}

# Cancel abbreviation mode
z-skk-cancel-abbrev() {
    Z_SKK_ABBREV_BUFFER=""
    Z_SKK_ABBREV_ACTIVE=0
    Z_SKK_MODE="hiragana"  # Return to default mode
}

# Mode-specific special key handlers
z-skk-handle-katakana-special() {
    local key="$1"

    case "$key" in
        q)
            # q in katakana mode returns to hiragana
            z-skk-hiragana-mode
            return 0
            ;;
        l|L)
            # Switch to ASCII mode
            z-skk-ascii-mode
            return 0
            ;;
    esac

    return 1
}

z-skk-handle-zenkaku-special() {
    local key="$1"

    case "$key" in
        $'\x0a')  # C-j
            # Return to hiragana mode
            z-skk-hiragana-mode
            return 0
            ;;
    esac

    return 1
}

z-skk-handle-abbrev-special() {
    local key="$1"

    case "$key" in
        $'\x0a')  # C-j
            # Return to hiragana mode
            z-skk-cancel-abbrev
            z-skk-hiragana-mode
            return 0
            ;;
    esac

    return 1
}

# Check if in abbrev mode
z-skk-is-abbrev-mode() {
    [[ "$Z_SKK_MODE" == "abbrev" ]] && [[ $Z_SKK_ABBREV_ACTIVE -eq 1 ]]
}
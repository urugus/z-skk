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

# Check if a string could be the start of a valid romaji sequence
z-skk-is-partial-romaji() {
    local input="$1"
    local key

    # Check if any key in the table starts with this input
    for key in ${(k)Z_SKK_ROMAJI_TO_HIRAGANA}; do
        if [[ "$key" == "$input"* ]]; then
            return 0
        fi
    done

    return 1
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

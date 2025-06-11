#!/usr/bin/env zsh
# Special key handlers for z-skk

# Convert previous hiragana character(s) to katakana (X key)
z-skk-convert-previous-to-katakana() {
    # Only works in hiragana mode
    if [[ "$Z_SKK_MODE" != "hiragana" ]]; then
        return 1
    fi

    # Get the last character from LBUFFER
    if [[ -z "$LBUFFER" ]]; then
        return 1
    fi

    # Extract the last character (considering multi-byte)
    local last_char="${LBUFFER[-1]}"
    local remaining="${LBUFFER[1,-2]}"

    # Convert hiragana to katakana
    local katakana=$(z-skk-hiragana-to-katakana "$last_char")

    if [[ -n "$katakana" ]]; then
        # Replace the last character with katakana
        LBUFFER="${remaining}${katakana}"
        return 0
    fi

    return 1
}

# Convert a single hiragana character to katakana
z-skk-hiragana-to-katakana() {
    local hiragana="$1"
    local katakana=""

    # Hiragana to Katakana conversion table
    case "$hiragana" in
        # あ行
        あ) katakana="ア" ;;
        い) katakana="イ" ;;
        う) katakana="ウ" ;;
        え) katakana="エ" ;;
        お) katakana="オ" ;;
        # か行
        か) katakana="カ" ;;
        き) katakana="キ" ;;
        く) katakana="ク" ;;
        け) katakana="ケ" ;;
        こ) katakana="コ" ;;
        # が行
        が) katakana="ガ" ;;
        ぎ) katakana="ギ" ;;
        ぐ) katakana="グ" ;;
        げ) katakana="ゲ" ;;
        ご) katakana="ゴ" ;;
        # さ行
        さ) katakana="サ" ;;
        し) katakana="シ" ;;
        す) katakana="ス" ;;
        せ) katakana="セ" ;;
        そ) katakana="ソ" ;;
        # ざ行
        ざ) katakana="ザ" ;;
        じ) katakana="ジ" ;;
        ず) katakana="ズ" ;;
        ぜ) katakana="ゼ" ;;
        ぞ) katakana="ゾ" ;;
        # た行
        た) katakana="タ" ;;
        ち) katakana="チ" ;;
        つ) katakana="ツ" ;;
        て) katakana="テ" ;;
        と) katakana="ト" ;;
        # だ行
        だ) katakana="ダ" ;;
        ぢ) katakana="ヂ" ;;
        づ) katakana="ヅ" ;;
        で) katakana="デ" ;;
        ど) katakana="ド" ;;
        # な行
        な) katakana="ナ" ;;
        に) katakana="ニ" ;;
        ぬ) katakana="ヌ" ;;
        ね) katakana="ネ" ;;
        の) katakana="ノ" ;;
        # は行
        は) katakana="ハ" ;;
        ひ) katakana="ヒ" ;;
        ふ) katakana="フ" ;;
        へ) katakana="ヘ" ;;
        ほ) katakana="ホ" ;;
        # ば行
        ば) katakana="バ" ;;
        び) katakana="ビ" ;;
        ぶ) katakana="ブ" ;;
        べ) katakana="ベ" ;;
        ぼ) katakana="ボ" ;;
        # ぱ行
        ぱ) katakana="パ" ;;
        ぴ) katakana="ピ" ;;
        ぷ) katakana="プ" ;;
        ぺ) katakana="ペ" ;;
        ぽ) katakana="ポ" ;;
        # ま行
        ま) katakana="マ" ;;
        み) katakana="ミ" ;;
        む) katakana="ム" ;;
        め) katakana="メ" ;;
        も) katakana="モ" ;;
        # や行
        や) katakana="ヤ" ;;
        ゆ) katakana="ユ" ;;
        よ) katakana="ヨ" ;;
        # ら行
        ら) katakana="ラ" ;;
        り) katakana="リ" ;;
        る) katakana="ル" ;;
        れ) katakana="レ" ;;
        ろ) katakana="ロ" ;;
        # わ行
        わ) katakana="ワ" ;;
        ゐ) katakana="ヰ" ;;
        ゑ) katakana="ヱ" ;;
        を) katakana="ヲ" ;;
        ん) katakana="ン" ;;
        # 小文字
        ぁ) katakana="ァ" ;;
        ぃ) katakana="ィ" ;;
        ぅ) katakana="ゥ" ;;
        ぇ) katakana="ェ" ;;
        ぉ) katakana="ォ" ;;
        ゃ) katakana="ャ" ;;
        ゅ) katakana="ュ" ;;
        ょ) katakana="ョ" ;;
        ゎ) katakana="ヮ" ;;
        っ) katakana="ッ" ;;
        # その他
        ー) katakana="ー" ;;
        *) katakana="" ;;
    esac

    echo "$katakana"
}

# Insert today's date (@ key)
z-skk-insert-date() {
    local format="${1:-%Y-%m-%d}"  # Default format: YYYY-MM-DD
    local date_str=$(date "+$format")

    # Convert to Japanese format if in hiragana/katakana mode
    if [[ "$Z_SKK_MODE" == "hiragana" || "$Z_SKK_MODE" == "katakana" ]]; then
        # Convert to Japanese date format (令和6年11月7日)
        local year=$(date +%Y)
        local month=$(date +%-m)
        local day=$(date +%-d)

        # Calculate Reiwa year (2019 = Reiwa 1)
        local reiwa_year=$((year - 2018))

        # Convert numbers to Japanese
        date_str="令和${reiwa_year}年${month}月${day}日"
    fi

    LBUFFER+="$date_str"
}

# JIS code input (; key)
z-skk-code-input() {
    # Start code input mode
    typeset -g Z_SKK_CODE_INPUT_MODE=1
    typeset -g Z_SKK_CODE_BUFFER=""

    # Show prompt
    LBUFFER+=";"
}

# Process code input
z-skk-process-code-input() {
    local key="$1"

    # Check if we're in code input mode
    if [[ ${Z_SKK_CODE_INPUT_MODE:-0} -ne 1 ]]; then
        return 1
    fi

    case "$key" in
        [0-9a-fA-F])
            # Add to code buffer
            Z_SKK_CODE_BUFFER+="$key"
            LBUFFER+="$key"

            # Check if we have 4 digits (JIS code)
            if [[ ${#Z_SKK_CODE_BUFFER} -eq 4 ]]; then
                z-skk-complete-code-input
            fi
            ;;
        $'\r')  # Enter
            z-skk-complete-code-input
            ;;
        $'\x07')  # C-g
            z-skk-cancel-code-input
            ;;
        *)
            # Invalid input, cancel
            z-skk-cancel-code-input
            ;;
    esac
}

# Complete code input
z-skk-complete-code-input() {
    if [[ -z "$Z_SKK_CODE_BUFFER" ]]; then
        z-skk-cancel-code-input
        return
    fi

    # Remove the code display from buffer
    local code_len=$((${#Z_SKK_CODE_BUFFER} + 1))  # +1 for semicolon
    LBUFFER="${LBUFFER[1,-$((code_len + 1))]}"

    # Convert JIS code to character
    local char=$(z-skk-jis-to-char "$Z_SKK_CODE_BUFFER")

    if [[ -n "$char" ]]; then
        LBUFFER+="$char"
    fi

    # Reset code input mode
    Z_SKK_CODE_INPUT_MODE=0
    Z_SKK_CODE_BUFFER=""
}

# Cancel code input
z-skk-cancel-code-input() {
    # Remove the semicolon and any code from buffer
    if [[ $Z_SKK_CODE_INPUT_MODE -eq 1 ]]; then
        local code_len=$((${#Z_SKK_CODE_BUFFER} + 1))
        LBUFFER="${LBUFFER[1,-$((code_len + 1))]}"
    fi

    Z_SKK_CODE_INPUT_MODE=0
    Z_SKK_CODE_BUFFER=""
}

# Convert JIS code to character (simplified version)
z-skk-jis-to-char() {
    local code="$1"

    # Basic JIS code conversion (simplified)
    # In a real implementation, this would use iconv or similar
    case "$code" in
        # Some common JIS codes
        "3042") echo "あ" ;;
        "30a2") echo "ア" ;;
        "6f22") echo "漢" ;;
        "5b57") echo "字" ;;
        # Add more as needed
        *) echo "" ;;
    esac
}

# Suffix input mode (> key)
z-skk-start-suffix-input() {
    typeset -g Z_SKK_SUFFIX_MODE=1
    typeset -g Z_SKK_SUFFIX_BUFFER=""

    # Show marker
    LBUFFER+=">"
}

# Prefix input mode (? key)
z-skk-start-prefix-input() {
    typeset -g Z_SKK_PREFIX_MODE=1
    typeset -g Z_SKK_PREFIX_BUFFER=""

    # Show marker
    LBUFFER+="?"
}

# Check if in special input mode
z-skk-is-special-input-mode() {
    [[ ${Z_SKK_CODE_INPUT_MODE:-0} -eq 1 ]] || \
    [[ ${Z_SKK_SUFFIX_MODE:-0} -eq 1 ]] || \
    [[ ${Z_SKK_PREFIX_MODE:-0} -eq 1 ]]
}

# Reset special input modes
z-skk-reset-special-modes() {
    Z_SKK_CODE_INPUT_MODE=0
    Z_SKK_CODE_BUFFER=""
    Z_SKK_SUFFIX_MODE=0
    Z_SKK_SUFFIX_BUFFER=""
    Z_SKK_PREFIX_MODE=0
    Z_SKK_PREFIX_BUFFER=""
}
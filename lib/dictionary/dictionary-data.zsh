#!/usr/bin/env zsh
# Dictionary data for z-skk

# Simple hardcoded dictionary for initial implementation
typeset -gA Z_SKK_DICTIONARY=(
    # Basic words
    [あい]="愛:love/相:mutual/合い:match"
    [あき]="秋:autumn/明き:vacancy/飽き:boredom"
    [あさ]="朝:morning/浅:shallow"
    [あめ]="雨:rain/飴:candy"
    [いし]="石:stone/意志:will/医師:doctor"
    [いぬ]="犬:dog"
    [うみ]="海:sea/膿:pus"
    [えき]="駅:station/液:liquid/益:benefit"
    [おと]="音:sound/弟:younger brother"
    [かい]="会:meeting/回:counter/階:floor/界:world/買い:buying"
    [かみ]="紙:paper/髪:hair/神:god/上:up"
    [かぜ]="風:wind/風邪:cold"
    [かんじ]="漢字:kanji/感じ:feeling/幹事:organizer"
    [きかい]="機会:opportunity/機械:machine/器械:instrument"
    [きょう]="今日:today/京:capital/教:teaching/橋:bridge"
    [くも]="雲:cloud/蜘蛛:spider"
    [けん]="県:prefecture/剣:sword/件:matter/見:view"
    [こえ]="声:voice/肥:fertilizer"
    [さくら]="桜:cherry blossom"
    [しごと]="仕事:work"
    [すし]="寿司:sushi"
    [せんせい]="先生:teacher"
    [そら]="空:sky"
    [たいよう]="太陽:sun"
    [つき]="月:moon/付き:attached/突き:thrust"
    [でんしゃ]="電車:train"
    [とうきょう]="東京:Tokyo"
    [なか]="中:inside/仲:relationship"
    [にほん]="日本:Japan"
    [にほんご]="日本語:Japanese"
    [ねこ]="猫:cat"
    [はし]="橋:bridge/箸:chopsticks/端:edge"
    [はな]="花:flower/鼻:nose/話:talk"
    [はる]="春:spring/張る:stretch"
    [ひと]="人:person"
    [ふゆ]="冬:winter"
    [ほん]="本:book"
    [まち]="町:town/待ち:waiting"
    [みず]="水:water"
    [むら]="村:village"
    [め]="目:eye/芽:sprout"
    [もり]="森:forest"
    [やま]="山:mountain"
    [ゆき]="雪:snow/行き:going"
    [よる]="夜:night"
    [りんご]="林檎:apple"
    [わたし]="私:I/渡し:ferry"

    # Okurigana entries
    [おく*り]="送り:send"
    [おく*る]="送る:to send"
    [か*く]="書く:to write/描く:to draw"
    [か*いた]="書いた:wrote/描いた:drew"
    [よ*む]="読む:to read"
    [よ*んだ]="読んだ:read (past)"
    [はし*る]="走る:to run"
    [はし*った]="走った:ran"
    [た*べる]="食べる:to eat"
    [た*べた]="食べた:ate"
    [み*る]="見る:to see/診る:to examine"
    [み*た]="見た:saw/診た:examined"
    [つか*う]="使う:to use"
    [つか*った]="使った:used"
    [おも*う]="思う:to think"
    [おも*った]="思った:thought"
    [さが*す]="探す:to search"
    [さがs]="探す:to search"
)

# Dictionary index for first character lookup (performance optimization)
typeset -gA Z_SKK_DICTIONARY_INDEX=()

# Build dictionary index
_z-skk-build-dictionary-index() {
    local key first_char
    Z_SKK_DICTIONARY_INDEX=()

    for key in ${(k)Z_SKK_DICTIONARY}; do
        first_char="${key:0:1}"
        if [[ -z "${Z_SKK_DICTIONARY_INDEX[$first_char]}" ]]; then
            Z_SKK_DICTIONARY_INDEX[$first_char]=""
        fi
        Z_SKK_DICTIONARY_INDEX[$first_char]+="$key "
    done
}

# Load dictionary data
z-skk-load-dictionary-data() {
    # Build index for performance
    _z-skk-build-dictionary-index

    # In the future, this could load from external files
    # For now, the data is already loaded via typeset above
    return 0
}
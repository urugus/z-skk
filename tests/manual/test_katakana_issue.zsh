#!/usr/bin/env zsh
# Manual test for katakana newline issue

# Setup
typeset -g TEST_DIR="${0:A:h:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Create a mock ZLE environment
zle() {
    case "$1" in
        -R)
            # Mock redraw - check if it's being called excessively
            echo "[ZLE-REDRAW]"
            ;;
        reset-prompt)
            # This is what causes newlines!
            echo "[RESET-PROMPT - This causes newline!]"
            ;;
        *)
            echo "[ZLE: $@]"
            ;;
    esac
}

# Initialize
LBUFFER=""
RBUFFER=""

print "Testing katakana input..."
print "Switching to katakana mode..."
z-skk-set-mode "katakana"

print "\nInputting 'ka'..."
z-skk-handle-input "k"
print "LBUFFER after 'k': '$LBUFFER'"
z-skk-handle-input "a"
print "LBUFFER after 'a': '$LBUFFER'"

print "\nInputting 'ta'..."
z-skk-handle-input "t"
print "LBUFFER after 't': '$LBUFFER'"
z-skk-handle-input "a"
print "LBUFFER after 'a': '$LBUFFER'"

print "\nFinal LBUFFER: '$LBUFFER'"
print "Expected: 'カタ'"

# Check for mode display updates
print "\n--- Checking mode display updates ---"
LBUFFER=""

# Add debug to z-skk-update-mode-display
functions[z-skk-update-mode-display-original]=$functions[z-skk-update-mode-display]
z-skk-update-mode-display() {
    print "[DEBUG] z-skk-update-mode-display called!"
    z-skk-update-mode-display-original
}

print "\nNow testing with instrumented function..."
print "Switching to hiragana mode..."
z-skk-set-mode "hiragana"

print "\nSwitching to katakana mode..."
z-skk-set-mode "katakana"

print "\nInputting in katakana mode..."
z-skk-handle-input "k"
z-skk-handle-input "a"
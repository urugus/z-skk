#!/usr/bin/env zsh
# Debug script to diagnose z-skk startup issues

print "=== Z-SKK Debug Script ==="
print "Current time: $(date)"
print ""

# Function to time operations
time_operation() {
    local name="$1"
    shift
    local start=$(date +%s.%N)
    "$@"
    local end=$(date +%s.%N)
    local duration=$(echo "$end - $start" | bc)
    print "Time for $name: ${duration}s"
}

# Check environment
print "Environment check:"
print "- Shell: $SHELL"
print "- ZSH Version: $ZSH_VERSION"
print "- Interactive: $([[ -o interactive ]] && echo "yes" || echo "no")"
print "- Current directory: $PWD"
print ""

# Check dictionary files
print "Dictionary files:"
print "- User dictionary: ${SKK_JISYO_PATH:-${HOME}/.skk-jisyo}"
[[ -f "${SKK_JISYO_PATH:-${HOME}/.skk-jisyo}" ]] && {
    print "  - Exists, size: $(wc -c < "${SKK_JISYO_PATH:-${HOME}/.skk-jisyo}") bytes"
} || print "  - Does not exist"
print "- System dictionary: ${SKK_SYSTEM_JISYO_PATH:-not set}"
[[ -n "$SKK_SYSTEM_JISYO_PATH" && -f "$SKK_SYSTEM_JISYO_PATH" ]] && {
    print "  - Exists, size: $(wc -c < "$SKK_SYSTEM_JISYO_PATH") bytes"
}
print ""

# Test dictionary file reading
if [[ -f "${SKK_JISYO_PATH:-${HOME}/.skk-jisyo}" ]]; then
    print "Testing dictionary read performance:"
    time_operation "cat dictionary" cat "${SKK_JISYO_PATH:-${HOME}/.skk-jisyo}" > /dev/null
    time_operation "wc -l dictionary" wc -l "${SKK_JISYO_PATH:-${HOME}/.skk-jisyo}"
    print ""
fi

# Test keybinding performance
print "Testing keybinding setup:"
time_operation "character range expansion" zsh -c 'for c in {" ".."~"}; do :; done'
print ""

# Source the plugin with timing
print "Loading z-skk plugin:"
time_operation "source z-skk.plugin.zsh" source ./z-skk.plugin.zsh
print ""

# Check for errors
print "Checking for widget registration:"
zle -la | grep -c "z-skk-" | xargs -I {} print "- Found {} z-skk widgets"
print ""

print "=== Debug complete ==="
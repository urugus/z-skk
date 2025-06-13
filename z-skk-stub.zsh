#!/usr/bin/env zsh
# Stub functions to prevent errors when called before z-skk is loaded

# Define stub functions that will be replaced when z-skk loads
if ! (( ${+functions[z-skk-setup-keybindings]} )); then
    z-skk-setup-keybindings() {
        # This is a stub that does nothing
        # It will be replaced when z-skk is properly loaded
        :
    }
fi

if ! (( ${+widgets[z-skk-toggle-kana]} )); then
    # Create a stub widget to prevent bindkey errors
    z-skk-toggle-kana() { :; }
    zle -N z-skk-toggle-kana
fi
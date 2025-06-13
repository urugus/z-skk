# Fix for undefined-key error at zsh startup

## Problem
When loading z-skk, you might see an error like:
```
"z-skk-self-insert" undefined-key
```

This happens when keybindings are set up before the plugin is fully loaded.

## Root Cause
The error occurs when:
1. Your `.zshrc` or other config files try to call `z-skk-setup-keybindings` before z-skk is loaded
2. Keybindings are created before the widgets are registered
3. Functions are called before their dependencies are loaded

## Solution Implemented

### 1. Added guards to all function calls in input.zsh
- Functions that might not be loaded yet (from lazy modules) are now called with existence checks
- Example: `(( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw`

### 2. Made widget registration more defensive
- Widget registration now happens in a dedicated function `z-skk-register-widgets()`
- This function is called before keybindings are set up
- Functions are only registered as widgets if they exist

### 3. Made z-skk-self-insert more robust
- The main input widget now checks if its dependencies are loaded
- If not loaded, it falls back to the default behavior

## For Users

### Correct Setup in .zshrc

```zsh
# Load z-skk plugin (adjust path as needed)
source /path/to/z-skk/z-skk.plugin.zsh

# AFTER loading, you can call setup functions
z-skk-setup-keybindings

# Or set custom keybindings
bindkey "^J" z-skk-toggle-kana
```

### Using with zinit

```zsh
zinit light urugus/z-skk
```

### If you need to call z-skk functions before loading

Source the stub file first:
```zsh
source /path/to/z-skk/z-skk-stub.zsh
# Now you can safely reference z-skk functions
z-skk-setup-keybindings  # This will be a no-op until z-skk loads

# Load the actual plugin later
source /path/to/z-skk/z-skk.plugin.zsh
```

## Technical Details

The fix involved:
1. Adding function existence checks before calling functions from lazy-loaded modules
2. Making the widget registration process more defensive
3. Ensuring proper loading order of modules
4. Adding fallback behavior when dependencies aren't loaded

All lazy-loaded modules (special-keys, input-modes, registration, etc.) are now properly guarded.
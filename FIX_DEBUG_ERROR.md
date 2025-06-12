# Fix Summary: z-skk-debug Command Not Found Error

## Issues Fixed

### 1. "z-skk-debug: command not found" Error
**Problem**: The `z-skk-debug` function was being called in `z-skk-init` before it was loaded, causing a "command not found" error during zsh startup.

**Root Cause**: 
- There were two conflicting `z-skk-debug` functions: one in `debug.zsh` and one in `utils.zsh`
- The debug module was being loaded manually in `z-skk-init` but wasn't guaranteed to be available when called
- The simpler version in `utils.zsh` was overwriting the more feature-rich version from `debug.zsh`

**Solution**:
1. Removed the duplicate `z-skk-debug` function from `utils.zsh`
2. Added `debug` module to the module loading configuration as an optional module
3. Added `debug` to the module loading order (loaded early, right after error-handling)
4. Removed manual loading of debug.zsh from `z-skk-init`
5. Added function existence checks before calling `z-skk-debug` in the init function

### 2. "z-skk-self-insert" undefined-key Error
**Problem**: The error appears because the user has z-skk commands in their personal zsh configuration (`~/.config/zsh/rc/bindkey.zsh`) that are trying to use z-skk functions before the plugin is loaded.

**Root Cause**: The user's config file contains:
```zsh
z-skk-setup-keybindings
bindkey "^J" z-skk-toggle-kana
```

These commands run during shell initialization before z-skk is loaded, causing "command not found" and "undefined-key" errors.

**Recommendation for User**: 
The user should either:
1. Remove these lines from their personal config, as z-skk sets up its own keybindings automatically
2. Or wrap them in a check to ensure z-skk is loaded first:
```zsh
if (( ${+functions[z-skk-setup-keybindings]} )); then
    z-skk-setup-keybindings
    bindkey "^J" z-skk-toggle-kana
fi
```

## Files Modified

1. `/Users/urugus/private/z-skk/lib/core.zsh`:
   - Added debug module to Z_SKK_MODULES configuration
   - Added debug to Z_SKK_MODULE_ORDER (loaded early)
   - Removed manual debug.zsh loading from z-skk-init
   - Added function existence checks before all z-skk-debug calls

2. `/Users/urugus/private/z-skk/lib/utils.zsh`:
   - Removed duplicate z-skk-debug function

## Verification

All tests pass successfully:
- Total Passed: 19
- Total Failed: 0
- All pre-commit checks pass

The plugin now loads without errors when debug mode is enabled or disabled.
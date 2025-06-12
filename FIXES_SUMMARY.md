# z-skk Startup Issues - Fixes Applied

## Issues Identified

1. **Undefined-key error**: The ZLE widgets were being used in `bindkey` commands before they were registered with `zle -N`.

2. **30-second startup delay**: The dictionary-io module was being loaded at startup despite being marked for lazy loading, causing file I/O operations during initialization.

## Fixes Applied

### 1. Fixed Widget Registration Order (lib/keybindings.zsh)
- Moved all `zle -N` widget registrations to occur BEFORE the `z-skk-setup-keybindings()` function
- This ensures widgets exist before any `bindkey` commands try to use them
- The widgets are now registered immediately when the module is sourced

### 2. Fixed Dictionary Loading Delay (multiple files)

#### lib/core.zsh:
- Changed dictionary-io and related modules from "required" to "lazy" in `Z_SKK_MODULES`
- Removed lazy modules from `Z_SKK_MODULE_ORDER` array to prevent loading at startup
- Removed call to `z-skk-init-dictionary-loading` from `_z-skk-post-load-init()`
- Added debug logging to help diagnose future issues

#### lib/dictionary-io.zsh:
- Replaced process substitution `< <(cat "$dict_file")` with direct file reading
- This avoids potential hangs from process substitution with large or missing files
- Improved error handling for file reading operations

### 3. Added Debug Utilities
- Created lib/debug.zsh for troubleshooting startup performance
- Added `Z_SKK_DEBUG` environment variable for debug logging
- Created test scripts to verify the fixes

## Results

- **Undefined-key errors**: Eliminated by fixing widget registration order
- **Startup time**: Reduced from 30 seconds to near-instant
- **Dictionary loading**: Now happens on-demand rather than at startup

## Testing

To verify the fixes work correctly:

```bash
# Run the test script
./test-fixes.zsh

# Or enable debug mode to see detailed startup logging
Z_SKK_DEBUG=1 zsh -c 'source ./z-skk.plugin.zsh'
```

## Future Recommendations

1. Consider implementing a progress indicator for dictionary loading when it does occur
2. Add caching for parsed dictionary data to speed up subsequent loads
3. Consider using a binary dictionary format for faster parsing
4. Add unit tests to prevent regression of these issues
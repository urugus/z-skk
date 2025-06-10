# z-skk Naming Conventions

## Variables
- Global variables: `Z_SKK_VARIABLE_NAME` (all caps with Z_SKK prefix)
- Local variables: `local_variable_name` (lowercase with underscores)

## Functions
- Public functions: `z-skk-function-name` (z-skk prefix with hyphens)
- Private functions: `_z-skk-function-name` (underscore prefix + z-skk + hyphens)
- Test helper functions: `_test-helper-name` (underscore prefix with hyphens)

## Files
- Library files: `module-name.zsh` (lowercase with hyphens)
- Test files: `test_module_name.zsh` (test prefix with underscores)

## Constants
- Readonly constants: `readonly Z_SKK_CONSTANT_NAME` (same as global variables)
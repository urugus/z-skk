# z-skk Test Suite

This directory contains the test suite for the z-skk Japanese input method plugin.

## Test Organization

The test suite is organized into the following directories:

### unit/
Unit tests for individual functions and modules:
- `test_conversion.zsh` - Romaji-to-hiragana conversion and conversion flow
- `test_core.zsh` - Core functionality and initialization
- `test_dictionary_lookup.zsh` - Dictionary lookup functions
- `test_dictionary_io.zsh` - Dictionary I/O operations
- `test_display.zsh` - Display and marker functionality
- `test_input_handling.zsh` - Input handler and mode-specific input
- `test_modes.zsh` - Mode management and switching
- `test_okurigana.zsh` - Okurigana (送り仮名) processing
- `test_registration.zsh` - Word registration functionality
- `test_special_keys.zsh` - Special key functions (X, @, ;, etc.)

### integration/
Integration tests for complete workflows:
- `test_basic_input.zsh` - Basic input flow tests
- `test_conversion.zsh` - Full conversion workflow
- `test_mode_switching.zsh` - Mode switching integration
- `integration_test_utils.zsh` - Utilities for integration tests

### regression/
Tests for specific bug fixes:
- `test_niho_bug.zsh` - Regression test for the "niho" bug

### loading/
Plugin loading tests:
- `test_plugin_loading.zsh` - Basic plugin loading
- `test_zinit_loading.zsh` - Zinit-specific loading

### manual/
Manual test scripts (not run automatically):
- `manual_display_test.zsh` - Interactive display testing
- `manual_keybinding_test.zsh` - Interactive keybinding testing
- `manual_test.zsh` - General manual testing

## Running Tests

### Run all tests:
```bash
zsh tests/run_all.zsh
```

### Run tests from a specific directory:
```bash
# Run only unit tests
zsh tests/unit/test_*.zsh

# Run only integration tests
zsh tests/integration/test_*.zsh
```

### Run a specific test:
```bash
zsh tests/unit/test_conversion.zsh
```

## Test Utilities

- `test_utils.zsh` - Common test framework functions
- `run_all.zsh` - Test runner that executes all tests and provides a summary

## Writing Tests

Tests use the assertion functions provided in `test_utils.zsh`:
- `assert` - Test a condition
- `assert_equals` - Test equality
- `assert_contains` - Test string containment
- `assert_not_empty` - Test non-empty value

Example test:
```zsh
#!/usr/bin/env zsh
# Test description

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"  # For tests in subdirectories
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Write your tests
test_example() {
    assert_equals "Expected" "Actual" "Test description"
}

# Run tests
test_example

print_test_summary
```

## CI Integration

Before committing, run the pre-commit check:
```bash
zsh scripts/pre-commit-check.zsh
```

This will run all tests and perform additional checks to ensure code quality.
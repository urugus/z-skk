# z-skk

SKK-like Japanese input method for zsh

[![CI](https://github.com/urugus/z-skk/actions/workflows/ci.yml/badge.svg)](https://github.com/urugus/z-skk/actions/workflows/ci.yml)

## Installation

### Using zinit

```zsh
zinit light urugus/z-skk
```

## Configuration

### Dictionary Settings

You can configure dictionary paths using environment variables:

```zsh
# Personal dictionary path (default: ~/.skk-jisyo)
export SKK_JISYO_PATH="$HOME/.config/skk/jisyo"

# System dictionary path (optional)
export SKK_SYSTEM_JISYO_PATH="/usr/share/skk/SKK-JISYO.L"
```

Add these to your `.zshrc` before loading z-skk.

### Getting SKK Dictionaries

You can download SKK dictionaries from:
- [SKK Dictionary Project](https://skk-dev.github.io/dict/)
- Install via package manager:
  ```bash
  # macOS with Homebrew
  brew install skk-jisyo
  
  # Ubuntu/Debian
  apt-get install skkdic
  ```

## Usage

### Basic Input

- **Hiragana mode** (default): Type romaji to input hiragana
- **Conversion**: Start with uppercase letter (e.g., `Kanji` → 漢字)
- **Mode switching**:
  - `Ctrl-J`: Toggle hiragana/ASCII mode
  - `l` or `L`: Switch to ASCII mode (in hiragana mode)
  - `q`: Switch to katakana mode (in hiragana mode)
  - `Ctrl-Q`: Switch to full-width mode

### Key Bindings

See [CLAUDE.md](CLAUDE.md) for full documentation of key bindings and features.

## Development

### Running tests

```bash
# Run all tests
zsh tests/run_all.zsh

# Run specific test
zsh tests/test_plugin_loading.zsh
```

### CI

Tests and linting are automatically run on push and pull requests via GitHub Actions.
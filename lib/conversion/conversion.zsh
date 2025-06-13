#!/usr/bin/env zsh
# Main conversion module for z-skk
# Note: This module has been split into smaller focused modules:
# - romaji-processing.zsh: Romaji input handling
# - candidate-management.zsh: Candidate lookup and navigation
# - conversion-display.zsh: Display updates during conversion
# - conversion-control.zsh: Conversion orchestration

# This file now serves as a compatibility layer that ensures
# all conversion-related functions are available
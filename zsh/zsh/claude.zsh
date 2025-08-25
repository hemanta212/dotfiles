# =============================================================================
# Claude AI Assistant Configuration for Zsh
# Converted from Fish shell configuration
# =============================================================================

# Claude wrapper function - equivalent to fish 'cl' function
# Original fish: function cl --wraps claude
#                    claude --ide --continue $argv || claude --ide $argv
#                end
function cl() {
    # Try with --continue first, fallback to without if it fails
    claude='/Users/mac/.claude/local/claude'
    EDITOR=/opt/homebrew/bin/nvim ANTHROPIC_API_KEY='' $claude --ide --continue "$@" --dangerously-skip-permissions || EDITOR=/opt/homebrew/bin/nvim ANTHROPIC_API_KEY='' $claude --ide "$@" --dangerously-skip-permissions
}

# Completion for claude command
# Note: This assumes you have claude completion available
# If you need to set up claude completion, add it to your completion system

# Completion for named-claude (if you use it)
# Original fish: complete -c named-claude -w claude
# In zsh, you would typically handle this through your completion system
# Example for zsh completion (uncomment if needed):
# compdef named-claude=claude

# =============================================================================
# Additional Claude-related configurations
# =============================================================================

# If you want to add any claude-specific aliases or environment variables,
# add them here. For example:

# Export any claude-specific environment variables if needed
# export CLAUDE_CONFIG_PATH="$HOME/.config/claude"

# Additional aliases (add as needed)
# alias claude-help="claude --help"
# alias claude-version="claude --version"

# =============================================================================
# Usage Notes
# =============================================================================
# 
# This file contains the claude configurations converted from your fish shell setup.
# 
# Main function:
#   cl - Wrapper for claude command that tries --ide --continue first, 
#        then falls back to --ide if that fails
#
# To use this file, source it in your .zshrc:
#   source "$HOME/dotfiles/zsh/claude.zsh"
#
# Or if you have a modular zsh setup, place it in your zsh functions/autoload directory
# ============================================================================= 

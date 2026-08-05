# Prezto shell configurator options

# shellcheck shell=zsh

# General

# Theme to use down below in prompt section
# Other themes I like:
#   sorin, steeef, cloud, agnoster, sorin-apj, apjanke-01
_ZPREZTO_THEME="${JX_PREZTO_THEME:-sorin}"

# Set case-sensitivity for completion, history lookup, etc.
zstyle ':prezto:*:*' case-sensitive 'no'

# Color output (auto set to 'no' on dumb terminals).
zstyle ':prezto:*:*' color 'yes'

# Zsh modules to load (man zshmodules).
# zstyle ':prezto:load' zmodule 'attr' 'stat'

# Zsh functions to load (man zshcontrib).
# zstyle ':prezto:load' zfunction 'zargs' 'zmv'

# Prezto modules to load (browse modules). Order is significant.
() {
  local pmodules
  pmodules=(
    environment
    terminal
    editor
    history
    directory
    spectrum
    utility
    ssh
    completion
    git
    osx
    rsync
    history-substring-search
    belak/contrib/contrib-prompt
    apjanke/personal/prompt
    prompt
  )
  zstyle ':prezto:load' pmodule $pmodules
}

# Editor

# Key binding style: 'emacs' or 'vi'
zstyle ':prezto:module:editor' key-bindings 'emacs'
# Auto convert .... to ../..?
zstyle ':prezto:module:editor' dot-expansion 'no'

# Git

# Ignore submodules when they are 'dirty', 'untracked', 'all', or 'none'.
# zstyle ':prezto:module:git:status:ignore' submodules 'all'

# GNU Utility

# Command prefix for non-GNU systems.
zstyle ':prezto:module:gnu-utility' prefix 'g'

# History Substring Search

# Query found color.
# zstyle ':prezto:module:history-substring-search:color' found ''
# Query not found color.
# zstyle ':prezto:module:history-substring-search:color' not-found ''
# Search globbing flags.
# zstyle ':prezto:module:history-substring-search' globbing-flags ''

# Prompt

# Prompt theme. Theme name, 'random', or 'off'.
zstyle ':prezto:module:prompt' theme "$_ZPREZTO_THEME"

# Ruby

# Auto switch the Ruby version on directory change.
# zstyle ':prezto:module:ruby:chruby' auto-switch 'yes'

# GNU Screen

# Auto start a session when Zsh is launched in a local terminal.
# zstyle ':prezto:module:screen:auto-start' local 'yes'
# Auto start a session when Zsh is launched in a SSH connection.
# zstyle ':prezto:module:screen:auto-start' remote 'yes'

# SSH

# SSH identities to load into the agent.
# zstyle ':prezto:module:ssh:load' identities 'id_rsa' 'id_rsa2' 'id_github'

# Syntax Highlighting

# Syntax highlighters.
# By default, only the main highlighter is enabled.
# zstyle ':prezto:module:syntax-highlighting' highlighters \
#   'main' \
#   'brackets' \
#   'pattern' \
#   'cursor' \
#   'root'
#
# Set syntax highlighting styles.
# zstyle ':prezto:module:syntax-highlighting' styles \
#   'builtin' 'bg=blue' \
#   'command' 'bg=blue' \
#   'function' 'bg=blue'

# Terminal

# Auto set the tab and window titles.
zstyle ':prezto:module:terminal' auto-title 'yes'

# Window title format.
# zstyle ':prezto:module:terminal:window-title' format '%n@%m: %s'
# Tab title format.
# zstyle ':prezto:module:terminal:tab-title' format '%m: %s'

# Tmux

# Auto start a session when Zsh is launched in a local terminal.
# zstyle ':prezto:module:tmux:auto-start' local 'yes'
# Auto start a session when Zsh is launched in a SSH connection.
# zstyle ':prezto:module:tmux:auto-start' remote 'yes'
# Integrate with iTerm2.
# zstyle ':prezto:module:tmux:iterm' integrate 'yes'

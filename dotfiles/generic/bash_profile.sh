# .bash_profile - Bash login shell configuration 
#
# Bash-specific login shell configuration.

if [[ $JX_TRACE_SHELL_STARTUP = 1 ]]; then
  set -o xtrace
fi

# Include common bashlike configuration
if [[ -f "$HOME/.profile" ]]; then . "$HOME/.profile"; fi

# Include interactive bash settings
if [[ -r "$HOME/.bashrc" ]]; then . "$HOME/.bashrc"; fi

# Bash-specific stuff

# (nothing here currently)



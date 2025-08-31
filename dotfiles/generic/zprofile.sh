# zprofile - zsh-specific profile (env configuration)
#

if [[ $JX_TRACE_SHELL_STARTUP = 1 ]]; then
  set -o xtrace
fi

# Include common bashlike env configuration, which is in the bash profile
if [[ -f "$HOME/.profile" ]]; then
  source "$HOME/.profile"
fi

# Zsh configurator

# Valid: 'oh-my-zsh', 'prezto', or 'none'
export JX_ZSH_CONFIGURATOR=${JX_ZSH_CONFIGURATOR:-oh-my-zsh}
export JX_OMZ_THEME=${JX_OMZ_THEME:-agnosterj}
export JX_PREZTO_THEME=${JX_PREZTO_THEME:-sorin-apj}


# Machine- or environment-local settings.
# Call this last so it can override previously-set stuff by clobbering it.

if [[ -f $HOME/.zprofile-local ]]; then
  source "${HOME}/.zprofile-local"
fi

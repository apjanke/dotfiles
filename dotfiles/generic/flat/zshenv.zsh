# zshenv - zsh env configuration

if [[ $JX_TRACE_SHELL_STARTUP = 1 ]]; then
  set -o xtrace
fi

# Include common bashlike env configuration, which is in the bash profile
# I put common bash and zsh env setup in m .profile, not a bashyenv.sh
if [[ -f "$HOME/.profile" ]]; then
  source "$HOME/.profile"
fi


# zsh-specific env setup follows here

# Zsh configurator

# Valid: 'ohmyzsh', 'prezto', or 'none'
export JX_ZSH_CONFIGURATOR=${JX_ZSH_CONFIGURATOR:-ohmyzsh}
export JX_OMZ_THEME=${JX_OMZ_THEME:-agnosterj}
# export JX_OMZ_DEBUG=1
export JX_PREZTO_THEME=${JX_PREZTO_THEME:-sorin-apj}

# Machine- or environment-local settings.
# Call this last so it can override previously-set stuff by clobbering it.

if [[ -f $HOME/.zshenv-local ]]; then
  source "${HOME}/.zshenv-local"
fi

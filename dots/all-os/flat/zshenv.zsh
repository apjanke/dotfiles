# zshenv - zsh env configuration

if [[ $JX_TRACE_SHELL_STARTUP = 1 ]]; then
  set -o xtrace
fi

# Include common bashlike env configuration, which is in the bash profile
# (I put common bash and zsh env setup in my .profile, not a bashyenv.sh.)
# Intentionally not guarded by a $JX_ENV_LOADED check, so manual re-sourcing gets it.
if [[ -f $HOME/.profile ]]; then
  source "$HOME/.profile"
fi


# zsh-specific env setup follows here

# Zsh configurator

# Valid: 'ohmyzsh', 'prezto', or 'none'
export JX_ZSH_CONFIGURATOR=${JX_ZSH_CONFIGURATOR:-ohmyzsh}
export JX_OMZ_THEME=${JX_OMZ_THEME:-agnosterj}
# export JX_OMZ_DEBUG=1
export JX_PREZTO_THEME=${JX_PREZTO_THEME:-sorin-apj}

# Per-machine/site local definitions
# Call this last so it can override previously-set stuff by clobbering it.
#
# jx::* and _jx_source_maybe are defined in .profile, sourced above.

for __where in site user local; do
  _jx_source_maybe "$HOME/.zshenv-${__where}"
done
unset __where

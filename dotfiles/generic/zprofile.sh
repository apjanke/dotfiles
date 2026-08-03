# zprofile - zsh-specific login-shell profile 
#

# Machine- or environment-local settings.
# Call this last so it can override previously-set stuff by clobbering it.

if [[ -f $HOME/.zprofile-local ]]; then
  source "${HOME}/.zprofile-local"
fi

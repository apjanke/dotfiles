# zshrc-prezto.zsh
#
# Logic for loading and configuring Prezto.
#
# Most configuration is in zpreztorc.zsh instead, since that's its conventional
# configuration file.

# Source Prezto.
if [[ -f "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

zstyle ':prezto:module:prompt' pwd-length 'long'
# .bash_logout - bash logout script

# shellcheck shell=bash
# shellcheck disable=SC1091

# Include common bashlike logout script
if [[ -f $HOME/.dotlib/bashylogout.sh ]]; then
  source "$HOME/.dotlib/bashylogout.sh"
fi

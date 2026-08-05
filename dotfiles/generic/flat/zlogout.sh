# .zlogout - zsh logout script

# shellcheck shell=zsh

# Include common bashlike logout script
if [[ -f "$HOME/.dots/bashylogout.sh" ]]; then
  source "$HOME/.dots/bashylogout.sh"
fi

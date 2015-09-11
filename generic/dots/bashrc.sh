# .bashrc for apjanke
#
# (interactive bash configuration)

# Pull in common bash/zsh configuration
if [ -f $HOME/.dotfiles/zshbashrc.zsh ]; then source $HOME/.dotfiles/zshbashrc.zsh; fi

# bash-specific settings

unset maybe_add_path

#  History and interaction  #

history_control=ignoredups
export HISTIGNORE="&:ls:ls -la:[bf]g:exit"

set -o ignoreeof
set -o vi
shopt -s cdspell
shopt -s checkwinsize

#  Appearance  #

if [ "$USER" = "janke" ]; then
  export PS1="[\W] \$ "
else
  export PS1="[\h: \W] \$ "
fi


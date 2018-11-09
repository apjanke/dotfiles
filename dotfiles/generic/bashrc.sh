# .bashrc for apjanke
#
# (interactive bash configuration)

# Pull in common bash/zsh configuration
if [ -f $HOME/.dotfiles/zshbashrc.zsh ]; then source $HOME/.dotfiles/zshbashrc.zsh; fi

# bash-specific settings  #

unset maybe_add_path

#  History and interaction  #

history_control=ignoredups
export HISTIGNORE="&:ls:ls -la:[bf]g:exit"
# Larger bash history (allow 32^3 entries; default is 500)
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups
export HISTIGNORE="ls:ls *:cd:cd -:pwd:exit:date:* --help"
shopt -s histappend

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

#  Homebrew  #

if type brew 2&>/dev/null; then
  for completion_file in $(brew --prefix)/etc/bash_completion.d/*; do
    source "$completion_file"
  done
fi

#  Miscellaneous  #

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

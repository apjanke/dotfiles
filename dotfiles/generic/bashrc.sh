# .bashrc for apjanke
#
# (interactive bash configuration)

if [[ $JX_TRACE_SHELL_STARTUP = 1 ]]; then
  set -o xtrace
fi

# Pull in common bashlike configuration
if [[ -f "$HOME/.dots/bashyrc.sh" ]]; then
  source "$HOME/.dots/bashyrc.sh"
fi

# Bash-specific settings


# History and interaction

history_control=ignoredups
export HISTIGNORE="&:ls:ls -la:[bf]g:exit"
export HISTSIZE=32768   # Longer history (default is only 500)
export HISTFILESIZE="$HISTSIZE"
export HISTCONTROL=ignoredups
export HISTIGNORE="ls:ls *:cd:cd -:pwd:exit:date:* --help"
shopt -s histappend

set -o ignoreeof
set -o vi
shopt -s cdspell
shopt -s checkwinsize

# Appearance

if [[ "$USER" = "janke" ]]; then
  export PS1="[\W] \$ "
else
  export PS1="[\h: \W] \$ "
fi

# Homebrew bash-specifics

if type brew &> /dev/null; then
  for _completion_file in $(brew --prefix)/etc/bash_completion.d/*; do
    source "$_completion_file"
  done
fi
unset _completion_file


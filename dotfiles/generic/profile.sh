# .profile
# apjanke's .profile
#
# (non-bash-specific login shell configuration)


#   Non-platform-specifc stuff   #

if which subl &>/dev/null; then
    # Let's try using Sublime Text for shell-invoked editor, too
   export EDITOR='subl -w'
   export VISUAL='subl -w'
fi


if [[ -e $HOME/.rvm/bin ]]; then
  export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
  if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
  fi
fi
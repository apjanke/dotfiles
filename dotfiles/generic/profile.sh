# .profile
# apjanke's .profile
#
# (non-bash-specific login shell configuration)


#  Non-platform-specifc stuff

if which subl &>/dev/null; then
    # Let's try using Sublime Text for shell-invoked editor, too
   export EDITOR='subl -w'
   export VISUAL='subl -w'
fi

export PATH

if [[ -e $HOME/.rvm/bin ]]; then
  PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
  if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
  fi
fi

#  Anaconda

# Currently all commented out because I'm trying to work with system pythons

#if [[ -e /anaconda/bin ]]; then
#  PATH="/anaconda/bin:$PATH"
#fi
#if [[ -e /anaconda3/bin ]]; then
#  PATH="/anaconda3/bin:$PATH"
#fi
#if [[ -e "$HOME/anaconda3/bin" ]]; then
#  PATH="$HOME/anaconda3/bin:$PATH"
#fi

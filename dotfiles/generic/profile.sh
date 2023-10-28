# .profile
# apjanke's .profile
#
# (non-bash-specific login shell configuration)

# Configuration and choices

# Whether to load Homebrew (in addition to MacPorts). If on, then brew's stuff
# will be loaded in front of MacPorts.
USE_HOMEBREW=1


# Path setup

export PATH

if [[ -e $HOME/.rvm/bin ]]; then
  PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
  if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
  fi
fi

# Anaconda

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

# Allow for machine- or environment-local overrides
if [[ -f $HOME/.profile-local ]]; then
  source "${HOME}/.profile-local"
fi

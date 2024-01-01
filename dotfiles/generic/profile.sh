# .profile
#
# Common bashlike login shell and env configuration.

# Call uname once and stash results for performance
if [[ -z $__uname ]]; then
  __uname=$(uname)
fi


# Configuration and choices for these dotfiles

# Whether to load Homebrew (in addition to MacPorts). If on, then brew's stuff
# will be loaded in front of MacPorts.
export JX_USE_HOMEBREW="${JX_USE_HOMEBREW:-1}"
# Anaconda loading controls
export JX_CONDA_AUTOLOAD="${JX_CONDA_AUTOLOAD:-1}"
export JX_CONDA_AUTOACTIVATE="${JX_CONDA_AUTOACTIVATE:-1}"
# Other stuff
export JX_DO_XML_CATALOG=0
# Which Ruby env mgr to load on startup: rbenv, rvm, none. or ''
export JX_RUBY_AUTOLOAD_ENVMGR=rbenv


# MacOS specifics

if [[ $__uname = "Darwin" ]]; then

  # Default $TMPPREFIX may be insecure
  # TODO: Find a citation for that and whether it's still relevant
  # And also, OSTYPE says like "darwin23.0", not "D..." - is "==" case sensitive?
  # Once that's resolved, remove the conditionality and either do it or don't, based
  # on the same uname-based detection used elsewhere.
  # And why does it say "zsh" here? Is TMPPREFIX zsh-specific?
  if [[ $OSTYPE == Darwin* ]]; then
    TMPPREFIX="$TMPDIR/zsh"
  fi

fi


# Allow for machine- or environment-local overrides

if [[ -f $HOME/.profile-local ]]; then
  source "$HOME/.profile-local"
fi

# Path setup

if [[ -f $HOME/.dots/bashy-paths.sh ]]; then
  source "$HOME/.dots/bashy-paths.sh"
fi


# .profile
#
# Common bashlike login shell and env configuration.

# Call uname once and stash results for performance
if [[ -z $__uname ]]; then
  __uname=$(uname)
fi


# Configuration and choices for these Janke dotfiles

# Whether to load Homebrew (in addition to MacPorts). If on, then brew's stuff
# will be loaded in front of MacPorts.
export JX_USE_HOMEBREW="${JX_USE_HOMEBREW:-1}"
# Whether to load MacPorts (in addition to Homebrew).
export JX_USE_MACPORTS="${JX_USE_MACPORTS:-0}"
# Anaconda loading controls
export JX_CONDA_AUTOLOAD="${JX_CONDA_AUTOLOAD:-0}"
export JX_CONDA_AUTOACTIVATE="${JX_CONDA_AUTOACTIVATE:-0}"
# Which Ruby env mgr to load on startup, if any: rbenv, rvm, or none.
# TODO: split in to bool "do autoload" and str "which env manager" controls
export JX_RUBY_AUTOLOAD_ENVMGR=rbenv

# NVM controls

# Always set NVM_DIR, to avoid NVM clobbering itself or other system things if you're
# pulling in the executables from a system install (instead of NVM's recommended per-user
# installation location).
export NVM_DIR="${HOME}/.nvm"
# NVM is slow to load, so I usually have this off unless I'm actively doing
# NVM development. The nvm command will still be available if it's system installed;
# just won't modify the shell setup for it.
# Enabled for now to get working with VS Code and RogCel MUD project.
export JX_NVM_AUTOLOAD="${JX_NVM_AUTOLOAD:-1}"


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

  # MacPorts

  function jx-load-macports() {
    local bindir
    local -a bindirs
    # In reverse order of addition
    bindirs=(
      '/opt/local/sbin'
      '/opt/local/bin'
    )
    for bindir in $bindirs; do
      if [[ -d "$bindir" ]]; then
        PATH="${bindir}:$PATH"  
      fi
    done
  }

  if [[ "$JX_USE_MACPORTS" = 1 ]]; then
    jx-load-macports
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


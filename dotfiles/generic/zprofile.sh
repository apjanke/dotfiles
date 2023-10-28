# zprofile - zsh-specific profile
#
# TODO: Should this source ~/.profile too, so common stuff can be defined in one
# location?

# Configuration and choices

# Whether to load Homebrew (in addition to MacPorts). If on, then brew's stuff
# will be loaded in front of MacPorts.
USE_HOMEBREW=1

# MacPorts

function () {
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


# Allow for machine- or environment-local overrides

if [[ -f $HOME/.zprofile-local ]]; then
  source "${HOME}/.zprofile-local"
fi

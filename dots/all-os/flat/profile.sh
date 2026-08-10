# .profile
#
# Common bashlike login shell and env configuration.

# shellcheck shell=bash

# This is redundant with the .bash_profile and .zshenv setting of it, but that lets
# this .profile file still work independently of them.
if [[ $JX_TRACE_SHELL_STARTUP = 1 ]]; then
  set -o xtrace
fi

# Call uname once and stash results for performance
if [[ -z $__jx_uname ]]; then
  __jx_uname=$(uname)
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
export JX_RUBY_AUTOLOAD_ENVMGR="${JX_RUBY_AUTOLOAD_ENVMGR:-rbenv}"

# NVM controls

# Always set NVM_DIR, to avoid NVM clobbering itself or other system things if you're
# pulling in the executables from a system install (instead of NVM's recommended per-user
# installation location).
export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
# NVM is slow to load, so I usually have this off unless I'm actively doing
# NVM development. The nvm command will still be available if it's system installed;
# just won't modify the shell setup for it.
# I enable it when I'm working with the RogCel MUD project in VS Code. So if it's on, that's
# probably why.
export JX_NVM_AUTOLOAD="${JX_NVM_AUTOLOAD:-0}"


# MacOS specifics

if [[ $__jx_uname = "Darwin" ]]; then

  # Default $TMPPREFIX may be insecure? So clobber it.
  # TODO: Find a citation for that and whether it's still relevant
  # And also, OSTYPE says like "darwin23.0", not "D..." - is "==" case sensitive? Once
  # that's resolved, remove the conditionality and either do it or don't, based on the
  # same uname-based detection used elsewhere. And why does it say "zsh" here? Is
  # TMPPREFIX zsh-specific?
  if [[ ${OSTYPE:-} == Darwin* ]]; then
    export TMPPREFIX="$TMPDIR/zsh"
  fi

  # MacPorts

  function jx-load-macports() {
    local bindir
    local -a bindirs
    # In reverse order of addition
    bindirs=( '/opt/local/sbin' '/opt/local/bin' )
    for bindir in "${bindirs[@]}"; do
      if [[ -d $bindir ]]; then
        PATH="${bindir}:$PATH"
      fi
    done
  }

  if [[ ${JX_USE_MACPORTS:-} = 1 ]]; then
    jx-load-macports
  fi

fi


# These stay defined after .profile finishes, unlike the usual sourced-script cleanup
# convention: .zshenv's and .dotlib/bashyrc.sh's own local-loading loops, later in the same
# shell session, reuse them too. This is JX's own layer, kept independent of JXL (see
# .dotlib/jxl-lib.sh) since JXL isn't loaded this early.
function jx::is_debug() { [[ ${_JX_DEBUG:-0} != 0 ]]; }
function jx::debug()    { jx::is_debug && jx::emit "$*"; }
function jx::error()    { jx::emit "ERROR: $*"; }
function jx::emit()     { echo >&2 "jx: $*"; }

function _jx_source_maybe() {
  local file="$1"
  [[ -f $file ]] || return
  jx::debug "source-ing $file"
  source "$file" || jx::error "Failed source-ing: $file"
}

# Per-machine/site local definitions

for __where in site user local; do
  _jx_source_maybe "$HOME/.profile-${__where}"
done
unset __where


# Path setup

_jx_source_maybe "$HOME/.dotlib/bashy-paths.sh"

# Cleanup

# Mark that .profile has run in this shell process. Deliberately not exported: a new
# shell process always needs .profile to run fresh anyway, since it defines functions
# that (unlike exported variables) never survive a fork/exec. This exists purely so
# .bashrc's fallback source (see its own comment) can skip a login shell's second
# automatic run: .bash_profile sources .profile directly, then sources .bashrc, whose
# fallback would otherwise re-source .profile a moment later in the same process.
# shellcheck disable=SC2034  # read by .bashrc, not this file
JX_ENV_LOADED=1

# jxl-lib.sh - JXL, the JX shell library
#
# Shared boilerplate for JX shebang scripts and for "command functions" -- shell functions
# defined in the rc files and used as commands in interactive sessions, like
# jx-shell-info.
#
# Sourced, never run. Installed as ~/.dotlib/jxl-lib.sh.
#
# Naming. Functions: jxl::foo is public, jxl::_foo is internal. Command functions keep
# hyphenated names (jx-shell-info) rather than "::" -- colons confuse bash completion for
# interactive commands, which is the one place Google's shell guide advises against its
# own convention.
#
# Variables use three tiers, and the leading underscore marks SCOPE, not privacy -- plenty
# of $_JXL_* names are documented API that scripts are meant to set:
#
#   JXL_*     Caller-facing configuration. May be exported, and deliberately visible to a
#             `set | grep ^JX` style sweep alongside the rest of the JX_* variables.
#   _JXL_*    JXL's own variable space. MUST NOT be exported, and stays out of the JX*
#             glob so that sweep shows configuration rather than machinery. Public or
#             internal is a separate question, answered per variable in the interface
#             block below: _JXL_EMIT_PROGNAME is something a script sets, while
#             _JXL_WANT_HELP is something JXL maintains.
#   _jxl_*    Lowercase, function-local working variables. These really are internal.
#
# THE ONE ASYMMETRY WORTH KNOWING: jxl::die exits. That is correct in a shebang script,
# and correct in a command function running with `isolation subshell` (the default),
# where the exit kills only the subshell. It is FORBIDDEN in an `isolation inline`
# command, where it would take the user's interactive shell down with it -- use
# jxl::error and an explicit `return` there. Same for errexit.
#
# This file is parsed by both bash 3.2 and zsh, so: no bash 4+ constructs, and no numeric
# array subscripts (zsh indexes from 1, bash from 0) -- use jxl::array_at instead. Nothing
# here may be `readonly` at top level, which would freeze the name in the user's live
# shell.
#
#
# ========== The JXL variable interface ==========
#
# Functions are documented at their own definitions; this is the variable contract.
#
# Set by a CALLER, to steer JXL. Read-only as far as JXL is concerned -- it never assigns
# to these, so a --verbose flag can never leak out into child processes:
#
#   VERBOSE, DEBUG            Generic cross-tool controls. May be exported. Any non-zero
#                             value turns the corresponding mode on.
#   JXL_VERBOSE, JXL_DEBUG    JX-specific overrides; win over VERBOSE / DEBUG when set.
#                             Use these if another tool's exported DEBUG gets in the way.
#                             jxl::verbose and jxl::debug honor these directly before any
#                             per-invocation state is seeded, so they work at source time too.
#   TRACE                     Set to 1 for `set -o xtrace`; honored by jxl::init_script.
#   JXL_NO_READONLY           Set to 1 to skip every `readonly` JXL would apply, so the
#                             library can be re-sourced in a live shell while hacking on
#                             it. Development escape hatch; leave unset normally.
#
# Set by a SHEBANG SCRIPT or a COMMAND FUNCTION, to configure its own behavior. These are
# seeded by jxl::_seed_std_vars and may be overridden afterward:
#
#   _JXL_EMIT_PROGNAME        1 to prefix messages with $PROGRAM_NAME. Default 0.
#   _JXL_EMIT_TIMESTAMP       1 to prefix messages with a timestamp. Default 0.
#                             Command functions can set both from $_JXL_COMMAND_INFO
#                             instead; see jxl::run_command.
#   _JXL_COMMAND_INFO         Per-command declaration array, read by jxl::run_command.
#                             Keys: name, usage_headline, synopsis_args, options,
#                             isolation, emit_progname, emit_timestamp.
#
# Maintained by JXL during an invocation; a script or impl may read them, and jxl::std_opt
# writes them from the standard command-line options:
#
#   PROGRAM_NAME              Script or command name, for messages and help.
#   _JXL_VERBOSE, _JXL_DEBUG, _JXL_DRY_RUN, _JXL_WANT_HELP
#   _JXL_CLI_ARGS             Arguments not yet consumed; see jxl::run_command.
#
# Defined by JXL at source time, for callers to inspect:
#
#   _JXL_VERSION              Version string, e.g. "0.1.0".
#   _JXL_VERSION_ARR          The same, pre-split: (0 1 0). Compare components from this
#                             rather than parsing the string.
#   _JXL_LIB_PATH             Path of the jxl-lib.sh that actually got sourced.

# shellcheck shell=bash

# Idempotent: sourcing twice is free, so scripts and rc files need not coordinate.
#
# These two are the ONLY variables sourcing sets. Everything else is per-invocation state,
# seeded by jxl::_seed_std_vars into whatever scope is current -- globals in a shebang
# script, locals inside a command function. bashyrc.sh sources this into every interactive
# shell, and none of that state belongs in the user's namespace.
#
if [[ -n ${_JXL_VERSION:-} ]]; then
  return 0
fi

# SemVer-ish, kept as components so a future "at least X" check compares numbers rather
# than parsing a string. Joined fork-free: this runs on every shell startup.
#
# `readonly` is safe here even though this lands in a live interactive shell: the guard
# above means a re-source returns before ever reaching these assignments. The only cost is
# that neither name can be unset for the life of the shell, and re-sourcing was never a
# clean reload anyway -- it leaves renamed or deleted functions behind and does not reset
# state set through other means. A new shell is the honest way to reload.
_JXL_VERSION_ARR=(0 1 0)
_JXL_VERSION=''
for _jxl_v in "${_JXL_VERSION_ARR[@]}"; do
  _JXL_VERSION="${_JXL_VERSION:+${_JXL_VERSION}.}${_jxl_v}"
done
unset _jxl_v

# Which copy of this file got loaded. With a repo copy, an installed copy, and an
# idempotence guard all in play, that is a real question -- jxl::show_shell_info reports
# it, and the debug load notice at the bottom prints it.
if [[ -n ${BASH_VERSION:-} ]]; then
  _JXL_LIB_PATH="${BASH_SOURCE[0]}"
else
  # zsh's equivalent of $BASH_SOURCE for the file being sourced. bash parses this fine
  # (verified with bash -n) and never reaches it; shellcheck reads it as bash and does not
  # know the (%) flag form.
  # shellcheck disable=SC2296
  _JXL_LIB_PATH="${(%):-%x}"
fi

# Set JXL_NO_READONLY=1 to skip this, for the rare in-shell reload while hacking on JXL.
if [[ ${JXL_NO_READONLY:-0} == 0 ]]; then
  readonly _JXL_VERSION _JXL_VERSION_ARR _JXL_LIB_PATH
fi


# ========== Entry points ==========

# shellcheck disable=SC2120  # takes its own options; callers pass none, by design
function jxl::init_script() {
  # Set up a shebang script: shell options, $PROGRAM_NAME, and the standard state.
  #
  # Usage: jxl::init_script [--no-errexit]
  #
  # Replaces the four-line preamble. `set` inside a function affects the whole shell in
  # both bash and zsh, which is what makes this work.
  local arg want_errexit=1

  while [[ $# -ge 1 ]]; do
    arg="$1"; shift
    case "$arg" in
      --no-errexit)   want_errexit=0 ;;
      *)              jxl::die "jxl::init_script: unexpected argument: ${arg}" ;;
    esac
  done

  if [[ $want_errexit == 1 ]]; then
    set -o errexit
  fi
  set -o nounset
  set -o pipefail
  if [[ ${TRACE:-0} == "1" ]]; then
    set -o xtrace
  fi

  PROGRAM_NAME=$(basename "$0")
  jxl::_seed_std_vars
}

function jxl::run_command() {
  # Run a command function's implementation with JXL state set up around it.
  #
  # Usage: jxl::run_command <impl_function> "$@"
  #
  # The caller is a thin wrapper; this owns the `local` list, so adding a variable later
  # touches one place rather than every command. Both shells are dynamically scoped, so
  # the locals declared here are visible to the impl.
  local _jxl_impl="$1"; shift
  local _jxl_isolation=subshell _jxl_rc=0

  if jxl::assocarray_has _JXL_COMMAND_INFO isolation; then
    jxl::assocarray_at _jxl_isolation _JXL_COMMAND_INFO isolation
  fi

  case "$_jxl_isolation" in
    subshell)
      # Everything the impl does is contained: options, variables, even an exit. That is
      # what lets jxl::die and errexit work normally in a command function.
      #
      # A subshell inherits every shell option from its parent, so without normalizing
      # here an impl would behave differently depending on what the user happens to have
      # set interactively. nounset and pipefail go on, which is what JXL code assumes.
      #
      # errexit starts OFF and is opt-in. An impl is welcome to `set -o errexit` for
      # itself: in this mode that is safe and supported, since the subshell absorbs the
      # exit, and it is often the right thing for an impl that runs a series of commands
      # where any failure should stop the rest. Only `isolation inline` impls must avoid
      # it -- there it would take the user's shell down.
      (
        # Order matters: the baseline reset restores every option to its default, so it
        # has to come before the three JXL wants set a particular way.
        jxl::_normalize_shell_options
        set +o errexit
        set -o nounset
        set -o pipefail
        jxl::_run_command_body "$_jxl_impl" "$@"
      )
      return $?
      ;;
    inline)
      # The impl changes the calling shell, so nothing can be contained. Same normalized
      # options, but each has to be put back afterward. errexit is never set here: it
      # would take the user's interactive shell down on the first failing command.
      #
      # Residual risk, bash only: an interrupt mid-impl skips the restore, leaving nounset
      # or pipefail set in the interactive shell. zsh has no such gap (`local_options`
      # would cover it), and the default subshell mode avoids the question entirely.
      local _jxl_had_pipefail=0 _jxl_had_nounset=0
      if [[ -o pipefail ]]; then _jxl_had_pipefail=1; fi
      if [[ -o nounset ]];  then _jxl_had_nounset=1;  fi
      set -o pipefail
      set -o nounset
      jxl::_run_command_body "$_jxl_impl" "$@" || _jxl_rc=$?
      if [[ $_jxl_had_nounset  == 0 ]]; then set +o nounset;  fi
      if [[ $_jxl_had_pipefail == 0 ]]; then set +o pipefail; fi
      return $_jxl_rc
      ;;
    *)
      jxl::error "jxl::run_command: unknown isolation mode: ${_jxl_isolation}"
      return 2
      ;;
  esac
}

function jxl::_run_command_body() {
  # Seed state, parse arguments, then hand off to the impl. Runs inside the subshell in
  # the default mode, so the leftover-argument check sees what the command's parser ate.
  local _jxl_impl="$1"; shift
  # Every piece of state jxl::_seed_std_vars touches has to be declared local here, or it
  # would land in the caller's namespace -- which in `inline` mode is the user's live
  # interactive shell.
  local PROGRAM_NAME
  local _JXL_VERBOSE _JXL_DEBUG _JXL_DRY_RUN _JXL_WANT_HELP
  local _JXL_EMIT_PROGNAME _JXL_EMIT_TIMESTAMP
  local -a _JXL_CLI_ARGS=()

  PROGRAM_NAME=$(jxl::_calling_command_name)
  jxl::_seed_std_vars

  # A command can declare its log format alongside the rest of its metadata, rather than
  # assigning to the _JXL_EMIT_* variables separately.
  if jxl::assocarray_has _JXL_COMMAND_INFO emit_progname; then
    jxl::assocarray_at _JXL_EMIT_PROGNAME _JXL_COMMAND_INFO emit_progname
  fi
  if jxl::assocarray_has _JXL_COMMAND_INFO emit_timestamp; then
    jxl::assocarray_at _JXL_EMIT_TIMESTAMP _JXL_COMMAND_INFO emit_timestamp
  fi

  jxl::_parse_std_opts "$@"
  if [[ $_JXL_WANT_HELP == 1 ]]; then
    jxl::command_help
    return 0
  fi

  # A command may define <impl>_parse_cli to handle its own options. It receives the
  # remaining arguments and writes the ones it did not consume back to $_JXL_CLI_ARGS.
  if jxl::_is_function "${_jxl_impl}_parse_cli"; then
    "${_jxl_impl}_parse_cli" ${_JXL_CLI_ARGS[@]+"${_JXL_CLI_ARGS[@]}"}
  fi

  if [[ ${#_JXL_CLI_ARGS[@]} -gt 0 ]]; then
    local _jxl_first
    jxl::array_at _jxl_first _JXL_CLI_ARGS 0
    jxl::error "Unrecognized argument: ${_jxl_first}"
    return 1
  fi

  # Options are settled once parsing is done, so freeze them -- the same `readonly` that
  # ends a hand-written parse_cli. An impl that assigns to one has a bug, and this is how
  # it finds out.
  #
  # SUBSHELL MODE ONLY, because the two shells disagree about how loud that is: bash
  # prints "readonly variable" and carries on, while zsh treats it as fatal and aborts.
  # Verified under `zsh -i -c`, which died on the spot; I could not test a real
  # interactive prompt session, so inline mode -- which runs in the user's live shell --
  # does not take the risk. In a subshell, fatal is exactly what we want.
  #
  # $_JXL_EMIT_PROGNAME and $_JXL_EMIT_TIMESTAMP stay writable on purpose: they are the
  # impl's own log format, which it may reasonably change partway through.
  if [[ ${_jxl_isolation:-subshell} == subshell && ${JXL_NO_READONLY:-0} == 0 ]]; then
    readonly PROGRAM_NAME _JXL_VERBOSE _JXL_DEBUG _JXL_DRY_RUN
  fi

  "$_jxl_impl"
}

function jxl::_normalize_shell_options() {
  # Reset the shell to a known baseline before a command impl runs.
  #
  # SUBSHELL MODE ONLY -- every one of these is a global change, so in inline mode they
  # would follow the user home. A command function inherits the interactive session's
  # options, and a caller who set any of these has silently changed how the impl's code
  # behaves.
  #
  # The rule: reset what silently changes the MEANING of the impl's code, and leave what
  # the caller set deliberately. So nocasematch goes -- it quietly makes every `case` in
  # this file match case-insensitively -- while xtrace and verbose stay, since someone
  # mid-`set -x` is debugging on purpose, and so does noclobber, which is a guard rail
  # against clobbering a file and should apply to a JXL command like anything else.
  local had_noclobber=0
  if [[ -o noclobber ]]; then had_noclobber=1; fi

  if [[ -n ${ZSH_VERSION:-} ]]; then
    # zsh hands us the whole job in one builtin: back to zsh defaults, undoing
    # `emulate sh`, ksh_arrays, sh_word_split and the rest. It is thorough enough to take
    # noclobber with it, so put that back.
    emulate -R zsh
    if [[ $had_noclobber == 1 ]]; then set -o noclobber; fi
    return 0
  fi

  # bash has no equivalent, so spell it out. Chosen for impact, not completeness:
  #   allexport   would export every assignment, including the _JXL_* internals that the
  #               whole VERBOSE/DEBUG design depends on NOT being exported
  #   nocasematch makes `case` and `[[ == ]]` case-insensitive, everywhere
  #   noglob / nullglob / failglob / dotglob / nocaseglob / extglob   change what a glob
  #               matches, or whether an unmatched one is empty, itself, or fatal
  #   xpg_echo    changes what `echo` does with backslashes
  #   posix / keyword / onecmd   change parsing or control flow outright
  set +o allexport
  set +o noglob
  set +o keyword
  set +o onecmd
  set +o posix
  set -o braceexpand

  # 2>/dev/null because globstar and lastpipe do not exist in bash 3.2, and naming a
  # missing option is an error there rather than a no-op.
  local opt
  for opt in nullglob failglob dotglob nocaseglob nocasematch extglob xpg_echo \
             expand_aliases globstar lastpipe; do
    shopt -u "$opt" 2>/dev/null || true
  done
}

function jxl::_seed_std_vars() {
  # Establish the per-invocation state. Assigns into the current scope, so a shebang
  # script gets globals and a command function gets the locals _run_command_body declared.
  #
  # $VERBOSE and $DEBUG are read-only interface: a caller may set or export them to steer
  # several tools at once. JXL never assigns to them, because a `local VERBOSE=1` on an
  # exported VERBOSE leaks the value to every child process in bash -- and silently drops
  # it from the environment entirely in zsh. So the working copies are $_JXL_* instead.
  _JXL_VERBOSE="${JXL_VERBOSE:-${VERBOSE:-0}}"
  _JXL_DEBUG="${JXL_DEBUG:-${DEBUG:-0}}"
  _JXL_DRY_RUN=0
  _JXL_WANT_HELP=0

  # Message decoration. Underscore-prefixed for namespace hygiene, not because they are
  # internal -- a shebang script sets these directly after jxl::init_script, and a command
  # function can declare them in $_JXL_COMMAND_INFO. They sit outside the JX* glob because
  # they are a command's own log format rather than configuration a caller supplies, and
  # that sweep (see jx-shell-info) should show the latter.
  _JXL_EMIT_PROGNAME=0
  _JXL_EMIT_TIMESTAMP=0
}

function jxl::_calling_command_name() {
  # Name of the command function two frames up, for $PROGRAM_NAME. Explicit `name` in
  # $_JXL_COMMAND_INFO wins.
  local name=''
  if jxl::assocarray_has _JXL_COMMAND_INFO name; then
    jxl::assocarray_at name _JXL_COMMAND_INFO name
    printf '%s\n' "$name"
    return 0
  fi
  # shellcheck disable=SC2154  # funcstack is zsh's; guarded by the bash test
  if [[ -n ${BASH_VERSION:-} ]]; then
    printf '%s\n' "${FUNCNAME[3]:-jxl}"
  else
    printf '%s\n' "${funcstack[4]:-jxl}"
  fi
}


# ========== Argument parsing and help ==========

function jxl::std_opt() {
  # Consume one standard option. Returns 0 if it was one of ours, 1 if the caller must
  # handle it. Shebang scripts use this from their own parse_cli:
  #
  #   -*)  jxl::std_opt "$arg" || jxl::die "Unexpected option: ${arg}" ;;
  #
  # --help sets a flag rather than printing and exiting, because an exit here would take
  # the user's interactive shell down in `isolation inline` mode.
  case "$1" in
    --verbose | -v)               _JXL_VERBOSE=1 ;;
    --debug)                      _JXL_DEBUG=1 ;;
    --dry-run)                    _JXL_DRY_RUN=1 ;;
    --help | -help | -h | '-?')   _JXL_WANT_HELP=1 ;;
    *)                            return 1 ;;
  esac
  return 0
}

function jxl::_parse_std_opts() {
  # Consume the standard options; whatever is left goes to $_JXL_CLI_ARGS.
  local arg
  local -a leftover=()

  while [[ $# -ge 1 ]]; do
    arg="$1"; shift
    if ! jxl::std_opt "$arg"; then
      leftover+=("$arg")
    fi
  done

  _JXL_CLI_ARGS=( ${leftover[@]+"${leftover[@]}"} )
}

function jxl::command_help() {
  # Assemble a help screen from $_JXL_COMMAND_INFO plus the shared options block.
  local headline='' synopsis='' options=''

  if jxl::assocarray_has _JXL_COMMAND_INFO usage_headline; then
    jxl::assocarray_at headline _JXL_COMMAND_INFO usage_headline
  fi
  if jxl::assocarray_has _JXL_COMMAND_INFO synopsis_args; then
    jxl::assocarray_at synopsis _JXL_COMMAND_INFO synopsis_args
  fi
  if jxl::assocarray_has _JXL_COMMAND_INFO options; then
    jxl::assocarray_at options _JXL_COMMAND_INFO options
  fi

  printf '\n'
  if [[ -n $headline ]]; then
    printf '%s - %s\n\n' "${PROGRAM_NAME:-???}" "$headline"
  fi
  printf 'Usage:\n  %s %s\n\n' "${PROGRAM_NAME:-???}" "$synopsis"
  printf 'Options:\n'
  if [[ -n $options ]]; then
    printf '%s\n' "$options"
  fi
  jxl::std_options_help
  printf '\n'
}

function jxl::std_options_help() {
  # The options every JX command takes. Scripts interpolate this into their own usage().
  cat <<'EOF'
    -v, --verbose   verbose output
        --debug     debug output
        --dry-run   report what would be done, without doing it
    -h, --help      display help
EOF
}


# ========== Messaging ==========

function jxl::info()    { jxl::emit "$*"; }
function jxl::warning() { jxl::emit "WARNING: $*"; }
function jxl::error()   { jxl::emit "ERROR: $*"; }
function jxl::die()     { jxl::error "$*"; exit 1; }
function jxl::verbose() { if jxl::is_verbose; then jxl::info "$*"; fi; }
function jxl::debug()   { if jxl::is_debug;   then jxl::info "debug: $*"; fi; }

function jxl::emit() {
  # All diagnostics go to stderr, including progress and success -- stdout is reserved for
  # the program's actual work product.
  local msgline="$*"
  if [[ ${_JXL_EMIT_PROGNAME:-0} == 1 ]]; then
    msgline="${PROGRAM_NAME:-???}: ${msgline}"
  fi
  if [[ ${_JXL_EMIT_TIMESTAMP:-0} == 1 ]]; then
    msgline="$(jxl::now): ${msgline}"
  fi
  echo >&2 "$msgline"
}

function jxl::now() { date +'%Y-%m-%d %H:%M:%S'; }

# A bare [[ ]] is already the return status, so no if/then/else wrapper is needed.
# The fallback chain matches jxl::_seed_std_vars, so these read correctly at source time too,
# before any per-invocation state exists. Keep the two in sync.
function jxl::is_verbose() { [[ ${_JXL_VERBOSE:-${JXL_VERBOSE:-${VERBOSE:-0}}} != 0 ]]; }
function jxl::is_debug()   { [[ ${_JXL_DEBUG:-${JXL_DEBUG:-${DEBUG:-0}}}       != 0 ]]; }
function jxl::is_dry_run() { [[ ${_JXL_DRY_RUN:-0} != 0 ]]; }


# ========== Dry run ==========

function jxl::dry()     { jxl::info "dry-run: would:" "$@"; }
function jxl::dry_vrb() { jxl::verbose "dry-run: would:" "$@"; }

function jxl::wet() {
  # Run a command, or just report it when this is a dry run.
  if jxl::is_dry_run; then jxl::dry "$@"; else jxl::verbose 'running:' "$@"; "$@"; fi
}

function jxl::wet_vrb() {
  # Same, but the dry-run report is verbose-only.
  if jxl::is_dry_run; then jxl::dry_vrb "$@"; else jxl::verbose 'running:' "$@"; "$@"; fi
}

function jxl::forbid_dry_run() {
  if jxl::is_dry_run; then
    jxl::die "dry-run is not implemented for this functionality yet. Aborted. Sorry"
  fi
}


# ========== Timing ==========

# tick/tock rather than tic/toc: /usr/bin/tic is the terminfo compiler, and these get
# short-name wrappers that would otherwise shadow it.
function jxl::tick() { date +%s; }
function jxl::tock() { local t0="$1" t1; t1=$(jxl::tick); echo $((t1 - t0)); }

function jxl::s2mmss() {
  local sec="$1"
  local h m s
  h=0; m=$((sec / 60)); s=$((sec % 60))
  if [[ $m -ge 60 ]]; then
    h=$((m / 60)); m=$((m % 60))
    printf '%02d:%02d:%02d' "$h" "$m" "$s"
  else
    printf '%02d:%02d' "$m" "$s"
  fi
}

function jxl::say_tock() {
  local label="$1" t0="$2" te
  te=$(jxl::tock "$t0")
  jxl::info "$(printf 'Elapsed time: %s: %s' "$label" "$(jxl::s2mmss "$te")")"
}

function jxl::timeit() {
  local label="$1"; shift
  if [[ $# == 0 ]]; then
    jxl::die "BUG: jxl::timeit called with too few arguments"
  fi
  local t0
  t0=$(jxl::tick)
  "$@"
  jxl::say_tock "$label" "$t0"
}


# ========== Array accessors ==========
#
# Numeric array subscripts diverge silently between the shells -- ${a[0]} is the second
# element in zsh -- so these exist to give one 0-based meaning in both.
#
# These index by POSITION IN ITERATION ORDER, not by the shell's native subscript. For an
# array built the normal way -- assigned as a whole list, or appended to with += -- those
# are the same thing in both shells, and that is all JXL itself uses.
#
# They part company once you assign past the end, because the shells do not even agree on
# whether arrays are sparse. After `a=(1 2 3); a[7]=7`:
#
#   bash   sparse:  4 elements, ${a[3]} is unset, ${a[7]} is 7
#   zsh    dense:   back-fills 4..6 with empty strings, so ${#a[@]} is 7
#
# So jxl::array_len reports 4 under bash and 7 under zsh for those same two lines, and
# jxl::array_at 3 gives bash's fourth element (7) rather than bash's unset subscript 3.
# Deliberately not worked around: nothing here uses sparse arrays, and matching bash's
# subscript space would mean giving up the one thing these are for, a single meaning that
# holds in both shells.

function jxl::array_at() {
  # jxl::array_at OUT_VAR ARRAY_NAME INDEX
  #
  # Copying the array into $@ sidesteps subscripts entirely: positional parameters are
  # 1-based in both shells, so `shift $idx` then $1 is uniformly 0-based. The [@]+ guard
  # is
  # required because expanding an empty array under `nounset` errors in bash 3.2 (but not
  # in zsh). `eval "$_out=\$1"` never re-parses the value; eval sees the literal text.
  local _out="$1" _name="$2" _idx="$3"

  eval "set -- \${${_name}[@]+\"\${${_name}[@]}\"}"
  if [[ $_idx -lt 0 || $_idx -ge $# ]]; then
    jxl::error "jxl::array_at: index ${_idx} out of range for \$${_name} (length $#)"
    return 1
  fi
  shift "$_idx"
  eval "$_out=\$1"
}

function jxl::array_len() {
  # jxl::array_len OUT_VAR ARRAY_NAME
  local _out="$1" _name="$2"
  eval "set -- \${${_name}[@]+\"\${${_name}[@]}\"}"
  eval "$_out=$#"
}

function jxl::assocarray_at() {
  # jxl::assocarray_at OUT_VAR ARRAY_NAME KEY
  #
  # Emulated associative array: one flat array of alternating key/value entries, walked
  # two
  # at a time. Returns 1 if the key is absent, 2 if the table has an odd length.
  #
  # Under `set -o nounset` a missing key also reports an error, in the spirit of the
  # shell's own unbound-variable check -- it returns rather than exiting, because this has
  # to be safe inside an `isolation inline` command function.
  local _out="$1" _name="$2" _key="$3"

  eval "set -- \${${_name}[@]+\"\${${_name}[@]}\"}"
  if [[ $(( $# % 2 )) -ne 0 ]]; then
    jxl::error "jxl::assocarray_at: \$${_name} has an odd number of entries ($#);" \
        "want key/value pairs"
    return 2
  fi
  while [[ $# -ge 2 ]]; do
    if [[ $1 == "$_key" ]]; then
      eval "$_out=\$2"
      return 0
    fi
    shift 2
  done
  if [[ -o nounset ]]; then
    jxl::error "jxl::assocarray_at: \$${_name} has no key: ${_key}"
  fi
  return 1
}

function jxl::assocarray_has() {
  # jxl::assocarray_has ARRAY_NAME KEY -- quiet presence test, for optional keys.
  local _name="$1" _key="$2"

  eval "set -- \${${_name}[@]+\"\${${_name}[@]}\"}"
  if [[ $(( $# % 2 )) -ne 0 ]]; then
    return 2
  fi
  while [[ $# -ge 2 ]]; do
    if [[ $1 == "$_key" ]]; then return 0; fi
    shift 2
  done
  return 1
}


# ========== Misc utilities ==========

function jxl::max_strlen() {
  local str width=0
  for str in "$@"; do
    if [[ ${#str} -gt $width ]]; then
      width=${#str}
    fi
  done
  echo "$width"
}

function jxl::quote_elem() {
  # jxl::quote_elem VALUE -- print VALUE for a diagnostic listing (an array element, a
  # $PATH entry), single-quoted if it is empty or contains whitespace or a quote.
  # Not real shell-quoting, just enough that "c d" cannot be mistaken for two elements;
  # nothing re-parses this output.
  local _val="$1"
  case "$_val" in
    '') printf "''" ;;
    *[[:space:]\']*)
      printf "'%s'" "${_val//\'/\'\\\'\'}"
      ;;
    *) printf '%s' "$_val" ;;
  esac
}

function jxl::strjoin() {
  # jxl::strjoin DELIM [STR...] -- join arguments with DELIM, to stdout.
  #
  # `IFS=x; "${arr[*]}"` does this natively in both shells, but only for a single-character
  # delimiter, only from an array, and only by touching IFS. This has none of those limits.
  #
  # Not the ${out:+${out}$delim} accumulator idiom: that reads an empty accumulator as
  # unset, so a leading empty argument loses its delimiter.
  local _jxl_strjoin_delim="$1"; shift
  local _jxl_strjoin_out='' _jxl_strjoin_s _jxl_strjoin_first=1

  for _jxl_strjoin_s in "$@"; do
    if [[ $_jxl_strjoin_first == 1 ]]; then
      _jxl_strjoin_out="$_jxl_strjoin_s"
      _jxl_strjoin_first=0
    else
      _jxl_strjoin_out="${_jxl_strjoin_out}${_jxl_strjoin_delim}${_jxl_strjoin_s}"
    fi
  done
  printf '%s\n' "$_jxl_strjoin_out"
}

function jxl::strsplit() {
  # jxl::strsplit OUT_ARRAY_NAME STRING [DELIM] -- split STRING on DELIM (default ":").
  #
  # Empty components are dropped: callers split config strings into patterns and arguments,
  # where an empty element is never meant and often harmful (`--exclude-dir=`, `-name ''`).
  #
  # String surgery, not `for x in $str`: zsh does not word-split unquoted expansions even
  # with IFS set. Same reason as jx_maybe_add_path in bashy-paths.sh.
  local _jxl_strsplit_out="$1" _jxl_strsplit_rest="$2" _jxl_strsplit_delim="${3-:}"
  local _jxl_strsplit_item
  local -a _jxl_strsplit_parts=()

  # An empty delimiter would match everywhere and never shrink $rest.
  if [[ -z $_jxl_strsplit_delim ]]; then
    jxl::error "jxl::strsplit: DELIM must not be empty"
    return 1
  fi
  while [[ -n $_jxl_strsplit_rest ]]; do
    # "$delim" quoted in all three patterns: unquoted, a delimiter of "*" becomes a glob
    # that matches strings not containing it, and the loop spins forever.
    case "$_jxl_strsplit_rest" in
      *"$_jxl_strsplit_delim"*)
        _jxl_strsplit_item="${_jxl_strsplit_rest%%"$_jxl_strsplit_delim"*}"
        _jxl_strsplit_rest="${_jxl_strsplit_rest#*"$_jxl_strsplit_delim"}"
        ;;
      *)
        _jxl_strsplit_item="$_jxl_strsplit_rest"
        _jxl_strsplit_rest=''
        ;;
    esac
    if [[ -n $_jxl_strsplit_item ]]; then
      _jxl_strsplit_parts+=("$_jxl_strsplit_item")
    fi
  done
  # Escaped $ so eval's own parse expands the array, keeping elements with spaces intact.
  eval "$_jxl_strsplit_out=( \${_jxl_strsplit_parts[@]+\"\${_jxl_strsplit_parts[@]}\"} )"
}

function jxl::thous() {
  # Format numbers with thousands separators.
  local py_script s
  local -a vals
  if [[ $# = 0 ]]; then
    # shellcheck disable=SC2207  # splitting stdin on any whitespace is the point here
    vals=($(cat))
  else
    vals=("$@")
  fi
  py_script='import sys; s = sys.argv[1]'
  py_script="$py_script"'; x = float(s) if "." in s else int(s); print(f"{x:,}")'
  for s in ${vals[@]+"${vals[@]}"}; do
    python3 -c "$py_script" "$s"
  done
}

function jxl::_short_names() {
  # Populates the caller's $_jxl_names array. One source of truth, since both
  # jxl::use_short_names and jxl::show_shell_info need the list.
  #
  # thous is deliberately absent -- a name worth leaving free, since it often gets defined
  # by hand for interactive use. Call jxl::thous when a script needs it.
  _jxl_names=(
    info warning error die emit verbose debug
    is_verbose is_debug is_dry_run
    dry dry_vrb wet wet_vrb forbid_dry_run
    tick tock s2mmss say_tock timeit max_strlen
  )
}

function jxl::_is_function() {
  # Portable "is this name a function?" -- `typeset -f` works in both shells.
  typeset -f "$1" >/dev/null 2>&1
}


# ========== Short names ==========

# shellcheck disable=SC2120  # takes its own options; callers pass none, by design
function jxl::use_short_names() {
  # Define unprefixed wrappers -- info, die, wet -- for the jxl:: functions.
  #
  # Usage: jxl::use_short_names [--safe] [--dry-run]
  #
  #   --safe      define only names that are not already a function, alias, or command on
  #               $PATH. Use this from an `isolation inline` command function, where a
  #               redefinition would persist in the user's interactive shell.
  #   --dry-run   report what would happen and define nothing. For debugging JXL itself.
  #
  # Shebang scripts call this; rc files deliberately do not, so an interactive shell never
  # has ~19 common words claimed by JXL.
  #
  # Reports what it did through jxl::debug, naming anything it redefined or shadowed --
  # a silent redefinition of someone else's `error` is a miserable thing to debug.
  local arg safe=0 dry_run=0
  while [[ $# -ge 1 ]]; do
    arg="$1"; shift
    case "$arg" in
      --safe)      safe=1 ;;
      --dry-run)   dry_run=1 ;;
      *)
        jxl::error "jxl::use_short_names: unexpected argument: ${arg}"
        return 2
        ;;
    esac
  done

  local -a _jxl_names
  jxl::_short_names

  local name kind defined='' redefined='' shadowed_alias='' shadowed_cmd='' skipped=''
  for name in "${_jxl_names[@]}"; do
    # Quoted, or `kind=command` reads as an assignment from a command's output (SC2209).
    kind='none'
    if jxl::_is_function "$name";            then kind='function'
    elif alias "$name" >/dev/null 2>&1;      then kind='alias'
    elif command -v "$name" >/dev/null 2>&1; then kind='command'
    fi

    case "$kind" in
      function)  redefined="${redefined:+${redefined}, }${name}" ;;
      alias)     shadowed_alias="${shadowed_alias:+${shadowed_alias}, }${name}" ;;
      command)   shadowed_cmd="${shadowed_cmd:+${shadowed_cmd}, }${name}" ;;
    esac

    if [[ $safe == 1 && $kind != none ]]; then
      skipped="${skipped:+${skipped}, }${name}"
      continue
    fi
    defined="${defined:+${defined}, }${name}"
    if [[ $dry_run == 0 ]]; then
      eval "function ${name}() { jxl::${name} \"\$@\"; }"
    fi
  done

  local msg
  if [[ $dry_run == 1 ]]; then
    msg='Would define short-name JXL functions.'
  else
    msg='Defined short-name JXL functions.'
  fi
  if [[ -z $redefined$shadowed_alias$shadowed_cmd ]]; then
    msg="$msg Nothing redefined or shadowed."
  else
    [[ -n $redefined ]]      && msg="$msg Redefined functions: ${redefined}."
    [[ -n $shadowed_alias ]] && msg="$msg Shadowed aliases: ${shadowed_alias}."
    [[ -n $shadowed_cmd ]]   && msg="$msg Shadowed commands: ${shadowed_cmd}."
  fi
  [[ -n $skipped ]] && msg="$msg Skipped (--safe): ${skipped}."
  jxl::debug "$msg"
}



# ========== Diagnostics ==========

function jxl::show_shell_info() {
  # Dump JXL's state and the shell it is running in, for debugging JXL or a command built
  # on it.
  #
  # Writes to stdout: for a diagnostic, the report IS the work product.
  #
  # Most of the invocation state only exists while a script or command function is
  # running, so calling this from a bare prompt correctly shows those as unset. Calling it
  # from inside an impl is where it earns its keep.
  local exports shell_name='?' shell_ver='?' depth='?'

  # One fork, then membership tests against the result. bash prints `declare -x FOO=...`
  # and zsh prints `export FOO=...`, but both contain " FOO=", which is all we check.
  exports=$(export -p 2>/dev/null || true)

  if [[ -n ${BASH_VERSION:-} ]]; then
    shell_name=bash; shell_ver="$BASH_VERSION"; depth="${BASH_SUBSHELL:-?}"
  elif [[ -n ${ZSH_VERSION:-} ]]; then
    # shellcheck disable=SC2154  # ZSH_SUBSHELL is zsh's; guarded by the version test
    shell_name=zsh;  shell_ver="$ZSH_VERSION";  depth="${ZSH_SUBSHELL:-?}"
  fi

  printf 'JXL %s\n' "${_JXL_VERSION:-<not loaded>}"
  printf '  loaded from: %s\n' "${_JXL_LIB_PATH:-<unknown>}"
  printf '\n'
  printf 'Shell: %s %s   subshell depth: %s\n' "$shell_name" "$shell_ver" "$depth"
  printf 'Call stack: %s\n' "$(jxl::_call_stack)"
  printf '\n'

  printf 'Caller-set interface:\n'
  local v
  for v in VERBOSE DEBUG JXL_VERBOSE JXL_DEBUG TRACE JXL_NO_READONLY; do
    jxl::show_var "$v" "$exports"
  done
  printf '\n'

  printf 'Invocation state:\n'
  for v in PROGRAM_NAME _JXL_VERBOSE _JXL_DEBUG _JXL_DRY_RUN _JXL_WANT_HELP \
           _JXL_EMIT_PROGNAME _JXL_EMIT_TIMESTAMP; do
    jxl::show_var "$v" "$exports"
  done
  printf '\n'

  printf 'Shell options:\n'
  jxl::_show_options
  printf '\n'

  printf 'Short-name functions:\n'
  jxl::_show_short_names
}

function jxl::show_var() {
  # jxl::show_var NAME [EXPORTS [WIDTH]] -- one report line: "NAME SIGILS = value", or
  # "NAME (unset)". Used by jxl::show_shell_info and by jx::shell_info's variable listing.
  #
  # EXPORTS is the pre-fetched output of `export -p`; pass it once per report rather than
  # forking per variable. Omit it to skip the exported sigil. WIDTH is the name column
  # width (see jxl::max_strlen); default 20.
  #
  # Sigils, in a fixed two-column field so "=" stays aligned: @ array, % associative array,
  # ^ exported -- type first, then export, so both sigil-bearing and plain names line up in
  # the same leftmost column. A multi-line value gets its continuation lines indented so
  # they cannot be mistaken for the next variable.
  local _name="$1" _exports="${2:-}" _width="${3:-20}"
  local _set _kind _sigils

  eval "_set=\${${_name}+x}"
  if [[ -z ${_set:-} ]]; then
    printf '  %-*s    (unset)\n' "$_width" "$_name"
    return 0
  fi

  jxl::_show_var_kind _kind "$_name"

  _sigils=''
  case "$_kind" in
    array) _sigils='@' ;;
    assoc) _sigils='%' ;;
  esac
  if [[ -n $_exports ]]; then
    case "$_exports" in
      *" ${_name}="*) _sigils="${_sigils}^" ;;
    esac
  fi

  case "$_kind" in
    array|assoc)
      local _rendered
      jxl::_show_var_render_array _rendered "$_name" "$_kind"
      printf '  %-*s %-2s = %s\n' "$_width" "$_name" "$_sigils" "$_rendered"
      ;;
    *)
      local _val _first=1 _l
      eval "_val=\$${_name}"
      # <<< always appends a trailing newline, so a plain one-line value still round-trips
      # through this loop exactly once -- no separate single-line code path needed.
      while IFS= read -r _l; do
        if [[ $_first == 1 ]]; then
          printf '  %-*s %-2s = %s\n' "$_width" "$_name" "$_sigils" "$_l"
          _first=0
        else
          printf '      %s\n' "$_l"
        fi
      done <<< "$_val"
      ;;
  esac
}

function jxl::_show_var_kind() {
  # jxl::_show_var_kind OUT_VAR NAME -- sets OUT_VAR to scalar, array, or assoc.
  #
  # `typeset -p NAME`'s first word plus flags differ completely by shell and by whether the
  # name is exported: bash says "declare -a NAME=", "declare -ax NAME=", or "declare -x
  # NAME="; zsh says the array forms with a leading "-g" (jx-lint-ok: bash4 -- prose, not
  # code) or, for an exported *scalar* specifically, the bare form "export NAME=" with no
  # "typeset" and no flags at all. Stripping the three known command words and checking
  # what flag letters remain handles every combination uniformly; "declare"/"typeset" as
  # literal words already contain an 'a', so the strip has to happen before the a/A check,
  # not instead of it.
  #
  # The internal working variable is deliberately not named the same as any out-var callers
  # pass in: an early version used "_kind" here too, and eval "$_out=$_k" silently wrote to
  # THIS frame's own local instead of escaping to the caller whenever a caller's out-var
  # happened to be called "_kind" -- everything downstream then misread as scalar.
  local _out="$1" _name="$2" _line _prefix _flags _k

  _line=$(typeset -p "$_name" 2>/dev/null | head -1)
  _prefix="${_line%%"${_name}="*}"
  _flags="${_prefix#declare }"
  _flags="${_flags#typeset }"
  _flags="${_flags#export }"
  case "$_flags" in
    *A*) _k=assoc ;;
    *a*) _k=array ;;
    *)   _k=scalar ;;
  esac
  eval "$_out=$_k"
}

function jxl::_show_var_render_array() {
  # jxl::_show_var_render_array OUT_VAR NAME KIND -- render NAME's elements as
  # "( e1 e2 ... )", quoting elements that need it (see jxl::quote_elem). KIND is
  # "array" or "assoc"; assoc elements render as [key]=value and only ever occur under
  # zsh -- bash 3.2 has no native associative arrays, so jxl::_show_var_kind can never
  # produce "assoc" there, and this branch is simply never reached under bash.
  local _out="$1" _name="$2" _kind="$3"
  local _buf='' _elem _key

  if [[ $_kind == assoc ]]; then
    if [[ -n ${ZSH_VERSION:-} ]]; then
      # zsh-only key expansion, ${(k)...}. Wrapped in eval so it is a string to bash's
      # parser rather than literal syntax -- unlike _JXL_LIB_PATH's ${(%):-%x} above, this
      # needs no shellcheck disable, and bash -n never has to parse it at all.
      local -a _keys
      eval "_keys=(\"\${(k)${_name}[@]}\")"
      for _key in "${_keys[@]}"; do
        eval "_elem=\"\${${_name}[\$_key]}\""
        _buf="${_buf:+${_buf} }[$(jxl::quote_elem "$_key")]=$(jxl::quote_elem "$_elem")"
      done
    fi
  else
    eval "set -- \${${_name}[@]+\"\${${_name}[@]}\"}"
    for _elem in "$@"; do
      _buf="${_buf:+${_buf} }$(jxl::quote_elem "$_elem")"
    done
  fi
  eval "$_out=\"( \$_buf )\""
}

function jxl::_show_options() {
  # The options JXL cares about, in two groups: the `set -o` ones both shells share, then
  # bash's shopt-only ones. Anything absent in this shell is skipped rather than reported
  # as off, so bash 3.2 does not claim to have globstar.
  local opt line=''
  for opt in errexit nounset pipefail noclobber noglob allexport xtrace verbose; do
    if [[ -o $opt ]]; then
      line="${line:+${line}  }${opt}=on"
    else
      line="${line:+${line}  }${opt}=off"
    fi
  done
  printf '  %s\n' "$line"

  if [[ -z ${BASH_VERSION:-} ]]; then
    return 0
  fi
  line=''
  for opt in nocasematch nullglob failglob dotglob nocaseglob extglob xpg_echo \
             expand_aliases globstar lastpipe; do
    if shopt -q "$opt" 2>/dev/null; then
      line="${line:+${line}  }${opt}=on"
    elif shopt -u "$opt" 2>/dev/null; then
      # Naming it succeeded, so it exists here and is off. (shopt -u on an already-unset
      # option is a no-op, so this costs nothing.)
      line="${line:+${line}  }${opt}=off"
    fi
  done
  printf '  %s\n' "$line"
}

function jxl::_show_short_names() {
  # Which of the unprefixed wrappers exist, and whether they are actually JXL's.
  local -a _jxl_names
  jxl::_short_names

  local name defined='' foreign='' missing=''
  for name in "${_jxl_names[@]}"; do
    if ! jxl::_is_function "$name"; then
      missing="${missing:+${missing}, }${name}"
    elif typeset -f "$name" 2>/dev/null | grep -q "jxl::${name}"; then
      defined="${defined:+${defined}, }${name}"
    else
      foreign="${foreign:+${foreign}, }${name}"
    fi
  done

  if [[ -n $defined ]]; then printf '  JXL wrappers: %s\n' "$defined"; fi
  if [[ -n $foreign ]]; then printf '  defined but NOT JXL: %s\n' "$foreign"; fi
  if [[ -n $missing ]]; then printf '  not defined: %s\n' "$missing"; fi
}

function jxl::_call_stack() {
  # Innermost first. The first frames are always this diagnostic's own plumbing.
  #
  # Per-frame subshell attribution is not available in either shell -- there is no record
  # of which frame forked -- so the depth is reported once, above, rather than per frame.
  local -a frames=()
  local f out=''

  if [[ -n ${BASH_VERSION:-} ]]; then
    frames=( ${FUNCNAME[@]+"${FUNCNAME[@]}"} )
  else
    # shellcheck disable=SC2154  # funcstack is zsh's; guarded by the bash test
    frames=( ${funcstack[@]+"${funcstack[@]}"} )
  fi
  for f in ${frames[@]+"${frames[@]}"}; do
    out="${out:+${out} < }${f}"
  done
  printf '%s\n' "${out:-<top level>}"
}


# ========== Load notice ==========

jxl::debug "JXL ${_JXL_VERSION} loaded from ${_JXL_LIB_PATH}"

# Borrowed from Perl's `1;` at the end of a module: `source` returns the status of the
# LAST command in the file, so without this the caller's "did it load?" check would be at
# the mercy of whatever statement happened to come last. Now a zero status means control
# reached the bottom of this file.
true

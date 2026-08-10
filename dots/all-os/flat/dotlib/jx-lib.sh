# jx-lib.sh - JX support functions etc.
#
# This is sourced by bashyrc.sh, so it is available in interactive shells. It's part
# of my bashyrc. It's a separate file just for source code organization, because bashyrc
# is getting pretty long.

# shellcheck shell=bash

# Dotfiles debugging tools

function jx-shell-info() {
  # Thin wrapper: jxl::run_command owns the JXL locals, so adding one later touches the
  # library instead of every command function. Default isolation runs the impl in a
  # subshell, which is right here -- this command only reports, and never changes the
  # shell it is called from.
  local path_mode=pretty path_width='' do_jxl=0
  # shellcheck disable=SC2016  # $COLUMNS below is prose, not an expansion
  local -a _JXL_COMMAND_INFO=(
    usage_headline 'Dump some info about this shell and its configuration'
    synopsis_args  '[--long-path | -p | --raw-path] [--width N] [--jxl]'
    options        '    -p, --long-path   print PATH one entry per line
        --raw-path    print PATH verbatim, one line, ":"-separated
        --width N     wrap PATH to N columns instead of $COLUMNS
        --jxl         also dump JXL'"'"'s own state (jxl::show_shell_info)'
  )
  jxl::run_command jx::shell_info "$@"
}

function jx::shell_info_parse_cli() {
  # Gets whatever jxl::run_command did not consume; hands back what it does not want.
  local arg
  local -a leftover=()
  while [[ $# -ge 1 ]]; do
    arg="$1"; shift
    case "$arg" in
      --long-path | -p)   path_mode=long ;;
      --raw-path)         path_mode=raw ;;
      --width)
        path_width="$1"; shift
        case "$path_width" in
          ''|*[!0-9]*) jxl::die "--width wants a positive integer, got: ${path_width}" ;;
        esac
        ;;
      --jxl)              do_jxl=1 ;;
      *)                  leftover+=("$arg") ;;
    esac
  done
  _JXL_CLI_ARGS=( ${leftover[@]+"${leftover[@]}"} )
}

function jx::shell_info() {
  # TODO: Show which order Homebrew and MacPorts are loaded in, in a more
  # concise manner than the $PATH.

  local shell_info java_ver java_ver_str ruby_info exports

  # Detect this current shell
  # Hack: assume common shell variables have been neither clobbered nor exported
  #
  # Every reference needs a :- default: the identifying variable of one shell is by
  # definition unset in the others, and JXL runs command impls under nounset.
  if [[ -n ${ZSH_ARGZERO:-} ]]; then
    shell_info="zsh ${ZSH_VERSION:-} (${ZSH_ARGZERO:-})"
  elif [[ -n ${BASH:-} ]]; then
    shell_info="bash ${BASH_VERSION:-} (${BASH:-})"
  elif [[ -n ${KSH_VERSION:-} ]]; then
    shell_info="ksh ${KSH_VERSION:-}"
  else
    shell_info='?'
  fi

  if command -v java &>/dev/null; then
    java_ver=$(java --version | head -1)
    java_ver_str="($java_ver)"
  fi

  # One fork for every jxl::show_var call below to share, rather than one each.
  exports=$(export -p 2>/dev/null || true)

  cat <<EOS
Shell state from jx dotfiles:

Shell: ${shell_info} on $(uname -m)

EOS
  jx::shell_info_std_vars "$exports"
  jx::shell_info_custom_vars "$exports"

  cat <<EOS
Java:
  java = $(command -v java 2>/dev/null)  ${java_ver_str:-}
  JAVA_HOME = ${JAVA_HOME:-}

EOS
  if command -v ruby &>/dev/null; then
    cat <<EOS
Ruby:
  ruby = $(command -v ruby)  $(ruby --version)
  rvm = $(command -v rvm 2>/dev/null)
  bundle = $(command -v bundle 2>/dev/null)
  GEM_HOME = ${GEM_HOME:-}
  GEM_PATH = ${GEM_PATH:-}

EOS
  fi
cat <<EOS
Python:
  python = $(command -v python 2>/dev/null)
  PYTHONPATH = ${PYTHONPATH:-}

${ruby_info:-}Commands:
  conda = $(command -v conda 2>/dev/null)
  mamba = $(command -v mamba 2>/dev/null)
  brew = $(command -v brew 2>/dev/null)
  port = $(command -v port 2>/dev/null)

EOS
  jx::shell_info_jx_vars "$exports"
  jx::shell_info_local_files
  jx::shell_info_internal_state "$exports"

  local path_width_effective
  if [[ -n $path_width ]]; then
    path_width_effective="$path_width"
  else
    # $COLUMNS is not always merely unset -- a non-interactive/non-tty environment can
    # export it as a literal "0" (observed in practice), which would otherwise sail
    # through this fallback chain and silently produce degenerate one-entry-per-line
    # output with no indication why. Non-numeric or non-positive counts as unusable, same
    # as unset, for both $COLUMNS and the tput fallback.
    path_width_effective="${COLUMNS:-}"
    case "$path_width_effective" in ''|*[!0-9]*|0) path_width_effective='' ;; esac
    if [[ -z $path_width_effective ]]; then
      path_width_effective=$(tput cols 2>/dev/null) || true
      case "$path_width_effective" in ''|*[!0-9]*|0) path_width_effective='' ;; esac
    fi
    : "${path_width_effective:=80}"
  fi
  jx::shell_info_path "$path_mode" "$path_width_effective"

  if [[ $do_jxl == 1 ]]; then
    printf '\n'
    jxl::show_shell_info
  fi
}

function jx::shell_info_std_vars() {
  # Well-known variables that outside programs read, e.g. $EDITOR by a spawned editor.
  local exports="$1" v width
  local -a names=(EDITOR VISUAL GUIEDITOR PAGER LESS CLICOLOR LSCOLORS LS_COLORS)

  width=$(jxl::max_strlen "${names[@]}")
  printf 'Standard variables:\n'
  for v in "${names[@]}"; do
    jxl::show_var "$v" "$exports" "$width"
  done
  printf '\n'
}

function jx::shell_info_custom_vars() {
  # My own variables that predate the JX_ prefix convention. Probably just DROPBOX
  # forever, but written as a list so adding another is a one-line change. Omitted
  # entirely when none of them are set, rather than printing an empty heading.
  local exports="$1" v is_set width
  local -a names=(DROPBOX)
  local -a set_names=()

  for v in "${names[@]}"; do
    eval "is_set=\${${v}+x}"
    if [[ -n ${is_set:-} ]]; then
      set_names+=("$v")
    fi
  done
  if [[ ${#set_names[@]} -eq 0 ]]; then
    return 0
  fi

  width=$(jxl::max_strlen "${set_names[@]}")
  printf 'JX custom variables:\n'
  for v in "${set_names[@]}"; do
    jxl::show_var "$v" "$exports" "$width"
  done
  printf '\n'
}

function jx::shell_info_jx_vars() {
  # Every currently-set JX_* variable, found by sweeping `set` for names only and then
  # letting normal expansion (via jxl::show_var) produce the value -- unlike the old
  # `set | grep ^JX_` one-liner, this renders identically in bash and zsh even for
  # arrays and multi-line values, which `set`'s own syntax does not.
  #
  # Union'd with a hardcoded list of known JX_* names, so a knob that has never been set
  # (JX_TRACE_SHELL_STARTUP, say) is still discoverable -- under --verbose, since showing
  # every unset knob by default would bury the ones actually in use. An unrecognized
  # JX_FOO still appears via discovery even if this list goes stale.
  local exports="$1" jx_line v width
  local -a set_names=()
  local -a known_names=(
    JX_CONDA_AUTOACTIVATE JX_CONDA_AUTOLOAD JX_ENV_LOADED
    JX_GRIN_EXCLUDE_DIRS JX_GRIN_EXCLUDE_FILES
    JX_HOMEBREW_PREFIX JX_MACPORTS_PREFIX JX_NVM_AUTOLOAD JX_OMZ_DEBUG JX_OMZ_DEBUG_DIR
    JX_OMZ_THEME JX_PREZTO_THEME JX_RUBY_AUTOLOAD_ENVMGR JX_TRACE_SHELL_STARTUP
    JX_USE_HOMEBREW JX_USE_MACPORTS JX_ZSH_CONFIGURATOR
  )

  while IFS= read -r jx_line || [[ -n $jx_line ]]; do
    set_names+=("$jx_line")
  done < <(set | grep '^JX_[A-Za-z0-9_]*=' | sed -e 's/=.*//' | sort -u)

  local -a report_names=( ${set_names[@]+"${set_names[@]}"} )
  if jxl::is_verbose; then
    local set_joined=" ${set_names[*]+"${set_names[*]}"} "
    for v in "${known_names[@]}"; do
      case "$set_joined" in
        *" ${v} "*) ;;
        *) report_names+=("$v") ;;
      esac
    done
  fi

  width=$(jxl::max_strlen ${report_names[@]+"${report_names[@]}"})
  printf 'JX dotfiles variables:\n'
  for v in ${report_names[@]+"${report_names[@]}"}; do
    jxl::show_var "$v" "$exports" "$width"
  done
  printf '\n'
}

function jx::shell_info_local_files() {
  # Presence of the optional per-machine/site files the rc files load if found -- see
  # profile.sh, zshenv.zsh, and this file's own "Per-machine/site local definitions"
  # below, plus zprofile.zsh and bashy-paths.sh's $HOME/bin-local. Present ones always
  # show; absent ones only under --verbose, so a clean setup does not bury the report in
  # files that were never expected to exist.
  local f width n
  local -a names=(
    .profile-site .profile-user .profile-local
    .zshenv-site .zshenv-user .zshenv-local
    .bashyrc-site .bashyrc-user .bashyrc-local
    .zprofile-local
    bin-local
  )

  n=0
  width=$(jxl::max_strlen "${names[@]}")
  printf 'Local files:\n'
  for f in "${names[@]}"; do
    if [[ -e $HOME/$f ]]; then
      n=$(( n + 1 ))
      printf '  %-*s present\n' "$width" "$f"
    elif jxl::is_verbose; then
      printf '  %-*s absent\n' "$width" "$f"
    fi
  done
  if [[ $n == 0 ]]; then
    echo '  (none present)'
  fi
  printf '\n'
}

function jx::shell_info_internal_state() {
  # JX's own _JX_* internal variables, --verbose only -- these are implementation
  # details, not something to check on every run. Only _JX_DEBUG exists today.
  if ! jxl::is_verbose; then
    return 0
  fi
  local exports="$1" v width
  local -a names=(_JX_DEBUG)

  width=$(jxl::max_strlen "${names[@]}")
  printf 'Internal state:\n'
  for v in "${names[@]}"; do
    jxl::show_var "$v" "$exports" "$width"
  done
  printf '\n'
}

function jx::shell_info_path() {
  # jx::shell_info_path MODE [WIDTH] -- MODE is "pretty" (default, greedy-wrapped and
  # quoted, WIDTH required), "long" (one entry per line, no quoting needed since there is
  # no ambiguity to quote against), or "raw" (today's old default: one ":"-joined line).
  #
  # $PATH is walked with parameter-expansion string surgery, not `for x in $PATH` or an
  # array -- zsh does not word-split unquoted expansions even with IFS=:, unlike bash. Same
  # idiom bashy-paths.sh's jx_maybe_add_path already uses for the same reason.
  local mode="$1" width="${2:-80}"
  local rest item quoted line count=0
  local -a lines=()

  case "$mode" in
    raw)
      printf 'PATH: %s\n\n' "${PATH:-}"
      return 0
      ;;
    long)
      printf 'PATH:\n'
      rest="${PATH:-}"
      while [[ -n $rest ]]; do
        case "$rest" in
          *:*) item="${rest%%:*}"; rest="${rest#*:}" ;;
          *)   item="$rest"; rest='' ;;
        esac
        printf '  %s\n' "$item"
      done
      printf '\n'
      return 0
      ;;
  esac

  # pretty (default): greedy word-wrap, one pass -- count entries and build wrapped lines
  # together, so $PATH is walked once, not twice. An entry alone longer than $width still
  # gets its own line rather than being truncated: the first token of a line is always
  # accepted regardless of length, same as ordinary text-wrap conventions.
  local avail=$(( width - 2 ))
  rest="${PATH:-}"
  while [[ -n $rest ]]; do
    case "$rest" in
      *:*) item="${rest%%:*}"; rest="${rest#*:}" ;;
      *)   item="$rest"; rest='' ;;
    esac
    count=$(( count + 1 ))
    quoted=$(jxl::quote_elem "$item")
    if [[ -z ${line:-} ]]; then
      line="$quoted"
    elif [[ $(( ${#line} + 1 + ${#quoted} )) -le $avail ]]; then
      line="${line} ${quoted}"
    else
      lines+=("$line")
      line="$quoted"
    fi
  done
  if [[ -n ${line:-} ]]; then
    lines+=("$line")
  fi

  if [[ $count == 1 ]]; then
    printf 'PATH (1 entry):\n'
  else
    printf 'PATH (%d entries):\n' "$count"
  fi
  for line in ${lines[@]+"${lines[@]}"}; do
    printf '  %s\n' "$line"
  done
  printf '\n'
}

# bashyrc.sh - common bashlike (bash/zsh/sh) interactive configuration
#
# This has common configuration for interactive bash or zsh shells. So the syntax
# must be compatible with both.

# shellcheck shell=bash
# shellcheck disable=SC1091

# JXL, for the command functions further down. See "Loading JXL" in dots/README.md.
if ! source "$HOME/.dotlib/jxl-lib.sh"; then
  echo >&2 "bashyrc.sh: ERROR: Failed loading JXL from ~/.dotlib/jxl-lib.sh." \
      "The jx-* commands will not work. Need to run install-dotfiles?"
fi

# Call uname once and stash results for performance
if [[ -z $__jx_uname ]]; then
  __jx_uname=$(uname)
fi


# Editor and tool selection

# TODO: Determine which of these env vars should clobber and which should inherit.

export PAGER="${PAGER:-less}"
export LESS="${LESS:-R}"
export CLICOLOR=1

export EDITOR="${EDITOR:-vi}"
if command -v code &>/dev/null; then
  export VISUAL="${VISUAL:-code}"
  export GUIEDITOR="${GUIEDITOR:-code}"
else
  export VISUAL="${VISUAL:-vi}"
  if command -v gvim &>/dev/null; then
    export GUIEDITOR="${GUIEDITOR:-gvim}"
  fi
fi

function jx-rainbow-me() {
  # Enable rainbow colorization in file listing
  export CLICOLOR=1
  export LSCOLORS=gx

  alias l='ls | lolcat'
  alias la='ls -la | lolcat'
}


# Tool and command customization

# ls customization

# shellcheck disable=SC2010
if ls --version 2> /dev/null | grep GNU &> /dev/null; then
  # ls is GNU ls: color on by default
  alias ls="ls --color --quoting-style=literal"
elif [[ $__jx_uname = "Darwin" ]] || [[ $__jx_uname = "FreeBSD" ]]; then
  # On BSD, prefer GNU ls for nicer colors
  # (Unsure if I really want to do this, bc of gls' uneven column widths)
  # As of 2023-12, I disabled this for now.
  # if command -v gls &>/dev/null && gls --color -d . &>/dev/null; then
  #   alias ls="gls --color --quoting-style=literal"
  # fi
  :
fi
if command -v gls &>/dev/null; then
  alias gls="gls --color"
fi

# (In zsh, this may be overridden by the theme when using OMZ, but it provides a default.)
# bashyrc gets called *after* the Zsh configurator, so you need to respect defaults instead
# of clobbering here.
export LSCOLORS="${LSCOLORS:-gxxxdxdxdxexexdxdxgxgx}"
# Same baseline as LSCOLORS, in different (GNU) format
if [[ -z ${LS_COLORS:-} ]]; then
  export LS_COLORS="di=36:so=33:pi=33:ex=33:bd=34:cd=34:su=33:sg=33:tw=36:ow=36"
  # GNU-specific extras
  LS_COLORS="${LS_COLORS}:ln=00;04"
fi


# MacOS specifics

if [[ $__jx_uname = "Darwin" ]]; then

  # TODO: Conditionalize all Homebrew stuff on Homebrew being installed, and add
  # MacPorts equivalents.

  # Make $JAVA_HOME defined by default, based on what's installed in the Mac
  # system Frameworks area
  if [[ -z $JAVA_HOME ]]; then
    __my_java_home=$(/usr/libexec/java_home 2> /dev/null)
    if [[ $? = 0 ]]; then
      export JAVA_HOME="$__my_java_home"
    fi
  fi

  # manp - view a man page in Preview
  function manp {
    man -t "$@" | open -f -a Preview &
  }

  # manb - view a man page in the browser
  # (Requires man2html and browser from Homebrew or MacPorts)
  function manb {
    man "$*" | man2html -title "man $*" | browser
  }

  # Empty the Trash etc on all mounted volumes
  function emptytrash() {
    sudo rm -rfv /Volumes/*/.Trashes
    sudo rm -rfv ~/.Trash
    # Also, clear Apple’s System Logs to hopefully improve shell startup speed
    # Actually, disable that: I just copy-pasted it from somewhere and don't really
    # understand what it does.
    # sudo rm -rfv /private/var/log/asl/*.asl
  }

  # MacPorts setup

  # MacPorts puts itself on the path at the system level (I think), so we don't have
  # to load it, just detect whether it's there.
  if command -v port &>/dev/null; then
    export JX_MACPORTS_PREFIX
    JX_MACPORTS_PREFIX=$(dirname "$(dirname "$(command -v port)")")
  fi

  # Homebrew setup

  function jx-load-homebrew() {
    local -a _cand_brew_prefixes
    local _brew_prefix
    # This detects the Intel vs. Apple Silicon location, plus non-default locations.
    # The default /usr/local on Intel will already be on the default PATH.
    _cand_brew_prefixes=(
      '/opt/homebrew'
      '/usr/local'
      '/usr/local/homebrew'
    )
    for _brew_prefix in "${_cand_brew_prefixes[@]}"; do
      if [[ -f ${_brew_prefix}/bin/brew ]]; then
        # Homebrew tries not to replace system commands, so at end of path should be fine?
        export JX_HOMEBREW_PREFIX="$_brew_prefix"
        PATH="${JX_HOMEBREW_PREFIX}/bin:${JX_HOMEBREW_PREFIX}/sbin:$PATH"
        break
      fi
    done
  }

  if [[ $JX_USE_HOMEBREW = 1 ]]; then
    # Load Homebrew
    jx-load-homebrew

    # brew configuration
    # export HOMEBREW_DEVELOPER=1
    export HOMEBREW_EDITOR=code
    export HOMEBREW_NO_AUTO_UPDATE=1
    # I like to do my cleanup separately, to avoid long and variant log spam when doing
    # big installs.
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_ENV_HINTS=1

    # My custom brew aliases and wrappers

    alias brew-repo='cd $(brew --repo)'
    alias brew-core='cd $(brew --repo)/Library/Taps/homebrew/homebrew-core/Formula'
    alias brew-octave='cd $(brew --repo)/Library/Taps/octave-app/homebrew-octave-app/Formula'

  fi  # end Homebrew stuff

  # Miscellaneous macOS stuff

  alias plistbuddy='/usr/libexec/PlistBuddy'

  # Command line JavaScript
  alias jsc=/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/Resources/jsc

  # Enable core dumps
  ulimit -c unlimited
fi


# Languages and dev platforms

if [[ -f $HOME/.dotlib/bashy-langs.sh ]]; then
  source "$HOME/.dotlib/bashy-langs.sh"
fi


# Aliases and misc interactive stuff

alias cls="clear"

alias l="ls -oG"
alias la="ls -a"
alias ll="ls -lh"
alias lla="ls -lha"
alias lsa='ls -lah'
alias lso="ls -og"
# Order by last modified, long form no user group, color
alias lt="ls -toG"
# List all except . and ..., color, mark file types, long form no user group, file size
alias laa="ls -AGFoh"

alias tree="tree -I '.git|.svn|*.swp'"
alias duh="du -csh"
alias fn='find . -iname'

# Grepping and finding

# grin - grep with exclusions
function grin()  { grep -rIn    "${JX_GRIN_EXCLUDES[@]}" "$@"; }
function griin() { grep -rIn -i "${JX_GRIN_EXCLUDES[@]}" "$@"; }
JX_GRIN_EXCLUDES=(
  --exclude-dir=.git --exclude-dir=.cvs --exclude-dir=.hg --exclude-dir=.svn
  --exclude-dir=venv --exclude-dir=.venv --exclude-dir=node_modules
  --exclude-dir=wp-includes
  '--exclude=*.ipynb'
)
# recursive grep, excluding big dumb managed subdirs
# This is prob redundant with, and inferior to, 'grin' now, and can prob be ditched soon.
alias grepx="grep -rIn --exclude-dir=node_modules --exclude-dir=dist --exclude=package-lock.json"
# Delegates to grin so the exclusions live in one place; grin always adds -n, so strip
# the leading "N:" grep -o leaves on every match before deduping.
function grhino() { grin -ho "$@" | cut -d: -f2- | sort -u; }

# Do a find but exclude .git repo directories
# Generify: expand to cover .svn, .cvs, .venv etc., and rename
function find-no-git {
  local dir="$1"; shift
  local args=( "$@" )
  find "$dir" \( -type d -name .git -prune \) -o "${args[@]}"
}


# Git stuff

alias gfpt='git fetch --prune --tags'
alias gc='git commit -v'
# alias gpforce='git push --force-with-lease'
alias gpushforce='git push --force-with-lease'
alias gco='git checkout'

alias gst='git status'
alias gdc='git diff | cat'
# 'glol' disabled to avoid shadowing OMZ's own 'glol' alias
# alias glol='git log --oneline'
# old 'glo' alias kept for muscle memory reasons while I consider switching to 'glol'
alias glo='git log --oneline'
glolh() { local n=${1:-20}; git --no-pager log --oneline -n "$n"; }
alias gloh=glolh
gpom()  { local cmd=(git pull origin main); echo >&2 "${cmd[*]}"; "${cmd[@]}"; }
# Open any files marked as “modified” in my default editor.
# TODO: This looks Mac-specific bc of the 'open' command?
alias geditchanged='open `git status --porcelain | sed -ne "s/^ M //p"`'
# This intentionally clobbers a Prezto 'gbc' alias; I prefer mine.
alias gbc="git branch | cat"

# I mis-type "code" as "cod" often enough that I prefer it now.
alias cod=code

# Hacks around default behavior that I dislike

alias ffprobe="ffprobe -hide_banner"
alias gdb="gdb -q"  # suppress banner
alias octave="octave -q"  # suppress banner
alias octave-default="octave-default -q"  # suppress banner
alias octave-stable="octave-stable -q"  # suppress banner

# Directory navigation

alias -- -='cd -'  # '-' = 'cd -'
# Disable this simple "~" alias bc (as of 2026) I think it might interfere with built-in shell stuff?
# alias ~="cd ~"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cd..='cd ..'
alias cd...='cd ../..'
alias cd....='cd ../../..'

# Disable pd, bc I don't use it enough to have that shorthand memorized.
# alias pd=pushd

function mkcd() { mkdir -p "$1"; cd "$1" || return; }

function wwhich() {
  if command -v "$1" &>/dev/null; then
    ls -loG "$(command -v "$1")"
  else
    command -v "$1"
  fi
}

# Fancycat
alias c="pygmentize -O style=solarized -f console256 -g"

# IP address discovery moved to home-bin-jx/whatsmyip -- these were too big for functions.

# Fun stuff
alias dadjoke="curl https://icanhazdadjoke.com --silent; echo"


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
    JX_CONDA_AUTOACTIVATE JX_CONDA_AUTOLOAD JX_ENV_LOADED JX_GRIN_EXCLUDES
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

# Dropbox
#
# How the hell do I locate this now, in its "new" OS-supported locations, esp. on macOS?
#
# On macOS, ~/Dropbox got moved to ~/Library/CloudStorage/Dropbox in like 2024, and having a
# symlink to it seems to mess things up, like with Spotlight maybe. Let's try having an alias
# and a path variable to handle that. And make that setup unconditional (not depending on
# whether that ~/Library dir exists), to avoid bad paths from the collapse of an undefined
# $DROPBOX variable etc. I really liked having a ~/Dropbox for keyboard navigation in Finder,
# but as of 2026-03 I'm going to try to do without, bc I think the symlink may be messing other
# things up, and bc I want to figure out how this is "supposed to" be used.

if [[ $__jx_uname = "Darwin" ]]; then
  if [[ -d $HOME/Library/CloudStorage/Dropbox ]]; then
    export DROPBOX="$HOME/Library/CloudStorage/Dropbox"
  else
    export DROPBOX=''
  fi
else
  # I don't know where Dropbox lives on Linux, Windows, or WSL these days. Handle that later.
  # But keep the variables defined to avoid collapse.
  export DROPBOX='/I/dont/know/where/Dropbox/lives/on/this/platform'
fi
alias dbox='cd "$DROPBOX"'

# Per-machine/site local definitions
#
# jx::* and _jx_source_maybe are defined in .profile, which always runs before this file.
#
# TODO: This should maybe also pulled from an XDG "local" config dir instead of just special
# files I made up?
for __where in site user local; do
  _jx_source_maybe "${HOME}/.bashyrc-${__where}"
done
unset __where

# Cleanup

unset __jx_uname

# bashyrc.sh - common bashlike (bash/zsh/sh) interactive configuration
#
# This has common configuration for interactive bash or zsh shells. So the syntax
# must be compatible with both.

# shellcheck shell=bash
# shellcheck disable=SC1091

# Call uname once and stash results for performance
if [[ -z $__uname ]]; then
  __uname=$(uname)
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
elif [[ $__uname = "Darwin" ]] || [[ $__uname = "FreeBSD" ]]; then
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
if [[ -z "${LS_COLORS:-}" ]]; then
  export LS_COLORS="di=36:so=33:pi=33:ex=33:bd=34:cd=34:su=33:sg=33:tw=36:ow=36"
  # GNU-specific extras
  LS_COLORS="${LS_COLORS}:ln=00;04"
fi


# MacOS specifics

if [[ $__uname = "Darwin" ]]; then

  # TODO: Conditionalize all Homebrew stuff on Homebrew being installed, and add
  # MacPorts equivalents.

  # Make $JAVA_HOME defined by default, based on what's installed in the Mac
  # system Frameworks area
  if [[ -z $JAVA_HOME ]]; then
    __my_java_home=$(/usr/libexec/java_home 2>/dev/null)
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
      if [[ -f "${_brew_prefix}/bin/brew" ]]; then
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

if [[ -f "$HOME/.dots/bashy-langs.sh" ]]; then
  source "$HOME/.dots/bashy-langs.sh"
fi


# Aliases and misc interactive stuff

alias cls="clear"
# recursive grep, excluding big dumb managed subdirs
alias grepx="grep -RIn --exclude-dir=node_modules --exclude-dir=dist --exclude=package-lock.json"

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

# IP address discovery
alias myip='IP=`dig +short myip.opendns.com @resolver1.opendns.com`; echo "${IP}"; echo "${IP}" | pbcopy'
alias lip='IP=`ipconfig getifaddr en0`; echo "${IP}"; echo "${IP}" | pbcopy'
alias whatismyip='curl ifconfig.me; echo'

# Fun stuff
alias dadjoke="curl https://icanhazdadjoke.com --silent; echo"


# Dotfiles debugging tools

function jx-shell-info() {
  # Dump some info about this shell and its configuration

  # TODO: Show which order Homebrew and MacPorts are loaded in, in a more
  # concise manner than the $PATH.

  local flag OPTIND do_long_path
  while getopts 'p' flag; do
    case "${flag}" in
      p) do_long_path=1 ;;
      *) echo >&2 "jx-shell-info: Unrecognized option: $flag"; return 1 ;;
    esac
  done

  local shell_info java_ver java_ver_str ruby_info

  # Detect this current shell
  # Hack: assume common shell variables have been neither clobbered nor exported
  if [[ -n $ZSH_ARGZERO ]]; then
    shell_info="zsh ${ZSH_VERSION:-} ($ZSH_ARGZERO)"
  elif [[ -n $BASH ]]; then
    shell_info="bash $BASH_VERSION ($BASH)"
  elif [[ -n $KSH_VERSION ]]; then
    shell_info="ksh $KSH_VERSION"
  else
    shell_info='?'
  fi

  if command -v java &>/dev/null; then
    java_ver=$(java --version | head -1)
    java_ver_str="($java_ver)"
  fi

  cat <<EOS
Shell state from jx dotfiles:

Shell: ${shell_info} on $(uname -m)

Vars:
  EDITOR = ${EDITOR}  VISUAL = ${VISUAL}  GUIEDITOR = ${GUIEDITOR}

Java:
  java = $(command -v java 2>/dev/null)  ${java_ver_str}
  JAVA_HOME = ${JAVA_HOME}

EOS
  if command -v ruby &>/dev/null; then
    cat <<EOS
Ruby:
  ruby = $(command -v ruby)  $(ruby --version)
  rvm = $(command -v rvm 2>/dev/null)
  bundle = $(command -v bundle 2>/dev/null)
  GEM_HOME = ${GEM_HOME}
  GEM_PATH = ${GEM_PATH}

EOS
  fi
cat <<EOS
Python:
  python = $(command -v python 2>/dev/null)
  PYTHONPATH = ${PYTHONPATH}

${ruby_info}Commands:
  conda = $(command -v conda 2>/dev/null)
  mamba = $(command -v mamba 2>/dev/null)
  brew = $(command -v brew 2>/dev/null)
  port = $(command -v port 2>/dev/null)

JX dotfiles variables:
$(set | grep ^JX_ | sed -e 's/^/  /')

EOS
  if [[ $do_long_path = 1 ]]; then
    # shellcheck disable=SC2001
    cat <<EOS
PATH:
  $(echo "$PATH" | sed -e 's/:/\n  /g')

EOS
  else
    cat <<EOS
PATH: ${PATH}

EOS
  fi
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

if [[ $__uname = "Darwin" ]]; then
  if [[ -d $HOME/Library/CloudStorage/Dropbox ]]; then
    DROPBOX="$HOME/Library/CloudStorage/Dropbox"
  else
    DROPBOX=''
  fi
else
  # I don't know where Dropbox lives on Linux, Windows, or WSL these days. Handle that later.
  # But keep the variables defined to avoid collapse.
  DROPBOX='/I/dont/know/where/Dropbox/lives/on/this/platform'
fi
alias dbox='cd "$DROPBOX"'

# Allow for machine- or environment-local overrides
#
# TODO: This should maybe be pulled from an XDG "local" config dir instead of a special file
# I made up?
if [[ -f "${HOME}/.bashyrc-local" ]]; then
  source "${HOME}/.bashyrc-local"
fi


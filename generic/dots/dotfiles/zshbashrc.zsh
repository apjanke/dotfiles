# .zshbashrc for apjanke
#
# (configuration common to bash and zsh interactive shells)
#
# This has common configuration for interactive bash or zsh shells. The syntax must
# be compatible with both.
#
# This deals mostly with configuration for external commands, and not the shells' 
# internal behavior.

# Aliases and environment

export TERMINFO_DIRS=~/.terminfo:$TERMINFO
TERMINFO=""

# Misc stuff
alias cls="clear"
alias la="ls -a"
alias ll="ls -lh"
alias lla="ls -lha"
alias lsa='ls -lah'
alias lso="ls -og"
alias tree="tree -I '.git|.svn|*.swp'"
alias duh="du -csh"
# Git stuff
alias gst='git status'
alias gc='git commit -v'
alias gco='git checkout'
# Hacks around default behavior that I dislike
alias ffprobe="ffprobe -hide_banner"
alias gdb="gdb -q"  # suppress banner
alias grep='grep --exclude-dir={.bzr,.cvs,.git,.hg,.svn}'
# Directory navigation
# (Same as OMZ lib/completion)
alias -- -='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias cd..='cd ..'
alias cd...='cd ../..'
alias cd....='cd ../../..'

#  Paths and commands  #

function maybe_add_path() {
  if [ -d "$1" ]; 
    then PATH="$PATH:$1"; 
  fi
}

# Prefer local binaries
PATH="/usr/local/bin:$PATH"
# Alternate Homebrew locations
if [ -d "/homebrew" ]; then PATH="/homebrew/bin:$PATH"; fi
# Get my local dirs on the path
if [ -d "$HOME/bin" ]; then PATH="$HOME/bin:$PATH"; fi
# Hack: unconditionally load the Ruby gem location I've been working with
maybe_add_path "$HOME/.gem/ruby/2.0.0/bin"

export GOPATH=$HOME/local/go-work
maybe_add_path "$HOME/local/go-work/bin"

# ls customization
uname=`uname`
if ls --version 2>/dev/null | grep GNU &>/dev/null; then
  # Color on by default
  alias ls="ls --color"
elif [ $uname = "Darwin" ] || [ $uname = "FreeBSD" ]; then
  # On BSD, prefer GNU ls for nicer colors
  # (Unsure if I really want to do this, b/c of gls' uneven column widths)
  if which gls &>/dev/null && gls --color -d . &>/dev/null; then
    alias ls="gls --color"
  fi
fi
if which gls &>/dev/null; then
  alias gls="gls --color"
fi

#  Command configuration  #

export PAGER="less"
export LESS="-R"
export CLICOLOR=1
export EDITOR=vi

#  Mac OS X specifics  #

if [ $uname = "Darwin" ]; then

  # Force /usr/local (for Homebrew, including git) to front of path
  PATH="/usr/local/bin:/usr/local/sbin:$PATH"

  # Detect installed JDK 
  if [ -z $JAVA_HOME ] && /usr/libexec/java_home &> /dev/null; then
    export JAVA_HOME=$(/usr/libexec/java_home)
  fi

  # Set up Sublime Text command line support
  if whence subl &>/dev/null; then
    export VISUAL='subl -w'
    export GUIEDITOR='subl'
  fi

  # manp - view a man page in Preview
  function manp {
    man -t $@ | open -f -a Preview &
  }

  # manb - view a man page in the browser
  # (Requires man2html and browser from homebrew)
  function manb {
    man "$*" | man2html -title "man $*" | browser
  }

  # Homebrew stuff

  export HOMEBREW_DEVELOPER=1
  export HOMEBREW_SANDBOX=1
  alias bas='brew audit --strict --no-test-do-check'
  
  # brewsubl - open a brew formula in subl (doesn't work with taps)
  function brewsubl {
    subl "$(brew --repository)/Library/Formula/${1%%.rb}.rb"
  }

  # brewsublogs - open the brew logs dir for a formula in subl
  function brewsublogs {
    local logdir=~/Library/Logs/Homebrew/$1
    if [ -e $logdir ]; then
      subl $logdir
    else
      print "No such directory: $logdir"
      return 1
    fi
  }

  # brew-gist-logs - brew gist-logs wrapper, with login support
  function brew-gist-logs() {
    if [[ -e ~/.github-token ]]; then
      # Use a subshell so the secret isn't left in main shell's environment
      ( export HOMEBREW_GITHUB_API_TOKEN=$(cat ~/.github-token); brew gist-logs $* )
    else
      echo "~/.github-token not found" >&2
      return 1
    fi
  }

  # Various Homebrew wrappers
  function brew-gist-bug() {
    brew-gist-logs --new-issue $*
  }

  function brew-install-debug() {
    HOMEBREW_MAKE_JOBS=1 brew install -v $* 2>&1
  }

  function brew-build() {
    brew install --build-from-source $*
  }

  function brew-build-debug() {
    HOMEBREW_MAKE_JOBS=1 brew install -v --build-from-source $* 2>&1
  }

  # Command line JavaScript
  alias jsc=/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/Resources/jsc

  # AsciiDoc / DocBook installation
  export XML_CATALOG_FILES=/usr/local/etc/xml/catalog

fi

#  Appearance  #

# (In zsh, this may be overridden by the theme when using OMZ, but it provides a
# default)

export LSCOLORS="gxxxdxdxdxexexdxdxgxgx"
# Same baseline as LSCOLORS
export LS_COLORS="di=36:so=33:pi=33:ex=33:bd=34:cd=34:su=33:sg=33:tw=36:ow=36"
# GNU-specific extras
LS_COLORS="${LS_COLORS}:ln=00;04"

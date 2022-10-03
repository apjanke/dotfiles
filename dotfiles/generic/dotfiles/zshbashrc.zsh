# .zshbashrc for apjanke
#
# (configuration common to bash and zsh interactive shells)
#
# This has common configuration for interactive bash or zsh shells. The syntax must
# be compatible with both.
#
# This deals mostly with configuration for external commands, and not the shells' 
# internal behavior.

uname=`uname`

# Aliases and environment

# Misc stuff
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
alias grin="grep -r -i -n"
alias fn='find . -iname'

# Git stuff
alias g="git"
alias gst='git status'
alias gc='git commit -v'
alias gco='git checkout'
alias gdc='git diff | cat'
alias glo='git log --oneline'
gloc() {
  local n=${1:-10}
  git log --oneline | head -$n
}
gpom() {
  echo git pull origin master
  git pull origin master
}
# Reset previous commit, but keep all the associated changes.
alias goddammit="git reset --soft HEAD^"
# Welp.
alias heckit="git reset --hard HEAD"
# Open any files marked as “modified” in your default editor.
alias geditchanged='open `git status --porcelain | sed -ne "s/^ M //p"`'
# Get rid of Prezto's alias and replace it with my preferred one
alias gbc="git branch | cat"

# I often mis-type "code" as "cod"
alias cod=code

# Hacks around default behavior that I dislike
alias ffprobe="ffprobe -hide_banner"
alias gdb="gdb -q"  # suppress banner
alias grep='grep --exclude-dir={.bzr,.cvs,.git,.hg,.svn}'
alias octave="octave -q"  # suppress banner
alias octave-default="octave-default -q"  # suppress banner
alias octave-stable="octave-stable -q"  # suppress banner
alias octave4="octave@4.4.1 -q"  # suppress banner
alias octave5="octave@5.1.0 -q"  # suppress banner
alias octave6="octave@6.1.0 -q"  # suppress banner
if which brew &>/dev/null; then
  alias octaveapp5='$(brew --prefix octave-octave-app@5.1.0)/bin/octave -q'
fi

# Directory navigation
# (Based on OMZ's lib/completion)
alias -- -='cd -'
alias ~="cd ~"
alias ..='cd ..'
alias ...='cd ../..'
alias cd..='cd ..'
alias cd...='cd ../..'
alias cd....='cd ../../..'
alias pd=pushd
alias ppd=popd
mkcd() {
  mkdir -p "$1"
  cd "$1"
}
alias subl-dotfiles="subl $HOME/Dropbox/\#repos/dotfiles/dotfiles"

# OMZ & Prezto sometimes alias these for "safety" to versions that prompt
# on clobber, etc. I don't want that.
unalias mv 2>/dev/null

# Fancycat™
alias c="pygmentize -O style=solarized -f console256 -g"

# IP address discovery
alias myip='IP=`dig +short myip.opendns.com @resolver1.opendns.com`; echo "${IP}"; echo "${IP}" | pbcopy'
alias lip='IP=`ipconfig getifaddr en0`; echo "${IP}"; echo "${IP}" | pbcopy'

# Copy my public SSH key to the pasteboard
alias pubkey="more ~/.ssh/id_rsa.pub | pbcopy | printf '=> Public key copied to pasteboard.\n'"

# Miscellaneous
alias qemu=qemu-system-x86_64

#  Paths and commands  #

function maybe_add_path() {
  if [[ -d "$1" ]]; then
    if [[ "$2" = "prepend" ]]; then
      PATH="$1:$PATH";
    else
      PATH="$PATH:$1";
    fi
  fi
}

# Prefer local binaries
PATH="/usr/local/bin:$PATH"
# Get my local dirs on the path
maybe_add_path "$HOME/bin" prepend
if [[ $uname = "Darwin" ]]; then
  maybe_add_path "$HOME/bin/osx" prepend
fi
maybe_add_path "$HOME/bin-local" prepend
maybe_add_path "$HOME/local/bin" prepend
maybe_add_path "$HOME/.local/bin" prepend
# Hack: unconditionally load the Ruby gem location I've been working with
maybe_add_path "$HOME/.gem/ruby/2.6.0/bin" prepend
# Pull in system Ruby
maybe_add_path "/usr/local/lib/ruby/gems/2.6.0/bin" prepend
maybe_add_path "/usr/local/lib/ruby/gems/2.7.0/bin" prepend
maybe_add_path "/usr/local/lib/ruby/gems/3.0.0/bin" prepend
# Get the Homebrew-installed Ruby, including its gems, and have it take
# precedence over system Ruby.
# (I don't really know how Ruby Gems path management is supposed to work)
maybe_add_path "/usr/local/opt/ruby/bin" prepend
# Google depot tools
maybe_add_path "$HOME/local/opt/depot_tools"
maybe_add_path "/Applications/Sublime Text.app/Contents/SharedSupport/bin"

# Optionally installed tools and thingies
# Go
export GOPATH=$HOME/local/go-work
maybe_add_path "$GOPATH/bin"
if [[ -d $HOME/.rvm ]]; then
  PATH="$PATH:$HOME/.rvm/bin"
fi
# DAML
maybe_add_path $HOME/.daml/bin

# ls customization
if ls --version 2>/dev/null | grep GNU &>/dev/null; then
  # Color on by default
  alias ls="ls --color --quoting-style=literal"
elif [[ $uname = "Darwin" ]] || [[ $uname = "FreeBSD" ]]; then
  # On BSD, prefer GNU ls for nicer colors
  # (Unsure if I really want to do this, b/c of gls' uneven column widths)
  if which gls &>/dev/null && gls --color -d . &>/dev/null; then
    alias ls="gls --color --quoting-style=literal"
  fi
fi
if which gls &>/dev/null; then
  alias gls="gls --color --quoting-style=literal"
fi

function wwhich() {
  if which $1 &>/dev/null; then
    ls -loG $(which $1)
  else
    which $1
  fi
}

#  Command configuration

export PAGER="less"
export LESS="-R"
export CLICOLOR=1
export EDITOR=vi

#  MacOS specifics

if [[ $uname = "Darwin" ]]; then

  # TODO: Conditionalize all Homebrew stuff on Homebrew being installed, and add
  # MacPorts equivalents.

  # Force /usr/local (for Homebrew, including git) to front of path
  PATH="/usr/local/sbin:$PATH"

  # Pick up new /opt/homebrew location
  if [[ -d /opt/homebrew/bin ]]; then
    PATH="/opt/homebrew/bin:$PATH"
  fi

  # Detect installed JDK 
  if [[ -z $JAVA_HOME ]] && /usr/libexec/java_home &> /dev/null; then
    export JAVA_HOME=$(/usr/libexec/java_home)
  fi

  # Set up Sublime Text command line support
  if whence subl &>/dev/null; then
    export VISUAL='code'
    export GUIEDITOR='code'
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

  # Empty the Trash on all mounted volumes and the main HDD
  # Also, clear Apple’s System Logs to improve shell startup speed
  alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"
  
  # Homebrew stuff

  export HOMEBREW_DEVELOPER=1
  export HOMEBREW_SANDBOX=1
  export HOMEBREW_EDITOR=subl
  export HOMEBREW_NO_AUTO_UPDATE=1
  alias bas='brew audit --strict'
  alias baso='brew audit --strict --online'
  alias brew-repo='cd $(brew --repo)'
  alias brew-core='cd $(brew --repo)/Library/Taps/homebrew/homebrew-core/Formula'
  alias brew-apjanke='cd $(brew --repo)/Library/Taps/apjanke/homebrew-personal/Formula'
  alias brew-octave='cd $(brew --repo)/Library/Taps/octave-app/homebrew-octave-app/Formula'
  alias bpull='brew pull --branch-okay'
  alias bpullb='brew pull --branch-okay --bottle'
  alias bsr='brew style --rspec --display-cop-names'
  alias plistbuddy='/usr/libexec/PlistBuddy'

  # brew-gist-logs - brew gist-logs wrapper, with login support
  function brew-gist-logs() {
    if [[ -e ~/.ssh/github-token ]]; then
      # Use a subshell so the secret isn't left in main shell's environment
      ( export HOMEBREW_GITHUB_API_TOKEN=$(cat ~/.ssh/github-token); brew gist-logs $* )
    else
      echo "~/.ssh/github-token not found" >&2
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

  # MacPorts stuff

  # Load NVM from MacPorts.
  # NVM initialization is too slow for me to want it on every shell startup, so stick it
  # inside a function I'll call manually when I want NVM.
  # This function only loads from the MacPorts location, but I'll expand it if I start using
  # NVM from other installation methods, so use the generic name "nvm-load".
  function nvm-load() {
    if [ -e /opt/local/share/nvm/init-nvm.sh ]; then
      source /opt/local/share/nvm/init-nvm.sh
    fi
  }

  # Enable rainbow colorization in file listing
  function rainbow-me() {
    export CLICOLOR=1
    export LSCOLORS=gx

    alias l='ls | lolcat' 
    alias la='ls -la | lolcat'
  }

  # Command line JavaScript
  alias jsc=/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/Resources/jsc

  # AsciiDoc / DocBook installation
  # TODO: This location is Homebrew-specific; update it with MacPorts and maybe other locations.
  export XML_CATALOG_FILES=/usr/local/etc/xml/catalog

  # Enable core dumps
  ulimit -c unlimited

  # Find Matlab
  function locate-matlab-on-mac() {
    if ! which matlab &> /dev/null; then
      # Prefer newer versions
      want_matlab_rels=(R2023b R2023a R2022b R2022a R2021b R2021a R2020b R2020a R2019b R2019a R2018b R2018a R2017b R2017a)
      # I actually am specifically on R2019b now
      want_matlab_rels=(R2019b $want_matlab_rels)
      for matlab_rel in "${want_matlab_rels[@]}"; do
        matlab_app="/Applications/MATLAB_${matlab_rel}.app"
        if [[ -f "$matlab_app/bin/matlab" ]]; then
          PATH="$PATH:$matlab_app/bin"
          break
        fi
      done
    fi
  }
  locate-matlab-on-mac
fi

# Appearance

# (In zsh, this may be overridden by the theme when using OMZ, but it provides a
# default)

export LSCOLORS="gxxxdxdxdxexexdxdxgxgx"
# Same baseline as LSCOLORS
export LS_COLORS="di=36:so=33:pi=33:ex=33:bd=34:cd=34:su=33:sg=33:tw=36:ow=36"
# GNU-specific extras
LS_COLORS="${LS_COLORS}:ln=00;04"

# Allow for machine- or environment-local overrides
if [[ -f $HOME/.zshbashrc-local ]]; then
  source $HOME/.zshbashrc-local
fi

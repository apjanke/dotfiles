# This is not the standard .zhsrc from oh-my-zsh. I wrote my own 
# based on it; it invokes oh-my-zsh, but sets other stuff too

# Debugging prompt with timestamp for profiling under `zsh -x`
#PS4=$'+ %D{%s.%6.} %N:%i> '

if type brew &>/dev/null; then
  HOMEBREW_PREFIX=$(brew --prefix)
fi

# Convert TERMINFO to a multi-entry path and pick up Homebrew's terminfo
# TODO: detect whether $TERMINFO_DIRS is supported on this system
() {
  if [[ -z $TERMINFO_DIRS ]]; then
    export TERMINFO_DIRS=~/.terminfo
    if [[ -n $HOMEBREW_PREFIX ]]; then
      TERMINFO_DIRS="$TERMINFO_DIRS:$HOMEBREW_PREFIX/share/terminfo"
    fi
    if [[ -n $TERMINFO ]]; then
      TERMINFO_DIRS="$TERMINFO_DIRS:$TERMINFO"
      TERMINFO=""
    fi
    # Include the default location
    TERMINFO_DIRS="$TERMINFO_DIRS:" 
  fi
}

# Pick up additional site-functions that may not be on system zsh's
# $fpath by default
() {
  local site_dir site_dirs

  site_dirs=( /usr/local/share/zsh/site-functions )
  if [[ -n $HOMEBREW_PREFIX ]]; then
    site_dirs+=$HOMEBREW_PREFIX/share/zsh/site-functions
  fi
  for site_dir ( $site_dirs ); do
    if [[ -d $site_dir  && ${fpath[(I)$site_dir]} == 0 ]]; then
      FPATH=$site_dir:$FPATH
    fi
  done
}

# Default $TMPPREFIX may be insecure
if [[ $OSTYPE == Darwin* ]]; then
  TMPPREFIX=$TMPDIR/zsh
fi

# OH-MY-ZSH or other Zsh Configurator

# Load selected configurator, falling back to stock if it is not
# installed on this system.

# Valid configurators: "oh-my-zsh", "prezto", or "none"
ZSH_CONFIGURATOR=oh-my-zsh
#ZSH_CONFIGURATOR=prezto
if [[ $ZSH_CONFIGURATOR == "oh-my-zsh" && -d "$HOME/.oh-my-zsh" ]]; then
  #_OMZ_DEBUG=1
  #_OMZ_DEBUG_SMKX=1
  #DISABLE_OH_MY_ZSH_CUSTOM=1
  ZSH_THEME=apjanke-01
  ZSH=${ZSH:-$HOME/.oh-my-zsh}
  plugins=( osx themes nyan brew github )
  source ~/.dotfiles/zshrc-oh-my-zsh.zsh
elif [[ $ZSH_CONFIGURATOR == "prezto" && -d "$HOME/.prezto" ]]; then
  source ~/.dotfiles/zshrc-prezto.zsh
else
  source ~/.dotfiles/zshrc-none.zsh
fi

# Regular non-configurator-driven stuff after here

# Pull in common bash/zsh configuration
if [ -f $HOME/.dotfiles/zshbashrc.zsh ]; then 
  source $HOME/.dotfiles/zshbashrc.zsh; 
fi

# zsh autocorrect is more trouble than it's worth for me; disable it
setopt no_correct
setopt ignore_eof
setopt no_auto_pushd
setopt no_share_history
setopt no_beep
setopt no_interactivecomments

# Completion control

if which omz_bindkey &>/dev/null; then
  function maybe_bindkey() {
    omz_bindkey -t "$@"
  }
else
  function maybe_bindkey() {
    local cap=$1 widget=$2
    if [[ -n ${terminfo[$cap]} ]]; then
      bindkey ${terminfo[$cap]} $widget
    fi
  }
fi

zstyle ':completion:*' rehash true
#zstyle ':completion:*' completer _complete _ignored
#zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
#zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}'

# Leading substring search for history
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

maybe_bindkey "kcuu1" up-line-or-beginning-search      # [Up-Arrow]
maybe_bindkey "kcud1" down-line-or-beginning-search    # [Down-Arrow]
maybe_bindkey "khome" beginning-of-line
maybe_bindkey "kend" end-of-line

#  Git and GitHub stuff  #

# Check out a PR locally
function _apj_print_and_do() {
  echo -E "==>" "$@"
  "$@"
}
function gh-local-pr() {
  emulate -L zsh
  local pr=$1
  local remote=${2:-upstream}
  _apj_print_and_do git fetch $remote pull/$pr/head:pr-$pr \
    || return
  _apj_print_and_do git checkout pr-$pr
}


export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

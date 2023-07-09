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

function is_at_demex () {
  env | grep demex &> /dev/null
}

# Valid configurators: "oh-my-zsh", "prezto", or "none"
ZSH_CONFIGURATOR=oh-my-zsh
if [[ $ZSH_CONFIGURATOR == "oh-my-zsh" && -d "$HOME/.oh-my-zsh" ]]; then
  #_OMZ_DEBUG=1
  #_OMZ_DEBUG_SMKX=1
  #DISABLE_OH_MY_ZSH_CUSTOM=1
  #ZSH_THEME=apjanke-01
  ZSH_DEFAULT_USERS=(janke apjanke andrew.janke@demextech.com ajanke-sa)
  AGNOSTER_PATH_STYLE=shrink
  AGNOSTER_RANDOM_EMOJI_REALLY_RANDOM=1
  AGNOSTER_RANDOM_EMOJI_EACH_PROMPT=1
  AGNOSTER_PROMPT_SEGMENTS=(
    random_emoji
    git
    context
    virtualenv
    vaulted
    dir
    kubecontext
    newline
    status
    blank
  )
  if is_at_demex; then
    ZSH_THEME=apjanke-01
  else
    ZSH_THEME=agnosterj
  fi
  ZSH=${ZSH:-$HOME/.oh-my-zsh}
  plugins=( osx themes )
  source ~/.dotfiles/zshrc-oh-my-zsh.zsh
elif [[ $ZSH_CONFIGURATOR == "prezto" && -d "$HOME/.zprezto" ]]; then
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

# Miscellaneous options
setopt clobber

# Git and GitHub stuff

# Check out a PR locally
# (This is probably superseded by hub now)
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

# For exercism.io
if [[ -f ~/.config/exercism/exercism_completion.zsh ]]; then
  . ~/.config/exercism/exercism_completion.zsh
fi

# Local configuration
if [[ -f ~/.zshrc-local ]]; then
  source ~/.zshrc-local
fi

# Google Cloud SDK.
# (This is a stupid installation location for it.)
() {
if [[ -f "${HOME}/Downloads/google-cloud-sdk/path.zsh.inc" ]]; then
  . "${HOME}/Downloads/google-cloud-sdk/path.zsh.inc"
fi
if [[ -f "${HOME}/Downloads/google-cloud-sdk/completion.zsh.inc" ]]; then
  . "${HOME}/Downloads/google-cloud-sdk/completion.zsh.inc"
fi
}

# Anaconda
function apj-load-conda () {
  # "Load" conda, adding it to the path, but not activating its base env.
  # Call `conda activate` to actually activate it.  
  local -a conda_candidates
  local prefix __conda_setup
  conda_candidates=(
    "$HOME/anaconda3"
    "$HOME/anaconda"
    "$HOME/mambaforge"
    '/opt/mambaforge'
    '/opt/anaconda3'
    '/opt/anaconda'
    '/usr/local/anaconda3'
    '/usr/local/anaconda'
  )
  for prefix in $conda_candidates; do
    # echo "Checking for conda at ${prefix}"
    if [[ -f "${prefix}/bin/conda" ]]; then
      __conda_setup="$('${prefix}/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
      if [[ $? -eq 0 ]]; then
        eval "$__conda_setup"
        # conda deactivate
      else
        if [[ -f "${prefix}/etc/profile.d/conda.sh" ]]; then
          . "${prefix}/etc/profile.d/conda.sh"
        else
          export PATH="${prefix}/bin:$PATH"
        fi
      fi
      echo "Loaded conda from ${prefix}"
      break
    fi
  done
}

# You can also do this:
#   conda config --set changeps1 false
# if you're running Agnoster or another prompt with virtualenv display in it.
# This is a one-time-per-machine thing.

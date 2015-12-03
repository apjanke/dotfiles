# This is not the standard .zhsrc from oh-my-zsh. I wrote my own 
# based on it; it invokes oh-my-zsh, but sets other stuff too

# Pick up additional site-functions that may not be on system zsh's
# $fpath by default
() {
  local site_dir site_dirs

  site_dirs=( /usr/local/share/zsh/site-functions )
  if type brew &>/dev/null; then
    site_dirs+=$(brew --prefix)/share/zsh/site-functions
  fi
  for site_dir ( $site_dirs ); do
    if [[ -d $site_dir  && ${fpath[(I)$site_dir]} == 0 ]]; then
      FPATH=$site_dir:$FPATH
    fi
  done
}

# OH-MY-ZSH

#DISABLE_OH_MY_ZSH=1
#DISABLE_OH_MY_ZSH_CUSTOM=1
#ZSH_THEME=apjanke-02
ZSH=${ZSH:-$HOME/.oh-my-zsh}
if [[ $DISABLE_OH_MY_ZSH != 1 && -d $ZSH ]]; then
  plugins=( osx themes nyan brew )
  source ~/.dotfiles/zshrc-omz.zsh
else
  source ~/.dotfiles/zshrc-no-omz.zsh
fi

#source ~/local/opp/agnoster/agnoster-zsh-theme/agnoster.zsh-theme

# Regular non-oh-my-zsh stuff after here

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

function maybe_bindkey() {
  local cap=$1 widget=$2
  if [[ -n ${terminfo[$cap]} ]]; then
    bindkey ${terminfo[$cap]} $widget
  fi
}

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
maybe_bindkey "kend" beginning-of-line

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

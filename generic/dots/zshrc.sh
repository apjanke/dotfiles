# This is not the standard .zhsrc from oh-my-zsh. I wrote my own 
# based on it; it invokes oh-my-zsh, but sets other stuff too

# OH-MY-ZSH

#DISABLE_OH_MY_ZSH=1
#DISABLE_OH_MY_ZSH_CUSTOM=1
#ZSH_THEME=apjanke-02
ZSH=${ZSH:-$HOME/.oh-my-zsh}
if [[ $DISABLE_OH_MY_ZSH != 1 && -d $ZSH ]]; then
  source ~/.dotfiles/zshrc-omz.zsh
else
  source ~/.dotfiles/zshrc-no-omz.zsh
fi

# Regular non-oh-my-zsh stuff after here

# Pull in common bash/zsh configuration
if [ -f $HOME/.dotfiles/zshbashrc.zsh ]; then source $HOME/.dotfiles/zshbashrc.zsh; fi

# zsh autocorrect is more trouble than it's worth for me; disable it
setopt no_correct
setopt ignore_eof
setopt no_auto_pushd
setopt no_share_history
setopt no_beep
setopt no_interactivecomments

# Completion control
zstyle ':completion:*' rehash true
#zstyle ':completion:*' completer _complete _ignored
#zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
#zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}'

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Leading substring search for history
function maybe_bindkey() {
  local cap=$1 widget=$2
  if [[ -n ${terminfo[$cap]} ]]; then
    bindkey ${terminfo[$cap]} $widget
  fi
}

maybe_bindkey "kcuu1" up-line-or-beginning-search      # [Up-Arrow]
maybe_bindkey "kcud1" down-line-or-beginning-search    # [Down-Arrow]





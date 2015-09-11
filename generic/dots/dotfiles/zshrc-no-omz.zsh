# .zshrc-no-omz
#
# zshrc for use when oh-my-zsh is not being used
# This contains alternate setup for the things in omz that I rely on
#
# Mostly copied from the indicated omz files, with my termsupport changes
#
# Stuff that is covered by my other common setup like .zshbashrc is not included
# here.

bindkey -e

alias cd/='cd /'

# lib/completion.zsh

setopt no_auto_menu

# lib/history.zsh

## Command history configuration
if [[ -z $HISTFILE ]]; then
  HISTFILE=$HOME/.zsh_history
fi

HISTSIZE=10000
SAVEHIST=10000

setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups # ignore duplication command history list
setopt hist_ignore_space
setopt share_history

# lib/termsupport.zsh

function title {
  if [[ $2 == "" ]]; then
    2="$1"
  fi
  if [[ "$EMACS" == *term* ]]; then
    return
  fi
  if [[ "$TERM" == screen* ]]; then
    print -Pn "\ek$1:q\e\\" #set screen hardstatus, usually truncated at 20 chars
  elif [[ "$TERM" == xterm* ]] || [[ $TERM == rxvt* ]] || [[ $TERM == ansi ]] || [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    print -Pn "\e]2;$2:q\a" #set window name
    print -Pn "\e]1;$1:q\a" #set icon (=tab) name (will override window name on broken terminal)
  fi
}

# lib/theme-and-appearance.zsh

# Theme

PS1="%n@%m:%~ $ "
# Make completion LS_COLORS consistent with main LS_COLORS
zstyle -e ':completion:*' list-colors 'reply=${(s.:.)LS_COLORS}'

# Completion

autoload -U compinit
compinit -i




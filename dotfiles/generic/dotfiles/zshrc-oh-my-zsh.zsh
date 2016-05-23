# zshrc-oh-my-zsh.zsh
#
# Logic for loading and configuring Oh My Zsh

# bindkey needs to be done before loading OMZ to hack around a load order issue
bindkey -e

#  Load OMZ  #

ZSH=${ZSH:-$HOME/.oh-my-zsh}

#APJ_OMZ_DEBUG=1
if [[ $APJ_OMZ_DEBUG == 1 ]]; then
  APJ_OMZ_DEBUG_DIR=~/var/oh-my-zsh
  mkdir -p $APJ_OMZ_DEBUG_DIR
  set | sort > $APJ_OMZ_DEBUG_DIR/vars_before_omz.txt
fi

ZSH_THEME_SCM_CHECK_TIMEOUT=0.5
#CASE_SENSITIVE=true
if [[ $DISABLE_OH_MY_ZSH_CUSTOM != 1 ]]; then
  ZSH_CUSTOM=$HOME/.oh-my-zsh-custom
  ZSH_THEME=${ZSH_THEME:-apjanke-01}
else
  ZSH_THEME=${ZSH_THEME:-robbyrussell}
fi
# These themes have problems for me, like bad hg calls
ZSH_BLACKLISTED_THEMES=(rkj-repos)
ZSH_DEFAULT_USER="janke"

#DISABLE_AUTO_TITLE=true
DISABLE_AUTO_UPDATE=true
source $ZSH/oh-my-zsh.sh

if [[ $APJ_OMZ_DEBUG == 1 ]]; then
  set | sort > $APJ_OMZ_DEBUG_DIR/vars_after_omz.txt
  diff -a $APJ_OMZ_DEBUG_DIR/vars_before_omz.txt $APJ_OMZ_DEBUG_DIR/vars_after_omz.txt > $APJ_OMZ_DEBUG_DIR/vars_diff.txt
fi

#  Undo OMZ stuff I don't want  #

function maybe_unalias() {
  if alias $1 &> /dev/null; then
    unalias $1
  fi
}
maybe_unalias ls
maybe_unalias grep
maybe_unalias st
maybe_unalias stt
unfunction maybe_unalias



# zshrc-ohmyzsh.zsh
#
# Logic for loading and configuring Oh My Zsh

# ===== Pre-load setup =====

ZSH=${ZSH:-$HOME/.oh-my-zsh}

# bindkey needs to be done before loading OMZ to hack around a load order issue
bindkey -e

# APJ_OMZ_DEBUG=1
if [[ $APJ_OMZ_DEBUG == 1 ]]; then
  APJ_OMZ_DEBUG_DIR=~/var/ohmyzsh
  mkdir -p $APJ_OMZ_DEBUG_DIR
  set | sort > $APJ_OMZ_DEBUG_DIR/vars_before_omz.txt
fi

ZSH_THEME_SCM_CHECK_TIMEOUT=0.5
#CASE_SENSITIVE=true
if [[ -d $HOME/.ohmyzsh-custom && $DISABLE_OH_MY_ZSH_CUSTOM != 1 ]]; then
  ZSH_CUSTOM=$HOME/.ohmyzsh-custom
  ZSH_THEME=${ZSH_THEME:-apjanke-01}
else
  ZSH_THEME=${ZSH_THEME:-robbyrussell}
fi
# These themes have problems for me, like bad hg calls
ZSH_BLACKLISTED_THEMES=(rkj-repos)

# DISABLE_AUTO_TITLE=true
DISABLE_AUTO_UPDATE=true


# ===== Load ohmyzsh =====

source $ZSH/oh-my-zsh.sh


# ===== Post-load setup =====

if [[ $APJ_OMZ_DEBUG == 1 ]]; then
  set | sort > $APJ_OMZ_DEBUG_DIR/vars_after_omz.txt
  diff -a $APJ_OMZ_DEBUG_DIR/vars_before_omz.txt $APJ_OMZ_DEBUG_DIR/vars_after_omz.txt > $APJ_OMZ_DEBUG_DIR/vars_diff.txt
fi

# Undo OMZ stuff I don't actually want

function maybe_unalias() { if alias $1 &> /dev/null; then unalias $1; fi; }

maybe_unalias ls
maybe_unalias grep
maybe_unalias st
maybe_unalias stt
unfunction maybe_unalias

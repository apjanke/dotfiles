# zshrc-cfgtr-ohmyzsh.zsh
#
# Logic for loading and configuring Oh My Zsh.


# ===== My custom OMZ debugging support =====

function _jx_omz_debug_start() {
  JX_OMZ_DEBUG_DIR="${JX_OMZ_DEBUG_DIR:-${HOME}/var/ohmyzsh}"
  mkdir -p $JX_OMZ_DEBUG_DIR
  set | sort > $JX_OMZ_DEBUG_DIR/vars_before_omz.txt
}

function _jx_omz_debug_finish() {
  set | sort > $JX_OMZ_DEBUG_DIR/vars_after_omz.txt
  diff -a $JX_OMZ_DEBUG_DIR/vars_before_omz.txt $JX_OMZ_DEBUG_DIR/vars_after_omz.txt > $JX_OMZ_DEBUG_DIR/vars_diff.txt
}

# ===== Pre-load setup =====

ZSH=${ZSH:-$HOME/.oh-my-zsh}

# bindkey needs to be done before loading OMZ to hack around a load order issue
bindkey -e

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

if [[ $JX_OMZ_DEBUG == 1 ]]; then _jx_omz_debug_start; fi

source $ZSH/oh-my-zsh.sh

if [[ $JX_OMZ_DEBUG == 1 ]]; then _jx_omz_debug_finish; fi


# ===== Post-load setup =====


# Undo OMZ stuff I don't actually want

function _maybe_unalias() { if alias $1 &> /dev/null; then unalias $1; fi; }

_maybe_unalias ls
_maybe_unalias grep
_maybe_unalias st
_maybe_unalias stt

unfunction _maybe_unalias _jx_omz_debug_start _jx_omz_debug_finish

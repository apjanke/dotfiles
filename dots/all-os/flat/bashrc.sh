# .bashrc for apjanke
#
# (interactive bash configuration)

# shellcheck shell=bash
# shellcheck disable=SC1091

# Pull in profile if not already there. To force a manual re-source, unset JX_ENV_LOADED.
if [[ -z ${JX_ENV_LOADED:-} ]]; then
  source "$HOME/.profile"
fi

if [[ $JX_TRACE_SHELL_STARTUP = 1 ]]; then
  set -o xtrace
fi

# Pull in common bashlike configuration
_jx_source_maybe "$HOME/.dotlib/bashyrc.sh"

# Bash-specific settings

set -o ignoreeof
shopt -s cdspell
# check the window size after each command and update LINES and COLUMNS.
shopt -s checkwinsize
# checkjobs and globstar arrived in bash 4.0; macOS still ships bash 3.2.
if (( BASH_VERSINFO[0] >= 4 )); then
  shopt -s checkjobs
  shopt -s globstar
fi

# History and interaction

HISTSIZE=32768   # Longer history (default is only 500)
HISTFILESIZE="$HISTSIZE"
# no duplicates or lines starting with space.
HISTCONTROL=ignoreboth
HISTIGNORE='&:ls:ls -la:[bf]g:cd:cd -:pwd:exit:date:* --help'
shopt -s histappend
#TODO: Better handle sharing history between concurrent sessions

# Completion

# progcomp_alias arrived in bash 4.1; macOS still ships bash 3.2.
if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 1) )); then
  shopt -s progcomp_alias
fi

if ! shopt -oq posix; then
  # Homebrew completion for when running on macOS
  if command -v brew &> /dev/null; then
    for _completion_file in "$(brew --prefix)"/etc/bash_completion.d/*; do
      source "$_completion_file"
    done
  fi
  unset _completion_file
fi
# Appearance

if [[ $USER = "janke" ]]; then
  export PS1='[\w]\n\$ '
else
  export PS1='[\u@\h: \w]\n\$ '
fi

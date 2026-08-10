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


# History and interaction

# shellcheck disable=SC2034
export HISTSIZE=32768   # Longer history (default is only 500)
export HISTFILESIZE="$HISTSIZE"
export HISTCONTROL=ignoredups
export HISTIGNORE="&:ls:ls *:ls -la:[bf]g:cd:cd -:pwd:exit:date:* --help"
shopt -s histappend

set -o ignoreeof
shopt -s cdspell
shopt -s checkwinsize

# Appearance

if [[ $USER = "janke" ]]; then
  export PS1="[\W] \$ "
else
  export PS1="[\h: \W] \$ "
fi

# Homebrew bash-specifics

if command -v brew &> /dev/null; then
  for _completion_file in "$(brew --prefix)"/etc/bash_completion.d/*; do
    source "$_completion_file"
  done
fi
unset _completion_file

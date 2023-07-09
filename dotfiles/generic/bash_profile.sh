# bash_profile.sh for apjanke
#
# (bash-specific login shell configuration)

# include common bourne/unix configuration
. $HOME/.profile

# include common interactive bash settings
[ -r $HOME/.bashrc ] && . $HOME/.bashrc

# bash-specific login-specific configuration

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*



# bashy-paths.sh - common bashlike path setup
#
# This gets called by bashyrc.sh or .profile. This code could just go inline
# there, but I've factored it out to a separate file to make it easier to switch
# around exactly where in the startup sequence it gets called, while I'm figuring
# out the exact Right Way to arrange all this shell startup stuff. Plus, it
# probably makes things more readable, given how large these startup scripts have
# gotten.

# Call uname once and stash results for performance
if [[ -z $__uname ]]; then
  __uname=$(uname)
fi


function jx_maybe_add_path() {
  if [[ -d "$1" ]]; then
    if [[ "$2" = "prepend" ]]; then
      PATH="$1:$PATH";
    else
      PATH="$PATH:$1";
    fi
  fi
}

# Prefer local installations
PATH="/usr/local/bin:$PATH"

# Custom local dirs defined by this dotfiles framework or just my habits

jx_maybe_add_path "$HOME/bin" prepend
if [[ $__uname = "Darwin" ]]; then
  jx_maybe_add_path "$HOME/bin/osx" prepend
fi
# Sheesh. I haven't been able to settle on a conventional local bin location, have I?
jx_maybe_add_path "$HOME/bin-local" prepend
jx_maybe_add_path "$HOME/local/bin" prepend
jx_maybe_add_path "$HOME/.local/bin" prepend


# RVM and Ruby

if [[ -d $HOME/.rvm ]]; then
  # TODO: Should this go to the front, to shadow system installations?
  jx_maybe_add_path "$HOME/.rvm/bin"
fi


unset __uname

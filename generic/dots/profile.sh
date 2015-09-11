# .profile
# apjanke's .profile
#
# (non-bash-specific login shell configuration)


#   Non-platform-specifc stuff   #

if which subl &>/dev/null; then
    # Let's try using Sublime Text for shell-invoked editor, too
   export EDITOR='subl -w'
   export VISUAL='subl -w'
fi

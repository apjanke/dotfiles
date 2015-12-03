#!/bin/bash
#
# Setup and installation of per-user tools on OS X
#  * Oh My Zsh

# TODO:
# Install fonts
# iTerm2 preferences

# Install Oh My Zsh
# (using manual installation)

omz_repo_dir=~/local/opp/oh-my-zsh
mkdir -p "$omz_repo_dir"
if [ ! -e "$omz_repo_dir/oh-my-zsh" ]; then
  echo "Cloning oh-my-zsh"
  git clone git@github.com:apjanke/oh-my-zsh.git "$omz_repo_dir/oh-my-zsh"
  pushd "$omz_repo_dir/oh-my-zsh"
  git remote add upstream https://github.com/robbyrussell/oh-my-zsh.git
  popd
fi
if [ ! -e "$omz_repo_dir/oh-my-zsh-custom" ]; then
  echo "Cloning oh-my-zsh-custom"
  git clone git@github.com:apjanke/oh-my-zsh-custom.git "$omz_repo_dir/oh-my-zsh-custom"
fi
if [ ! -e ~/.oh-my-zsh ]; then
  echo "Linking .oh-my-zsh"
  ln -s "$omz_repo_dir/oh-my-zsh" ~/.oh-my-zsh
fi
if [ ! -e ~/.oh-my-zsh-custom ]; then
  echo "Linking .oh-my-zsh-custom"
  ln -s "$omz_repo_dir/oh-my-zsh-custom" ~/.oh-my-zsh-custom
fi

if [ `uname` = Darwin ]; then
  curr_shell=$(dscl /Search -read "/Users/$USER" UserShell | awk '{print $2}')
else
  curr_shell="$SHELL"
fi
if [ $curr_shell != /bin/zsh ]; then
  chsh -s /bin/zsh
fi

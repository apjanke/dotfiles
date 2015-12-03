#!/bin/bash
#
# Sets up Homebrew on a machine
#
# This is idempotent, so you can rerun it on a machine that already has brew installed,
# though you may see spurious error messages.

# Install Homebrew
if [ ! -e /usr/local/Library/Homebrew ]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Homebrew is already installed"
fi

# Install Homebrew Cask
brew install caskroom/cask/brew-cask

# Install formulae
my_brew_cfg_dir="$HOME/Dropbox/computer/my computer setup/homebrew stuff"
if [ -e "$my_brew_cfg_dir" ]; then
  echo "Found config dir"
  taps=($(cat "$my_brew_cfg_dir/brew-taps-common"))
  formulae=($(cat "$my_brew_cfg_dir/brew-leaves-common"))
  casks=()
else
  echo "Using defaults"
  # Common defaults
  taps=( homebrew/versions )
  formulae=( zsh browser wget dos2unix fortune git pstree tree watch )
  casks=( iterm2 sublime-text xquartz firefox google-chrome thunderbird )
fi

# Special case: do cask-controlled dependencies first
brew cask install xquartz

for tap in "${taps[@]}"; do
  echo brew tap $tap
  brew tap $tap
done
echo brew install "${formulae[@]}"
brew install "${formulae[@]}"
for cask in "${casks[@]}"; do
  echo brew cask install $cask
  brew cask install $cask
done

# TODO: Point iTerm2 at shared pref folder




#!/bin/bash
#
# Sets up Homebrew on a machine
#
# This is idempotent, so you can rerun it on a machine that already has brew installed,
# though you may see spurious error messages.

# Prerequisites

rslt=$(xcode-select --install 2>&1)
if [[ "$rslt" = *"already installed"* ]]; then
  echo Xcode CLT is installed.
else
  echo "Error: Xcode CLT is not installed. Please install it (like with setup-osx-system.sh)"
  exit 1
fi

# Install Homebrew
if [[ -z $(which brew) ]]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Homebrew is already installed"
fi

# Pick what to install
my_brew_cfg_dir="$HOME/Dropbox/computer/my computer setup/homebrew stuff"
if [ -e "$my_brew_cfg_dir" ]; then
  echo "Found brew config dir"
  taps=($(cat "$my_brew_cfg_dir/brew-taps-common"))
  formulae=($(cat "$my_brew_cfg_dir/brew-formulae-standard"))
  casks=()
else
  echo "No brew config dir found; Using defaults"
  # Common defaults
  taps=( homebrew/versions homebrew/x11 homebrew/science )
  formulae=( zsh browser wget dos2unix fortune git pstree tree watch )
  #casks=( iterm2 sublime-text firefox google-chrome thunderbird )
  casks=()
fi

# Install Homebrew Cask
brew install caskroom/cask/brew-cask

# Special case: do cask-managed dependencies first, because regular `brew install`
# formulae may need them
# TODO: check for xquartz already installed outside cask
brew cask install xquartz

for tap in "${taps[@]}"; do
  echo brew tap $tap
  brew tap $tap
done

# Hack: do gcc first, since :recommended dependencies might not pick it up,
# due to a Homebrew dependency resolution bug
echo brew install gcc
brew install gcc
echo brew install "${formulae[@]}"
brew install "${formulae[@]}"

for cask in "${casks[@]}"; do
  echo brew cask install $cask
  brew cask install $cask
done




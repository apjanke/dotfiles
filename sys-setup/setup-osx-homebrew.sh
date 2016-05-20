#!/bin/bash
#
# Sets up Homebrew on a machine
#
# This is idempotent, so you can rerun it on a machine that already has brew installed,
# though you may see spurious error messages.

THISDIR="$( dirname "${BASH_SOURCE[0]}" )"
GITHUB_USERNAME=apjanke

_do() {
  echo "$@"
  "$@"
}

ensure_github_user_fork_remote() {
  USERNAME=$1
  REPO=$2
  if ! git remote get-url $USERNAME &>/dev/null; then
    _do git remote add $USERNAME https://github.com/$USERNAME/$REPO.git
  fi
}

# Prerequisites

# Check for Xcode or CLT
if ! xcode-select -p >/dev/null; then
  echo "Error: Neither Xcode nor CLT are installed. Please install one."
  echo "  To install CLT:  sudo xcode-select --install"
  echo "  To do Xcode:     Install Xcode and then sudo xcode-select -s /Applications/Xcode-<version>.app"
  exit 1
fi
# Check for JDK
if ! pkgutil --pkgs | grep com.oracle.jdk >/dev/null; then
  echo "Error: Java JDK is not installed. Please install it."
  exit 1
fi

# Install Homebrew
if [[ -z $(which brew) ]]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Homebrew is already installed."
fi
cd $(brew --repo)
git fetch --unshallow
ensure_github_user_fork_remote $GITHUB_USERNAME brew
git fetch --all

# Pick what to install
my_brew_cfg_dir="$THISDIR/homebrew"
if [ -e "$my_brew_cfg_dir" ]; then
  echo "Found brew config dir"
  taps=($(cat "$my_brew_cfg_dir/brew-taps-standard"))
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
_do brew install caskroom/cask/brew-cask

# Special case: do cask-managed dependencies first, because regular `brew install`
# formulae may need them
if [ ! -e /Applications/Utilities/XQuartz.app ]; then
  _do brew cask install xquartz
fi

for tap in "${taps[@]}"; do
  _do brew tap --full $tap
  cd $(brew --prefix)/Library/Taps/$tap
  tap_repo_name=homebrew-$(basename $tap)
  ensure_github_user_fork_remote $GITHUB_USERNAME $tap_repo_name
  git fetch --all
done

# Hack: do gcc first, since :recommended dependencies might not pick it up,
# due to a Homebrew dependency resolution bug
if [ ! -e $(brew --prefix)/bin/cc ]; then
  brew install gcc
  _do brew install gcc
fi
_do brew install "${formulae[@]}"

for cask in "${casks[@]}"; do
  _do brew cask install $cask
done



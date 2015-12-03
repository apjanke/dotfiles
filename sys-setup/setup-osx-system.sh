#!/bin/bash
#
# Updates the system settings to my preferred state.
#

# Do this manually to set hostname:
#
# sudo scutil --set HostName new-host-name

# Ask for administrator password up front
sudo -v

# Install Xcode CLT
# (needed for system git, at least)

rslt=$(sudo xcode-select --install 2>&1)
if [[ $? == 0 ]]; then
  echo " "
  echo "Now, complete the Xcode CLT install in that dialog!"
  echo -n "When done, press enter to continue: "
  read DUMMY
  echo " "
elif [[ $rslt == *"already installed"* ]]; then
  echo "Looks like Xcode CLT is already installed."
else
  echo "Error installing Xcode CLT: $rslt"
  exit 1
fi

if [[ ! -e /usr/local/bin ]]; then
  sudo mkdir -p -v /usr/local/bin
fi


#!/bin/bash
#
# Updates the system settings to my preferred state.

# Ask for administrator password up front
sudo -v

################################################
# Tools and editors
################################################

# Install Xcode CLT
# (needed for system git, at least)
# Disabled for now so user can manually choose whether to install Xcode or CLT
if false; then
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
fi

# Only /usr/local exists by default
# I might want to link in some binaries, so make sure bin/ exists, too

# These sudos aren't necessary or desirable if Homebrew is being installed.
# But I'm not going to assume that yet.
# Just run the Homebrew install script after this one and it will be fine.

if [[ ! -e /usr/local/bin ]]; then
  sudo mkdir -p -v /usr/local/bin
fi

# Link Sublime Text command line tool

if [[ -e /usr/local/bin/subl ]]; then
  echo "subl is already linked"
else
  if [[ -e "/Applications/Sublime Text 2.app" ]]; then
    sudo ln -s -v "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
  elif [[ -e "/Applications/Sublime Text 3.app" ]]; then
    sudo ln -s -v "/Applications/Sublime Text 3.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
  fi
fi

################################################
# System-wide behaviors
################################################


# Set the timezone; see `sudo systemsetup -listtimezones` for other values
sudo systemsetup -settimezone "America/New_York" > /dev/null

# Allow remote login
sudo systemsetup -setremotelogin on

# Sleep timings
#sudo systemsetup -setcomputersleep 60
#sudo systemsetup -setdisplaysleep 15
#sudo systemsetup -setharddisksleep 60

# Show system info on login screen
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Disable Spotlight indexing for any volume that gets mounted and has not yet
# been indexed before.
# Use `sudo mdutil -i off "/Volumes/foo"` to stop indexing any volume.
sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"

# Load new settings before rebuilding the index
killall mds > /dev/null 2>&1
# Make sure indexing is enabled for the main volume
sudo mdutil -i on / > /dev/null

################################################
# VM Guest specific stuff
################################################

# System settings for when running as a guest inside a VM

if pkgutil --pkg-info com.vmware.tools.macos.pkg.files &>/dev/null; then

  # Enable Retina/HiDPI display modes (requires restart)
  # This may not actually work, on a per-program basis
  sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

fi

echo "Done."


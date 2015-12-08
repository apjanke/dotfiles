#!/bin/bash
#
# User settings for when running as a guest inside a VM

# Re-enable “natural” (Lion-style) scrolling
# This will end up having old-style scrolling in effect, because of interaction
# with the host's scrolling setup and/or the VM's mouse driver
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

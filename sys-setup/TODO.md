# TODO

#  Bugs  #

(Also includes stuff I just don't know how to do from the command line.)

##  Core Bugs  ##

- Don't `sudo -v`; let it authenticate lazily, since this script can't run unattended anyway. Or maybe have user sudo it explicitly.

##  System Setup Bugs  ##

- Install Dropbox
- Install selected Mac App Store apps from command line

- Xcode installation
 - Better way of choosing an Xcode installation or CLT install up front, to get `git`, which is required for installing some of this other stuff, and install it automatically
  - Or just an alternate source of a usable `git` for bootstrapping the installs
  - Need to support both CLT and no-CLT boxes for Homebrew testing, and I don't know how to uninstall CLT installs
 - As part of Xcode setup, launch it (to get it verified) and agree to the EULA.
  - Or just switch to the CLT for everything, and I'll special-case the Xcode-only Homebrew test box installs

##  User Setup Bugs  ##

- Turning off system UI sound effects doesn't seem to work.
- Need to disable notifications for various programs.
- Install Dropbox
- Configure Dropbox selective sync

- Set up accounts in Tweetbot
- Set up accounts in Slack
- Set up mail accounts in Thunderbird
- Firefox user setup
 - Set up Firefox Sync via CLI
 - Get through or bypass initial Ghostery setup/walkthrough
 - Load Ghostery settings from exported settings file
- Set up Moom (run automatically, run as menu bar application)
- Configure Bartender from CLI (support both v1 (for 10.9) and v2)
- Configure Finder
 - Change items in sidebar (remove some, add some, reorder others)
 - https://discussions.apple.com/thread/3200109?start=15
- Configure screensaver
 - Random screensaver
- Keyboard shortcuts
 - e.g. Ctrl-arrow for switching spaces, vs Ctrl-shift-8/9
- Make JustNotes dock-only (and not show in menu bar)
- Disable the dashboard thing with widgets

#  Enhancements   #

##  Big stuff  ##

- Install fonts, at system level
- Support alternate Homebrew installations
 - Alternate `brew --prefix` location
 - Dedicated Homebrew user
 - As arguments
- Install VMware tools automatically, instead of requiring manual installation and using that to determine whether running inside a VM

###  Configurability   ###

- Multiple "profiles" that control what get installed
 - e.g. "developer" vs simpler "user" box

##  System Setup Enhancements ##

- Install iTerm2 somehow (probably brew cask)
- Learn `brew cask` and get stuff installed using it?
- Consider enabling HFS+ compression on some areas by default
- Script installation of Xcode, including versioning app name

##  User Setup Enhancements   ##

- Disable FaceTime Account
- Disable Messages Account
- Change items in Dock
 - Add new things as persistent items
 - Rearrange item order
- Install SSH keys from central source or peer
- Can we enable displaying ~/Library for mounted volumes, not just system drive?
- A way to disable screen savers that display photos from user Aperture/iPhoto library? Maybe point it at a custom library?


# TODO

- Review https://github.com/mathiasbynens/dotfiles; looks like he's got some new stuff since I first copied stuff over.

#  Bugs  #

(Also includes stuff I just don't know how to do from the command line.)

##  Core Bugs  ##

- Don't `sudo -v`; let it authenticate lazily, since this script can't run unattended anyway.
- Support for specific versions of OS X

- Remove spurious plistbuddy diagnostic messages
```
$ ./setup-osx-user.sh
Copy: ":Window Settings:Basic Improved" Entry Already Exists
Add: ":Window Settings:Basic Improved:shellExitAction" Entry Already Exists
Add: ":Window Settings:Basic Improved:columnCount" Entry Already Exists
Add: ":Window Settings:Basic Improved:rowCount" Entry Already Exists
```

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
 - Default to list view
 - Change items in sidebar (remove some, add some, reorder others)
 - New windows open in home directory
- Power Management settings
 - Change time-to-sleep, time-to-display-off
- Configure screensaver
 - Random screensaver; require password immediately; upper-left corner hotspot
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
- Research other people's mechanisms for setting this stuff up

##  Core scripts   ##

- Network install
 - On a frewsh install, I want to do a `sh -c $(curl ...)` to grab the master installer and have it do the whole shebang from there.
- Add top-level logging
- Factor Homebrew stuff out: pull default formula lists

###  Configurability   ###

- Multiple "profiles" that control what get installed
 - e.g. "developer" vs simpler "user" box

##  System Setup Enhancements ##

- Install iTerm2 somehow
- Learn `brew cask` and get stuff installed using it?
- Consider enabling HFS+ compression on some areas by default
- Script installation of Xcode, including versioning app name

##  User Setup Enhancements   ##

- Disable FaceTime Account
- Disable Messages Account
- Change items in Dock
 - Remove unwanted items
 - Add new things as persistent items
 - Rearrange item order
- Install SSH keys from central source or peer
- Set iTerm2 synced settings location preemptively via CLI, so you don't need to manually set it.
 - May require change in iTerm2; file a request there
- Can we enable displaying ~/Library for mounted volumes, not just system drive?
- A way to disable screen savers that display photos from user Aperture/iPhoto library? Maybe point it at a custom library?


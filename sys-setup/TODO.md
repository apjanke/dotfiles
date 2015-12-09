# TODO

- Review https://github.com/mathiasbynens/dotfiles; looks like he's got some new stuff since I first copied stuff over.

#  Bugs  #

(Also includes stuff I just don't know how to do from the command line.)

##  Core Bugs  ##

- De-Dropboxify
- Don't `sudo -v`; let it authenticate lazily, since this script can't run unattended anyway.
- Support for specific versions of OS X

##  System Setup Bugs  ##

- Do not install XQuartz via `brew cask` when a standalone is installed
- Install Dropbox
- Install selected Mac App Store apps from command line
- Better way of choosing an Xcode installation or CLT install up front, to get `git`, which is required for installing some of this other stuff
 - Or just an alternate source of a usable `git` for bootstrapping the installs
 - Need to support both CLT and no-CLT boxes for Homebrew testing, and I don't know how to uninstall CLT installs

####  Fully setting hostname via CLI  ####

Current hostname-setting mechanism sets the host at the "Unix" level. (E.g. it shows up correctly in terminal sessions.) But the displayed name in Sharing and in Finder stays the old name. Seems there's a Mac-specific layer that needs to be set in addition to or instead of how we're currently setting it.

I think I'm just missing some `scutil --set *Name` [from here](https://github.com/mathiasbynens/dotfiles/blob/ed0019b7f87828aad94a94665c198b556bd7be02/.osx#L15-L19).

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


#  Enhancements   #

##  Big stuff  ##

- See if I can de-Dropboxify this stuff
- Support alternate Homebrew installations
 - Alternate `brew --prefix` location
 - Dedicated Homebrew user
- Detect when running inside a VM guest and choose some alternate settings automatically
 - Install VMware tools automatically?
- Install fonts, at system level
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
- Accept hostname as an argument to setup
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


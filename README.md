#  Dotfiles Repo  #

My configuration files and system setup scripts.

The idea here is to get as close as possible to being able to sit down at a fresh computer or user account, be able to run just a couple commands, and have it fully set up the way I like it and be able to start working, instead of futzing around for hours with GUI preference panels and the like.

##  Using this repo  ##

Caution! This whole thing is a work in progress. I'm making this repo publicly available so other people can use my code and techniques. But it's not a product, it's not stable, and there's no support. I'm going to continue to change this stuff to meet my own needs, maybe in non-back-compatible ways. So don't think you can just clone the repo and use it directly. If you want to use it, make a copy, read and understand it, and make your own `dotfiles` repo (not a fork of mine; you want your own independent one).

##  Repo sections  ##

There are a few different parts to this repo.

* [*dotfiles*](dotfiles/README.md) – Unix-style configuration files for dropping in to your home directory
* [*sys-setup*](sys-setup/README.md) – System and user configuration scripts that install things and adjust system settings
* *manual-settings* – Exported and imported settings files from various programs
* [*iTerm2*](iTerm2/README.md) – Shared data directory for iTerm2's "load settings from folder" preference at

##   Overall Installation / Usage   ##

To set up a new computer from scratch:

* Clone this repo locally, to its permanent location
* Install Xcode and/or the Xcode CLT
* In `sys-setup`:
** `./setup-osx-homebrew`
** `sudo ./setup-osx-system`
** `./setup-osx-user`
* `./install-dotfiles`

Optional Dropbox setup:

* Install Dropbox
** Have it sync at least `computer/`
** Wait for sync to complete
* `./setup-iterm2`
* `./sync-desktop-folder-osx`

##  Design and implementation notes  ##

Symlinks cannot be used within this repo, since it may be stored on Dropbox. That'll change if I get off Dropbox and switch to Git-only. But the automatic Dropbox syncing is nice, especially for trying out changes on multiple boxes before committing.

The `setup-osx-system` and `setup-osx-user` scripts can only have soft dependencies on `setup-osx-homebrew`, so that they can be run without it to configure a "clean" machine without a Homebrew installation.

##  License  ##

All material in this project is licensed under the MIT License unless otherwise noted. See [LICENSE.md](LICENSE.md).

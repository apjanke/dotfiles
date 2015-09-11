#  Dotfiles   #

My configuration files.

Intended for syncing to multiple machines and platforms, and symlinks used to pull the files in as appropriate. Syncing can be done by Git, Dropbox, or network shares.

This dir is used by being mounted on or synced to multiple machines, and files symlinked in to it, at the level of individual files. Moving files around may break things and require a re-install.

Symlinks cannot be used within this repo, since it may be stored on Dropbox. That'll change if I get off Dropbox and switch to Git-only. But the automatic Dropbox syncing is nice, especially for trying out changes on multiple boxes before committing.

##   Installation / Usage   ##

* Clone or sync the repo to its permanent location and run `install.sh`
* Clone [the apjanke/oh-my-zsh-custom repo](https://github.com/apjanke/oh-my-zsh-custom) and link it at `~/.oh-my-zsh-custom`.

`install.sh` will set up the appropriate links in the current user's home directory, overwriting any previous links or files. They will be linked to the location `install.sh` is run from. If you relocate the repo/synced directory, you'll need to re-run it.

Caution: `install.sh` will clobber any locally-created files if you have them. It's not careful, and it's intended to be run in a newly created account, or one that already has dotfiles managed this way.

I like to keep both the dotfiles and oh-my-zsh-custom repo clones in my Dropbox and link to them from there so that my commonly used interactive machines pick up changes automatically without having to do a `git pull`, and for testing changes on multiple platforms before committing them.

##   Organization  ##

Subdirectory organization indicates where the files are applicable.

Dot file hierarchies are arranged by OS/platform.

* `generic` – dot files for any OS, platform, or host. They either are portable, or have OS detection tests and only set OS-specific things as appropriate.

I've cut down to only portable files now, so there are no other platform or host-specific directories.

Within each OS/platform directory, there are the following subdirectories:

* `dots` – Files in here have their name munged for the symlink name. They're stored this way to make them easier to list and edit.
* `no_dots` – Files in here are linked without any name changes.
* Any other directories are linked directly under $HOME with no name change.

Miscellaneous stuff:

* `iTerm2` – Dir to point iTerm2's "load settings from folder" preference at.
* `settings-manual` – Settings for various programs that need to be manually exported/imported.

###   Shell configuration files  ###

I use both zsh and bash, and in zsh I use Oh My Zsh ("OMZ"). The shell rc files here are designed to provide a common setup under both shells, and to do the Right Thing for all combinations of interactive/non-interactive and login/non-login sessions.

* `.zshrc` - zsh interactive shells
* `.bashrc` - bash interactive shells
* `.dotfiles/zshbashrc.sh` - common bash & zsh interactive shells
* `.bash_profile` - bash login shells
* `.profile` - common bourne login shells (sh, bash, zsh)
* `.dotfiles/zshrc-omz.zsh` - zsh when using Oh My Zsh
* `.dotfiles/zshrc-no-omz.sh` - zsh when not using Oh MY Zsh

The shell rc files are set up to source each other where appropriate, to avoid redundant code.

My OMZ customization files are in a separate [apjanke/oh-my-zsh-custom repo](https://github.com/apjanke/oh-my-zsh-custom).

##   Notes   ##

The symlinks are only done one level deep. This will be an issue if there end up being multiple platforms with bin/ or other directories that want to be merged somehow. Best approach is probably to just not support that, and require anything in bin/ or another subdir to be generic, or replaced per-platform on the basis of the entire folder.

##  License  ##

All material in this project is licensed under the MIT License unless otherwise noted. See [LICENSE.md](LICENSE.md).


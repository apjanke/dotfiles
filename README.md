#  Dotfiles   #

My configuration files and system setup scripts.

Intended for syncing to multiple machines and platforms, and symlinks used to pull the files in as appropriate. Syncing can be done by Git, Dropbox, or network shares.

This dir is used by being mounted on or synced to multiple machines, and files symlinked in to it, at the level of individual files. Moving files around may break things and require a re-install.

Symlinks cannot be used within this repo, since it may be stored on Dropbox. That'll change if I get off Dropbox and switch to Git-only. But the automatic Dropbox syncing is nice, especially for trying out changes on multiple boxes before committing.

##   Overall Installation / Usage   ##

To set up a new computer from scratch:

* Clone this repo locally, to its permanent location
* Install Xcode and/or the Xcode CLT
* `setup-osx-homebrew`
* `setup-osx-system`
* `setup-osx-user`

##   Dotfile Installation / Usage   ##

* Clone or sync the repo to its permanent location
 * `git clone https://github.com/apjanke/dotfiles.git`
* Run `install-dotfiles` from that cloned repo

(See [`sys-setup/README.md`](sys-setup/README.md) for info on using the system setup scripts.)

The `install-dotfiles` script will set up the appropriate links in the current user's home directory, overwriting any previous links or files. They will be linked to the location that `install-dotfiles` is run from. This means that you need to keep the repo around indefinitely, not just for installation. And if you relocate the repo/synced directory, you'll need to re-run `install-dotfiles`.

Caution: `install-dotfiles` will clobber any locally-created files if you have them. It's not careful, and it's intended to be run in a newly created account, or one that already has dotfiles managed this way.

I like to keep both the `dotfiles` and `oh-my-zsh-custom` repo clones in my Dropbox and link to them from there, so that my commonly used interactive machines pick up changes automatically without having to do a `git pull`, and for testing changes on multiple platforms before committing them.

##   Organization  ##

The dot file hierarchies are arranged by OS/platform, under the `dotfiles` directory.

* `dotfiles/` - Configuration files meant to be installed in the user's home directory
 * `generic/` – Dot files for any OS, platform, or host. They either are portable, or have OS detection tests and only set OS-specific things as appropriate.
 * `<osname>/` - Dot files specific to an OS. These take precedence over corresponding generic dot files.
* `sys-setup/` - system and user configuration scripts which can be run to do up-front configuration, but don't need installation
* `iTerm2/` – Shared data directory for iTerm2's "load settings from folder" preference at.
* `manual-settings/` – Settings for various programs that need to be manually exported and/or imported.

##  Dot file design   ##

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

My OMZ customization files are in a separate [apjanke/oh-my-zsh-custom repo](https://github.com/apjanke/oh-my-zsh-custom). This can be installed using the `sys-setup/setup-osx-user` script.

##   Notes   ##

The symlinks are only done one level deep. This will be an issue if there end up being multiple platforms with subdirectories that want to be merged somehow, or if I add support for XDG `~/.config` directories.

The same `bin` directory will be linked on all platforms, so it needs to have portability support inside it, instead of defining alternate platform-specific `bin` dirs. This is by design, since it will mostly contain script files.

##  License  ##

All material in this project is licensed under the MIT License unless otherwise noted. See [LICENSE.md](LICENSE.md).

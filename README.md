# Andrew's Dotfiles Repo

Andrew Janke's personal configuration files and system setup scripts.

The idea here is to get as close as possible to being able to sit down at a fresh computer or user account, run just a couple commands, and have it fully set up the way I like it and be able to start working, instead of futzing around for hours with manual setup of GUI preference panels and the like.

## Using this repo

Caution! This whole thing is a work in progress and it will probably never be "finished". I'm making this repo publicly available so other people can use my code and techniques. But it's not a product, it's not stable in either interface or behavior, and there is no support for it. I'm going to continue to change this stuff to meet my own needs, maybe in non-back-compatible ways, at any time. So you can't just clone the repo, use it directly, and expect it to be stable.

If you want to use this repo, make a copy, read and understand it, and load it in to your own `dotfiles` repo; then if you want, pull from upstream in a controlled, deliberate manner. (Probably not a GitHub fork of my repo; you want your own independent ("canonical") repo).

## Repo sections

There are a few different parts to this repo.

* [*dotfiles*](dotfiles/README.md) – Unix-style configuration files for dropping in to your home directory.
* *bin* – Portable-ish little Unix scripts and programs I want on all my computers.
* [*sys-setup*](sys-setup/README.md) – System and user configuration scripts that install things and adjust system settings.
* *settings* – Settings data files.
  * *manual* – Exported and imported settings files from various programs, managed manually.
  * [*iTerm2*](iTerm2/README.md) – Shared data directory for iTerm2's "load settings from folder" preference sync thing.

## Overall Installation / Usage

To set up the dotfiles:

* Clone this repo locally, to its permanent location.
* Run the `install-dotfiles` command found in the root of the repo.

That will symlink your various `~/.*` files to their definitions in the repo.

To set up a new Mac from scratch using `sys-setup`:

* Clone this repo locally, to its permanent location.
* Install Xcode and/or the Xcode CLT.
* In `sys-setup`:
  * `./setup-osx-homebrew`
  * `sudo ./setup-osx-system`
  * `./setup-osx-user`

### Using in Dropbox - not recommended

I used to keep my "local" clone of this repo in my Dropbox cloud drive, but that didn't work great and I don't do it any more or recommend that others do it. Now I just keep it in a regular repo clone directory outside Dropbox or any other cloud drive.

The idea was to save the work of periodically doing git pulls on each computer where I used it, and automatically get the latest-and-greatest everywhere. But Dropbox isn't quite suited for that, for various reasons. My dotfiles are high prioirity and I want them synced right away, but when there's been a lot of data churn it can take Dropbox hours or days to catch up, and there isn't a great way to prioritize syncing of certain files. Cloud drive sync seems to have potential conflicts with git, which is its own data sync mechanism. I sometimes do want to have different computers using different branches or versions of my dotfiles. Some programs like Anaconda like to clumsily modify your dotfiles as part of their setup process, and when that happens I want to notice it, see where it happened, and undo it. As of 2021-ish, Dropbox really wants to make your files cloud-only, but I want all my dotfiles to be locally synced so they're captured by local-computer backups. And so on.

## Design and implementation notes

See `dotfiles/README.md` for info in the design of my dotfiles and shell configuration setup.

The `setup-osx-system` and `setup-osx-user` scripts can only have soft dependencies on `setup-osx-homebrew`, so that they can be run without it to configure a "clean" machine without a Homebrew installation.

## License

All material in this project is licensed under the MIT License unless otherwise noted. See [LICENSE.md](LICENSE.md).

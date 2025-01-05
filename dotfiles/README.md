# README – Dotfiles

This directory structure is intended for syncing to multiple machines and platforms, and symlinks used to pull the files in as appropriate. Syncing can be done by Git, Dropbox, or network shares.

This dir is used by being mounted on or synced to multiple machines, and files symlinked in to it, at the level of individual files. (Typically done with Dropbox and/or Git.) Moving files around may break things and require a re-install.

## Installation and usage

* Clone or sync the repo to its permanent location
  * `git clone https://github.com/apjanke/dotfiles.git`
* Run `install-dotfiles` from that cloned repo

The `install-dotfiles` script will set up the appropriate links in the current user's home directory, overwriting any previous links or files. They will be linked to the location that `install-dotfiles` is run from. This means that you need to keep the repo around indefinitely, not just for installation. And if you relocate the repo/synced directory, you'll need to re-run `install-dotfiles`.

Caution: `install-dotfiles` will clobber any locally-created files if you have them. It's not careful, and it's intended to be run in a newly created account, or one that already has dotfiles managed this way.

I like to keep both the `dotfiles` and `oh-my-zsh-custom` repo clones in my Dropbox and link to them from there, so that my commonly used interactive machines pick up changes automatically without having to do a `git pull`, and for testing changes on multiple platforms before committing them.

## Organization

The dot file hierarchies are arranged by OS/platform, under the `dotfiles` directory.

* `dotfiles/` - Configuration files meant to be installed under the user's home directory
  * `generic/` – Dot files for any OS, platform, or host. They either are portable, or have OS detection tests and only set OS-specific things as appropriate.
  * `<osname>/` - Dot files specific to an OS. These take precedence over corresponding generic dot files.

The files in the `<osname>/` directories (e.g. `macos`) shadow the corresponding files in `generic/` on machines that are of that OS. This is a special-purpose mechanism for where I haven't been able to construct a single portable config file that works on all my OSes (e.g. using switch logic or conditional includes). I'd like to get rid of it entirely. As of 2023, I think I can: looks like `.gitconfig` supports conditional includes based on the OS it's running on; I just wasn't aware of that feature earlier.

## Dot file design

This section discusses the design of the configuration files themselves (as opposed to this repo and the installation script).

All the file names will be prefixed with a dot when they are installed or linked in place, and all ".sh" file extensions are stripped. E.g. `gvimrc` becomes `.gvimrc`, and `bashrc.sh` becomes `.bashrc`. This is for convenience in browsing and editing them in this repo: no dot means they aren't hidden, and the extension enables syntax support in editors. I'm not sure if I love that design; I may end up changing it.

## Shell configuration design

I use both Zsh and Bash, and in Zsh I use Oh My Zsh ("OMZ"). As a group, I'm calling those "Bashlikes".

The shell rc files here are designed to provide a common setup under both shells, do the Right Thing for all combinations of interactive/non-interactive and login/non-login sessions, and minimize redundant code in shell-specific config files. I use a somewhat unconventional file structure of my own design to support that and share code across all the bashlike shells. It hooks in to the standard startup file structure of each shell, and from there I have the standard shell-specific files source my custom common files or to standard files from other shells.

Defined files:

* `.bashrc` – bash interactive
* `.zshrc` – zsh interactive
* `.dots/bashyrc.sh` – common bashlike interactive
* `.bash_profile` – bash login
* `.profile` – common bashlike login
* `.zprofile` – zsh login
* `.dots/zshrc-omz.zsh` – zsh when using Oh My Zsh
* `.dots/zshrc-prezto.sh` – zsh when not using Prezto
* `.dots/zshrc-nocustomizer.sh` – zsh when not using an shell customizer framework
* `.zlogout`, `.bash_logout` – shell-specific logout
* `.dots/bashylogout.sh` – common bashlike logout

* `.zpreztorc` – Prezto configuration; called by Prezto and not zsh directly

The `.dots/zshrc-(omz|prezto|nocustomizer)` files are alternatives to each other, and exactly one is called, depending on which shell customizer (OMZ, Prezto, or none) you are running in that shell session.

My OMZ customization files are in a separate [apjanke/oh-my-zsh-custom repo](https://github.com/apjanke/oh-my-zsh-custom). This can be installed using the `sys-setup/setup-macos-user` script.

In the shell configuration, I try to separate env configuration from interactive-shell configuration, and keep the env configuration part minimal, which seems to be what the Bash and Zsh documentation recommend. The env config goes in `.profile`/`.zprofile`

### Shell startup file sequence

The startup file calling sequence is as follows.

The tree structure indicates that parent node scripts call child node scripts. Sibling scripts are called in the order they are shown in this tree. If you read down the trees line by line as arranged on this page (doing a depth-first traversal), that's the order all the files should get called in. This list reflects both the shells' standard behavior and what my custom rc files do.

For bash:

* `/etc/profile` (if login)
* `/etc/bash.bashrc` (if interactive)
* `~/.bash_profile` (if login)
  * `~/.profile`
    * `~/.profile-local`
    * `~/.dots/bashy-paths.sh`
  * `~/.bashrc` (or called directly by shell if non-login interactive)
    * `~/.dots/bashyrc.sh`
      * `~/.dots/bashy-langs.sh`
* `~/.bash_logout` (at logout)
  * `~/.dots/bashylogout.sh`

When `.bash_profile` exists, it takes precedence over `.profile`, so I have my `.bash_profile` explicitly call `.profile` so that I can keep common non-bash-specific config code there for sharing with zsh and sh, and have bash-specific stuff live in `.bash_profile`.

For zsh:

* `~/.zshenv` (all shell sessions)
* `~/.zprofile` (if login)
  * `~/.profile`
    * `/.profile-local`
    * `~/.dots/bashy-paths.sh`
  * `~/.zprofile-local`
* `~/.zshrc` (if interactive)
  * `~/.dots/bashyrc.sh`
    * `~/.dots/bashy-langs.sh`
* `~/.zlogin` (if login) (I currently don't define one)
* `~/.zlogout` (at logout)
  * `~/.dots/bashylogout.sh`

Both of these trees may omit some of the additional standard startup scripts that are called by the shells but are not required for use in my custom shell startup sequence.

The [Zsh "startup files" documentation](https://zsh.sourceforge.io/Intro/intro_3.html) says: "`.zprofile` is meant as an alternative to `.zlogin` for ksh fans; the two are not intended to be used together". I am using `.zprofile` not because I use ksh, but because I need the env-setup stuff to run before the rc step so I can have that control conditionalization of my own setup scripts, and I don't think I want all that going in the `.zshenv` that runs on every single shell invocation. It also says "`.zlogin` is not the place for alias definitions, options, environment variable settings, etc.; as a general rule, it should not change the shell environment at all. Rather, it should be used to set the terminal type and run a series of external commands (fortune, msgs, etc)."

Zsh distinguishes between env, login, and rc startup files, but Bash only has a login (`.profile`) vs. rc file split, and no separate env section. So I'm putting the env stuff at the profile level even though the Zsh doco says not to. Maybe I should revise that: factor out my env setup stuff to a common `.dots/bashyenv.sh` file, and have bash `.profile` and `.zshenv` call that, and not have `.zprofile` call `.profile`? Hmmm. Then what exactly does `.profile` mean, and would I have redundant code there?

Thought 2023-12: `$PATH` setup should probably stay in the login/profile section instead of the env (`.zshenv`) section so it's not re-applied on every subshell, which would cause the path to get long and messy, and slow things down.

Since Bash doesn't define an equivalent of `.zshenv` that's sourced for all shell sessions including noninteractive ones, you need to export variables that you want child shells to use uniformly, even if they're just shell variables for Bash's own use, because environment inheritance is the only way to propagate them to child shells.

See:

* <https://youngstone89.medium.com/unix-introduction-bash-startup-files-loading-order-562543ac12e9>
* <https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/>

The `.*-local` files are my own convention. Those are hooks for "local" customizations of these dotfiles that are specific to a particular machine, user, or environment. They are called if they exist and ignored if they don't, and are not checked in to this repo or managed by this repo's setup scripts, so you can drop them alongside this repo's managed files in any manner you want.

The idea here is:

* No customization of per-user shell startup files beyond linking in the files in this repo is required to get the "reasonable" default behavior that I like.
  * But users can still customize their standard shell startup files, in addition to my "standard custom" configuration files, and that will be respected. Basically, it's another layer of per-user customization you can plug in to this dotfiles framework (where a "user" means either a human user or a specific user account).
* The shell-specific `profile`, `bashrc*`, and `zsh*` files mostly only contain calls to the common `zshbashrc-*.sh` stuff, plus truly shell-specific configuration.
* The common `zshbashrc-*.sh` files contain all my main customization code that's common across shells, and are the ones to call out to additional user-specific or machine-local shell startup files.
* Doesn't require any changes to system shell startup files in `/etc`.

### Shell configuration variables

These dotfile scripts are themselves controllable by some custom shell/environment variables I came up with.

* `$JX_USE_HOMEBREW` - Whether to use Homebrew instead of MacPorts.
* `$JX_ZSH_CONFIGURATOR` – Selects Oh My Zsh, Prezto, or nothing as the Zsh configurator.
* `$JX_OMZ_THEME` - Which theme to use in OMZ.
* `$JX_PREZTO_THEME` - Which theme to use in Prezto.
* `$JX_CONDA_AUTOLOAD` – Whether to automatically load Anaconda at shell startup time.
* `$JX_CONDA_AUTOACTIVATE` - Whether to automatically activate Anaconda after loading it at shell startup time.
* `$JX_RUBY_AUTOLOAD_ENVMGR` – Selects a Ruby env manager to autoload.
* `$JX_TRACE_SHELL_STARTUP` – Whether to trace shell startup for debugging. (May cause breakage.)

Set these in the early env-stage shell startup scripts, `.profile` (for common ones) and `.zprofile` (for zsh-specifics). You'll probably want to both export them and make their assignment conditional (like with `FOO="${FOO:-myval}"`) so alterations to them are inherited by child shells.

The boolean ones ("whether"s) must be exactly 1 to be considered true.

I'm prefixing the variables and internal-use functions in these shell dotfiles with "JX" to avoid collisions with other env vars, and make it easy to see them in env listings.

These dotfiles also set up the following semistandard env vars. You should not modify them yourself.

* `$JX_HOMEBREW_PREFIX` – Where Homebrew is, if it is loaded in this session.
* `$JX_MACPORTS_PREFIX` – Where MacPorts is, if it is loaded in this session.
* `$__uname` – internal stash of `uname` output for performance.

### Shell functions supplied

These dotfiles define some special shell functions, including some for working with this dotfiles framework itself. Ones with "-"s are for interactive use; ones with "_"s are for calling inside shell startup and other shell script code.

* `jx-conda-load` – Loads an Anaconda install into the shell.
* `jx-rbenvmgr-load` – Loads a Ruby env mgr (like rbenv or rvm) into the shell.
* `jx-nvm-load` – Load NVM into the shell.
* `jx-rainbow-me` – Enable fun colorization of `ls` and other commands.
* `jx_maybe_add_path` – Add a dir to `$PATH` if it's not already there.
* debugging functions for dotfiles
  * `jx-shell-info` – Display current shell state related to these dotfiles.

Plus a bunch of small functions and aliases that act more like short commands, which I'm not going to document here. See the source code for those.

## Miscellaneous

The symlinks are only done one level deep. This will be an issue if there end up being multiple platforms with subdirectories that want to be merged somehow, or if I add support for XDG `~/.config` directories.

The same `bin` directory will be linked on all platforms, so it needs to have portability support inside it, instead of defining alternate platform-specific `bin` dirs. This is by design, since it will mostly contain script files.

I mostly test this on macOS and a bit on Linux, but it "should" work on other OSes that support Bash and Zsh.

## Issues

The shell startup files source files from their final location at `~/.*`, not relative to the calling file's location, so if you have local changes in the repo files and they aren't symlinked in to your `~`, those changes won't be reflected and your shell startup may get a mix of the installed and locally-modified files. I don't have a way to tell the shells "use the startup files from this repo instead of `$HOME`".

## TODO

* Make `jx-conda-load` work on bash too, and remove the unconditional conda load in `bashyrc.sh`.
* Move path setup up in to env/login stage.
* `.*env` files to go with `.*rc` files, or a common `.dots/bashyenv.sh`?
* Review and tighten up the shell file calling order and its documentation here.
* Look in to the XDG spec and its `~/.config` etc dirs, and see which programs support that now.
* Factor out user-specific customizations (like the list of "default" user names) to separate files, to make this easier to reuse across users.
* Figure out the conventions for when shell env files should clobber variables vs. leave already-set variables alone.
  * Think I need this to make `~/.profile` shareable between zsh and bash, if I want `~/.zshenv` or `~/.zprofile` to source it.
* Prefix my custom env and global shell variable names with `JX_` or similar.

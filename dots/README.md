# README – Dotfiles

This directory structure is intended for syncing to multiple machines and platforms, and symlinks used to pull the files in as appropriate. Syncing can be done by Git, Dropbox, or network shares.

This dir is used by being mounted on or synced to multiple machines, and files symlinked in to it, at the level of individual files. Moving files around may break things and require a re-install, and is not robustly auto-detected.

## Installation and usage

- Clone or sync the repo to its permanent location
  - `git clone https://github.com/apjanke/dotfiles.git`
- Run `install-dotfiles` from that cloned repo

The `install-dotfiles` script will set up the appropriate links in the current user's home directory, overwriting any previous links or files. They will be linked to the location that `install-dotfiles` is run from. This means that you need to keep the repo around indefinitely, not just for installation. And if you relocate the repo/synced directory, you'll need to re-run `install-dotfiles`.

Caution: `install-dotfiles` will clobber any locally-created files if you have them. It's not careful, and it's intended to be run in a newly created account, or one that already has dotfiles managed this way.

I like to keep both the `dotfiles` and `ohmyzsh-custom` repo clones in my Dropbox and link to them from there, so that my commonly used interactive machines pick up changes automatically without having to do a `git pull`, and for testing changes on multiple platforms before committing them.

## Organization

The dot file hierarchies are arranged by OS/platform, under the `dots` directory.

- `dots/` - Configuration files meant to be installed under the user's home directory
  - `all-os/` – Dot files for any OS, platform, or host. They either are portable, or have OS detection tests and only set OS-specific things as appropriate.
  - `<osname>/` - Dot files specific to an OS. These take precedence over corresponding all-os dot files.
  - `<osname>/flat/` - Entries map to `~/.<name>`, and are linked whole: a directory here becomes a single symlink, which is how `~/.dotlib` works. A leading dot is added, and a `.sh`/`.zsh`/`.bash` extension is stripped.
  - `<osname>/nested/` - A mirror of `$HOME`, for tracking individual files that live inside a subdirectory you don't want to claim as a whole (e.g. one file inside `~/.config/some-app/`). Nesting can go arbitrarily deep; only leaf files get symlinked, and intermediate directories are created as real directories in `~`. A path component starting with `_` installs with a leading `.` instead (e.g. `_config` → `.config`), so this repo never has to hold a literal dotfile that isn't actually meant to control the repo itself. A component that genuinely does start with `.` (like `.gitkeep`) is such a file, and is excluded outright: never linked, and never forces directory creation on its own. A leading `__` escapes to a literal `_`, for names that really do start with an underscore – zsh completion functions like `_git` being the main case.

The two trees are siblings rather than one living inside the other, so that neither scanner can see the other's tree as content to link. An earlier layout put the nested tree inside the flat namespace, and the flat scanner duly picked it up and linked the whole thing into `~`. As siblings, that failure can't be expressed, rather than having to be guarded against.

The two trees munge names differently, which is also deliberate. In the flat tree, *every* entry becomes a `~/.something`, so the dot is implicit and needs no marker; requiring one would mean `_bashrc.sh`, `_profile.sh`, `_gvimrc`, and so on for all of them, which distinguishes nothing. In `nested/`, only some components are dotted (`_config/btop/btop.conf` – one of three), so it has to be marked explicitly. Extension stripping likewise belongs only to the flat tree: those files are sourced rather than executed, so they carry no shebang, and the extension is the only language hint an editor gets. Files under `nested/` either already have a natural extension (`btop.conf`, `config.fish`) or would carry a shebang, so there is nothing there for stripping to fix.

The files in the `<osname>/` directories (e.g. `macos`) shadow the corresponding files in `all-os/` on machines that are of that OS. This is a special-purpose mechanism for where I haven't been able to construct a single portable config file that works on all my OSes (e.g. using switch logic or conditional includes). I'd like to get rid of it entirely. As of 2023, I think I can: looks like `.gitconfig` supports conditional includes based on the OS it's running on; I just wasn't aware of that feature earlier.

## Dot file design

This section discusses the design of the configuration files themselves (as opposed to this repo and the installation script).

In the `flat/` trees, all the file names will be prefixed with a dot when they are installed or linked in place, and all ".sh" file extensions are stripped. E.g. `gvimrc` becomes `.gvimrc`, and `bashrc.sh` becomes `.bashrc`. This is for convenience in browsing and editing them in this repo: no dot means they aren't hidden, and the extension enables syntax support in editors. I'm not sure if I love that design; I may end up changing it.

## Shell configuration design

I use both Zsh and Bash, and in Zsh I use Oh My Zsh ("OMZ"). As a group, I'm calling those "Bashlikes".

The shell rc files here are designed to provide a common setup under both shells, do the Right Thing for all combinations of interactive/non-interactive and login/non-login sessions, and minimize redundant code in shell-specific config files. I use a somewhat unconventional file structure of my own design to support that and share code across all the bashlike shells. It hooks in to the standard startup file structure of each shell, and from there I have the standard shell-specific files source my custom common files or to standard files from other shells.

Defined files:

- `.bashrc` – bash interactive
- `.zshrc` – zsh interactive
- `.dotlib/bashyrc.sh` – common bashlike interactive
- `.bash_profile` – bash login
- `.profile` – common bashlike login
- `.zprofile` – zsh login
- `.dotlib/zshrc-omz.zsh` – zsh when using Oh My Zsh
- `.dotlib/zshrc-prezto.sh` – zsh when not using Prezto
- `.dotlib/zshrc-nocustomizer.sh` – zsh when not using an shell customizer framework
- `.zlogout`, `.bash_logout` – shell-specific logout
- `.dotlib/bashylogout.sh` – common bashlike logout

- `.zpreztorc` – Prezto configuration; called by Prezto and not zsh directly

The `.dotlib/zshrc-(omz|prezto|nocustomizer)` files are alternatives to each other, and exactly one is called, depending on which shell customizer (OMZ, Prezto, or none) you are running in that shell session.

My OMZ customization files are in a separate [apjanke/ohmyzsh-custom repo](https://github.com/apjanke/ohmyzsh-custom). This can be installed using the `sys-setup/setup-macos-user` script.

In the shell configuration, I try to separate env configuration from interactive-shell configuration, and keep the env configuration part minimal, which seems to be what the Bash and Zsh documentation recommend. The env config goes in `.profile`/`.zprofile`

### Shell startup file sequence

The startup file calling sequence is as follows.

The tree structure indicates that parent node scripts call child node scripts. Sibling scripts are called in the order they are shown in this tree. If you read down the trees line by line as arranged on this page (doing a depth-first traversal), that's the order all the files should get called in. This list reflects both the shells' standard behavior and what my custom rc files do.

For bash:

- `/etc/profile` (if login)
- `/etc/bash.bashrc` (if interactive)
- `~/.bash_profile` (if login)
  - `~/.profile`
    - `~/.profile-local`
    - `~/.dotlib/bashy-paths.sh`
  - `~/.bashrc` (or called directly by shell if non-login interactive)
    - `~/.dotlib/bashyrc.sh`
      - `~/.dotlib/bashy-langs.sh`
- `~/.bash_logout` (at logout)
  - `~/.dotlib/bashylogout.sh`

When `.bash_profile` exists, it takes precedence over `.profile`, so I have my `.bash_profile` explicitly call `.profile` so that I can keep common non-bash-specific config code there for sharing with zsh and sh, and have bash-specific stuff live in `.bash_profile`.

For zsh:

- `~/.zshenv` (all shell sessions)
- `~/.zprofile` (if login)
  - `~/.profile`
    - `/.profile-local`
    - `~/.dotlib/bashy-paths.sh`
  - `~/.zprofile-local`
- `~/.zshrc` (if interactive)
  - `~/.dotlib/bashyrc.sh`
    - `~/.dotlib/bashy-langs.sh`
- `~/.zlogin` (if login) (I currently don't define one)
- `~/.zlogout` (at logout)
  - `~/.dotlib/bashylogout.sh`

Both of these trees may omit some of the additional standard startup scripts that are called by the shells but are not required for use in my custom shell startup sequence.

The [Zsh "startup files" documentation](https://zsh.sourceforge.io/Intro/intro_3.html) says: "`.zprofile` is meant as an alternative to `.zlogin` for ksh fans; the two are not intended to be used together". I am using `.zprofile` not because I use ksh, but because I need the env-setup stuff to run before the rc step so I can have that control conditionalization of my own setup scripts, and I don't think I want all that going in the `.zshenv` that runs on every single shell invocation. It also says "`.zlogin` is not the place for alias definitions, options, environment variable settings, etc.; as a general rule, it should not change the shell environment at all. Rather, it should be used to set the terminal type and run a series of external commands (fortune, msgs, etc)."

Zsh distinguishes between env, login, and rc startup files, but Bash only has a login (`.profile`) vs. rc file split, and no separate env section. So I'm putting the env stuff at the profile level even though the Zsh doco says not to. Maybe I should revise that: factor out my env setup stuff to a common `.dotlib/bashyenv.sh` file, and have bash `.profile` and `.zshenv` call that, and not have `.zprofile` call `.profile`? Hmmm. Then what exactly does `.profile` mean, and would I have redundant code there?

Thought 2023-12: `$PATH` setup should probably stay in the login/profile section instead of the env (`.zshenv`) section so it's not re-applied on every subshell, which would cause the path to get long and messy, and slow things down.

Since Bash doesn't define an equivalent of `.zshenv` that's sourced for all shell sessions including noninteractive ones, you need to export variables that you want child shells to use uniformly, even if they're just shell variables for Bash's own use, because environment inheritance is the only way to propagate them to child shells.

See:

- <https://youngstone89.medium.com/unix-introduction-bash-startup-files-loading-order-562543ac12e9>
- <https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/>

The `.*-local` files are my own convention. Those are hooks for "local" customizations of these dotfiles that are specific to a particular machine, user, or environment. They are called if they exist and ignored if they don't, and are not checked in to this repo or managed by this repo's setup scripts, so you can drop them alongside this repo's managed files in any manner you want.

The idea here is:

- No customization of per-user shell startup files beyond linking in the files in this repo is required to get the "reasonable" default behavior that I like.
  - But users can still customize their standard shell startup files, in addition to my "standard custom" configuration files, and that will be respected. Basically, it's another layer of per-user customization you can plug in to this dotfiles framework (where a "user" means either a human user or a specific user account).
- The shell-specific `profile`, `bashrc*`, and `zsh*` files mostly only contain calls to the common `zshbashrc-*.sh` stuff, plus truly shell-specific configuration.
- The common `zshbashrc-*.sh` files contain all my main customization code that's common across shells, and are the ones to call out to additional user-specific or machine-local shell startup files.
- Doesn't require any changes to system shell startup files in `/etc`.

### Shell configuration variables

These dotfile scripts are themselves controllable by some custom shell/environment variables I came up with.

- Package managers
  - `$JX_USE_HOMEBREW` - Whether to load Homebrew, if it exists.
  - `$JX_USE_MACPORTS` - Whether to load MacPorts, if it exists.
  - `$JX_MACPORTS_PREFIX`
- Configurators
  - `$JX_ZSH_CONFIGURATOR` – Selects Oh My Zsh, Prezto, or nothing as the Zsh configurator.
  - `$JX_OMZ_THEME`      - Which theme to use in OMZ.
  - `$JX_OMZ_DEBUG`      - Activate OMZ startup debugging.
  - `$JX_OMZ_DEBUG_DIR`  - Output location for OMZ debugging output.
  - `$JX_PREZTO_THEME`   - Which theme to use in Prezto.
- Language toolchains
  - `$JX_CONDA_AUTOLOAD` – Automatically load Anaconda at shell startup time?
  - `$JX_CONDA_AUTOACTIVATE` - Automatically activate Anaconda after loading it at shell startup time?
  - `$JX_RUBY_AUTOLOAD_ENVMGR` – Which Ruby env manager to autoload.
  - `$JX_NVM_AUTOLOAD` - Automatically load NVM?
- Miscellaneous
  - `$JX_TRACE_SHELL_STARTUP` – Whether to trace shell startup for debugging. (May cause breakage.)

Set these in the early env-stage shell startup scripts, `.profile` (for common ones) and `.zprofile` (for zsh-specifics). You'll probably want to both export them and make their assignment conditional (like with `FOO="${FOO:-myval}"`) so alterations to them are inherited by child shells.

The boolean ones ("whether"s) must be exactly 1 to be considered true.

I'm prefixing the variables and internal-use functions in these shell dotfiles with "JX" to avoid collisions with other env vars, and make it easy to see them in env listings.

These dotfiles also set up the following semistandard env vars. You should not modify them yourself.

- `$JX_HOMEBREW_PREFIX` – Where Homebrew is, if it is loaded in this session.
- `$JX_MACPORTS_PREFIX` – Where MacPorts is, if it is loaded in this session.
- `$__uname` – internal stash of `uname` output for performance.

### Shell functions supplied

These dotfiles define some special shell functions, including some for working with this dotfiles framework itself. Ones with "-"s are for interactive use; ones with "_"s are for calling inside shell startup and other shell script code.

- Toolchains and package managers
  - `jx-conda-load` – Loads an Anaconda install into the shell.
  - `jx-rbenvmgr-load` – Loads a Ruby env mgr (like rbenv or rvm) into the shell.
  - `jx-nvm-load` – Load NVM into the shell.
- Other
  - `jx_maybe_add_path` – Conditionally add dirs to `$PATH`.
  - `jx-rainbow-me` – Enable fun colorization of `ls` and other commands.
- Dotfile debugging
  - `jx-shell-info` – Display current shell state related to these dotfiles.

Plus a bunch of small functions and aliases that act more like short commands, which I'm not going to document here. See the source code for those.

### Loading JXL

JXL is the shared shell library, `dotlib/jxl-lib.sh`. It gets loaded two different ways, and the load lines themselves are kept to one line so this is where the reasoning lives.

**Shell rc files** load it from the installed copy, and only from there:

```bash
# JXL, for the command functions further down
if ! source "$HOME/.dotlib/jxl-lib.sh"; then
```

`$HOME/.dotlib` and never a repo-relative path, so an installed `$HOME` stands on its own and keeps working if the checkout moves or goes away. The tradeoff is that an rc file can end up paired with a different version of JXL than it was written against – acceptable for the rc files, not for scripts (below).

There is no `-e` or `-r` test first: the shell already prints a precise diagnostic, distinguishing "No such file or directory" from "Permission denied" better than a hand-written check would, and it's deliberately left visible.

The exit status is worth trusting only because `jxl-lib.sh` ends in a bare `true`, the way a Perl module ends in `1;`. Without that, `source` returns the status of whatever statement happened to come last in the file, so "did it load?" would be answered by accident. Testing it inside `if !` also keeps a caller running under `errexit` alive.

On failure the rc file **complains and carries on** rather than returning. Several things below the load need JXL and will be broken without it, but the rest of the file is still worth having: a shell missing a few `jx-*` commands beats one with no aliases, no `$EDITOR`, and no prompt.

**Shebang scripts** load it from the repo instead, by a path relative to their own location:

```bash
source "$(cd "$(dirname "$0")" && pwd -P)/../dots/all-os/flat/dotlib/jxl-lib.sh" || exit 1
```

Always the repo copy, never `~/.dotlib`, so a script can never be paired with a mismatched library version. The repo is always reachable: these scripts live in it, and `~/bin` is a symlink into it, so if the script ran at all the checkout is present.

`pwd -P` because `~/bin` is that symlink – the path up to the repo root has to be relative to the physical directory, not the logical one. The relative prefix varies with how deep the script sits, so this line is not identical everywhere. `$0` rather than `${BASH_SOURCE[0]}` because these are only ever run, never sourced.

`|| exit 1` so a broken checkout fails on one clear line instead of cascading into `jxl::init_script: command not found` and everything after it. `errexit` cannot cover this, since turning it on is `jxl::init_script`'s job and that has not run yet.

## Miscellaneous

Symlinking is split across two sibling trees under each OS root, per the "Organization" section above: `<osname>/flat/` links whole entries one level deep, and `<osname>/nested/` mirrors `$HOME` for tracking individual files nested inside a directory (like one file under `~/.config/some-app/`) without claiming the rest of that directory.

The same `bin` directory will be linked on all platforms, so it needs to have portability support inside it, instead of defining alternate platform-specific `bin` dirs. This is by design, since it will mostly contain script files.

I mostly test this on macOS and a bit on Linux, but it "should" work on other OSes that support Bash and Zsh.

## Issues

The shell startup files source files from their final location at `~/.*`, not relative to the calling file's location, so if you have local changes in the repo files and they aren't symlinked in to your `~`, those changes won't be reflected and your shell startup may get a mix of the installed and locally-modified files. I don't have a way to tell the shells "use the startup files from this repo instead of `$HOME`".

## TODO

See the `doc/TODO.md` file.

# TODO - dotfiles

## General

- Figure out the conventions for when shell env files should clobber variables vs. leave already-set variables alone.
  - Think I need this to make `~/.profile` shareable between zsh and bash, if I want `~/.zshenv` or `~/.zprofile` to source it.
  - In `.profile`, don't auto-set all those `JX_*` variables. Just support them being unset everywhere. So you can tell the difference between something a user set and the scripts using the defaults.
  - And figure out a place separation between a listing of all the vars that exist and their default values, vs. my actual user configuration of setting one. Distinguish between actual user configuration and shell script implementation of handling that configuration.
  - Consider `: ${MY_VAR:=default}` expansion form.
- new `jx*` functions from `.profile` vs. local replacement files
  - `install-dotfiles` doesn't clobber an existing regular (non-symlink) `~/.profile`, which is intentional - the idea was to let a plain local file supersede the dotfiles-managed one, per-file. But `.dotlib/bashyrc.sh`'s per-machine local-loading loop now hard-depends on the `jx::*`/`_jx_source_maybe` functions defined in `.profile` (added 2026-08-08), so a superseding non-JX-aware `.profile` silently breaks that loop. Revisit: maybe factor those function definitions out of `.profile` into their own file, so `bashyrc.sh` doesn't depend on `.profile` having actually run.
- Top-down function order code layout.
- Terminal colorization: basic support in JXL for colorization of output with basic ANSI terminal control escape codes, for use by command functions.
  - Should detect whether outputting to a TTY, and only colorize if it's a TTY. May need to get a bit fancy about this so command substitution can still produce terminal escape sequences for eventual interpolation in string output which will be going to a TTY. Maybe just a variable that indicates "my output is going to a TTY", that's set at command start time and read by the TTY colorization functions.
- Revisit: the environment can reach into non-interactive shells and change how scripts behave. Two vectors, verified 2026-08-06:
  - `BASH_ENV` - non-interactive bash sources whatever it points at, before running the script. Confirmed it can flip shell options: setting `nullglob` that way changed how an unmatched glob expanded inside a `#!/bin/bash` script. Not currently exposed (nothing here sets `BASH_ENV`, and it's unset in my env), but any script's behavior could be altered from outside if that changed. `BASHOPTS` was also tested and did *not* propagate, despite the bash manual implying it would.
  - zsh's equivalent is already active by design: zsh reads `.zshenv` for **all** invocations, including non-interactive `zsh -c`, and `setopt` there does apply to scripts. Ours then sources `.profile` → `dotlib/bashy-paths.sh`, so every `zsh -c` pays full `$PATH` setup and inherits whatever options `.zshenv` set. Worth asking whether `.zshenv` should be more minimal, and whether scripts should set the options they depend on rather than assuming defaults.
- Detect breakage in installation? (e.g. an `install-dotfiles --doctor` or `--check` option)
  - In the startup scripts, check for presence of required files linked in to ~ and complain if they're absent? To catch things like needing a fresh `install-dotfiles` run after I add/remove/rename linked files in the repo.
- `zshrc-ohmyzsh.zsh`
  - Pull default values for ZSH_THEME up into .zshenv or .profile?
- `.profile-early` hook - Also maybe a hook early enough in the process I can set `$JX_TRACE_SHELL_STARTUP` early enough, before any conditional stuff in `.profile` or `.{bash,bashy,zsh}rc`, to work
- Make .hgignore_global a symlink to .gitignore_global?
  - Add support for relative symlinks, like `.hgignore_global -> .gitignore_global`?
- `install-dotfiles`
  - Make it safer.
    - Still open: an *intermediate* parent directory in the nested tree that's itself a real file or a foreign symlink-to-a-directory isn't handled by `--clobber` at all -- `install_nested_tree`'s `mkdir -p` either fails outright or silently follows the symlink and writes leaf links inside someone else's directory, before `dotinstall::symlink` (and so `--clobber`) ever sees it.
  - Safely handle case-insensitive filesystems and link target files that differ only in case. Maybe include option to normalize them to the current case of the files in the repo, or even do that by default.
- Cleanup: Remove old symlinks for files that have been removed from this repo. Keep a list of files which were here in the past but removed, check for symlinks in home pointing to those files *in this repo but not elsewhere*, and delete them.
  - When adding the first `nested/_ssh/` or `nested/_gnupg/` content, verify and add a test for the `chmod 700` in `install_dotfiles_nested`. That branch has never run, and it fails silently when wrong: a group-writable `~/.ssh` under a umask of 002 makes sshd's StrictModes refuse public-key auth, which shows up much later as an unexplained fallback to password auth.
- Namespace-prefix more internal variables, like `__jx_uname` instead of `__uname`, and add more `unset`/`unfunction` cleanup.
- Fix everything to work with `sudo bash`.
- Add more documentation. A Design doc.
- Tool in zsh to quick switch to a simpler no-emoji theme suitable for copy-paste, in current session.
- A `_jx_do` function to echo a command and then run it.
- Make `jx-conda-load` work on bash too, and remove the unconditional conda load in `bashyrc.sh`.
- Move `$PATH` setup up in to env/login stage, not rc/interactive stage?
- `.*env` files to go with `.*rc` files, or a common `.dotlib/bashyenv.sh`?
  - Now, as of 2026-08, `.profile` serves this purpose: it's sourced by both bash & zsh, for both login and interactive sessions. But since `.profile` is a standard bash rc file name, maybe I should pull out the common env-stage stuff to a separate file, to make it more obvious what I'm doing here.
- More use of anonymous functions for variable hygiene?
- Homebrew/MacPorts loading
  - "auto" option for loading only one or the other of Homebrew or MacPorts if they both exist. Right now, set `$JX_USE_{HOMEBREW,MACPORTS}` both to true, and you get both loaded if they both exist.
     - That prob means switching to a single variable to control package managers, with values `homebrew`, `macports`, `auto`, `both`, and `none`. And the default should prob be `auto`. Along with another variable that sets the preferred one for `auto` for the case that both exist.
- Not sure I like the name `wet_vrb`. Maybe pick a better name? Or switch names `wet` and `wet_vrb`, interpreting `wet_vrb` to mean "`wet`, always with verbose-style output (regardless of whether `--verbose` enabled more)? And maybe it should also echo the command when `--debug` but not `--verbose` was given too?
- Make sure the `wet` output call is safe against `-` characters; maybe need to switch to printf?

### Big "framework + config" repo split?

- The `dots/` project subdir mixes two things: the sync/install framework and shell-rcfile structure (bash+zsh, multiple configurators) vs. my personal dotfile contents/preferences. Consider splitting the framework part out as its own project/repo, maybe named "dotframe" or "dotframe-jx". Not started.
- Split this repo into a public `dotfiles` (framework + non-sensitive config) and a private `dotfiles-private` repo for anything sensitive (starting with `~/.claude/CLAUDE.md`), with `install-dotfiles` layering the private repo's files in. Started: the linking engine now lives in `lib/dotinstall-lib.sh`, shared with `dotfiles-private`'s own `install-dotfiles-private`; `.linkdir`/`.linkdirs` markers support whole-directory links at an arbitrary nesting depth, which `~/.claude/skills/<skill>/` needs.
- Factor out user-specific customizations (like the list of "default" user names) to separate files, to make this easier to reuse across users.
- Load Ruby stuff from alternate locations and different platforms.

## Specific programs

- Look in to the XDG spec and its `~/.config` etc dirs, and see which programs support that now.
- Is there some way to *forcibly* prevent `conda init` from modifying the user and system init files, even when the user manually runs `conda init`?

## Aliases and functions

- Have `grhino` respect the `grin` exclusions?

## Details

### Getting Ruby dev env working on Mac

References:

- The "Ruby on Mac" guy
  - <https://www.moncefbelyamani.com/the-definitive-guide-to-installing-ruby-gems-on-a-mac/>

### sudo bash problem

When doing `sudo bash` on Mac, it spews a bunch of error messages like this:

```text
bash: jx_maybe_add_path: command not found
bash: have: command not found
bash: have: command not found
bash: have: command not found
[...]
bash: have: command not found
bash: /opt/homebrew/etc/bash_completion.d/dvd+rw-tools: line 19: syntax error near unexpected token `('
bash: /opt/homebrew/etc/bash_completion.d/dvd+rw-tools: line 19: `        /?(r)dev/*)'
bash: have: command not found
bash: have: command not found
bash: have: command not found
[...]
bash: have: command not found
bash: source: /opt/homebrew/etc/bash_completion.d/helpers: is a directory
bash: have: command not found
bash: have: command not found
[...]
```

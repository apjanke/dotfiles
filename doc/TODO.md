# TODO - dotfiles

## General

- Add more documentation. A Design doc.
- Tool in zsh to quick switch to a simpler no-emoji theme suitable for copy-paste, in current session.
- `install-dotfiles`
  - Make it safe. Don't replace existing non-symlink files, unless `--clobber` is given. Make backups of clobbered files. Update existing symlinks.
  - Cleanup: Remove old symlinks for files that have been removed from this repo. Keep a list of files which were here in the past but removed, check for symlinks in home pointing to those files *in this repo but not elsewhere*, and delete them.
  - When adding the first `deep/_ssh/` or `deep/_gnupg/` content, verify and add a test for the `chmod 700` in `install_dotfiles_deep`. That branch has never run, and it fails silently when wrong: a group-writable `~/.ssh` under a umask of 002 makes sshd's StrictModes refuse public-key auth, which shows up much later as an unexplained fallback to password auth.
- Split this repo into a public `dotfiles` (framework + non-sensitive config) and a private `dotfiles-private` repo for anything sensitive (starting with `~/.claude/CLAUDE.md`), with `install-dotfiles` layering the private repo's files in. Not started.
- The `dots/` project subdir mixes two things: the sync/install framework and shell-rcfile structure (bash+zsh, multiple configurators) vs. my personal dotfile contents/preferences. Consider splitting the framework part out as its own project/repo, maybe named "dotframe" or "dotframe-jx". Not started.
- `.profile-local` support, e.g. for setting homebrew/macports on a per-box basis.
  - Also maybe a hook early enough in the process I can set `$JX_TRACE_SHELL_STARTUP` early enough to work
- In `.profile`, don't auto-set all those `JX_*` variables. Just support them being unset everywhere. So you can tell the difference between something a user set and the scripts using the defaults.
  - And figure out a place separation between a listing of all the vars that exist and their default values, vs. my actual user configuration of setting one. Distinguish between actual user configuration and shell script implementation of handling that configuration.
- `jx_maybe_add_path` - conditionalize on "already in `$PATH`", not just dir existence; --prepend option form
- `jx-shell-info`
  - Distinguish unset variables from blank strings.
  - Reformat JX dotfiles variables to have spaces around " = ".
  - List presence of optional files, like `~/.*-local`.
  - Support multi-line JX variables?
  - Include my special non-JX-prefixed variables, like DROPBOX.
  - `-v | --verbose` option: show internal `_JX_*` vars, longer formatting
- A `_jx_do` function to echo a command and then run it.
- GitHub protection rule to prohibit force-pushing `main`.
- Make .hgignore_global a symlink to .gitignore_global?
  - Add support for relative symlinks, like `.hgignore_global -> .gitignore_global`?
- Detect breakage in installation?
  - In the startup scripts, check for presence of required files linked in to ~ and complain if they're absent? To catch things like needing a fresh `install-dotfiles` run after I add/remove/rename linked files in the repo.
- `zshrc-ohmyzsh.zsh`
  - Pull default values for ZSH_THEME up into .zshenv or .profile?
- Make `jx-conda-load` work on bash too, and remove the unconditional conda load in `bashyrc.sh`.
- Move path setup up in to env/login stage.
- `.*env` files to go with `.*rc` files, or a common `.dotlib/bashyenv.sh`?
- Review and tighten up the shell file calling order and its documentation here.
- Look in to the XDG spec and its `~/.config` etc dirs, and see which programs support that now.
- Factor out user-specific customizations (like the list of "default" user names) to separate files, to make this easier to reuse across users.
- Figure out the conventions for when shell env files should clobber variables vs. leave already-set variables alone.
  - Think I need this to make `~/.profile` shareable between zsh and bash, if I want `~/.zshenv` or `~/.zprofile` to source it.
- Prefix my custom env and global shell variable names with `JX_` or similar.
- Prefix more internal variables, like `__jx_uname` instead of `__uname`.
- Fix everything to work with `sudo bash`.
- More use of anonymous functions.
- "auto" option for loading only one or the other of Homebrew or MacPorts if they both exist. Right now, set `$JX_USE_{HOMEBREW,MACPORTS}` both to true, and you get both loaded if they both exist.
  - That prob means switching to a single variable to control package managers, with values `homebrew`, `macports`, `auto`, `both`, and `none`. And the default should prob be `auto`. Along with another variable that sets the preferred one for `auto` for the case that both exist.
- Load Ruby stuff from alternate locations and different platforms.
- Is there some way to prevent conda init from modifying the user and system init files?
- Consider `: ${MY_VAR:=default}` expansion form.

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

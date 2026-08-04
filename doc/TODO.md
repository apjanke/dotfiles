# TODO - dotfiles

## General

- Add more documentation. A Design doc.
- `install-dotfiles`
  - Make it safe. Don't replace existing non-symlink files, unless `--clobber` is given. Make backups of clobbered files. Update existing symlinks.
- Deep symlinks - symlinks for files in subdirs, like .config or .ssh.
- Replace old "APJ_" prefix with "JX_"?
- Rename "osx" things to "macos"?
- `.profile-local` support, e.g. for setting homebrew/macports on a per-box basis.
  - Also maybe a hook early enough in the process I can set `$JX_TRACE_SHELL_STARTUP` early enough to work
- In `.profile`, don't auto-set all those `JX_*` variables. Just support them being unset everywhere. So you can tell the difference between something a user set and the scripts using the defaults.
  - And figure out a place separation between a listing of all the vars that exist and their default values, vs. my actual user configuration of setting one. Distinguish between actual user configuration and shell script implementation of handling that configuration.
- GitHub protection rule to prohibit force-pushing `main`.
- Detect breakage in installation?
  - In the startup scripts, check for presence of required files linked in to ~ and complain if they're absent? To catch things like needing a fresh `install-dotfiles` run after I add/remove/rename linked files in the repo.
- Make `jx-conda-load` work on bash too, and remove the unconditional conda load in `bashyrc.sh`.
- Move path setup up in to env/login stage.
- `.*env` files to go with `.*rc` files, or a common `.dots/bashyenv.sh`?
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

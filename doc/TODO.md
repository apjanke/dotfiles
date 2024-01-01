# TODO - dotfiles

## General

* Why isn't `.profile` getting loaded in new zsh tabs in iTerm2?
  * `jx_maybe_add_path` is missing.
* Fix everything to work with `sudo bash`.
* "auto" option for loading Homebrew iff MacPorts is not present and Homebrew is.
* Load Ruby stuff from alternate locations and different platforms.
* Is there some way to prevent conda init from modifying the user and system init files?
* Consider `: ${MY_VAR:=default}` expansion form.

## Details

### Getting Ruby dev env working on Mac

References:

* The "Ruby on Mac" guy
  * <https://www.moncefbelyamani.com/the-definitive-guide-to-installing-ruby-gems-on-a-mac/>

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

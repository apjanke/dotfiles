# CLAUDE.md

Instructions for Claude Code working in this repo. See [README.md](../README.md) for what the repo is, and [doc/STYLE.md](../doc/STYLE.md) for the shell coding conventions.

# AI use in coding

My AI-assisted coding style is the opposite of "slop code" or "vibecoding". I care about correctness and robustness, and pay close attention to the actual code we are producing. Learning how the code works is an important part of the AI-assisted programming process; I don't want a "just do it for me" workflow.

# This repo is public

`github.com/apjanke/dotfiles` is published so others can read and reuse the code and techniques. Everything committed here is world-readable.

- Never commit credentials, tokens, API keys, or other secrets.
- Be wary of files that mix configuration with private or personal data. `~/.claude/CLAUDE.md` is deliberately excluded from the symlinking for exactly that reason.
- Default to not adding personal or sensitive content to any tracked file. Ask when it is unclear whether something qualifies.
- Weigh world-readability when proposing new symlink targets, config files, or `install-dotfiles` features.
- The long-term plan is to split this into the public `dotfiles` repo (framework plus non-sensitive config) and a separate private repo for the sensitive parts, with `install-dotfiles` layering the private files in.
- Don't mention Claude outside `.claude/` and the "AI use disclosure" section of `README.md`.

# Checking your work

Both run from the repo root and exit non-zero on any problem, so they work in CI:

- `./dots/tests/run-tests` – runs every `dots/tests/test-*` script. Those install into a throwaway `$HOME` and never touch the real one. Pass names to run a subset: `run-tests bashy-paths`.
- `./tools/lint` – shellcheck for bash/sh, `zsh -n` for zsh (shellcheck has no zsh dialect), plus a grep backstop for bash 4+ constructs.

Run both before calling shell work done.

# Don't run these

- **`./install-dotfiles` for real.** It writes to my actual `$HOME`. I run it myself. The tests exercise it against a fake `$HOME`.
- **Anything in `sys-setup/`.** Those `sudo` and change system state. I run them myself, on a VM.

# bash 3.2 is the floor

`/bin/bash` on macOS is 3.2.57, and everything here has to work under it. No associative arrays, no `${var,,}`, no `mapfile`/`readarray`, no `local -`, no `globstar`, no `lastpipe`.

These fail at *runtime*, not parse time, so `bash -n` doesn't catch them and neither does shellcheck, which has no option to target a bash version. Hence the grep-based blacklist in `tools/lint` – a backstop, not a real check. Suppress a false positive with a `# jx-lint-ok: bash4` comment on the line, or `# jx-lint-ok-file: bash4` on a line of its own.

The test suite runs across bash 3.2, bash 4+/5.x, and both system and Homebrew zsh, so a bash-4-ism usually surfaces there too.

See "Staying on bash 3.2" and "Emulating associative arrays" in [doc/STYLE.md](../doc/STYLE.md).

# JXL

`dots/all-os/flat/dotlib/jxl-lib.sh` holds the shared shell boilerplate – messaging, standard CLI options, dry-run helpers, array accessors – used by both shebang scripts and interactive command functions. See "Loading JXL" in [dots/README.md](../dots/README.md) for how files load it and why the prologue looks the way it does.

Two scripts deliberately don't use it: `tools/lint` and `dots/tests/run-tests`. Diagnostic and test tooling has to keep working when JXL itself is what's broken. The `jx-rainbow-me` command function in `bashyrc.sh` also skips it, being too small to benefit.

# Comments

Keep them short. Assume a reader proficient in bash and zsh and already familiar with this project. One line for the non-obvious *why*; nothing that restates what the code already says. No paragraph-style justification, even for tricky behavior – a short pointer is enough for the assumed reader. This applies to existing comments too: trim over-explained ones when working nearby.

# The `jx` namespace

`jx` (short for "Janke") namespaces shell identifiers in `dots/`:

- `_jx` / `__jx` – helpers that persist past the sourcing of a file, i.e. that end up living in the interactive shell.
- `jx-` – interactive functions: the big, unusual-use, or very dotfiles-specific ones.
- unprefixed – commonly-used interactive functions that read like ordinary commands.

Partly aspirational; existing code hasn't fully migrated (see the `APJ_` → `JX_` and `__uname` → `__jx_uname` items in `doc/TODO.md`).

This does not apply to `sys-setup/`, `home-bin/`, or `tools/`, which hold standalone shebang scripts where nothing persists past execution. Those use plain names, with a bare leading underscore for small internal helpers (`_do`, `_read_lines`) alongside unprefixed `main` and `usage`.

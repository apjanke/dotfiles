# Style - dotfiles

Shell code conventions for this repo.

I don't care much about `ksh`, and not at all about `dash`/`ash`, so while the
implementation supports them in many places, I won't bother mentioning them in
documentation like this.

## Formatting conventions

See `.editorconfig` for formatting conventions. This doc only lists things `.editorconfig`
cannot express.

### Continuation lines

A statement wrapping onto another line after a trailing `\` indents 4 spaces past the
first line of the statement.

Doesn't apply where the lines are aligning with *each other* rather than continuing a
statement – multi-item lists and pipeline stages keep their own alignment.

### Redirection spacing

A space between `>` (or `<`) and a destination that names a *file*: `> /dev/null`, not
`>/dev/null`. No space when redirecting one stream to another by file descriptor: `2>&1`,
not `2> &1`.

## Static checking

`tools/lint` from the repo root; exits non-zero on findings.

Uses separate checkers, since shellcheck has no zsh dialect, and will give false positives
if run on zsh. Use:

- **bash/sh** → [shellcheck](https://www.shellcheck.net/)
- **zsh** → `zsh -n` (syntax only, but the best available)

Checker selection is by extension (`.sh`/`.bash` vs `.zsh`), falling back to the shebang,
so name files accordingly.

bash/sh files get a third pass, a grep for constructs needing a bash newer than 3.2. See
"Staying on bash 3.2" below.

## Multi-mode files (sourced by both bash and zsh)

We have some files which are sourced by both bash and zsh, and they may include some
zsh-only code, if properly guarded.

Distinguish zsh-only *syntax* from zsh-only *behavior*. Zsh-only **syntax** can't appear
at all, not even behind a `$ZSH_VERSION` guard, because bash parses the whole file and
errors out on bad syntax. Aborted execution can leave a half-configured shell; no good.
Zsh-only **syntax** code must go in a separate `.zsh` file.

### Silent divergences

Worse than a syntax error, because the code parses and runs in both shells and just does
something different. Known traps:

- **zsh doesn't word-split unquoted expansions**, even with `IFS` set. `IFS=:; for p in
  $PATH` walks 24 components in bash and 1 in zsh. Walk the string with `${var%%:*}` /
  `${var#*:}` instead.
- **zsh arrays are 1-indexed, bash 0-indexed**, while `${#arr[@]}` reports the same count
  in both. So `for ((i=0; i<${#arr[@]}; i++))` runs clean in both and silently drops the
  last element in zsh. Avoid numeric array indexing in shared files; prefer `for x in
  "${arr[@]}"`, or no arrays at all.
- **`$var[...]` is array subscripting in zsh**, so `"$out[$item]"` is a parse error there.
  Brace any expansion followed by a `[`: `"${out}[${item}]"`.

**Behavior in bash-parseable syntax** is fine, guarded at runtime. Disable shellcheck on
it using `# shellcheck disable=all`. If there's more than one line of zsh-only code, stick
it in a function so you can use a function-scoped `shellcheck disable`. For single lines,
put the `disable` on that one line. In either case, make sure it's not at the top of the
file - some other command must come first - so you don't accidentally disable shellcheck
on the entire file.

```bash
# shellcheck disable=all
_zsh_only_setup() {
  setopt some_zsh_option
}

if [[ -n ${ZSH_VERSION:-} ]]; then
  _zsh_only_setup
fi
unset -f _zsh_only_setup
```

This `shellcheck disable` suppresses reporting, not analysis, so a variable used only
inside isn't then misreported as unused. The `$ZSH_VERSION` guard goes on the call site:
the function must be *defined* under both shells, *run* only under zsh. Clean it up with
`unset -f`, not `unfunction`, which is zsh-only.

## Hygienic sourced scripts

Undefine functions and unset non-`local` variables created solely for use during sourcing.
Otherwise, they leak into the interactive namespace. Deliberate persistent globals are
exempt, of course.

For functions, use `unfunction` in zsh-only code, and `unset -f` in bash or mixed-mode
code.

Do not use `2>/dev/null` on unfunction or unset calls. Let that error show and fix its
cause, detecting existence of conditionally defined functions and variables when
necessary. Detection: for variables, `[[ -n ${var+x} ]]`; for functions,
`(( $+functions[f] ))` in zsh, `typeset -f f >/dev/null` in bash or mixed-mode.

## Portability

Either GNU or BSD userland. Use invocations valid for both, or detect at runtime.
Bash-isms (arrays, `[[ ]]`) are fine; POSIX `sh` purity isn't the goal. But macOS ships
bash 3.2, which is what `#!/bin/bash` resolves to there, so no bash 4+ features
(associative arrays, `${var,,}`).

Handle file names with spaces, non-ASCII, and metacharacters: `printf '%s\n'` not `echo`
for arbitrary strings, `find -print0` with `xargs -0` or `read -r -d ''` for name lists,
`--` before file name arguments.

### Staying on bash 3.2

Nothing static catches a bash 4 feature on its own. shellcheck has no version targeting,
and `bash -n` under 3.2 exits 0 on all of them – they're *runtime* failures, not parse
errors, so bash 3.2 parses `${var,,}` happily and only says "bad substitution" when the
line executes. A bash 4 construct in a branch that rarely runs stays hidden until it runs
on a Mac.

So `tools/lint` greps for the known ones. It's a blacklist – it knows its table and nothing
else, so a clean run is not a guarantee. Add entries as new traps turn up.

Escape hatches, where a newer bash is deliberate:

- `# jx-lint-ok: bash4` at the end of a line exempts that line.
- `# jx-lint-ok-file: bash4`, alone on its own line, exempts the whole file.

The file form is anchored to a line holding nothing else, so that merely documenting the
directive doesn't exempt the file. `tools/lint` silently skipped itself that way until the
anchor went in.

### Emulating associative arrays

Bash 3.x does not have associative arrays. So emulate them, using one flat array of
alternating key/value entries, walked with a stride of 2:

```bash
tbl=(
  'key-one'   'value one'
  'key-two'   'value two'
)
for ((i = 0; i < ${#tbl[@]}; i += 2)); do
  key="${tbl[i]}" value="${tbl[i+1]}"
done
```

Subscripts are arithmetic contexts, so the index needs no `$`.

Not two parallel arrays: adding an entry to one and forgetting the other misaligns every
pair after it, and every lookup past that point is wrong without anything failing. And the
source code reads better with a single 2-stride array. Check for an odd length up front –
the one failure mode this form adds.

## Program output streams

Use stderr for diagnostics, stdout for data output. "Diagnostics" means all of it,
progress and success included, not just errors. That keeps the data stream clean for
pipeline consumers, and avoids misordering due to buffering differences between stdout and
stderr.

When it's unclear which a message is, consider what the program's "work product" is. The
work product goes on stdout. For `tools/lint` it's the findings, so the "clean" summary is
commentary → stderr. For `run-tests` it's the pass/fail record itself, so results →
stdout, where they can be captured and parsed.

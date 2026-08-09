# bashy-paths.sh - common bashlike path setup
#
# This gets called by bashyrc.sh or .profile. This code could just go inline
# there, but I've factored it out to a separate file to make it easier to switch
# around exactly where in the startup sequence it gets called, while I'm figuring
# out the exact Right Way to arrange all this shell startup stuff. Plus, it
# probably makes things more readable, given how large these startup scripts have
# gotten.

# shellcheck shell=bash

# Call uname once and stash results for performance
if [[ -z $__jx_uname ]]; then
  __jx_uname=$(uname)
fi


#TODO: Decide whether to accept arguments with internal ":" (path separator) special
# characters, and whether those are escaped or treated as path separators.

function jx_maybe_add_path() {
  # Add dirs to $PATH if they exist and aren't already on it.
  #
  # Usage: jx_maybe_add_path [--prepend|--append] [--move] [--case yes|no|auto] DIR...
  #
  # Dirs are processed left to right, as if called once per dir. With --prepend that puts
  # them on $PATH in reverse argument order; that's expected, not a bug.
  #
  # --move repositions a dir that's already on $PATH to the requested end. Without it, an
  # already-present dir is left where it is.
  #
  # --case controls whether an existing entry matches case-insensitively. "auto" (the
  # default) follows the OS's usual filesystem: case-sensitive on Linux, insensitive on
  # macOS and Windows. It does not probe the actual filesystem.
  #
  # Sourced by both bash and zsh, so: no arrays (zsh indexes from 1, bash from 0), and no
  # `for x in $PATH` (zsh doesn't word-split, even with IFS=:). Hence the string walking.
  local where=append move=0 casing=auto
  local dir found_entry rest item newpath lc_all lc_dir lc_item lc_rest

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prepend) where=prepend; shift ;;
      --append)  where=append;  shift ;;
      --move)    move=1;        shift ;;
      --case)    casing="$2";   shift 2 ;;
      --)        shift; break ;;
      -*)        echo >&2 "jx_maybe_add_path: unknown option: $1"; return 1 ;;
      *)         break ;;
    esac
  done

  case "$casing" in
    yes|no) ;;
    auto)
      # Match the OS's default filesystem behavior.
      case "$__jx_uname" in
        Darwin|CYGWIN*|MINGW*|MSYS*) casing=no ;;
        *)                           casing=yes ;;
      esac
      ;;
    *) echo >&2 "jx_maybe_add_path: --case takes yes, no, or auto; got '$casing'"; return 1 ;;
  esac

  for dir in "$@"; do
    # The old positional form silently becomes a no-op otherwise: "prepend" is not a
    # directory, so it would just be skipped and its real dir never added.
    case "$dir" in
      prepend|append)
        echo >&2 "jx_maybe_add_path: '$dir' is not a directory; the positional form was replaced by --$dir"
        continue
        ;;
    esac
    [[ -d "$dir" ]] || continue

    # Find the existing entry, keeping its original spelling: a case-insensitive match on
    # /Users/Foo against an existing /users/foo has to move /users/foo, not re-add ours.
    found_entry=""
    if [[ $casing == yes ]]; then
      case ":$PATH:" in
        *":$dir:"*) found_entry="$dir" ;;
      esac
    else
      # One tr per dir, not one per $PATH component: lowercase $PATH and $dir in a single
      # fork, then walk the two in lockstep. Lowercasing doesn't move any colons, so the
      # two strings split identically, and we can report the original-cased entry.
      lc_all=$(printf '%s\n%s' "$PATH" "$dir" | tr '[:upper:]' '[:lower:]')
      lc_rest="${lc_all%%$'\n'*}"
      lc_dir="${lc_all#*$'\n'}"
      rest="$PATH"
      while [[ -n "$rest" ]]; do
        case "$rest" in
          *:*) item="${rest%%:*}"; rest="${rest#*:}" ;;
          *)   item="$rest"; rest="" ;;
        esac
        case "$lc_rest" in
          *:*) lc_item="${lc_rest%%:*}"; lc_rest="${lc_rest#*:}" ;;
          *)   lc_item="$lc_rest"; lc_rest="" ;;
        esac
        if [[ "$lc_item" == "$lc_dir" ]]; then
          found_entry="$item"
          break
        fi
      done
    fi

    if [[ -n "$found_entry" ]]; then
      [[ $move == 1 ]] || continue
      # Already at the requested end? Nothing to do.
      if [[ $where == prepend ]]; then
        case "$PATH" in "$found_entry":*) continue ;; esac
      else
        case "$PATH" in *:"$found_entry") continue ;; esac
      fi
      newpath=""
      rest="$PATH"
      while [[ -n "$rest" ]]; do
        case "$rest" in
          *:*) item="${rest%%:*}"; rest="${rest#*:}" ;;
          *)   item="$rest"; rest="" ;;
        esac
        if [[ "$item" != "$found_entry" ]]; then
          newpath="${newpath:+${newpath}:}${item}"
        fi
      done
      PATH="$newpath"
      dir="$found_entry"
    fi

    if [[ $where == prepend ]]; then
      PATH="${dir}${PATH:+:${PATH}}"
    else
      PATH="${PATH:+${PATH}:}${dir}"
    fi
  done
}

# Prefer local installations
PATH="/usr/local/bin:$PATH"

# Custom local dirs defined by this dotfiles framework or just my habits

jx_maybe_add_path --prepend "$HOME/bin"
jx_maybe_add_path --prepend "$HOME/bin-jx"
if [[ $__jx_uname = "Darwin" ]]; then
  jx_maybe_add_path --prepend "$HOME/bin-jx/macos"
fi
# Sheesh. I haven't been able to settle on a conventional local bin location, have I?
jx_maybe_add_path --prepend "$HOME/bin-local"
jx_maybe_add_path --prepend "$HOME/local/bin"
jx_maybe_add_path --prepend "$HOME/.local/bin"


# RVM and Ruby

# TODO: Should this go to the front, to shadow system installations?
jx_maybe_add_path "$HOME/.rvm/bin"

#!/bin/bash
#
# dotinstall-lib.sh - shared symlink-installer engine
#
# Sourced by install-dotfiles (this repo) and by other repos' own installers, such as
# dotfiles-private's install-dotfiles-private. Exposes dotinstall::* functions; see the
# header comment on each. Not meant to be symlinked into $HOME -- unlike
# dots/all-os/flat/dotlib/, which IS (as ~/.dotlib), this is installer-time tooling, not
# shell runtime support, which is why it lives at the repo's top level instead.
#
# Two source trees per caller, siblings under each `DOTDIR/<osname>/` root passed to
# dotinstall::install_flat_tree / dotinstall::install_nested_tree. ("all-os" applies to
# all OSes; per-OS entries take precedence over it in both trees.) See dots/README.md for
# the full semantics; install-dotfiles's own header has the short version.
#
# A caller must call dotinstall::detect_os_type before either install_*_tree function --
# both read $OSNAME. A caller MUST set $_DOTINSTALL_REPO_ROOTS (an array of one or more
# repo root paths -- e.g. install-dotfiles-private includes both its own repo and the
# public dotfiles repo it depends on) before either function too: it's what
# dotinstall::symlink uses to tell a stale-but-ours symlink from a foreign one. A caller
# MAY also set $_DOTINSTALL_OPT_RELINK=1 and/or $_DOTINSTALL_OPT_CLOBBER=1 -- see
# dotinstall::symlink for what each does. Defaults are the safe, do-nothing settings.

# Bump this if a caller-visible function's name, argument order, or behavior changes, so a
# caller that checks it can fail loudly instead of half-working. Bumped to 2 when
# $_DOTINSTALL_REPO_ROOTS and $_DOTINSTALL_OPT_CLOBBER were added: an un-updated caller
# that doesn't set $_DOTINSTALL_REPO_ROOTS must not silently fall back to the old blunt
# "relink anything" behavior.
_DOTINSTALL_LIB_API=2

# Load JXL relative to this file, not the caller -- a caller in another repo shouldn't have
# to know this repo's internal layout.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../dots/all-os/flat/dotlib/jxl-lib.sh" \
    || { echo >&2 "ERROR: dotinstall-lib.sh: failed to load jxl-lib.sh"; return 1; }

_DOTINSTALL_ANY_CHANGED=0
_DOTINSTALL_ALREADY=0
_DOTINSTALL_SKIPPED=0
_DOTINSTALL_CLOBBERED=0
_DOTINSTALL_FAILED=0
_DOTINSTALL_OPT_RELINK=0
_DOTINSTALL_OPT_CLOBBER=0
_DOTINSTALL_REPO_ROOTS=()

function dotinstall::detect_os_type() {
  # Post: $OSNAME is set, or the script has exited with an error status
  uname=$(uname)
  case $uname in
    Darwin)
      # Apple renamed "Mac OS X" to "macOS" at some point; accept both.
      if which sw_vers &>/dev/null && [[ $(sw_vers -productName) == "Mac OS X" || $(sw_vers -productName) == "macOS" ]]; then
        OSNAME=macos
      else
        OSNAME=darwin
      fi
      ;;
    *)
      OSNAME="$uname"
      ;;
  esac
}

function dotinstall::is_repo_managed() {
  # dotinstall::is_repo_managed PATH -- true iff PATH lies under one of
  # $_DOTINSTALL_REPO_ROOTS. An empty/unset roots array correctly means "nothing is
  # repo-managed" (dotinstall::_path_under would otherwise treat an empty root as "/" and
  # match every absolute path).
  local path="$1" root
  for root in ${_DOTINSTALL_REPO_ROOTS[@]+"${_DOTINSTALL_REPO_ROOTS[@]}"}; do
    [[ -n $root ]] || continue
    dotinstall::_path_under "$path" "$root" && return 0
  done
  return 1
}

function dotinstall::_do_link() {
  # dotinstall::_do_link SOURCE TARGET VERB [SUFFIX]
  # out: $_DOTINSTALL_ANY_CHANGED, $_DOTINSTALL_THIS_CHANGED, $_DOTINSTALL_FAILED
  local source="$1" target="$2" verb="$3" suffix="${4:-}" descr
  descr=$(printf '%-18s -> %s\n' "$target" "$source")
  # wet_vrb, not wet: on a dry run the raw `ln` line is verbose-only detail, while the
  # verb line below is the preview worth seeing. Running the normal logging path is half
  # the value of a dry run -- it exercises those branches too.
  if jxl::wet_vrb ln -sfn "$source" "$target"; then
    _DOTINSTALL_ANY_CHANGED=1; _DOTINSTALL_THIS_CHANGED=1
    jxl::info "$verb: $descr$suffix"
  else
    _DOTINSTALL_FAILED=$((_DOTINSTALL_FAILED + 1))
    jxl::error "Failed: $descr"
  fi
}

function dotinstall::_backup() {
  # dotinstall::_backup PATH -- moves PATH to PATH.bak, or PATH.bak-<datetime>.bak if that
  # already exists, or PATH.bak-<datetime>-<pid>.bak if even that's taken (two clobbers of
  # the same target within one second, e.g. from a test loop -- $$ is a cheap
  # always-different-per-process tiebreaker). Returns 1 (reports Failed, touches nothing)
  # if no slot is free or the move itself fails -- the caller MUST NOT link on a nonzero
  # return, since ln -sfn's -f would then delete PATH outright.
  # out: $_DOTINSTALL_FAILED
  local path="$1"
  local backup="$path.bak"
  if [[ -e $backup || -L $backup ]]; then
    backup="$path.bak-$(date +%Y%m%d-%H%M%S).bak"
    if [[ -e $backup || -L $backup ]]; then
      backup="$path.bak-$(date +%Y%m%d-%H%M%S)-$$.bak"
    fi
  fi
  if [[ -e $backup || -L $backup ]]; then
    jxl::error "Failed: no free backup slot for '$path'"
    _DOTINSTALL_FAILED=$((_DOTINSTALL_FAILED + 1))
    return 1
  fi
  if jxl::wet_vrb mv "$path" "$backup"; then
    jxl::info "Backed up: $path -> $backup"
  else
    jxl::error "Failed: could not back up '$path'"
    _DOTINSTALL_FAILED=$((_DOTINSTALL_FAILED + 1))
    return 1
  fi
}

function dotinstall::symlink() {
  # out: $_DOTINSTALL_ANY_CHANGED, $_DOTINSTALL_THIS_CHANGED, $_DOTINSTALL_ALREADY,
  #      $_DOTINSTALL_SKIPPED, $_DOTINSTALL_CLOBBERED, $_DOTINSTALL_FAILED
  # in: $_DOTINSTALL_OPT_RELINK, $_DOTINSTALL_OPT_CLOBBER, $_DOTINSTALL_REPO_ROOTS
  #
  # An existing symlink pointing somewhere OTHER than $source is handled two different
  # ways, depending on whether its CURRENT target is recognizable as repo-managed (under
  # one of $_DOTINSTALL_REPO_ROOTS):
  #   - repo-managed but stale (e.g. a file that moved within the repo): relinked if
  #     $_DOTINSTALL_OPT_RELINK OR $_DOTINSTALL_OPT_CLOBBER is set (clobber implies
  #     relink -- consenting to the more dangerous operation implies consenting to the
  #     strictly less risky one), else reported SKIPPED.
  #   - not repo-managed ("foreign"): the same bucket as a pre-existing regular
  #     file/directory below -- backed up and replaced under $_DOTINSTALL_OPT_CLOBBER,
  #     else reported SKIPPED.
  # The current target is compared as the literal string readlink returns, never
  # resolved -- a relative target therefore never matches a repo root and is always
  # foreign. That's deliberate: resolving would also resolve symlinks in the recorded
  # root, which the "invoked through a symlink" test relies on NOT happening.
  local source="$1" target="$2"
  _DOTINSTALL_THIS_CHANGED=0
  local current_source=''
  if [[ -L $target ]]; then
    current_source=$(readlink "$target")
    if [[ $current_source == "$source" ]]; then
      jxl::verbose "Already set up: $(printf '%-18s -> %s' "$target" "$source")"
      _DOTINSTALL_ALREADY=$((_DOTINSTALL_ALREADY + 1))
    elif dotinstall::is_repo_managed "$current_source"; then
      if [[ $_DOTINSTALL_OPT_RELINK == 1 || $_DOTINSTALL_OPT_CLOBBER == 1 ]]; then
        dotinstall::_do_link "$source" "$target" Relinked " (was -> $current_source)"
      else
        jxl::info "SKIPPED: $target is a symlink to '$current_source' (not '$source');" \
            "pass --relink to update it"
        _DOTINSTALL_SKIPPED=$((_DOTINSTALL_SKIPPED + 1))
      fi
    elif [[ $_DOTINSTALL_OPT_CLOBBER == 1 ]]; then
      if dotinstall::_backup "$target"; then
        _DOTINSTALL_CLOBBERED=$((_DOTINSTALL_CLOBBERED + 1))
        dotinstall::_do_link "$source" "$target" Clobbered
      fi
    else
      jxl::info "SKIPPED: $target is a symlink to '$current_source', not managed by a" \
          "recognized dotfiles repo; pass --clobber --yes-really to replace it"
      _DOTINSTALL_SKIPPED=$((_DOTINSTALL_SKIPPED + 1))
    fi
  elif [[ -e $target && ! -L $target ]]; then
    if [[ $_DOTINSTALL_OPT_CLOBBER == 1 ]]; then
      if dotinstall::_backup "$target"; then
        _DOTINSTALL_CLOBBERED=$((_DOTINSTALL_CLOBBERED + 1))
        dotinstall::_do_link "$source" "$target" Clobbered
      fi
    else
      local file_type
      if [[ -f $target ]]; then
        file_type='regular file'
      elif [[ -d $target ]]; then
        file_type='non-symlink directory'
      else
        file_type='file of some sort (neither regular file nor symlink)'
      fi
      jxl::info "SKIPPED: $target is a $file_type"
      _DOTINSTALL_SKIPPED=$((_DOTINSTALL_SKIPPED + 1))
    fi
  else
    dotinstall::_do_link "$source" "$target" Linked
  fi
}

function dotinstall::install_flat_tree() {
  # DOTDIR/{all-os,$OSNAME}/flat/ -> ~/.foo. Pre: cwd is the target home. Reads $OSNAME.
  # A missing DOTDIR/all-os/flat is not an error -- a caller with only a nested tree (e.g.
  # dotfiles-private) has none.
  local dotdir="$1"
  local dotfiles file tofile fromfile seen_targets=""
  local allosdir="$dotdir/all-os/flat" osdir="$dotdir/$OSNAME/flat"

  [[ -d $allosdir ]] || return 0

  if [[ -d $osdir ]]; then
      # shellcheck disable=SC2207
      dotfiles=( $( (ls "$allosdir"; ls "$osdir") | sort | uniq ) )
  else
      # shellcheck disable=SC2207
      dotfiles=($(ls "$allosdir"))
  fi

  # An existing-but-empty all-os/flat is legitimate (a synthetic tree in a test, e.g.), and
  # "${dotfiles[@]}" on an empty array is an unbound-variable error under bash 3.2 nounset.
  [[ ${#dotfiles[@]} -eq 0 ]] && return 0

  # Catch e.g. a stale zshrc.sh next to zshrc.zsh before linking anything.
  for file in "${dotfiles[@]}"; do
    tofile=$(dotinstall::munge_dotfile_name "$file")
    if [[ " $seen_targets " == *" $tofile "* ]]; then
      jxl::die "ERROR: Two source files in $dotdir both install as '$tofile'." \
          "Nothing was changed. Most likely a rename left a stale file behind."
    fi
    seen_targets+=" $tofile"
  done

  for file in "${dotfiles[@]}"; do
    tofile=$(dotinstall::munge_dotfile_name "$file")
    if [[ -e $osdir/$file ]]; then
      fromfile="$osdir/$file"
    else
      fromfile="$allosdir/$file"
    fi
    dotinstall::symlink "$fromfile" "$tofile"
  done
}

function dotinstall::munge_dotfile_name() {
  # Turn a flat-tree source filename into the name it installs as in ~.
  #
  # Use a case rather than the tidier extglob one-liner ".${1%.@(sh|zsh|bash)}" bc
  # extglob is off by default in bash and you get wrong names.
  local name="$1"
  case "$name" in
    *.sh)    echo ".${name%.sh}"   ;;
    *.zsh)   echo ".${name%.zsh}"  ;;
    *.bash)  echo ".${name%.bash}" ;;
    *)       echo ".$name"         ;;
  esac
}

function dotinstall::_path_under() {
  # dotinstall::_path_under PATH DIR -- true iff PATH lies strictly inside DIR (not equal
  # to it). A plain substring comparison, not a glob match, so a literal '[' or '*' in DIR
  # is never misread as a pattern.
  local path="$1" dir="$2"
  local prefix="${path:0:$((${#dir}+1))}"
  [[ $prefix == "$dir/" ]]
}

function dotinstall::install_nested_tree() {
  # DOTDIR/{all-os,$OSNAME}/nested/, munged via munge_nested_path. $OSNAME overrides
  # all-os on a matching target. Pre: cwd is the target home. Reads $OSNAME.
  #
  # A directory containing a '.linkdir' file is linked whole, instead of walking into it
  # for leaf files. A directory containing a '.linkdirs' file has each of ITS immediate
  # child directories linked whole; the marked directory itself stays real. Motivating
  # case: ~/.claude/skills/<skill> must each be one symlink (so files can come and go
  # inside a skill without an install re-run), but ~/.claude/skills itself must stay real
  # (other skills and harness state live alongside).
  #
  # Three phases, in target space, not per-tier source space: collect every entry (dir or
  # file) from both tiers, with the usual by-target shadowing; validate the merged set for
  # a target kind flipping between tiers, and for any target nested under a whole-linked
  # directory target, BEFORE any write; only then apply. Validating in target space is
  # load-bearing -- checking per-tier on source paths would miss e.g. all-os marking a
  # directory whole while $OSNAME has a leaf file inside that same target, and the leaf's
  # `ln` would then write through the freshly created symlink into the source tree itself.
  local dotdir="$1"
  local tier srcdir file relpath tofile dir i j found child skip d
  local -a kinds=() targets=() sources=() tier_dirs=()

  for tier in all-os "$OSNAME"; do
    srcdir="$dotdir/$tier/nested"
    [[ -d $srcdir ]] || continue
    tier_dirs=()

    while IFS= read -r -d '' file; do
      dir=$(dirname "$file")
      if [[ $dir == "$srcdir" ]]; then
        jxl::die "ERROR: '.linkdir' at the root of a nested tree ($srcdir) would link" \
            "the entire tree over \$HOME. Remove it, or mark a subdirectory instead." \
            "Nothing was changed."
      fi
      tier_dirs+=("$dir")
    done < <(find "$srcdir" -type f -name '.linkdir' -print0 | sort -z)

    # '.linkdirs' at the tier root is fine -- "link ~/.config, ~/.local, etc. whole" is a
    # coherent statement, not a $HOME clobber.
    while IFS= read -r -d '' file; do
      dir=$(dirname "$file")
      for child in "$dir"/*/; do
        [[ -d $child ]] || continue
        tier_dirs+=("${child%/}")
      done
    done < <(find "$srcdir" -type f -name '.linkdirs' -print0 | sort -z)

    for dir in ${tier_dirs[@]+"${tier_dirs[@]}"}; do
      relpath="${dir#"$srcdir"/}"
      tofile=$(dotinstall::munge_nested_path "$relpath")
      found=-1
      for i in "${!targets[@]}"; do
        [[ ${targets[$i]} == "$tofile" ]] && { found=$i; break; }
      done
      if [[ $found -ge 0 ]]; then
        if [[ ${kinds[$found]} != dir ]]; then
          jxl::die "ERROR: '$tofile' would install as both a whole-linked directory" \
              "(from '$dir') and a leaf file (from '${sources[$found]}'), across dots" \
              "tiers. Nothing was changed."
        fi
        sources[found]="$dir"
      else
        kinds+=(dir); targets+=("$tofile"); sources+=("$dir")
      fi
    done

    while IFS= read -r -d '' file; do
      relpath="${file#"$srcdir"/}"
      # Filter on the relpath, not find's absolute path: '*/.* ' would otherwise also match
      # a dot component in an ancestor directory (e.g. a repo checked out under
      # ~/.dotfiles), and silently skip every nested file. This also excludes .linkdir and
      # .linkdirs themselves, which must never be linked into ~.
      case "/$relpath" in
        */.*) continue ;;  # skip repo-control dotfiles like .gitkeep
      esac
      skip=0
      for d in ${tier_dirs[@]+"${tier_dirs[@]}"}; do
        if dotinstall::_path_under "$file" "$d"; then
          skip=1; break  # its whole parent directory is linked instead
        fi
      done
      [[ $skip == 1 ]] && continue
      tofile=$(dotinstall::munge_nested_path "$relpath")
      found=-1
      for i in "${!targets[@]}"; do
        [[ ${targets[$i]} == "$tofile" ]] && { found=$i; break; }
      done
      if [[ $found -ge 0 ]]; then
        if [[ ${kinds[$found]} != file ]]; then
          jxl::die "ERROR: '$tofile' would install as both a whole-linked directory" \
              "(from '${sources[$found]}') and a leaf file (from '$file'), across dots" \
              "tiers. Nothing was changed."
        fi
        sources[found]="$file"
      else
        kinds+=(file); targets+=("$tofile"); sources+=("$file")
      fi
    done < <(find "$srcdir" -type f -print0 | sort -z)
  done

  for i in "${!targets[@]}"; do
    [[ ${kinds[$i]} == dir ]] || continue
    for j in "${!targets[@]}"; do
      [[ $i == "$j" ]] && continue
      if dotinstall::_path_under "${targets[$j]}" "${targets[$i]}"; then
        jxl::die "ERROR: '${targets[$j]}' (from '${sources[$j]}') is nested under the" \
            "whole-linked directory '${targets[$i]}' (from '${sources[$i]}')." \
            "Nothing was changed."
      fi
    done
  done

  for i in "${!targets[@]}"; do
    tofile="${targets[$i]}"
    dir=$(dirname "$tofile")
    if [[ $dir != "." && ! -d $dir ]]; then
      jxl::wet_vrb mkdir -p "$dir"
      jxl::verbose "Created directory '$dir'"
      case "$dir" in
        .ssh | .ssh/* | .gnupg | .gnupg/*) jxl::wet_vrb chmod 700 "$dir" ;;  # sshd StrictModes
      esac
    fi
    dotinstall::symlink "${sources[$i]}" "$tofile"
  done
}

function dotinstall::munge_nested_path() {
  # nested-relative path -> installed path, per component: _x -> .x, __x -> _x, x -> x.
  local relpath="$1" part out=""
  local IFS=/
  local -a parts
  read -ra parts <<< "$relpath"
  for part in "${parts[@]}"; do
    # __x first, so it can't fall through to the _x arm. Escapes names that really do
    # start with an underscore, like zsh completion functions (_git, _docker).
    case "$part" in
      __*) part="${part#_}"  ;;
      _*)  part=".${part#_}" ;;
    esac
    out="${out:+$out/}$part"
  done
  echo "$out"
}

function dotinstall::_append_msg() {
  # Append a string, with space separator.
  local msg="$1" add="$2"
  if [[ -n $add ]]; then
    [[ -n $msg ]] && msg+=' '
    msg+="$add"
  fi
  echo "$msg"
}

function dotinstall::summary() {
  # Prints a status line via jxl::info; returns 1 iff anything failed. A caller adds any
  # trailing lines of its own (e.g. "Dotfiles are now linked to ...") and owns its own
  # exit -- this neither exits nor prints one.
  local msg=''
  if [[ $_DOTINSTALL_ANY_CHANGED == 0 ]]; then
    msg=$(dotinstall::_append_msg "$msg" 'All links were already up to date.')
  fi
  if [[ $_DOTINSTALL_SKIPPED != 0 ]]; then
    msg=$(dotinstall::_append_msg "$msg" "Skipped $_DOTINSTALL_SKIPPED files.")
  fi
  if [[ $_DOTINSTALL_CLOBBERED != 0 ]]; then
    msg=$(dotinstall::_append_msg "$msg" "Replaced $_DOTINSTALL_CLOBBERED files (backed up).")
  fi
  if [[ $_DOTINSTALL_FAILED != 0 ]]; then
    jxl::info "FAILED linking $_DOTINSTALL_FAILED files."
  fi
  # Only when there is something to say: an unconditional jxl::info prints a blank line.
  if [[ -n $msg ]]; then
    jxl::info "$msg"
  fi
  [[ $_DOTINSTALL_FAILED == 0 ]]
}

true

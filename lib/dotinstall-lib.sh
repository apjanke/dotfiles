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
# both read $OSNAME.

# Bump this if a caller-visible function's name, argument order, or behavior changes, so a
# caller that checks it can fail loudly instead of half-working.
_DOTINSTALL_LIB_API=1

# Load JXL relative to this file, not the caller -- a caller in another repo shouldn't have
# to know this repo's internal layout.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../dots/all-os/flat/dotlib/jxl-lib.sh" \
    || { echo >&2 "ERROR: dotinstall-lib.sh: failed to load jxl-lib.sh"; return 1; }

_DOTINSTALL_ANY_CHANGED=0
_DOTINSTALL_ALREADY=0
_DOTINSTALL_SKIPPED=0
_DOTINSTALL_FAILED=0

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

function dotinstall::symlink() {
  # out: $_DOTINSTALL_ANY_CHANGED, $_DOTINSTALL_THIS_CHANGED, $_DOTINSTALL_ALREADY,
  #      $_DOTINSTALL_SKIPPED, $_DOTINSTALL_FAILED
  #
  # An existing symlink that points somewhere OTHER than $source is left completely alone:
  # not relinked, not counted, not reported. That's pre-existing behavior, unchanged here.
  local source="$1" target="$2"
  _DOTINSTALL_THIS_CHANGED=0
  local current_source='' descr
  descr=$(printf '%-18s -> %s\n' "$target" "$source")
  if [[ -L "$target" ]]; then
    current_source=$(readlink "$target")
    if [[ "$current_source" == "$source" ]]; then
      jxl::log_vrb "Already set up: $descr"
      _DOTINSTALL_ALREADY=$((_DOTINSTALL_ALREADY + 1))
    fi
  elif [[ -e "$target" && ! -L "$target" ]]; then
    local file_type
    if [[ -f "$target" ]]; then
      file_type='regular file'
    elif [[ -d "$target" ]]; then
      file_type='non-symlink directory'
    else
      file_type='file of some sort (neither regular file nor symlink)'
    fi
    jxl::info "SKIPPED: $target is a $file_type"
    _DOTINSTALL_SKIPPED=$((_DOTINSTALL_SKIPPED + 1))
  else
    # wet_vrb, not wet: on a dry run the raw `ln` line is verbose-only detail, while the
    # "Linked:" message below is the preview worth seeing. Running the normal logging path
    # is half the value of a dry run -- it exercises those branches too.
    if jxl::wet_vrb ln -sfn "$source" "$target"; then
      _DOTINSTALL_ANY_CHANGED=1; _DOTINSTALL_THIS_CHANGED=1
      jxl::info "Linked: $descr"
    else
      _DOTINSTALL_FAILED=$((_DOTINSTALL_FAILED + 1))
      jxl::error "Failed: $descr"
    fi
  fi
}

function dotinstall::install_flat_tree() {
  # DOTDIR/{all-os,$OSNAME}/flat/ -> ~/.foo. Pre: cwd is the target home. Reads $OSNAME.
  # A missing DOTDIR/all-os/flat is not an error -- a caller with only a nested tree (e.g.
  # dotfiles-private) has none.
  local dotdir="$1"
  local dotfiles file tofile fromfile seen_targets=""
  local allosdir="$dotdir/all-os/flat" osdir="$dotdir/$OSNAME/flat"

  [[ -d "$allosdir" ]] || return 0

  if [[ -d "$osdir" ]]; then
      # shellcheck disable=SC2207
      dotfiles=( $( (ls "$allosdir"; ls "$osdir") | sort | uniq ) )
  else
      # shellcheck disable=SC2207
      dotfiles=($(ls "$allosdir"))
  fi

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
    if [[ -e "$osdir/$file" ]]; then
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

function dotinstall::install_nested_tree() {
  # DOTDIR/{all-os,$OSNAME}/nested/, munged via munge_nested_path. $OSNAME overrides
  # all-os on a matching target. Pre: cwd is the target home. Reads $OSNAME.
  local dotdir="$1"
  local tier srcdir file relpath tofile dir i found
  local -a targets=() sources=()

  for tier in all-os "$OSNAME"; do
    srcdir="$dotdir/$tier/nested"
    [[ -d "$srcdir" ]] || continue
    while IFS= read -r -d '' file; do
      relpath="${file#"$srcdir"/}"
      # Filter on the relpath, not find's absolute path: '*/.* ' would otherwise also match
      # a dot component in an ancestor directory (e.g. a repo checked out under
      # ~/.dotfiles), and silently skip every nested file.
      case "/$relpath" in
        */.*) continue ;;  # skip repo-control dotfiles like .gitkeep
      esac
      tofile=$(dotinstall::munge_nested_path "$relpath")
      found=-1
      for i in "${!targets[@]}"; do
        [[ "${targets[$i]}" == "$tofile" ]] && { found=$i; break; }
      done
      if [[ $found -ge 0 ]]; then
        sources[found]="$file"
      else
        targets+=("$tofile")
        sources+=("$file")
      fi
    done < <(find "$srcdir" -type f -print0 | sort -z)
  done

  for i in "${!targets[@]}"; do
    tofile="${targets[$i]}"
    dir=$(dirname "$tofile")
    if [[ "$dir" != "." && ! -d "$dir" ]]; then
      jxl::wet_vrb mkdir -p "$dir"
      jxl::log_vrb "Created directory '$dir'"
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
  if [[ $_DOTINSTALL_FAILED != 0 ]]; then
    jxl::info "FAILED linking $_DOTINSTALL_FAILED files."
  fi
  # Only when there is something to say: an unconditional jxl::info prints a blank line.
  if [[ -n "$msg" ]]; then
    jxl::info "$msg"
  fi
  [[ $_DOTINSTALL_FAILED == 0 ]]
}

true

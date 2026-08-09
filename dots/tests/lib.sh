# tests/lib.sh - shared helpers for the test-* scripts
#
# Sourced, not run. Each test-* script sources this, runs its cases, and calls
# print_summary; the exit status comes from $FAILS.
#
# shellcheck shell=bash

TESTS=0
FAILS=0

# ---- shell discovery, for tests that must pass under every shell we support ----

# Absolute paths of the shells to test under; filled in by select_test_shells.
TEST_SHELLS=()

# shellcheck disable=SC2016  # the single-quoted $... is code for the shell being probed
function shell_version() {
  # Echoes a short version string for the given shell, or nothing if it will not run.
  local sh="$1"
  case "${sh##*/}" in
    zsh)  "$sh" -c 'echo "${ZSH_VERSION:-}"'  2>/dev/null ;;
    *)    "$sh" -c 'echo "${BASH_VERSION:-}"' 2>/dev/null ;;
  esac
}

function select_test_shells() {
  # One entry per distinct shell build worth exercising.
  #
  # Testing plain `bash` is not enough, and was actively misleading: Homebrew is ahead of
  # the system directories on $PATH, so unqualified `bash` gets 5.x and the suite was
  # never running the bash 3.2 at /bin/bash that #!/bin/bash actually gets on macOS.
  #
  # Candidates cover both Homebrew prefixes, since these repos run on x64 and arm64 Macs
  # alike, plus MacPorts. Dedup is per shell name and version, so several paths to one
  # build cost nothing, while system zsh 5.9 and Homebrew zsh 5.9.2 both get a turn.
  local name cand ver key seen=''
  local -a candidates
  # Standard install locations, checked whether or not they are on $PATH -- a build that
  # is installed but not first, or not on the path at all, still needs testing.
  local -a std_dirs=(
    /bin                # macOS system shells; /bin/bash is the 3.2 to stay compatible
                        # with
    /usr/local/bin      # Homebrew on x64, and the usual spot for a local build
    /opt/homebrew/bin   # Homebrew on arm64
    /opt/local/bin      # MacPorts
  )

  TEST_SHELLS=()
  for name in bash zsh; do
    candidates=()
    for cand in "${std_dirs[@]}"; do
      candidates+=("$cand/$name")
    done
    # Then everything on $PATH: `which -a`, not `command -v`, to get every hit rather
    # than just the first.
    while IFS= read -r cand; do
      if [[ -n "$cand" ]]; then candidates+=("$cand"); fi
    done < <(which -a "$name" 2>/dev/null || true)

    for cand in "${candidates[@]}"; do
      if [[ ! -x "$cand" ]]; then continue; fi
      ver=$(shell_version "$cand")
      if [[ -z "$ver" ]]; then continue; fi
      key="${name}:${ver}"
      case " $seen " in *" $key "*) continue ;; esac
      seen="$seen $key"
      TEST_SHELLS+=("$cand")
    done
  done
}

function print_test_env() {
  # One line naming the OS and every shell in play, so a failure report says which builds
  # actually ran rather than leaving it to be guessed.
  local sh line=''
  for sh in ${TEST_SHELLS[@]+"${TEST_SHELLS[@]}"}; do
    line="${line:+${line} | }${sh##*/} $(shell_version "$sh") ${sh}"
  done
  echo "----- $(uname -rs) | ${line} -----"
}

function ok() {
  TESTS=$((TESTS + 1))
  printf '  ok   %s\n' "$1"
}

function fail() {
  local descr="$1" detail="${2:-}"
  TESTS=$((TESTS + 1))
  FAILS=$((FAILS + 1))
  printf '  FAIL %s\n' "$descr"
  if [[ -n "$detail" ]]; then
    printf '         %s\n' "$detail"
  fi
}

function assert_eq() {
  local got="$1" want="$2" descr="$3"
  if [[ "$got" == "$want" ]]; then
    ok "$descr"
  else
    fail "$descr" "got '$got', wanted '$want'"
  fi
}

function assert_contains() {
  local haystack="$1" needle="$2" desc="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    ok "$desc"
  else
    fail "$desc" "output did not contain: $needle"
  fi
}

function assert_not_contains() {
  local haystack="$1" needle="$2" desc="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    ok "$desc"
  else
    fail "$desc" "output unexpectedly contained: $needle"
  fi
}

function print_summary() {
  echo ''
  if [[ $FAILS -eq 0 ]]; then
    echo "===== all $TESTS assertions passed ====="
  else
    echo "===== $FAILS of $TESTS assertions FAILED ====="
  fi
}

# ---- helpers for tests that install into a throwaway $HOME ----

function assert_symlink_to() {
  local path="$FAKE_HOME/$1" want="$2" desc="$3" got
  if [[ ! -L "$path" ]]; then
    fail "$desc" "not a symlink: $path"
    return
  fi
  got=$(readlink "$path")
  if [[ "$got" != "$want" ]]; then
    fail "$desc" "points at $got, wanted $want"
    return
  fi
  if [[ ! -e "$path" ]]; then
    fail "$desc" "symlink is dangling: $path -> $got"
    return
  fi
  ok "$desc"
}

function assert_real_dir() {
  local path="$FAKE_HOME/$1" desc="$2"
  if [[ -d "$path" && ! -L "$path" ]]; then
    ok "$desc"
  else
    fail "$desc" "not a real directory: $path"
  fi
}

function assert_absent() {
  local path="$FAKE_HOME/$1" desc="$2"
  if [[ -e "$path" || -L "$path" ]]; then
    fail "$desc" "exists but should not: $path"
  else
    ok "$desc"
  fi
}

FAKE_HOMES=()

# shellcheck disable=SC2329  # reached via the EXIT trap set below; shellcheck doesn't follow it
function cleanup_fake_homes() {
  local d
  for d in ${FAKE_HOMES+"${FAKE_HOMES[@]}"}; do
    case "$d" in                                            # only ever rm what mktemp made
      */dotfiles-test.*) rm -rf "$d" ;;
      *) echo >&2 "refusing to remove unexpected path: $d" ;;
    esac
  done
}

function new_fake_home() {
  FAKE_HOME=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
  FAKE_HOMES+=("$FAKE_HOME")
}

function new_fake_dots() {
  # A synthetic dots/ tree for tests that build their own fixtures rather than touching
  # the tracked one. Sets $FAKE_DOTS; pass it to install-dotfiles as --dots-dir. Reuses the
  # dotfiles-test.* cleanup in cleanup_fake_homes -- that match is on the temp-dir naming
  # template, not on what the dir is used for.
  FAKE_DOTS=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
  FAKE_HOMES+=("$FAKE_DOTS")
  mkdir -p "$FAKE_DOTS/all-os/flat" "$FAKE_DOTS/all-os/nested"
}

# tests/lib.sh - shared helpers for the test-* scripts
#
# Sourced, not run. Each test-* script sources this, runs its cases, and calls
# print_summary; the exit status comes from $FAILS.
#
# shellcheck shell=bash

TESTS=0
FAILS=0

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

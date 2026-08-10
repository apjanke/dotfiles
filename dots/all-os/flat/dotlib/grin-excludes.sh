# grin-excludes.sh - shared exclusion defaults for grin (bashyrc.sh) and findd
#
# ":"-separated glob patterns, $PATH-style. Scalars rather than arrays because arrays can't
# be exported, and findd is a child process that has to see retuning done in a live shell.
# (So a pattern can't contain a ":". Same deal as $PATH.)
#
# "=" not ":=", so an explicit empty value means "no exclusions" instead of being reset to
# the defaults, and a customization survives into nested shells.
#
# Sourced by both bashyrc.sh and findd, rather than only setting these in the rc file: findd
# needs the defaults too when run from a shell that never loaded the rc files, such as a
# script or a cron job. When it is run from a shell that did, the exported values are
# already set and these assignments leave them alone.

# shellcheck shell=bash

: "${JX_GRIN_EXCLUDE_DIRS=.git:.cvs:.hg:.svn:venv:.venv:node_modules:wp-includes}"
: "${JX_GRIN_EXCLUDE_FILES=*.ipynb}"
export JX_GRIN_EXCLUDE_DIRS JX_GRIN_EXCLUDE_FILES

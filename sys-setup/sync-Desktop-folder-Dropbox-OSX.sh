#!/bin/bash
#
# sync-Desktop-folder-Dropbox-OSX.sh
#
# This script reconfigures the current user's Desktop folder to sync via
# Dropbox, using my Dropbox file layout conventions
#
# This does not preserve the special icon for the Desktop folder. There's
# probably a way to do this with Rez/DeRez, but I don't care enough to
# research it now.

# TODO: This fails if you have no files in the local Desktop folder

# My directory structure convention
DROPBOX="$HOME/Dropbox"
DB_DESKTOP="$DROPBOX/computer/data/Desktops/OSX/Desktop"
LOCAL_DESKTOP="$HOME/Desktop"

echo "Configuring local Desktop to sync with Dropbox"

# Don't reconfigure already-synced folders
if [[ -h "$LOCAL_DESKTOP" ]]; then
  "Looks like '$LOCAL_DESKTOP' is already synced (it's a symlink)"
  exit 0
fi

# Move existing local stuff in to Dropbox

# First, check existence of everything so we can abort gracefully
for file in "$LOCAL_DESKTOP"/*; do
  base_file=$(basename "$file")
  synced_file="$DB_DESKTOP/$base_file"
  if [[ -f "$synced_file" ]]; then
  	echo >&2 "ERROR: Synced file $synced_file already exists; aborting"
  	exit 1
  fi
done

# Authenticate first to avoid breakage partway through move
sudo -v

# Now, actually move
for file in "$LOCAL_DESKTOP"/*; do
  base_file=$(basename "$file")
  synced_file="$DB_DESKTOP/$base_file"
  mv "$file" "$synced_file"
  if [[ $? != 0 ]]; then
    echo >&2 "ERROR: Failed moving file '$file' to '$synced_file'"
    echo >&2 "ERROR: Aborted syncing due to error"
    exit 1
  fi
done
echo "Moved files to synced Desktop"

# Symlink the local Desktop folder to Dropbox
mkdir -p "$HOME/tmp"
sudo mv "$LOCAL_DESKTOP" "$HOME/tmp"
if [[ $? != 0 ]]; then
  echo >&2 "ERROR: Failed moving existing $HOME/Desktop out of the way. Aborted"
  exit 1
fi
ln -s "$DB_DESKTOP" "$LOCAL_DESKTOP"
if [[ $? != 0 ]]; then
  echo >&2 "ERROR: Failed creating Desktop symlink"
  exit 1
fi

echo "Desktop configured to sync with Dropbox at $DB_DESKTOP"

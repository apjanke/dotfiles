#!/bin/bash
#
# install.sh
#
# Installs symlinks to dotfiles in this repo into current user's $HOME dir.
# Blows away existing dotfiles, even if they're not symlinks.
#
# This just installs the "generic" (non platform or hardware specific) links.
# I used to have additional specialized links for different OSes or retina/non-retina,
# but I've gotten away from that now, so there's no non-generic logic left.

sourcedir=`dirname $0`
sourcedir=$(cd $sourcedir; pwd)
todir=$HOME

# Normally I don't use `cd`, but this makes display a lot nicer
cd $todir

# "dots" 
# These files have their names munged to add a leading dot and strip extension.
# Makes it easier to work with them in shell and editors.
fromdir="$sourcedir/generic/dots"
for file in `ls $fromdir`; do
	tofile=".${file%\.sh}"
	ln -sfnv "$fromdir/$file" "$tofile"
done

# "no_dots" 
# These files get no name munging
fromdir="$sourcedir/generic/no_dots"
for file in `ls $fromdir`; do
	tofile="$file"
	ln -sfnv "$fromdir/$file" "$tofile"
done

ln -sfn "$sourcedir/generic/bin" "bin"

echo Linked dotfiles to $sourcedir

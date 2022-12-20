#!/bin/bash

set -euo pipefail

# Using symlinks, make all of the files in $DOTFILE_DIR appear to be 
# in the user's home directory.  Note that we do not process or traverse 
# directories under $DOTFILE_DIR 

DOTFILE_DIR=~/linux-config/dotfiles

# Given an absolute name of a target file ($1), create a symlink in the user's 
# home directory that points to that file relative to the specified
# base directory ($2).  Note that we will only replace an existing file
# if it is a regular file or a symlink to a regular file.  We will make
# backup of a file before replacing it 
#
function makeLink {
  TARGET_FILE="$1"
  TARGET_BASEDIR="$2"
  FILENAME=~/"$(realpath --relative-to $TARGET_BASEDIR $TARGET_FILE)"
  BAK_FILENAME="${FILENAME}.orig"

  if [ -f "$FILENAME" ] || [ -L "$FILENAME" ]; then 
    if [ ! -e "$BAK_FILENAME" ] && [ ! -L "$BAK_FILENAME" ]; then
      mv "$FILENAME" "$BAK_FILENAME"
    fi
  fi

  if [ ! -e "$FILENAME" ]; then
    printf "%s \n" "$FILENAME"
    ln -s "$TARGET_FILE" "$FILENAME"
  else
    # Original file still exists in home directory, so either it was 
    # not a regular file or we werent able to make a backup first 
    printf "%s - skipping\n" "$FILENAME"
  fi
}

function main {
  for f in $(find "$DOTFILE_DIR" -mindepth 1 -maxdepth 1 -not -type d)
  do 
    makeLink "$f" "$DOTFILE_DIR"
  done
}

main "$@" 


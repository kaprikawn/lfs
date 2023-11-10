#!/bin/bash

# https://www.linuxfromscratch.org/lfs/view/stable/

# set -x

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
DATE=$( date '+%Y-%m-%d' )
time=$( date '+%H:%M' )
CORE_COUNT=$( grep -c processor /proc/cpuinfo )

WGET_LIST_FILEPATH=$SCRIPT_DIR/wget-list.txt

LOGFILE=$SCRIPT_DIR/log.txt
if [[ -f $LOGFILE ]]; then
  rm -f $LOGFILE
fi

cd $SCRIPT_DIR
if [[ -f "functions.sh" ]]; then
  source ./functions.sh
else
  echo "Could not find functions.sh - exitting"
  exit 1
fi

log $LOGFILE "######################################"
log $LOGFILE "### ~~~ Starting script ch6.sh ~~~ ###"
log $LOGFILE "######################################"

function InitialChecks() {
  
  # Check directories exist
  DIRS=( $LFS $LFS/tools $LFS/sources )
  for dir in ${DIRS[@]}; do
    if [[ -d $dir ]]; then
      log $LOGFILE "Directory $dir exists"
    else
      log $LOGFILE "Directory $dir does not exist - exitting"
      exit 1
    fi
  done
  
  # Make sure we have the wget-list
  if [[ -f $WGET_LIST_FILEPATH ]]; then
    log $LOGFILE "wget list found in $WGET_LIST_FILEPATH"
  else
    log $LOGFILE "wget list not found - exitting"
  fi
}

function M4() {
  section="6.2. M4-1.4.19"
  
  log $LOGFILE " ### ~~~ $section ~~~ ### "
  
  parse_file_properties $WGET_LIST_FILEPATH m4
  
  download $url $archive
  
  extract $archive
  
  cd $LFS/sources/$directory
  
  log $LOGFILE "Starting configure"
  
  ./configure --prefix=/usr         \
              --host=$LFS_TGT       \
              --build=$(build-aux/config.guess)
  CheckRetVal $?
  
  callMake
  
  log $LOGFILE "Calling make DESTDIR=$LFS install"
  make DESTDIR=$LFS install
  CheckRetVal $?
  
  cd $LFS/sources
  rm -rf $directory
}

M4

exit 0


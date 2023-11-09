#!/bin/bash

LFS=/mnt/lfs
LFS_TGT=$( uname -m )-lfs-linux-gnu
SCRIPT_DIR=$PWD
LOGFILE=$SCRIPT_DIR/log.txt
CORE_COUNT=$( grep -c processor /proc/cpuinfo )
wget_list=$SCRIPT_DIR/wget-list
section=


function log() {
  echo $( date +%H:%M:%S ) "${section} -- " $1 >> $LOGFILE
}

function download() {
  cd $LFS/sources

  if [ -e $2 ]; then
    echo "$2 already downloaded"
  else
    wget $1
  fi

  if [ ! -e $2 ]; then
    echo "failed to download $2"
    exit 1
  fi
}

# echo "https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.xz" | sed -En "s/([^\/]+$)/\1/p"
# echo "binutils-2.37.tar.xz" | sed 's:.*\.::'

# echo  "binutils-2.37.tar.xz" | sed -En "s/(.*?)(\.tar\..*)/\1/p"

function parse_file_properties() {
  
  program_name=$1
  
  url=$( cat $wget_list | grep $program_name | grep tar )
  archive=$( echo $url | sed 's:.*/::' )
  archive_type=$( echo $archive | sed 's:.*\.::' )
  source_dir=$( echo $archive | sed -En "s/(.*?)(\.tar\..*)/\1/p" )
  
  # url=$( cat $wget_list | grep $program_name | grep tar )
  
  
  # sed -E "/[^\/]+$/" <<< $url
  
  # archive=$( echo $url | sed -En "s/([^\/]+$)/\1/" )
  # echo archive is $archive
  # version=$( echo $url | sed -r 's/.*?([\d\.]{1,})\.tar.*/\1/' )
  # archiveType=$( cat wget-list | grep $program_name | grep tar | sed -r 's/.*$program_name-.*?\.tar\.(.*)/\1/' )
  # program=binutils-$version
  # source_dir=$program
  # archive=$program.tar.$archiveType
}

function extract() {
  tarball=$1
  directory=$( sed -E "s/\.tar\.[a-z0-9]{2,3}$//" <<< $tarball )
  filename=$( basename $1==$tarball )
  extension="${filename##*.}"

  cd $LFS/sources

  if [ -d $directory ]; then
    rm -rf $directory
  fi

  log "extracting $tarball into $directory"

  tar -xf $tarball

  if [ ! -d $directory ]; then
    log "$tarball does not appear to have unpacked into $directory"
    exit 1
  fi
}

function checkRetVal() {
  if [ $1 -ne 0 ]; then
    echo "checkRetVal failed"
    log "checkRetVal failed"
    exit 1
  fi
  log "retVal check ok"
}

function callMake() {
  log "calling make"
  make -j${CORE_COUNT}
  if [ $? -eq 0 ]; then
    log "make ran successfully"
  else
    log "make was unsuccessful"
    exit 1
  fi
}

function callMakeInstall() {
  log "calling make install"
  make install
  if [ $? -eq 0 ]; then
    log "make install ran successfully"
  else
    log "make install was unsuccessful"
    exit 1
  fi
}

# function cleanUpSource() {
  
# }

if [ -e $LOGFILE ]
then
  rm -f $LOGFILE
fi


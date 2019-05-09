#!/bin/bash

LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
rundir=$PWD
logfile=$rundir/log.txt

source versions.sh

function log() {
  echo $(date +%H:%M:%S) $1 >> $logfile
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
  make
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

if [ -e $logfile ]
then
  rm -f $logfile
fi


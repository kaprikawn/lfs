#!/bin/bash

source functions.sh

if [ ! -d $LFS ]
then
  echo lfs directory does not exist - exiting
  exit 1
fi

if [ ! -d /tools ]
then
  echo tools directory does not exist - exiting
  exit 1
fi

function BinutilsPass1() {
  ver=$binutilsVer
  archiveType=bz2
  program=binutils-$ver
  archive=$program.tar.$archiveType
  url=http://ftp.gnu.org/gnu/binutils/$archive
  section="5.4. Binutils-2.27 - Pass 1"

  log "$section"

  download $url $archive
  extract $archive

  cd $program
  
  
  mkdir -v build
  cd build
  checkRetVal $?

  log "starting configure"
  ../configure --prefix=/tools          \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror

  checkRetVal $?

  callMake

  case $(uname -m) in
    x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
  esac

  callMakeInstall

  rm -rf $LFS/sources/$program
}

exit 0


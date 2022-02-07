#!/bin/bash

source common.sh

cd $LFS || exit 1
cd $LFS/tools || exit 1

function BinutilsPass1() {
  section="5.2. Binutils-2.37 - Pass 1"
  
  log "$section"

  parse_file_properties binutils
  
  download $url $archive
  exitex
  extract $archive

  cd $source_dir || exit 1

  mkdir -v build
  cd build || exit 1

  log "starting configure"
  ../configure  --prefix=$LFS/tools         \
                --with-sysroot=$LFS         \
                --target=$LFS_TGT           \
                --disable-nls               \
                --disable-werror

  checkRetVal $?

  callMake

  case $( uname -m ) in
    x86_64) mkdir -pv /tools/lib && ln -sv lib /tools/lib64 ;;
  esac

  callMakeInstall
  
  cd $LFS

  rm -rf $LFS/sources/$source_dir
}

BinutilsPass1

exit 0

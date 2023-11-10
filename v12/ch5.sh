#!/bin/bash

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
log $LOGFILE "### ~~~ Starting script ch5.sh ~~~ ###"
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

function BinutilsPass1() {
  section="5.2. Binutils-2.37 - Pass 1"
  
  log $LOGFILE " ### ~~~ $section ~~~ ### "
  
  parse_file_properties $WGET_LIST_FILEPATH binutils
  
  download $url $archive
  
  extract $archive
  
  cd $LFS/sources/$directory
  
  mkdir -pv build
  cd build
  
  log $LOGFILE "Starting configure"
  
  ../configure  --prefix=$LFS/tools   \
                --with-sysroot=$LFS   \
                --target=$LFS_TGT     \
                --disable-nls         \
                --enable-gprofng=no   \
                --disable-werror
  CheckRetVal $?
  
  callMake
  
  ## this isn't in the instructions for v12 but was in v11
  case $( uname -m ) in
    x86_64) mkdir -pv /tools/lib && ln -sv lib /tools/lib64 ;;
  esac
  
  callMakeInstall
  
  cd $LFS/sources
  
  rm -rf $directory
}

function GccPass1() {
  section="5.5. GCC-6.3.0 - Pass 1"
  
  log $LOGFILE " ### ~~~ $section ~~~ ### "
  
  parse_file_properties $WGET_LIST_FILEPATH mpfr
  download $url $archive
  
  parse_file_properties $WGET_LIST_FILEPATH gmp
  download $url $archive
  
  parse_file_properties $WGET_LIST_FILEPATH mpc
  download $url $archive
  
  parse_file_properties $WGET_LIST_FILEPATH gcc
  download $url $archive
  
  extract $archive
  cd $LFS/sources/$directory
  
  tar -xf ../mpfr-*.tar.*
  CheckRetVal $?
  mpfr_dir=$( ls -d mpfr*/ | cut -f1 -d'/' )
  mv -v $mpfr_dir mpfr
  CheckRetVal $?
  
  tar -xf ../gmp-*.tar.*
  CheckRetVal $?
  gmp_dir=$( ls -d gmp*/ | cut -f1 -d'/' )
  mv -v $gmp_dir gmp
  CheckRetVal $?
  
  tar -xf ../mpc-*.tar.*
  CheckRetVal $?
  mpc_dir=$( ls -d mpc*/ | cut -f1 -d'/' )
  mv -v $mpc_dir mpc
  CheckRetVal $?
  
  case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
  
  mkdir -pv build
  cd build
  
  log $LOGFILE "Starting configure"
  ../configure                  \
    --target=$LFS_TGT           \
    --prefix=$LFS/tools         \
    --with-glibc-version=2.38   \
    --with-sysroot=$LFS         \
    --with-newlib               \
    --without-headers           \
    --enable-default-pie        \
    --enable-default-ssp        \
    --disable-nls               \
    --disable-shared            \
    --disable-multilib          \
    --disable-threads           \
    --disable-libatomic         \
    --disable-libgomp           \
    --disable-libquadmath       \
    --disable-libssp            \
    --disable-libvtv            \
    --disable-libstdcxx         \
    --enable-languages=c,c++
  CheckRetVal $?
  
  callMake
  
  callMakeInstall
  
  cd $LFS/sources/$directory
  
  cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
  CheckRetVal $?
  
  cd $LFS/sources
  
  rm -rf $directory
  log $LOGFILE " ### ~~~ Finished $section ~~~ ### "
}

function LinuxApiHeaders() {
  section="5.4. Linux-6.4.12 API Headers"
  log $LOGFILE " ### ~~~ $section ~~~ ### "
  parse_file_properties $WGET_LIST_FILEPATH "/linux/kernel"
  download $url $archive
  extract $archive
  cd $LFS/sources/$directory
  make mrproper
  CheckRetVal $?
  make headers
  CheckRetVal $?
  find usr/include -type f ! -name '*.h' -delete
  cp -rv usr/include $LFS/usr
  CheckRetVal $?
  cd $LFS/sources
  rm -rf $directory
}

function Glibc() {
  section="5.5. Glibc-2.38"
  
  log $LOGFILE " ### ~~~ $section ~~~ ### "
  
  parse_file_properties $WGET_LIST_FILEPATH "glibc/glibc"
  download $url $archive
  extract $archive
  cd $LFS/sources/$directory
  
  case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac
  
  log $LOGFILE "Patching"
  glibc_patch_file="glibc-2.38-fhs-1.patch"
  url=$( cat $WGET_LIST_FILEPATH | grep $glibc_patch_file )
  cd $LFS/sources
  if [[ ! -f $glibc_patch_file ]]; then
    log $LOGFILE "Running wget $url"
    wget $url
    CheckRetVal $?
  fi
  cd $LFS/sources/$directory
  log $LOGFILE "Patching with $glibc_patch_file"
  patch -Np1 -i ../$glibc_patch_file
  CheckRetVal $?
  
  mkdir -pv build
  cd build
  
  echo "rootsbindir=/usr/sbin" > configparms
  log $LOGFILE "Starting configure"
  ../configure                              \
      --prefix=/usr                         \
      --host=$LFS_TGT                       \
      --build=$(../scripts/config.guess)    \
      --enable-kernel=4.14                  \
      --with-headers=$LFS/usr/include       \
      libc_cv_slibdir=/usr/lib
  CheckRetVal $?
  
  callMake
  
  log $LOGFILE "Running make DESTDIR=$LFS install"
  make DESTDIR=$LFS install
  CheckRetVal $?
  
  sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
  
  echo 'int main(){}' | $LFS_TGT-gcc -xc -
  readelf -l a.out | grep ld-linux
  readelf_output=$( readelf -l a.out | grep ld-linux )
  if [[ "$readelf_output" == *"/lib64/ld-linux-x86-64.so.2"* ]]; then
    log $LOGFILE "a.out output expected string"
  else
    log $LOGFILE "a.out did not output expected string"
    log $LOGFILE "$readelf_output"
    readelf_output=$( readelf -l a.out )
    log $LOGFILE "$readelf_output"
  fi
  rm -v a.out
  
}

function Libstdc() {
  section="5.6. Libstdc++ from GCC-13.2.0"
  
  log $LOGFILE " ### ~~~ $section ~~~ ### "
  parse_file_properties $WGET_LIST_FILEPATH gcc
  download $url $archive
  
  extract $archive
  cd $LFS/sources/$directory
  
  mkdir -pv build
  cd build
  
  log $LOGFILE "pkg_version is $pkg_version"
  
  ../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/$pkg_version
  CheckRetVal $?
  
  callMake
  
  log $LOGFILE "Calling make DESTDIR=$LFS install"
  make DESTDIR=$LFS install
  CheckRetVal $?
  
  
  log $LOGFILE "Calling rm -v $LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la"
  rm -v $LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la
  CheckRetVal $?
  
}

# InitialChecks
# BinutilsPass1
# GccPass1
# LinuxApiHeaders
# Glibc
Libstdc

exit 0

# https://www.linuxfromscratch.org/lfs/view/stable/

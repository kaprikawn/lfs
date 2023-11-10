
function log() {
  local locallogfile=$1
  local msg=$2
  echo $(date +%H:%M) $msg
  echo $(date +%H:%M) $msg >> $locallogfile
}

function set_time() {
  # set the 'time' variable to the current time
  time=$( date '+%H:%M' )
}

function parse_file_properties() {
  
  progam_list_filepath=$1
  program_name=$2
  
  url=$( cat $progam_list_filepath | grep $program_name | grep tar | head -n 1 )
  archive=$( echo $url | sed 's:.*/::' )
  archive_type=$( echo $archive | sed 's:.*\.::' )
  source_dir=$( echo $archive | sed -En "s/(.*?)(\.tar\..*)/\1/p" )
  pkg_version=$( echo $archive | sed -En "s/(.*?)-([0-9\.]{1,})(\.tar\..*)/\2/p" )
  
  if [[ -z $url ]]; then
    log $LOGFILE "Failed to get url for $program_name"
    exit 1
  fi
  
  if [[ -z $archive ]]; then
    log $LOGFILE "Failed to get archive for $program_name"
    exit 1
  fi
  
  if [[ -z $archive_type ]]; then
    log $LOGFILE "Failed to get archive_type for $program_name"
    exit 1
  fi
  
  if [[ -z $source_dir ]]; then
    log $LOGFILE "Failed to get source_dir for $program_name"
    exit 1
  fi
  
}

function download() {
  local url=$1
  local tarball=$2
  
  log $LOGFILE "Getting $tarball"
  
  pushd $LFS/sources
  
  if [ -e $tarball ]; then
    log $LOGFILE "$tarball already downloaded"
  else
    log $LOGFILE "Downloading from $url"
    wget $url
    ret_val=$?
    log $LOGFILE "Download ret_val is $ret_val"
  fi
  
  if [ ! -e $tarball ]; then
    log $LOGFILE "Failed to download $tarball"
    echo "failed to download $tarball"
    exit 1
  fi
  
  popd
}

function extract() {
  tarball=$1
  directory=$( sed -E "s/\.tar\.[a-z0-9]{2,3}$//" <<< $tarball )
  filename=$( basename $1==$tarball )
  extension="${filename##*.}"
  
  pushd $LFS/sources
  
  if [ -d $directory ]; then
    rm -rf $directory
  fi
  
  log $LOGFILE "Extracting $tarball into $directory"
  
  tar -xf $tarball
  
  if [ ! -d $directory ]; then
    log $LOGFILE "$tarball does not appear to have unpacked into $directory"
    exit 1
  fi
  
  popd
}

function CheckRetVal() {
  if [ $1 -ne 0 ]; then
    log $LOGFILE "CheckRetVal failed"
    exit 1
  fi
  log $LOGFILE "RetVal check ok"
}

function callMake() {
  
  if [[ $CORE_COUNT -gt 1 ]]; then
    log $LOGFILE "Calling make -j${CORE_COUNT}"
    make -j${CORE_COUNT}
    ret_val=$?
  else
    log $LOGFILE "Calling make"
    make
    ret_val=$?
  fi
  
  if [ $ret_val -eq 0 ]; then
    log $LOGFILE "make ran successfully"
  else
    log $LOGFILE "make was unsuccessful"
    exit 1
  fi
}

function callMakeInstall() {
  log $LOGFILE "calling make install"
  make install
  if [ $? -eq 0 ]; then
    log $LOGFILE "make install ran successfully"
  else
    log $LOGFILE "make install was unsuccessful"
    exit 1
  fi
}

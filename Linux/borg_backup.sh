#!/bin/bash
#--------------------- VARIABLES ---------------------
DIR='/path/to/script'
NAME='ExampleNAS'
DATA_PATH='/path/to/data'
REPO_PATH='/path/to/borg-repository'
START_CMD='systemctl start smbd.service'
STOP_CMD='systemctl stop smbd.service'
COMPRESSION='lz4' # Default => lz4,default
REPO_PRUNE='--keep-last 14 --keep-daily 14 --keep-monthly 6 --keep-yearly 1'

DEBUG=0
LOG_FILE="$(date -I).log"
LOG_DIR=$DIR"/log/$(date +'%Y')/$(date +'%m')"
#--------------------- LOG FOLDERS ---------------------
for dir in $(echo $LOG_DIR | tr "/" "\n")
do
  if [ -z $path ]; then
    path=$dir
  else
    path=$path"/"$dir
  fi

  if [ ! -d $path ]; then
    mkdir $path
  fi
done

#--------------------- FUNCTIONS ---------------------
log() {
  case $1 in
    'ERROR'*) c='\033[0;31m';;
    'WARNING'*) c='\033[1;33m';;
    'COMMAND'*) c='\033[0;36m';;
    *) c='\033[0m';;
  esac

  if [ $# \> 1 ]; then
    echo -e "$c[$(date -Ins)] [$1] $2 \033[0m"
    echo "[$(date -Ins)] [$1] $2" >> $path"/"$LOG_FILE
  else
    while read -r line; do
      # Process each line of input here
      echo -e "$c[$(date -Ins)] [$1] $line \033[0m"
      echo "[$(date -Ins)] [$1] $line" >> $path"/"$LOG_FILE
    done
  fi
}

run() {
  if [ $DEBUG -eq 1 ]; then
    echo "$@" | log 'DEBUG'
  fi

  $@ 3>&1 1> >(log 'COMMAND') 2>&1
  status=$?
  sleep 0.5

  if [ $status -eq 1 ] || [[ $1 == 'borg' && $status -eq 2 ]]; then
    log 'ERROR' 'Command exit with Error!'
  elif [[ $1 == 'borg' && $status -eq 1 ]]; then
    log 'WARNING' 'Command successfully with Warning! Check Command Output!'
  elif [ $status -eq 127 ]; then
    log 'ERROR' 'Command could not be found!'
  fi
  return $status
}

#--------------------- MAIN PROGRAMM ---------------------
log 'INFO' 'Prepare for Backup.....'

log 'INFO' 'Stop Service.....'
run $STOP_CMD
log 'INFO' 'Service stoped!'

log 'INFO' 'Start Backup Process.....'
if [ $DEBUG -eq 1 ]; then
  run borg create --dry-run --progress -C $COMPRESSION $REPO_PATH::$NAME-{now:%Y-%m-%dT%H:%M} $DATA_PATH
  run borg prune --dry-run --list $REPO_PRUNE $REPO_PATH
else
#  run borg create -s --progress -C $COMPRESSION $REPO_PATH::$NAME-{now:%Y-%m-%dT%H:%M} $DATA_PATH
  run borg create -s -C $COMPRESSION $REPO_PATH::$NAME-{now:%Y-%m-%dT%H:%M} $DATA_PATH
  run borg prune --list $REPO_PRUNE $REPO_PATH
fi
log 'INFO' 'Backup Process finished!'

log 'INFO' 'Start Service.....'
run $START_CMD
log 'INFO' 'Service started!'

log 'INFO' 'Finished Backup!'
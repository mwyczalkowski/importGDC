#!/bin/bash

# author: Matthew Wyczalkowski m.wyczalkowski@wustl.edu

# Usage: start_step.sh [options] UUID [UUID2 ...]
# Start processing given step.  Run on host computer
# options:
# -d: dry run
# -g LSF_GROUP: LSF group to use starting job
# -S SR_FILE: path to SR data file.  Default: config/SR.dat
# -O DATA_DIR: path to base of download directory (will write to $DATA_DIR/GDC_import). Default: ./data
# -s STEP: Step to process.  Default (and only available value) is 'import'
# -t TOKEN: token filename, path relative to container.  Default: /data/token/gdc-user-token.txt
# -D: Download only, do not index
# -I: Index only, do not Download.  DT must be "BAM"
# -M: MGI environment
#
# If UUID is - then read UUID from STDIN
# 
# Path to importGDC directory is defined by environment variable IMPORTGDC_HOME.  Default
# is /usr/local/importGDC; can be changed with,
#```
#    export IMPORTGDC_HOME="/path/to/importGDC"
#```

# If environment variable not defined, set it for the duration of this script to the path below
if [ -z $IMPORTGDC_HOME ]; then
    IMPORTGDC_HOME="/usr/local/importGDC"
fi


function launch_import {
UUID=$1

FN=$(grep $UUID $SR | cut -f 6)
DF=$(grep $UUID $SR | cut -f 8)

if [ -z $FN ]; then
    >&2 echo Error: UUID $UUID not found in $SR
    exit
fi

if [ -z $DRYRUN ]; then
    BASH="/bin/bash"
else
    BASH="echo /bin/bash"
fi

$BASH $IMPORTGDC_HOME/GDC_import.sh $XARGS -t $TOKEN -O $DATA_DIR -p $DF -n $FN  $UUID

}

# Default values
SR="config/SR.dat"
DATA_DIR="./data"
STEP="import"
TOKEN="/data/token/gdc-user-token.txt"

while getopts ":dg:S:O:s:t:IDM" opt; do
  case $opt in
    d)  # example of binary argument
      echo "Dry run" >&2
      DRYRUN=1
      ;;
    g) # define LSF_GROUP
      XARGS="$XARGS -g $OPTARG"
      ;;
    S) 
      SR=$OPTARG
      echo "SR File: $SR" >&2
      ;;
    t) 
      TOKEN=$OPTARG
      echo "Token File: $TOKEN" >&2
      ;;
    O) # set DATA_DIR
      DATA_DIR="$OPTARG"
      echo "Data Dir: $DATA_DIR" >&2
      ;;
    s) 
      STEP="$OPTARG"
      ;;
    I)  
      XARGS="$XARGS -I"
      ;;
    D)  
      XARGS="$XARGS -D"
      ;;
    M)  
      XARGS="$XARGS -M"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z $SR ]; then
    >&2 echo Error: SR file not defined \(-S\)
    exit
fi
if [ ! -e $SR ]; then
    >&2 echo "Error: $SR does not exist"
    exit
fi

if [ "$#" -lt 1 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo Usage: start_step.sh [options] UUID [UUID2 ...]
    exit
fi

echo Step $STEP

# this allows us to get UUIDs in one of two ways:
# 1: start_step.sh ... UUID1 UUID2 UUID3
# 2: cat UUIDS.dat | start_step.sh ... -
if [ $1 == "-" ]; then
    UUIDS=$(cat - )
else
    UUIDS="$@"
fi

# Loop over all remaining arguments
for UUID in $UUIDS
do

    if [ $STEP == 'import' ]; then
        launch_import $UUID
    else
        echo Unknown step $STEP
        echo Only 'import' implemented
    fi

done

#!/bin/bash

# author: Matthew Wyczalkowski m.wyczalkowski@wustl.edu

# Usage: start_step.sh [options] STEP UUID [UUID2 ...]
# Start processing step STEP on host computer.  Currently, only acceptable value of STEP is 'import'
# options:
# -d: dry run
# -g LSF_GROUP: LSF group to use starting job
# -S SR_FILE: path to SR data file.  Default: config/SR.dat
# -O DATA_DIR: path to base of download directory (will write to $DATA_DIR/GDC_import (confirm this))
#       Default: ./data
#
# If UUID is - then read UUID from STDIN

SR="config/SR.dat"

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

$BASH $SRC/GDC_import.sh $XARGS -M -t $TOKEN_CONTAINER -O $DATA_DIR -p $DF -n $FN  $UUID

}

DATA_DIR="./data"

while getopts ":dg:S:O:" opt; do
  case $opt in
    d)  # example of binary argument
      echo "Dry run" >&2
      DRYRUN=1
      ;;
    g) # define LSF_GROUP
      XARGS="$XARGS -g $OPTARG"
      ;;
    S) # example of value argument
      SR=$OPTARG
      if [ ! -e $SR ]; then
        >&2 echo "Error: $SR does not exist"
        exit
      fi
      echo "SR File: $SR" >&2
      ;;
    O) # set DATA_DIR
      DATA_DIR="$OPTARG"
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

if [ "$#" -lt 2 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo Usage: start_step.sh [options] step UUID [UUID2 ...]
    exit
fi



STEP=$1; shift
echo Stage $STEP

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

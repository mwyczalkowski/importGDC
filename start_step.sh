#!/bin/bash

# author: Matthew Wyczalkowski m.wyczalkowski@wustl.edu

# Usage: start_step.sh [options] UUID [UUID2 ...]
# Start processing given step.  Run on host computer
# options:
# -d: dry run.  This may be repeated (e.g., -dd or -d -d) to pass the -d argument to called functions instead, 
#     with each called function called in dry run mode if it gets one -d, and popping off one and passing rest otherwise
# -g LSF_GROUP: LSF group to use starting job
# -S SR_H: path to SR data file.  Default: config/SR.dat
# -O IMPORT_DATAD_H: path to base of download directory (will write to $IMPORT_DATAD_H/GDC_import/data). Default: ./data
# -s STEP: Step to process.  Default (and only available value) is 'import'
# -t TOKEN_C: token filename, path relative to container.  Required
# -l LOGD_H: Log output directory.  Required for MGI
# -D: Download only, do not index
# -I: Index only, do not Download.  DT must be "BAM"
# -M: MGI environment
# -B: Run BASH in Docker instead of gdc-client
# -f: force overwrite of existing data files
# -T TRICKLE_RATE: Run using trickle to shape data usage; rate is maximum cumulative download rate
# -E RATE: throttle download rate using MGI using LSF queue (Matt Callaway test).  Rate in mbps, try 600
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

NMATCH=$(grep $UUID $SR_H | wc -l)
if [ $NMATCH -ne "1" ]; then
    >&2 echo ERROR: UUID $UUID  matches $NMATCH lines in $SR_H \(expecting unique match\)
    exit 1;
fi

# Columns of SR.dat - Jan2018 update with sample_name
#     1 sample_name
#     2 case
#     3 disease
#     4 experimental_strategy
#     5 sample_type
#     6 samples
#     7 filename
#     8 filesize
#     9 data_format
#    10 UUID
#    11 MD5
FN=$(grep $UUID $SR_H | cut -f 7)
DF=$(grep $UUID $SR_H | cut -f 9)


if [ -z "$FN" ]; then
    >&2 echo Error: UUID $UUID not found in $SR_H
    exit 1
fi

# If DRYRUN is 'd' then we're in dry run mode (only print the called function),
# otherwise call the function as normal with one less -d argument than we got
if [ -z $DRYRUN ]; then   # DRYRUN not set
    BASH="/bin/bash"
elif [ $DRYRUN == "d" ]; then  # DRYRUN is -d: echo the command rather than executing it
    BASH="echo /bin/bash"
    echo "Dry run in $0" >&2
else    # DRYRUN has multiple d's: strip one d off the argument and pass it to function
    BASH="/bin/bash"
    DRYRUN=${DRYRUN%?}
    XARGS="$XARGS -$DRYRUN"
fi

$BASH $IMPORTGDC_HOME/GDC_import.sh $XARGS -t $TOKEN_C -O $IMPORT_DATAD_H -p $DF -n $FN  $UUID

}

# Default values
SR_H="config/SR.dat"
IMPORT_DATAD_H="./data"
STEP="import"

while getopts ":dg:S:O:s:t:IDMBfl:T:E:" opt; do
  case $opt in
    d)  # -d is a stack of parameters, each script popping one off until get to -d
      DRYRUN="d$DRYRUN"
      ;;
    B) # define LSF_GROUP
      XARGS="$XARGS -B"
      ;;
    g) # define LSF_GROUP
      XARGS="$XARGS -g $OPTARG"
      ;;
    S) 
      SR_H=$OPTARG
      >&2 echo "SR File: $SR_H" 
      ;;
    t) 
      TOKEN_C=$OPTARG
      >&2 echo "Token File: $TOKEN_C" 
      ;;
    O) # set IMPORT_DATAD_H
      IMPORT_DATAD_H="$OPTARG"
      >&2 echo "Data Dir: $IMPORT_DATAD_H" 
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
    f)  
      XARGS="$XARGS -f"
      ;;
    l)  
      XARGS="$XARGS -l $OPTARG"
      ;;
    T)  
      XARGS="$XARGS -T $OPTARG"
      ;;
    E)  
      XARGS="$XARGS -E $OPTARG"
      ;;
    \?)
      >&2 echo "Invalid option: -$OPTARG" 
      exit 1
      ;;
    :)
      >&2 echo "Option -$OPTARG requires an argument." 
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z $SR_H ]; then
    >&2 echo Error: SR file not defined \(-S\)
    exit 1
fi
if [ ! -e $SR_H ]; then
    >&2 echo "Error: $SR_H does not exist"
    exit 1
fi
if [ -z $TOKEN_C ]; then
    >&2 echo Error: Token file not defined \(-t\)
    exit 1
fi

if [ "$#" -lt 1 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo Usage: start_step.sh [options] UUID [UUID2 ...]
    exit 1
fi

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
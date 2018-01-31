#!/bin/bash

# author: Matthew Wyczalkowski m.wyczalkowski@wustl.edu

# Summarize details of given samples and check success of download
# Usage: make_bam_map.sh [options] UUID [UUID2 ...]
# If UUID is - then read UUID from STDIN
#
# Output written to STDOUT.  Format is TSV with the following columns:
#     1  SampleName
#     2  Case
#     3  Disease
#     4  ExpStrategy
#     5  SampType
#     6  DataPath
#     7  FileSize
#     8  DataFormat
#     9  Reference
#    10  UUID
# where SampleName is a generated unique name for this sample

# options
# -S SR_FILE: path to SR data file.  Default: config/SR.dat
# -O DATA_DIR: path to base of download directory (downloads will be written to to $DATA_DIR/GDC_import/data). Default: ./data
# -r REF: reference name - assume same for all SR.  Default: hg19
# -w: don't print warnings about missing data
# -H: Print header

# For a given UUID, confirm existence of output file and (if appropriate) index file.
# output a "bam map" file which can later be used as input for processing.  Note that
# all information used to generate BamMap comes from SR file and local configuration (paths, etc),
# We evaluate success of download by checking whether data file exists in the expected path;
# no effort is made to critically compare downloaded file against that expected from SR file (though
# that would be helpful)
#
# Procedure:
# * extract information from SR file 
# * Make sure output file exists
# * If this is a BAM, make sure .bai file exists.  Print warning if it does not
#
function summarize_import {
# SR columns: case, disease, experimental_strategy, sample_type, samples, filename, filesize, data_format, UUID, md5sum
    UUID=$1
    REF=$2

    SR=$(grep $UUID $SR_FILE)  # assuming only one value returned
    if [ -z "$SR" ]; then
        >&2 echo UUID $UUID not found in $SR_FILE
        >&2 echo Quitting.
        exit
    fi
    
    SN=$(echo "$SR" | cut -f 1)
    CASE=$(echo "$SR" | cut -f 2)
    DIS=$(echo "$SR" | cut -f 3)
    ES=$(echo "$SR" | cut -f 4)
    STL=$(echo "$SR" | cut -f 5)
    FN=$(echo "$SR" | cut -f 7)
    DS=$(echo "$SR" | cut -f 8)
    DF=$(echo "$SR" | cut -f 9)  # data format
    UUID=$(echo "$SR" | cut -f 10)

    if [ "$STL" == "Blood Derived Normal" ]; then 
        ST="normal"
    elif [ "$STL" == "Solid Tissue Normal" ]; then 
        ST="normal"
    elif [ "$STL" == "Primary Tumor" ]; then 
        ST="tumor"
    else
        >&2 echo Error: Unknown sample type: $STL
        exit
    fi

    # Test existence of output file and index file
    FNF=$(echo "$DATD/$UUID/$FN" | tr -s '/')  # append full path to data file, normalize path separators
    if [ ! -e $FNF ] && [ -z $NOWARN ]; then
        >&2 echo WARNING: Data file does not exist: $FNF
    fi

    if [ $DF == "BAM" ]; then
        # If BAM file, test to make sure that .bai file generated
        BAI="$FNF.bai"
        if [ ! -e $BAI ] && [ -z $NOWARN ]; then
            >&2 echo WARNING: Index file does not exist: $BAI
        fi
    fi


    printf "$SN\t$CASE\t$DIS\t$ES\t$ST\t$FNF\t$DS\t$DF\t$REF\t$UUID\n"
}

# Default values
SR_FILE="config/SR.dat"
DATA_DIR="./data"
REF="hg19"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":S:O:r:Hw" opt; do
  case $opt in
    S) 
      SR_FILE=$OPTARG
      ;;
    O) # set DATA_DIR
      DATA_DIR="$OPTARG"
      ;;
    r) 
      REF="$OPTARG"
      ;;
    H) 
      HEADER=1
      ;;
    w) 
      NOWARN=1
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

if [ -z $SR_FILE ]; then
    >&2 echo Error: SR file not defined \(-S\)
    exit
fi
if [ ! -e $SR_FILE ]; then
    >&2 echo "Error: $SR_FILE does not exist"
    exit
fi

if [ "$#" -lt 1 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo Usage: make_bam_map.sh [options] UUID [UUID2 ...]
    exit
fi

DATD="$DATA_DIR/GDC_import/data"
if [ ! -e $DATD ]; then
    >&2 echo "Error: Data directory does not exist: $DATD"
    exit
fi

if [ $HEADER ]; then
#    dt=$(date '+%d/%m/%Y %H:%M:%S');
#    echo "# Summary Date $dt" 
    printf "# SampleName\tCase\tDisease\tExpStrategy\tSampType\tDataPath\tFileSize\tDataFormat\tReference\tUUID\n"
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
    summarize_import $UUID $REF
done

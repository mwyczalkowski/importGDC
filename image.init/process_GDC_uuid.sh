#!/bin/bash

# author: Matthew Wyczalkowski m.wyczalkowski@wustl.edu

# Usage: process_GDC_uuid.sh [options] UUID TOKEN FN DT
# Download and index (if BAM) data from GDC.  This script runs within docker container
# Indexing will also create a flagstat summary file
# Arguments:
#   UUID - UUID of object to download.  Mandatory
#   TOKEN - token filename visible from container.  Mandatory
#   FN - filename of object.  Required, used only for indexing
#   DF - dataformat of object (BAM, FASTQ).  Required
# Options:
#   -O OUTD: base of imported data dir, visible from container.  Default is /data/GDC_import/data.  Optional
#   -D: Download only, do not index
#   -I: Index only, do not Download.  DT must be "BAM"
#   -d: dry run, simply print commands which would be executed for principal steps
#   -f: force overwrite of existing data files
#   -P GDCBIN: Path to gdc-client.  Default: /usr/local/bin
#   -T TRICKLE_RATE: Run using trickle to shape data usage; rate is maximum cumulative download rate
#       e.g., -T 75000 will run `trickle -s -d 75000 gdc-client ...`.  See https://github.com/mariusae/trickle


OUTD="/data/GDC_import/data"
GDCBIN="/usr/local/bin"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":O:DIdP:fT:" opt; do
  case $opt in
    O)
      OUTD="$OPTARG"
      >&2 echo Output directory: $OUTD
      ;;
    P)
      GDCBIN="$OPTARG"
      >&2 echo GDC Path: $GDCBIN
      ;;
    D)  # Download only
      DLO=1
      >&2 echo MGI Mode
      ;;
    I)  # Index only
      IXO=1
      >&2 echo Output dir: $OUTD
      ;;
    f)  # dry run
      FORCE_OVERWRITE=1
      >&2 echo Force overwrite of existing files
      ;;
    d)  # dry run
      DRYRUN=1
      ;;
    T)
      TRICKLE_RATE="$OPTARG"
      >&2 echo Using trickle with rate $OPTARG
      ;;
    \?)
      >&2 echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      >&2 echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ "$#" -ne 4 ]
then
    >&2 echo "Error - invalid number of arguments"
    >&2 echo Usage: process_GDC_uuid.sh \[options\] UUID TOKEN FN DT
    exit 1
fi

mkdir -p $OUTD

UUID=$1
TOKEN=$2
FN=$3
DT=$4

# Where we expect output to go
DAT=$OUTD/$UUID/$FN

# RUN is a prefix which allows us to short-circuit execution for dry run
RUN=""
if [ ! -z $DRYRUN ]; then
    RUN="echo"
    >&2 echo Dry run $0
fi

# use trickle to slow down downloads to play nicely in clusters, especially with multiple jobs running
if [ $TRICKLE_RATE ]; then
    TRICKLE="trickle -s -d $TRICKLE_RATE"
    RUN="$RUN $TRICKLE"
fi

# If output file exists and FORCE_OVERWRITE not set, and not in Index Only mode, exit
if [ -f $DAT ] && [ -z $FORCE_OVERWRITE ] && [ -z $IXO ]; then
    >&2 echo Output file $DAT exists.  Stopping.  Use -f to force overwrite.
    exit 1
fi

# Download if not "index only"
if [ -z $IXO ]; then
    >&2 echo Writing to $DAT

    # Confirm token file exists
    if [ ! -e $TOKEN ]; then
        >&2 echo ERROR: Token file does not exist: $TOKEN
        exit 1
    fi

    # Documentation of gdc-client: https://docs.gdc.cancer.gov/Data_Transfer_Tool/Users_Guide/Accessing_Built-in_Help/
    # GDC Client saves data to file $OUTD/$UUID/$FN.  We take advantage of this information to index BAM file after download
    $RUN $GDCBIN/gdc-client download -t $TOKEN -d $OUTD $UUID
fi


## Now index if this is a BAM file, and not download-only
if [ $DT == "BAM" ] && [ -z $DLO ] ; then
>&2 echo Indexing $DAT

# Confirm $DAT exists
if [ ! -f $DAT ]; then
>&2 echo BAM file $DAT does not exist.  Not indexing.
exit 1
fi

$RUN /usr/bin/samtools index $DAT
$RUN /usr/bin/samtools flagstat $DAT > ${DAT}.flagstat

fi



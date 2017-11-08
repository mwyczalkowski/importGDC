# Launch docker instance to import and index GDC data
# Usage: GDC_import.sh [options] UUID [UUID2 ...]
#
# -M: run in MGI environment
# -O: output directory on localhost.  Mandatory
# -t: token file path in container.  Mandatory
# -n: filename associated with UUID.  Mandatory
# -p: dataformat (BAM or FASTQ).  Mandatory
# -d: dry run - print out docker statement but do not execute (for debugging)
# -B: run bash instead of process_GDC_uuid.sh
# -D: Download only, do not index
# -I: Index only, do not Download.  DT must be "BAM"

# This is run from the host computer.  
# Executes script image.init/process_GDC_uuid.sh from within docker container

# start process_GDC_uuid.sh in vanilla docker environment
function processUUID {
UUID=$1
OUTD=$2
TOKEN=$3
FN=$4
DF=$5

# This starts mwyczalkowski/gdc-client and maps directories:
# Container: /data
# Host: $OUTD

IMAGE="mwyczalkowski/gdc-client"

# the XARGS things is ugly; used to pass -I and -O without redoing plumbing

if [ -z $RUNBASH ]; then
    CMD="bash /usr/local/importGDC/image.init/process_GDC_uuid.sh $XARGS $UUID $TOKEN $FN $DF"
else
    CMD="/bin/bash"
fi

if [ -z $DRYRUN ]; then
    docker run -v $OUTD:/data -it $IMAGE $CMD
else
    >&2 echo docker run -v $OUTD:/data -it $IMAGE $CMD
fi

}

# start docker in MGI environment
function processUUID_MGI {
ID=$1

# logs will be written to $SCRIPTD/bsub_run-step_$STEP.err, .out
mkdir -p logs
ERRLOG="logs/$ID.err"
OUTLOG="logs/$ID.out"
LOGS="-e $ERRLOG -o $OUTLOG"
rm -f $ERRLOG $OUTLOG
echo Writing bsub logs to $OUTLOG and $ERRLOG

# CMD is passed as argument to /usr/local/bin/gdc-client
    # This is defined in /Users/mwyczalk/src/docker/mgi/Dockerfile.gdc-client with 
    # ENTRYPOINT ["/usr/local/bin/gdc-client"]
#CMD="download -t $TOKEN -d $OUTD $ID"

echo Not implemented
exit

bsub -q research-hpc $LOGS -a 'docker (mwyczalkowski/gdc-client)' "$CMD"

}

XARGS=""
# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":Mt:O:p:n:dBID" opt; do
  case $opt in
    M)  # example of binary argument
      MGI=1
      >&2 echo MGI Mode
      ;;
    t)
      TOKEN=$OPTARG
      >&2 echo Token file: $TOKEN
      ;;
    O)  # Note, this used to be O
      OUTD=$OPTARG
      >&2 echo Host data dir: $OUTD
      ;;
    p)
      DF=$OPTARG
      >&2 echo Data Format: $DF
      ;;
    n)
      FN=$OPTARG
      >&2 echo Filename: $FN
      ;;
    d) 
      DRYRUN=1
      >&2 echo Dry run
      ;;
    B)  
      RUNBASH=1
      >&2 echo Run bash
      ;;
    I)  
      XARGS="$XARGS -I"
      ;;
    D)  
      XARGS="$XARGS -D"
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

if [ -z $TOKEN ]; then
    >&2 echo Error: token not defined \[-t\]
    exit
fi
if [ -z $OUTD ]; then
    >&2 echo Error: output directory not defined \[-o\]
    exit
fi

for UUID in "$@"
do

if [ $MGI ]; then
processUUID_MGI $UUID
else
processUUID $UUID $OUTD $TOKEN $FN $DF
fi

done

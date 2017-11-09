# Evaluate status of all samples in batch file 
# This is specific to MGI
# Usage: evaluate_status.sh [options] batch.dat
#
# Output written to STDOUT

# options
# -f status: output only lines matching status, e.g., -f import:completed
# -u: output UUID only
# -D: output data file path

# these are locale-specific assumptions
LOGD="bsub-logs"
DATD="/gscmnt/gc2521/dinglab/mwyczalk/CPTAC3-download/GDC_import"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":uf:D" opt; do
  case $opt in
    u)  
      UUID_ONLY=1
      ;;
    D)  
      DATA_PATH=1
      ;;
    f) # example of value argument
      FILTER=$OPTARG
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

if [ "$#" -ne 1 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo Usage: update_batch_status.sh \[options\] batch.dat
    exit
fi

BATCH=$1


if [ ! -e $DATD ]; then
    >&2 echo "Error: Data directory does not exist: $DATD"
    exit
fi


# Evaluate download status of gdc-client by examining LSF logs (MGI-specific) and existence of output file
# Returns one of "ready", "running", "completed", "error"
# Usage: test_import_success UUID FN
# where FN is the filename (relative to data directory) as written by gdc-client
function test_import_success {
UUID=$1
FN=$2

LOGERR="$LOGD/$UUID.err"  # this is generally not used
LOGOUT="$LOGD/$UUID.out"
DAT="$DATD/$FN"
DATP="$DATD/$FN.partial"

# flow of gdc-client download and processing
# 1. create output directory and $DAT.partial file as it is being downloaded
# 2. index file (if it is a .bam) to create .bai file
# 3. Create $DAT when it is finished.  Write "Successfully completed." to log.out file
# 4. If dies for some reason, write "Exited with exit code" to log.out file

# Other, tests may be added as necessary

# If neither DAT or DATP created, assume download did not start and status is ready
if [ ! -e $DAT ] && [ ! -e $DATP ] ; then
    echo ready
    return
fi

ERROR="Exited with exit code"
if fgrep -Fq "$ERROR" $LOGOUT; then
    echo error
    return
fi

SUCCESS="Successfully completed."
if fgrep -Fxq "$SUCCESS" $LOGOUT; then
    echo completed
else
    echo running
fi

}

function get_job_status {
UUID=$1
SN=$2
FN=$3
# evaluates status of import by checking LSF logs
# Based on /gscuser/mwyczalk/projects/SomaticWrapper/SW_testing/BRCA77/2_get_runs_status.sh

# Its not clear how to test completion of a program in a general way, and to test if it exited with an error status
# For now, we'll grep for "Successfully completed." in the .out file of the submitted job
# This will probably not catch jobs which exit early for some reason (memory, etc), and is LSF specific


TEST1=$(test_import_success $UUID $FN)  

# for multi-step processing would report back a test for each step
printf "$UUID\t$SN\t$FN\timport:$TEST1\n"
}

while read L; do
    # Skip comments and header
    [[ $P = \#* ]] && continue

    UUID=$(echo "$L" | cut -f 1) # unique ID of file
    SN=$(echo "$L" | cut -f 2)   # sample name
    FN=$(echo "$L" | cut -f 3)   # filename

    STATUS=$(get_job_status $UUID $SN $FN )

    # which columns to output?
    if [ ! -z $UUID_ONLY ]; then
        COLS="1"
    elif [ ! -z $DATA_PATH ]; then        
        COLS="1-4" 
    else 
        COLS="1,2,4" 
    fi

    if [ ! -z $FILTER ]; then
        echo "$STATUS" | grep $FILTER | cut -f $COLS
    else 
        echo "$STATUS" | cut -f $COLS
    fi

done <$BATCH


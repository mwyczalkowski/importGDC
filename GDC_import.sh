# Import GDC data using bsub and docker
# Usage: GDC_import.sh UUID [UUID2 ...]

# TODO: Create wrapper script which will index this file, using command e.g., 
# samtools index CPT0000110163.WholeExome.RP-1303.bam

# TODO: this needs to have BAM filename passed. Do parsing of JSON stuff here?

# Using UUID instead
TOKEN="import-config/gdc-user-token.2017-10-27T18-16-34.880Z.txt"


OUTD="/gscmnt/gc2521/dinglab/mwyczalk/CPTAC3-download"
echo Output to $OUTD

function processUUID {
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
# Documentation: https://docs.gdc.cancer.gov/Data_Transfer_Tool/Users_Guide/Accessing_Built-in_Help/
CMD="download -t $TOKEN -d $OUTD $ID"

bsub -q research-hpc $LOGS -a 'docker (mwyczalkowski/gdc-client)' "$CMD"

}

for UUID in "$@"
do

processUUID $UUID

done

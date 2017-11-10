#!/bin/bash

# author: Matthew Wyczalkowski m.wyczalkowski@wustl.edu

# Read in an SR data file and write (to STDOUT) a batch file
# Batch files define a collection of samples (submitted read entries) 
# They have the UUID of the Submitted Read (BAM / FASTQ), as well as a unique name which is generated here

# Usage: make_batch_file.sh SR.dat > batch.dat
# SR.dat may be - to read from stdin

if [ "$#" -ne 1 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo make_batch_file.sh SR.dat
    exit
fi

SR=$1

source "$IMPORTGDC_HOME/batch.import/get_SN.sh"

# SR columns: case, disease, experimental_strategy, sample_type, samples, filename, filesize, data_format, UUID, md5sum


while read line; do

    CASE=$(echo "$line" | cut -f 1)
    ES=$(echo "$line" | cut -f 3)
    UUID=$(echo "$line" | cut -f 9)
    FN=$(echo "$line" | cut -f 6)

    STL=$(echo "$line" | cut -f 4) # sample_type - long format: "Blood Derived Normal" or "Primary Tumor"
    DF=$(echo "$line" | cut -f 8)

    SN=$(get_SN $CASE "$STL" $ES $FN $DF)  # quote STL because it has spaces

    # Finally, create expected filename as imported by gdc-client.  This consists of UUID/filename
    GDCFN="$UUID/$FN"

    printf "$UUID\t$SN\t$GDCFN\n"


done < <(cat $SR)


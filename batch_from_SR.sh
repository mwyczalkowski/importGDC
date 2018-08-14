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


while read line; do

    SN=$(echo "$line" | cut -f 1)  # Sample name defined in SR file now
    CASE=$(echo "$line" | cut -f 2)
    ES=$(echo "$line" | cut -f 4)
    UUID=$(echo "$line" | cut -f 10)
    FN=$(echo "$line" | cut -f 7)

    STL=$(echo "$line" | cut -f 5) # sample_type - long format: "Blood Derived Normal" or "Primary Tumor"
    DF=$(echo "$line" | cut -f 9)

    # Finally, create expected filename as imported by gdc-client.  This consists of UUID/filename
    GDCFN="$UUID/$FN"

    >&2 echo $CASE: $ES
    printf "$UUID\t$SN\t$GDCFN\n"


done < <(cat $SR)


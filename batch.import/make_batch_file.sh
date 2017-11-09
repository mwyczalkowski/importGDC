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

# SR columns: case, disease, experimental_strategy, sample_type, samples, filename, filesize, data_format, UUID, md5sum

# Sample name will be made of case, experimental_strategy, and sample_type abbreviation
# In the case of RNA-Seq, we extract the read number (R1 or R2) from the file name - this is empirical, and may change with different data types

while read line; do

CASE=$(echo "$line" | cut -f 1)
ES=$(echo "$line" | cut -f 3)
UUID=$(echo "$line" | cut -f 9)
FN=$(echo "$line" | cut -f 6)

STL=$(echo "$line" | cut -f 4)
if [ "$STL" == "Blood Derived Normal" ]; then 
    ST="N"
elif [ "$STL" == "Primary Tumor" ]; then 
    ST="T"
else
    >&2 echo Error: Unknown sample type: $STL
    exit
fi

DF=$(echo "$line" | cut -f 8)
if [ $ES == "RNA-Seq" ] && [ $DF == "FASTQ" ]; then
# Identify R1, R2 by matching for _R1_ or _R2_ in filename.  This only works for FASTQs.
# RNA-Seq filename 170830_UNC31-K00269_0078_AHLCVMBBXX_AGTCAA_S18_L006_R1_001.fastq.gz
    
    if [[ $FN == *"_R1_"* ]]; then
        RN="R1"
    elif [[ $FN == *"_R2_"* ]]; then
        RN="R2"
    else
        >&2 echo "Unknown filename format (cannot find _R1_ or _R2_): $FN"
        exit
    fi
    ES="$ES.$RN"
fi

SN="$CASE.$ES.$ST"

# Finally, create expected filename as imported by gdc-client.  This consists of UUID/filename

GDCFN="$UUID/$FN"

printf "$UUID\t$SN\t$GDCFN\n"


done < <(cat $SR)


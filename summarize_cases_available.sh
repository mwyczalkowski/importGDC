#!/bin/bash

# Matthew Wyczalkowski <m.wyczalkowski@wustl.edu>
# https://dinglab.wustl.edu/

read -r -d '' USAGE <<'EOF'
Evaluate presence of data on system and on GDC

Usage:
  summarize_cases_available.sh [options]CASES.dat AR.dat BAMMAP.dat

Options:
    -h: Print this help message
    -d: Dry Run

EOF

# This script is based on https://github.com/ding-lab/CPTAC3.case.discover/blob/master/summarize_cases.sh
# Writes to STDOUT simple ASCII summary of data present at GDC and on this system
#
# We are interested in identifying counts of various "data species".  These consist of the following data types:
# * WGS.hg19 
# * WXS.hg19 
# * RNA.fq 
# * miRNA.fq 
# * WGS.hg38 
# * WXS.hg38 
# * RNA.hg38 
# For each, consider tumor (T), blood normal (N), and tissue adjacant normal (A)
# Data available on system (in BamMap) indicated with upper case, those on GDC but not here are in lower case

# 
# Algorithm:
#   Loop over all cases
#       Consier each "data species": 

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hdf:" opt; do
  case $opt in
    h)
      echo "$USAGE"
      exit 0
      ;;
    d)  # example of binary argument
      >&2 echo "Dry run" 
      CMD="echo"
      ;;
#    f) # example of value argument
#      FILTER=$OPTARG
#      >&2 echo "Setting memory $MEMGB Gb" 
#      ;;
    \?)
      >&2 echo "Invalid option: -$OPTARG" 
      echo "$USAGE"
      exit 1
      ;;
    :)
      >&2 echo "Option -$OPTARG requires an argument." 
      echo "$USAGE"
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ "$#" -ne 3 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo "$USAGE"
    exit 1
fi

CASES=$1
DAT=$2
OUT=$3

# Usage: repN X N
# will return a string consisting of character X repeated N times
# if N is 0 empty string is returned
# https://stackoverflow.com/questions/5349718/how-can-i-repeat-a-character-in-bash
function repN {
    X=$1
    N=$2

    if [ $N == 0 ]; then
        return
    fi

    printf "$1"'%.s' $(eval "echo {1.."$(($2))"}");
}

function summarize_case {
CASE=$1
DIS=$2

# Get counts for (tumor, normal, tissue) x (WGS.hg19, WXS.hg19, WGS.hg38, WXS.hg38, RNA-Seq, miRNA-Seq)
# Columns of SR.dat
#     1  sample_name
#     2  case
#     3  disease
#     4  experimental_strategy
#     5  sample_type
#     6  samples
#     7  filename
#     8  filesize
#     9  data_format
#    10  UUID
#    11  MD5
#    12  reference

# values of sample_type we are evaluating:
# blood_normal = N
# tissue_normal = A
# tumor = T

# Note that Submitted Aligned Reads were previously (y1) all hg19.  That will not necessarily always
# be the case, but we don't know what they are. For now, for simplicity, we will list the reference of all submitted
# aligned reads as "hg19"

function count_entries {
CASE=$1
ES=$2
ST=$3
REF=$4

awk -v c=$CASE -v es=$ES -v st=$ST -v ref=$REF 'BEGIN{FS="\t";OFS="\t"}{if ( ($2 == c) && ($4 == es) && ($5 == st) && ($12 == ref)) print}' $DAT | wc -l
}

# Get number of matches for each data category
WGS19_T=$(count_entries $CASE WGS tumor hg19)
WGS19_N=$(count_entries $CASE WGS blood_normal hg19)
WGS19_A=$(count_entries $CASE WGS tissue_normal hg19)

WXS19_T=$(count_entries $CASE WXS tumor hg19)
WXS19_N=$(count_entries $CASE WXS blood_normal hg19)
WXS19_A=$(count_entries $CASE WXS tissue_normal hg19)

WGS38_T=$(count_entries $CASE WGS tumor hg38)
WGS38_N=$(count_entries $CASE WGS blood_normal hg38)
WGS38_A=$(count_entries $CASE WGS tissue_normal hg38)

WXS38_T=$(count_entries $CASE WXS tumor hg38)
WXS38_N=$(count_entries $CASE WXS blood_normal hg38)
WXS38_A=$(count_entries $CASE WXS tissue_normal hg38)

RNA_T=$(count_entries $CASE RNA-Seq tumor NA)
RNA_N=$(count_entries $CASE RNA-Seq blood_normal NA)
RNA_A=$(count_entries $CASE RNA-Seq tissue_normal NA)

RNA38_T=$(count_entries $CASE RNA-Seq tumor hg38)
RNA38_N=$(count_entries $CASE RNA-Seq blood_normal hg38)
RNA38_A=$(count_entries $CASE RNA-Seq tissue_normal hg38)

MIRNA_T=$(count_entries $CASE miRNA-Seq tumor NA)
MIRNA_N=$(count_entries $CASE miRNA-Seq blood_normal NA)
MIRNA_A=$(count_entries $CASE miRNA-Seq tissue_normal NA)

MIRNA38_T=$(count_entries $CASE miRNA-Seq tumor hg38)
MIRNA38_N=$(count_entries $CASE miRNA-Seq blood_normal hg38)
MIRNA38_A=$(count_entries $CASE miRNA-Seq tissue_normal hg38)

# Get string representations, given character repeated as many times as datasets 
WGS19_TS=$(repN T $WGS19_T)
WGS19_NS=$(repN N $WGS19_N)
WGS19_AS=$(repN A $WGS19_A)

WXS19_TS=$(repN T $WXS19_T)
WXS19_NS=$(repN N $WXS19_N)
WXS19_AS=$(repN A $WXS19_A)

WGS38_TS=$(repN T $WGS38_T)
WGS38_NS=$(repN N $WGS38_N)
WGS38_AS=$(repN A $WGS38_A)

WXS38_TS=$(repN T $WXS38_T)
WXS38_NS=$(repN N $WXS38_N)
WXS38_AS=$(repN A $WXS38_A)

RNA_TS=$(repN T $RNA_T)
RNA_NS=$(repN N $RNA_N)
RNA_AS=$(repN A $RNA_A)

MIRNA_TS=$(repN T $MIRNA_T)
MIRNA_NS=$(repN N $MIRNA_N)
MIRNA_AS=$(repN A $MIRNA_A)

RNA38_TS=$(repN T $RNA38_T)
RNA38_NS=$(repN N $RNA38_N)
RNA38_AS=$(repN A $RNA38_A)

MIRNA38_TS=$(repN T $MIRNA38_T)
MIRNA38_NS=$(repN N $MIRNA38_N)
MIRNA38_AS=$(repN A $MIRNA38_A)

printf "$CASE\t$DIS\t\
WGS.hg19 $WGS19_TS $WGS19_NS $WGS19_AS\t\
WXS.hg19 $WXS19_TS $WXS19_NS $WXS19_AS\t\
RNA.fq $RNA_TS $RNA_NS $RNA_AS\t\
miRNA.fq $MIRNA_TS $MIRNA_NS $MIRNA_AS\t\
WGS.hg38 $WGS38_TS $WGS38_NS $WGS38_AS\t\
WXS.hg38 $WXS38_TS $WXS38_NS $WXS38_AS\t\
RNA.hg38 $RNA38_TS $RNA38_NS $RNA38_AS\n"
}

while read L; do

    [[ $L = \#* ]] && continue  # Skip commented out entries

    CASE=$(echo "$L" | cut -f 1 )
    DIS=$(echo "$L" | cut -f 2 )

    >&2 echo Processing $CASE

    summarize_case $CASE $DIS >> $OUT

done < $CASES




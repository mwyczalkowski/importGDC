
# Usage: process_GDC_uuid.sh [-O OUTD] UUID TOKEN FN DT
# Download and index (if BAM) data from GDC
# Arguments:
#   UUID - UUID of object to download.  Mandatory
#   TOKEN - token filename visible from container.  Mandatory
#   FN - filename of object.  Required, used only for indexing
#   DF - dataformat of object (BAM, FASTQ).  Required
#   OUTD - base of imported data dir, visible from container.  Default is /data/GDC_import.  Optional

OUTD="/data/GDC_import"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":O:" opt; do
  case $opt in
#    M)  # example of binary argument
#      MGI=1
#      >&2 echo MGI Mode
#      ;;
    O)
      OUTD=$OPTARG
      >&2 echo Output dir: $OUTD
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
    >&2 echo Usage: process_GDC_uuid.sh [-O OUTD] UUID TOKEN FN DT
    exit 1
fi

mkdir -p $OUTD

UUID=$1
TOKEN=$2
FN=$3
DT=$4

# Documentation of gdc-client: https://docs.gdc.cancer.gov/Data_Transfer_Tool/Users_Guide/Accessing_Built-in_Help/
# GDC Client saves data to file $OUTD/$UUID/$FN.  We take advantage of this information to index BAM file after download
/usr/local/bin/gdc-client download -t $TOKEN -d $OUTD $UUID

if [ $DT == "BAM" ]; then
DAT=$OUTD/$UUID/$FN
>&2 echo Indexing $DAT

/usr/bin/samtools index $DAT

fi



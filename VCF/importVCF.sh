IMPORT_DATAD_H=/data/VCF-import 
TOKEN=/data/gdc-user-token.2018-08-20T16_10_39.566Z.txt
DF=FASTQ

PROCESS="/usr/local/importGDC/process_GDC_uuid.sh"
ARGS="-O $IMPORT_DATAD_H"  # this will move destination directory, keep VCF separate from sequence data

# Usage: vcf_download UUID FN
function vcf_download {
	UUID=$1
	FN=$2

	bash $PROCESS $ARGS $UUID $TOKEN $FN $DF
}

UUID=9a7713dd-6647-4b88-9107-9926ae006e2c
FN=fd18991b-7e0a-4533-ac5c-bffebff4c37b.wxs.mutect2.raw_somatic_mutation.vcf.gz
vcf_download $UUID $FN

UUID=b5960db6-5540-4cb1-89a5-f7767b1c0c8f
FN=fd18991b-7e0a-4533-ac5c-bffebff4c37b.wxs.somaticsniper.raw_somatic_mutation.vcf.gz
vcf_download $UUID $FN

UUID=78d4f5a5-6b5e-43d8-a546-223b47f86879
FN=fd18991b-7e0a-4533-ac5c-bffebff4c37b.wxs.varscan2.raw_somatic_mutation.vcf.gz
vcf_download $UUID $FN

UUID=995f9665-0cce-41b8-83de-c87a1e52a142
FN=fd18991b-7e0a-4533-ac5c-bffebff4c37b.wxs.muse.raw_somatic_mutation.vcf.gz
vcf_download $UUID $FN


# Output:
# /data/VCF-import/9a7713dd-6647-4b88-9107-9926ae006e2c/fd18991b-7e0a-4533-ac5c-bffebff4c37b.wxs.mutect2.raw_somatic_mutation.vcf.gz
# /data/VCF-import/b5960db6-5540-4cb1-89a5-f7767b1c0c8f/fd18991b-7e0a-4533-ac5c-bffebff4c37b.wxs.somaticsniper.raw_somatic_mutation.vcf.gz
# /data/VCF-import/78d4f5a5-6b5e-43d8-a546-223b47f86879/fd18991b-7e0a-4533-ac5c-bffebff4c37b.wxs.varscan2.raw_somatic_mutation.vcf.gz
# /data/VCF-import/995f9665-0cce-41b8-83de-c87a1e52a142/fd18991b-7e0a-4533-ac5c-bffebff4c37b.wxs.muse.raw_somatic_mutation.vcf.gz


# Convenience function to run bash in mwyczalkowski/importgdc docker container
# with data directory mounted to /data
# essentially equivalent to GDC_import.sh -B


DATA_DIR="/diskmnt/Projects/cptac"
DOCKER_IMAGE="mwyczalkowski/importgdc"
CMD="/bin/bash"

docker run -v $OUTD:/data -it $DOCKER_IMAGE $CMD

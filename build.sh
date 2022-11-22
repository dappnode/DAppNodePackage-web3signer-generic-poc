#!/bin/bash

ENVIRONMENT_DIR=enviroments
TEMPLATES_DIR=template_files
STATIC_DIR=static_files

## search for all *.env
for env_file in $(find ${ENVIRONMENT_DIR} -type f -maxdepth 1 -name "*.env"); do
    echo "Processing $env_file file..."
    #Remove the .env path and extension
    ENVIRONMENT=${env_file##*/}
    ENVIRONMENT=${ENVIRONMENT%%.*}
    #load the environment variables
    source $env_file
    #export environment variables
    export $(awk -F"=" '{printf "%s ",$1} END {print ""}' $env_file)
    echo "Building $ENVIRONMENT"
    #set destination folder and create it if it doesn't exist
    DST_PATH=build/$ENVIRONMENT
    mkdir -p "${DST_PATH}"

    # Copy non generated files to build folder
    for SRC in $(find $TEMPLATES_DIR -type f -not -name "*-build*" -a -not -name ".*"); do
        DIR="$(dirname "${SRC}")"
        mkdir -p $DST_PATH/${DIR/$TEMPLATES_DIR/.}
        DST=$DST_PATH${SRC/$TEMPLATES_DIR/}
        cp $SRC $DST
    done

    # Generate files from templates
    for SRC in $(find $TEMPLATES_DIR -name "*-build*"); do
        DIR="$(dirname "${SRC}")"
        mkdir -p $DST_PATH${DIR/$TEMPLATES_DIR/}
        DST=${SRC/$TEMPLATES_DIR/.}
        DST=${DST/-build/}
        ENVS_VARS=$(awk -F"=" '{printf "$%s ",$1} END {print ""}' $env_file)
        if [ ! -f $DST ]; then
            envsubst "${ENVS_VARS}" <$SRC >$DST_PATH/$DST
        fi
        if [ "${DST: -3}" == ".sh" ]; then
            chmod +x $DST_PATH/$DST
        fi
    done

    # copy static files from templates
    STATIC_DIR_ENVIRONMENT=$STATIC_DIR/$ENVIRONMENT
    for SRC in $(find $STATIC_DIR_ENVIRONMENT -type f); do
        DIR="$(dirname "${SRC}")"
        DST=$DST_PATH${SRC/$STATIC_DIR_ENVIRONMENT/}
        mkdir -p $DST_PATH/${DIR/$STATIC_DIR_ENVIRONMENT/}
        cp $SRC $DST
    done
done

#!/bin/bash

# usage:
# 	video.autoCrop.sh FILE='xyz.mkv'


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${FILE:=""};
EXT=${FILE##*.};
: ${FMT:="$EXT"};
: ${OUTPUT:="${FILE%.*}-reenc.${EXT}"};
: ${CLEANUP:="no"};
: ${BPS:="350k"};

REALFILE="$FILE";

# ffmpeg -i "$FILE" -c:a copy "${OUTPUT}";
# ffmpeg -y -i "$FILE" -c:v libx264 -b:v $BPS -pass 1 -an -f null /dev/null && ffmpeg -i "$FILE" -c:v libx264 -b:v $BPS -pass 2 -c:a copy "${OUTPUT}";
ffmpeg -i "$FILE" -c:v libx264 -preset slow -tune animation -crf 32 -c:a copy "${OUTPUT}";

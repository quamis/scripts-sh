#!/bin/bash

# usage:
# 	video.autoCrop.sh FILE='xyz.mkv'

# re-encode all AV1 files in a folder with this:
#     find . -type f -exec bash -c "video.is.AV1.sh FILE='{}' && video.reencode-testing.sh FILE='{}';" \;


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
: ${PRESET:="libx264,27"};

REALFILE="$FILE";

# ffmpeg -i "$FILE" -c:a copy "${OUTPUT}";
# ffmpeg -y -i "$FILE" -c:v libx264 -b:v $BPS -pass 1 -an -f null /dev/null && ffmpeg -i "$FILE" -c:v libx264 -b:v $BPS -pass 2 -c:a copy "${OUTPUT}";
if [[ "$PRESET" == "libx264,34" ]]; then
    ffmpeg -i "$FILE" -c:v libx264 -preset slow -crf 34 -c:a copy "${OUTPUT}";
    if [[ "$?" == "0" ]]; then
        if [[ "$CLEANUP" == "yes" ]]; then
            rm "$FILE";
            mv "${OUTPUT}" "$FILE";
        fi;
    fi;
fi;

if [[ "$PRESET" == "libx264,27" ]]; then
    ffmpeg -i "$FILE" -c:v libx264 -preset slow -crf 27 -c:a copy "${OUTPUT}";
    if [[ "$?" == "0" ]]; then
        if [[ "$CLEANUP" == "yes" ]]; then
            rm "$FILE";
            mv "${OUTPUT}" "$FILE";
        fi;
    fi;
fi;



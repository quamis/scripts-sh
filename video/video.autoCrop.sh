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
: ${OUTPUT:="${FILE%.*}-autocropped.${EXT}"};
: ${AUTOCROP:="yes"};

CROPREGION=`ffmpeg -i "$FILE" -ss 2 -t 1 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1`;

echo "CROP REGION: $CROPREGION"
if [[ "$AUTOCROP" == "yes" ]]; then
	# video encoding help: https://trac.ffmpeg.org/wiki/Encode/H.264
	ffmpeg -i "$FILE" -c:a copy -c:v libx264 -preset slow -crf 28 -vf "$CROPREGION" "$OUTPUT";
fi;


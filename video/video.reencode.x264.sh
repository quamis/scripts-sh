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
: ${RESCALE:="yes"};
: ${BPS:="350k"};
: ${PRESET:="libx264,27"};

REALFILE="$FILE";

# ffmpeg -i "$FILE" -c:a copy "${OUTPUT}";
# ffmpeg -y -i "$FILE" -c:v libx264 -b:v $BPS -pass 1 -an -f null /dev/null && ffmpeg -i "$FILE" -c:v libx264 -b:v $BPS -pass 2 -c:a copy "${OUTPUT}";

FFMPEG_CRF=51;
FFMPEG_PRESET="slow";
FFMPEG_AUDIO_CODEC="copy";  # ac3, aac, mp3, copy
FFMPEG_EXTRA_PARAM1="";
FFMPEG_EXIT_CODE="-1";

if [[ "$PRESET" == "libx264,20" ]]; then
    FFMPEG_CRF=20;
elif [[ "$PRESET" == "libx264,27" ]]; then
    FFMPEG_CRF=27;
elif [[ "$PRESET" == "libx264,34" ]]; then
    FFMPEG_CRF=34;
elif [[ "$PRESET" == "libx264,50" ]]; then
    FFMPEG_CRF=50;
else
    echo "Unkown preset: ${PRESET}";
    exit 1;
fi;


if [[ "$PREVIEW" == "yes" ]]; then
    FFMPEG_PRESET="ultrafast";
    FFMPEG_AUDIO_CODEC="copy";
    FFMPEG_EXTRA_PARAM1="-ss 00:00:30 -t 00:02:30";
fi;

if [[ "$RESCALE" == "yes" ]]; then
    FFMPEG_EXTRA_PARAM1="$FFMPEG_EXTRA_PARAM1 -vf scale='max(960,iw*0.75)':-2";
fi;

ffmpeg -i "$FILE" $FFMPEG_EXTRA_PARAM1 -c:v libx264 -preset $FFMPEG_PRESET -crf $FFMPEG_CRF -c:a $FFMPEG_AUDIO_CODEC "$OUTPUT";
FFMPEG_EXIT_CODE=$?;

if [[ "$FFMPEG_EXIT_CODE" == "0" ]]; then
    if [[ "$CLEANUP" == "yes" ]]; then
        rm "$FILE";
        mv "${OUTPUT}" "$FILE";
    fi;
fi;

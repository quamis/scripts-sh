#!/bin/bash

# usage:
# 	video.autoCrop.sh FILE='xyz.mkv'

# re-encode all AV1 files in a folder with this:
#   find . -type f -exec bash -c "video.is.AV1.sh FILE='{}' && video.reencode.x264.sh FILE='{}';" \;

# re-encode ALL files:
#   find . -type f -exec bash -c "video.reencode.x264.sh FILE='{}';" \;



# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${DIR:="./"};
: ${FMT:="mkv"};
: ${OUTPUT:="video.${FMT}"};
: ${PRESET:="libx264,27"};
: ${PREVIEW:="no"};

CONCATENATED_FILENAMES=`ls $DIR/*.VOB | sort | tr "\n" "|"`;

# ffmepg params @https://trac.ffmpeg.org/wiki/Encode/H.264
#   Possible presets: ultrafast superfast veryfast faster fast medium slow slower veryslow placebo
#   Possible tunes: film animation grain stillimage psnr ssim fastdecode zerolatency

FFMPEG_CRF=51;
FFMPEG_PRESET="slow";
FFMPEG_AUDIO_CODEC="aac";  # ac3, aac, mp3, copy
FFMPEG_EXTRA_PARAM1="";

if [[ "$PRESET" == "libx264,20" ]]; then
    FFMPEG_CRF=20;
elif [[ "$PRESET" == "libx264,27" ]]; then
    FFMPEG_CRF=27;
elif [[ "$PRESET" == "libx264,34" ]]; then
    FFMPEG_CRF=34;
elif [[ "$PRESET" == "libx264,50" ]]; then  # lowest quality
    FFMPEG_CRF=50;
else
    echo "Unkown preset: ${PRESET}";
    exit 1;
fi;

if [[ "$PREVIEW" == "yes" ]]; then
    FFMPEG_PRESET="ultrafast";
    FFMPEG_AUDIO_CODEC="copy";
    FFMPEG_EXTRA_PARAM1="-ss 00:12:00 -t 00:02:30";
fi;

ffmpeg -i "concat:${CONCATENATED_FILENAMES}" $FFMPEG_EXTRA_PARAM1 -c:v libx264 -preset $FFMPEG_PRESET -tune film -crf $FFMPEG_CRF -c:a $FFMPEG_AUDIO_CODEC "${OUTPUT}";


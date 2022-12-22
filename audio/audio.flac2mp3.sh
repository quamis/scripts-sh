#!/bin/bash

# usage:
# 	audio.flac2mp3.sh EXT=flac,mp3 PRESET=m4a,3 RUN_MODE=parallel CLEANUP=yes


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done


: ${DIR:="./"};
: ${EXT:="flac,wav"};

: ${PRESET:="mp3,2"};
: ${COMMANDFILE:=`mktemp --tmpdir="${TMPDIR}"`};
: ${VERBOSE:="0"};	# 0, 1
: ${CLEANUP:="no"};

: ${RUN_MODE:="parallel"};	# 'dry-run', 'parallel', 'sequential'
: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${MAX_LOAD:="80%"};

regexpEXT=`echo "$EXT" | sed s/\,/\|/g`

echo > "$COMMANDFILE";

declare -A PRESET_MAP=( \
    ['mp3,0']='-acodec libmp3lame -b:a 320k' \
    ['mp3,1']='-acodec libmp3lame -b:a 256k' \
    ['mp3,2']='-acodec libmp3lame -b:a 224k' \
    ['mp3,3']='-acodec libmp3lame -b:a 192k' \
    ['mp3,4']='-acodec libmp3lame -b:a 160k' \
    ['mp3,5']='-acodec libmp3lame -b:a 128k' \
    ['mp3,6']='-acodec libmp3lame -b:a 112k' \
    ['mp3,7']='-acodec libmp3lame -b:a 96k ' \
    ['mp3,8']='-acodec libmp3lame -b:a 80k ' \
    ['mp3,9']='-acodec libmp3lame -b:a 64k ' \
                                             \
    ['m4a,0']='-acodec libfdk_aac -b:a 320k' \
    ['m4a,1']='-acodec libfdk_aac -b:a 256k' \
    ['m4a,2']='-acodec libfdk_aac -b:a 224k' \
    ['m4a,3']='-acodec libfdk_aac -b:a 192k' \
    ['m4a,4']='-acodec libfdk_aac -b:a 160k' \
    ['m4a,5']='-acodec libfdk_aac -b:a 128k' \
    ['m4a,6']='-acodec libfdk_aac -b:a 112k' \
    ['m4a,7']='-acodec libfdk_aac -b:a 96k ' \
    ['m4a,8']='-acodec libfdk_aac -b:a 80k ' \
    ['m4a,9']='-acodec libfdk_aac -b:a 64k ' \
)

# NOTE: for mp3, @see https://trac.ffmpeg.org/wiki/Encode/MP3

# NOTE: for aac, @see https://trac.ffmpeg.org/wiki/Encode/AAC
#       instead of libfdk_aac you could try libfaac or aac

SAVEIFS=$IFS
IFS=$'\n'
for FILE in `find "${DIR}/" -type f -print | egrep "\.(${regexpEXT})$" | sort`; do
    FILE_NAME=$(basename -- "${FILE}")
	FILE_DIR_AND_NAME_AND_EXT="${FILE}"
	FILE_EXT="${FILE_NAME##*.}"
	FILE_NAME="${FILE_NAME%.*}"
	FILE_NAME_WITH_EXT="${FILE_DIR_AND_NAME_AND_EXT##*/}"
	FILE_DIR="${FILE_DIR_AND_NAME_AND_EXT%/*}/"

    PRESET_EXT="${PRESET%,*}"

    CMD="ffmpeg -loglevel panic -i \"${FILE_DIR_AND_NAME_AND_EXT}\" -vn -y ${PRESET_MAP[$PRESET]} \"${FILE_DIR}/${FILE_NAME}.${PRESET_EXT}\"";
    if [[ "$CLEANUP" == "yes" ]]; then
        CMD="${CMD} && rm \"${FILE_DIR_AND_NAME_AND_EXT}\"";
    fi;

    if [ "$VERBOSE" = "1" ]; then
        echo "$CMD";
    fi;

    # append to the command list
    echo "($CMD;)" >> "$COMMANDFILE";
done;
IFS=$SAVEIFS

# simply display the "to-run" commands
if [ "$RUN_MODE" = "parallel" ]; then
	# run the list in paralel
	# @see https://www.gnu.org/software/parallel/man.html
	parallel --no-notice --bar --jobs $THREADS --load $MAX_LOAD < "$COMMANDFILE"
elif [ "$RUN_MODE" = "sequential" ]; then
	bash -x "$COMMANDFILE";
elif [ "$RUN_MODE" = "dry-run" ]; then
	cat "$COMMANDFILE";
else
	# TODO: sequential conversion
	echo "Unknown run mode";
fi;
rm $COMMANDFILE;


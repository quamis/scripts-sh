#!/bin/bash

# @requires
# ffmpeg, recompiled, see below for instructions

# audio.normalize.sh FILE='x.mp3';
#

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${FILE:="inout-file.mp3"};

: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${RUN_MODE:="parallel"};	# 'dry-run', 'parallel', 'sequential'
: ${MAX_LOAD:="95%"};



# @see https://superuser.com/questions/323119/how-can-i-normalize-audio-using-ffmpeg

# clear the command list
echo > "$COMMANDFILE";

# build a list of commands to run
regexpEXT=`echo "$EXT" | sed s/\,/\|/g`;

maxdepth="99999"
if [ "$RECURSE" = "0" ]; then
	maxdepth="1"
fi;

DIR=`realpath "${DIR}"`;

SAVEIFS=$IFS
IFS=$'\n'
for FILE in `find "${DIR}/" -maxdepth ${maxdepth} -type f -print | egrep "\.(${regexpEXT})$"`; do
	FILE_NAME=$(basename -- "${FILE}")
	FILE_DIR_AND_NAME_AND_EXT="${FILE}"
	FILE_EXT="${FILE_NAME##*.}"
	FILE_NAME="${FILE_NAME%.*}"
	FILE_NAME_WITH_EXT="${FILE_DIR_AND_NAME_AND_EXT##*/}"
	FILE_DIR="${FILE_DIR_AND_NAME_AND_EXT%/*}/"

	TMP_FILE=`mktemp "${TMPDIR}audio.XXXXXXXXXXXXXXXXXXXXXXX.${FILE_EXT}"`

	# DEBUGGING
	if [ "$VERBOSE" = "1" ]; then
		echo "FILE::$FILE_DIR_AND_NAME_AND_EXT"
		echo "    FILE_DIR:            $FILE_DIR"
		echo "    FILE_NAME_WITH_EXT:  $FILE_NAME_WITH_EXT"
		echo "    FILE_NAME:           $FILE_NAME"
		echo "    FILE_EXT:            $FILE_EXT"
	fi;

	# @see https://medium.com/@peter_forgacs/audio-loudness-normalization-with-ffmpeg-1ce7f8567053
	# 	ffmpeg -i input.mp4 -af loudnorm=I=-23:LRA=7:tp=-2:print_format=json -f null -
	# 	ffmpeg -i input.mp4 -af
	# 	loudnorm=I=-23:LRA=7:tp=-2:measured_I=-30:measured_LRA=1.1:measured_tp=-11 04:measured_thresh=-40.21:offset=-0.47 -ar 48k -y output.mp4

	CMD="(ffmpeg -loglevel panic -y -i \"${FILE_DIR_AND_NAME_AND_EXT}\" -filter:a \"dynaudnorm=p=0.99:s=5\" \"${TMP_FILE}\" && mv \"${TMP_FILE}\" \"${FILE_DIR}${FILE_NAME}-normalized.${FILE_EXT}\")"

	if [ "$VERBOSE" = "1" ]; then
		echo "$CMD";
	fi;

	# append to the command list
	echo "$CMD" >> "$COMMANDFILE";
done;
IFS=$SAVEIFS


# https://www.msi.umn.edu/support/faq/how-can-i-use-gnu-parallel-run-lot-commands-parallel

# process the command list

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

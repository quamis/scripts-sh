#!/bin/bash

# @requires
# imagemagik/convert
# pngcrush
# pngquant

# image.reencode-screenshot.sh DIR='/media/ext1Tb/nextcloud/music/files/Radio Guerilla - Zona Libera/';


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${DIR:="./"};
: ${EXT:="png"};
: ${QUALITY:="65"};
: ${RECURSE:="0"};
: ${TMPDIR:="/tmp/"};
: ${COMMANDFILE:=`mktemp --tmpdir="${TMPDIR}"`};
: ${VERBOSE:="0"};	# 0, 1
: ${METHOD:="pngquant"};	# 0, 1
: ${OVERWRITE:="0"};	# 0, 1

: ${RUN_MODE:="parallel"};	# 'dry-run', 'parallel', 'sequential'
: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${MAX_LOAD:="95%"};

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
for FILE in `find "${DIR}/" -maxdepth ${maxdepth} -type f -print | egrep "\.(${regexpEXT})$" | sort`; do
	FILE_NAME=$(basename -- "${FILE}")
	FILE_DIR_AND_NAME_AND_EXT="${FILE}"
	FILE_EXT="${FILE_NAME##*.}"
	FILE_NAME="${FILE_NAME%.*}"
	FILE_NAME_WITH_EXT="${FILE_DIR_AND_NAME_AND_EXT##*/}"
	FILE_DIR="${FILE_DIR_AND_NAME_AND_EXT%/*}/"

	# TMP_FILE=`mktemp "${TMPDIR}pdf.XXXXXXXXXXXXXXXXXXXXXXX.m4a"`

	# DEBUGGING
	if [ "$VERBOSE" = "1" ]; then
		echo "FILE::$FILE_DIR_AND_NAME_AND_EXT"
		echo "    FILE_DIR:            $FILE_DIR"
		echo "    FILE_NAME_WITH_EXT:  $FILE_NAME_WITH_EXT"
		echo "    FILE_NAME:           $FILE_NAME"
		echo "    FILE_EXT:            $FILE_EXT"
	fi;

	if [ "$METHOD" = "pngquant" ]; then
		CMD1="";
		CMD2="";
		if [ "$OVERWRITE" = "1" ]; then
			CMD="(${CMD1}pngquant --speed 1 --strip -f --ext .png \"${FILE_DIR_AND_NAME_AND_EXT}\"${CMD2})";
		else
			OUTPUT="${FILE_DIR}${FILE_NAME}.reenc.png";
			CMD="(${CMD1}pngquant --speed 1 --strip \"${FILE_DIR_AND_NAME_AND_EXT}\" --output \"${OUTPUT}\"${CMD2})";
		fi;

	elif [ "$METHOD" = "pngcrush" ]; then
		CMD1="";
		CMD2="";
		OUTPUT="${FILE_DIR}${FILE_NAME}.reenc.png";
		if [ "$OVERWRITE" = "1" ]; then
			CMD1="mv \"${FILE_DIR_AND_NAME_AND_EXT}\" \"${TMPDIR}${FILE_NAME_WITH_EXT}\" && ";
			CMD2=" && rm \"${FILE_DIR_AND_NAME_AND_EXT}\"";
			FILE_DIR_AND_NAME_AND_EXT="${TMPDIR}${FILE_NAME_WITH_EXT}";
			OUTPUT="${FILE_DIR}${FILE_NAME}.png";

			CMD="(${CMD1}pngcrush \"${FILE_DIR_AND_NAME_AND_EXT}\" \"${FILE_DIR}${FILE_NAME}.jpg\"${CMD2})";
		else
			CMD="(${CMD1}pngcrush \"${FILE_DIR_AND_NAME_AND_EXT}\" --output \"${OUTPUT}\"${CMD2})";
		fi;

	elif [ "$METHOD" = "jpg" ]; then
		CMD1="";
		CMD2="";
		OUTPUT="${FILE_DIR}${FILE_NAME}.reenc.png";
		if [ "$OVERWRITE" = "1" ]; then
			CMD1="mv \"${FILE_DIR_AND_NAME_AND_EXT}\" \"${TMPDIR}${FILE_NAME_WITH_EXT}\" && ";
			FILE_DIR_AND_NAME_AND_EXT="${TMPDIR}${FILE_NAME_WITH_EXT}";
			OUTPUT="${FILE_DIR}${FILE_NAME}.png";
			CMD2=" && rm \"${FILE_DIR_AND_NAME_AND_EXT}\"";
		fi;

		C1="-alpha remove -background \"#ffffff\"";
		C2="-fuzz 5% -trim +repage"; # autocrop page

		CMD="(${CMD1}convert \"${FILE_DIR_AND_NAME_AND_EXT}\" -quality ${QUALITY} $C1 $C2 \"${FILE_DIR}${FILE_NAME}.jpg\"${CMD2})";
	else
		echo "ERROR: unknown method: $METHOD";
		exit 1;
	fi;

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

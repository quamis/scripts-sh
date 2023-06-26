#!/bin/bash

# pdf.autoShrink.sh KEEP=smaller METHODS=hiq  DIR='./courses/';


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${DIR:="./"};
: ${EXT:="pdf"};
: ${METHODS:="default"};
: ${RECURSE:="0"};
: ${TMPDIR:="/tmp/"};
: ${COMMANDFILE:=`mktemp --tmpdir="${TMPDIR}"`};
: ${VERBOSE:="0"};	# 0, 1
: ${ODIR:="./compressed/"};
: ${KEEP:="smallest"};

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

    # for PNG quality encoding, see https://stackoverflow.com/questions/9710118/convert-multipage-pdf-to-png-and-back-linux/12046542#12046542
	CMD="(mkdir -p \"${ODIR}\" && pdf.autoShrinkOneFile.sh FILE=\"${FILE_DIR_AND_NAME_AND_EXT}\" OFILE=\"${ODIR}/${FILE_NAME_WITH_EXT}\" KEEP=\"${KEEP}\" METHODS=\"${METHODS}\" VERBOSE="0" )"

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

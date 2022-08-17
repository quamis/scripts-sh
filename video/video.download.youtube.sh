#!/bin/bash

# @requires
# imagemagik/convert

# if installed via pip, update is done like this:
# 	pip install -U youtube-dl
# to check if installed via pip, do this:
# 	pip list | grep youtube-dl


# usage:
# 	video.download.youtube.sh URL='https://www.youtube.com/watch?v=T5OkKPrcvT0'


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${LIST:=""};
: ${LISTFILE:=""};
: ${URL:=""};

: ${DIR:="./"};
: ${SPEED_LIMIT_KB:="512"};
: ${SLEEP_BETWEEN_REQUESTS:="2"};

: ${TMPDIR:="/tmp/"};	# default to /tmp
: ${COMMANDFILE:=`mktemp --tmpdir="${TMPDIR}"`};
: ${VERBOSE:="0"};	# 0, 1

: ${IGNORE_ERRORS:="no"};

: ${SPLIT_PLAYLIST:="no"};

: ${REORGANISE:="no"};

: ${RUN_MODE:="sequential"};	# 'dry-run', 'parallel', 'sequential'
: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${MAX_LOAD:="95%"};


# clear the command list
echo > "$COMMANDFILE";

if [[ "$LIST" == "" && "$URL" == ""  && "$LISTFILE" == "" ]]; then
   echo "Please specify either LIST=filename or URL=http://...  or LISTFILE=list.txt";
   exit;
fi

# build a list of commands to run
mkdir -p "${DIR}";
DIR=`realpath "${DIR}"`;

SAVEIFS=$IFS
IFS=$'\n'
if [[ "$LIST" == "" && "$URL" != "" ]]; then
	LIST="$URL"
fi;
if [[ "$LIST" == "" && "$LISTFILE" != "" ]]; then
    LIST=$(cat "$LISTFILE");
fi;

for URL in `echo "$LIST" | sort`; do
	# TMP_FILE=`mktemp "${TMPDIR}pdf.XXXXXXXXXXXXXXXXXXXXXXX.m4a"`

	# DEBUGGING
	if [ "$VERBOSE" = "1" ]; then
		echo "URL: $URL"
	fi;

    # for more options, see the manual
	C1="";
	if [[ "$IGNORE_ERRORS" == "yes" ]]; then
		C1="--ignore-errors";
	fi;

	C2="";
	if [[ "$REORGANISE" == "playlist" ]]; then
		C2="--output '%(playlist)s/%(playlist_index)s- %(title)s.%(ext)s' ";
	fi;

	if [[ "$SPLIT_PLAYLIST" == "yes" ]]; then
		PREV_LIMIT=0;
		for LIMIT in 2 4 6 8 10 20 30 40 50 60 70 80 90 100 200 300 400 500 600 700 800 900 1000 1200 1400 1600 1800 2000 2200 2400 2600 2800 3000 3200 3400 3600 3800 4000 4500 5000 5500 6000 6500 7000 7500 8000 9000 "max"; do
			PREV_LIMIT=$(( PREV_LIMIT + 1));
			if [[ "$LIMIT" == "max" ]]; then
				C3="--playlist-start ${PREV_LIMIT} ";
			else
				C3="--playlist-start ${PREV_LIMIT} --playlist-end ${LIMIT} ";
			fi;

			CMD="(mkdir -p \"${DIR}\" && youtube-dl $C1 --rate-limit ${SPEED_LIMIT_KB}k -f 'bestvideo[height<=720]+bestaudio/bestvideo+bestaudio' $C2 $C3 --geo-bypass --merge-output-format mkv --encoding utf-8 \"${URL}\";)"

			if [ "$VERBOSE" = "1" ]; then
				echo "$CMD";
			fi;

			echo "$CMD" >> "$COMMANDFILE";
			CMD="";

			PREV_LIMIT=$LIMIT;
		done;
	else
		CMD="(mkdir -p \"${DIR}\" && youtube-dl $C1 --rate-limit ${SPEED_LIMIT_KB}k -f 'bestvideo[height<=720]+bestaudio/bestvideo+bestaudio' $C2 --geo-bypass --merge-output-format mkv --encoding utf-8 \"${URL}\";)"
		if [ "$VERBOSE" = "1" ]; then
			echo "$CMD";
		fi;

		# append to the command list
		echo "$CMD" >> "$COMMANDFILE";
	fi;
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

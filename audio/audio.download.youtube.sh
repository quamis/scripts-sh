#!/bin/bash

# @requires
# imagemagik/convert

# if installed via pip, update is done like this:
# 	pip install -U youtube-dl
# 	pip install -U yt-dlp
# to check if installed via pip, do this:
# 	pip list | grep youtube-dl

# @see https://github.com/coletdjnz/yt-dlp-get-pot




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

: ${TMPDIR:="/tmp/"};
: ${COMMANDFILE:=`mktemp --tmpdir="${TMPDIR}"`};
: ${VERBOSE:="0"};	# 0, 1

: ${RUN_MODE:="sequential"};	# 'dry-run', 'parallel', 'sequential'
: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${MAX_LOAD:="95%"};

: ${DOWNLOADER:="yt-dlp"};	# youtube-dl, yt-dlp
: ${USE_COOKIES:="no"};	# chrome, firefox



# clear the command list
echo > "$COMMANDFILE";

if [[ "$LIST" == "" && "$URL" == ""  && "$LISTFILE" == "" ]]; then
   echo "Please specify either LIST=filename or URL=http://... ";
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
	CMD="(mkdir -p \"${DIR}\" && $DOWNLOADER";
	if [[ "$USE_COOKIES" == "firefox" || "$USE_COOKIES" == "chrome" ]]; then
		CMD="$CMD --cookies-from-browser $USE_COOKIES";
	fi;
	CMD="$CMD -f \"bestaudio[ext=m4a]/bestaudio[ext=ogg]/bestaudio[ext=mp3]/bestaudio\" --sleep-interval=${SLEEP_BETWEEN_REQUESTS} --rate-limit=${SPEED_LIMIT_KB}k -c --extract-audio \"${URL}\" --output=\"${DIR}/%(playlist_index)s - %(title)s.%(ext)s\"";
	CMD="$CMD;)";

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

#!/bin/bash

# @requires
# imagemagik/convert

# usage:
# 	video.download.digi24.sh URL='https://www.digi24.ro/special/campanii-digi24/romania-fast-forward/a-renuntat-la-tot-pentru-o-afacere-cu-ii-ce-beneficii-ii-aduce-1160856'


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)   
	declare $KEY="$VALUE"
done

: ${LIST:=""};
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


# clear the command list
echo > "$COMMANDFILE";

if [[ "$LIST" == "" && "$URL" == "" ]]; then
   echo "Please specify either LIST=filename or URL=http://...";
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

for URL in `echo "$LIST" | sort`; do
	# TMP_FILE=`mktemp "${TMPDIR}pdf.XXXXXXXXXXXXXXXXXXXXXXX.m4a"`
	
	# DEBUGGING
	if [ "$VERBOSE" = "1" ]; then
		echo "URL: $URL"
	fi;

	#VIDEOURL=`wget -q -O- "${URL}" | egrep -o "\"http[^\"]+mp4\"" | tail -n 1 | sed -e "s/^\"//" | sed -e "s/\"$//"`
	HTML=`wget -q -O- "${URL}"`
	JSONVIDEOURL=`echo "${HTML}" | egrep -o "\"http[^\"]+mp4\"" | tail -n 1`
	FAKEJSONVIDEOURL="{\"source\":${JSONVIDEOURL}}"
	VIDEOURL=`echo ${FAKEJSONVIDEOURL} | jq -r ".source"`

	JSONTITLE=`echo "${HTML}" | egrep -o "\"headline\":[ ]*\"[^\"]+\""`
	FAKEJSONTITLE="{${JSONTITLE}}"
	TITLE=`echo ${FAKEJSONTITLE} | jq -r ".headline" | sed "s/null//"`
	
	HTMLTITLE=`echo "${HTML}" | egrep -o "<title>.+</title>" | sed -r "s/<(\/)?title>//g"`
	if [ "$TITLE" = "" ]; then
		if [ "$VERBOSE" = "1" ]; then
			echo "Using page title: ${HTMLTITLE}"
		fi;
		TITLE="${HTMLTITLE}"
	fi;

	if [ "$VERBOSE" = "1" ]; then
		echo "	media: $VIDEOURL"
		echo "	title: $TITLE"
	fi;


    # for more options, see the manual
	CMD="(mkdir -p \"${DIR}\" && wget --continue --limit-rate ${SPEED_LIMIT_KB}k -O \"${DIR}/${TITLE}.mp4\" \"${VIDEOURL}\";)"
	
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

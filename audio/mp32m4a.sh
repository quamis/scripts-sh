#!/bin/bash

# mp32m4a.sh DIR='/media/ext1Tb/nextcloud/music/files/Radio Guerilla - Zona Libera/';
#			sudo -u www-data php /var/www/html/nextcloud/occ files:scan --path='/lucian.sirbu/files/@muzica.mp3/testing/' --verbose

# OR, in order to re-encode everything as m4a:
#		 mp32m4a.sh EXT="mp3,mp4,m4a,mp2" DIR="./"

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   
	declare $KEY="$VALUE"
done

: ${DIR:="./"};
: ${EXT:="mp3,mp2"};
: ${QUALITY:="4"};
: ${MAX_LOAD:="95%"};
: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${RECURSE:="0"};
: ${RUN_MODE:="parallel"};	# 'dry-run', 'parallel', 'sequential'
: ${TMPDIR:="/tmp/"};
: ${COMMANDFILE:=`mktemp --tmpdir="${TMPDIR}"`};



# @see https://stackoverflow.com/questions/16374028/unable-to-convert-mp3-to-m4a-using-ffmpeg
# @see https://trac.ffmpeg.org/wiki/Encode/AAC

# clear the command list
echo > "$COMMANDFILE";

# build a list of commands to run
regexpEXT=`echo "$EXT" | sed s/\,/\|/g`;
QUALITY_MAP_TO_KBS=( ['0']='192k' ['1']='164k' ['2']='128k' ['3']='96k' ['4']='64k' ['5']='56k' ['6']='48k' ['7']='32k' )

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
	FILE_DIR="${FILE_DIR_AND_NAME_AND_EXT%/*}"
	
	TMP_FILE=`mktemp --tmpdir="${TMPDIR}"`
	
	# DEBUGGING
	#echo "FILE::$FILE_DIR_AND_NAME_AND_EXT"
	#echo "    FILE_DIR:            $FILE_DIR"
	#echo "    FILE_NAME_WITH_EXT:  $FILE_NAME_WITH_EXT"
	#echo "    FILE_NAME:           $FILE_NAME"
	#echo "    FILE_EXT:            $FILE_EXT"

	# ffmpeg
	#  -c:a aac : lower quality, but free
	#  -c:a libfaac : lower quality, but free, old
	#  -c:a libfdk_aac : higher quality, but non-free
	#		also use -cutoff 18000
	
	# -vbr ${QUALITY_MAP_TO_KBS[$QUALITY]} : vbr, but aac code doesn;t cope well with this
	# -b:a ${QUALITY_MAP_TO_KBS[$QUALITY]} : cbr, seems to work as expected
	
	CMD="(ffmpeg -loglevel panic -y -i \"${FILE_DIR_AND_NAME_AND_EXT}\" -c:a libfdk_aac -cutoff 18000 -vn -b:a ${QUALITY_MAP_TO_KBS[$QUALITY]} \"${TMP_FILE}.m4a\" && mv \"${TMP_FILE}.m4a\" \"${FILE_DIR}${FILE_NAME}.m4a\")"
	
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
elif [ "$RUN_MODE" = "dry-run" ]; then
	cat "$COMMANDFILE";
else
	# TODO: sequential conversion
	echo "Unknown run mode";
fi;

rm $COMMANDFILE;

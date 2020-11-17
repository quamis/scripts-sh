#!/bin/bash

# @requires
# jq
# ffmpeg, recompiled, see below for instructions

# mp32m4a.sh DIR='/media/ext1Tb/nextcloud/music/files/Radio Guerilla - Zona Libera/';
#			sudo -u www-data php /var/www/html/nextcloud/occ files:scan --path='/lucian.sirbu/files/@muzica.mp3/testing/' --verbose
#
# OR, in order to re-encode everything as m4a:
#		 mp32m4a.sh EXT="mp3,mp4,m4a,mp2" DIR="./"
#
# OR, in order to re-encode old mp3 tracks as m4a:
#		mp32m4a.sh EXT="mp3" QUALITY="4" RUN_MODE="dry-run" DIR="./" QUALITY_AUTO=1 > /tmp/run.cmd
#       mp32m4a.sh EXT="mp3" QUALITY="4" RUN_MODE="dry-run" DIR="./" QUALITY_AUTO=1 >> /tmp/run.cmd
#		parallel --no-notice --bar --jobs 4 < /tmp/run.cmd
#
# OR, in order to re-encode flac files:
#		audio.mp32m4a.sh EXT=flac QUALITY=2 RUN_MODE="dry-run" DIR="./" RECURSE=1 > /tmp/run.cmd
#		parallel --no-notice --bar --jobs 4 < /tmp/run.cmd

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${DIR:="./"};
: ${EXT:="mp3,mp2"};
: ${QUALITY:="4"};
: ${QUALITY_AUTO:="0"}	# 0,1
: ${RECURSE:="0"};
: ${TMPDIR:="/tmp/"};
: ${COMMANDFILE:=`mktemp --tmpdir="${TMPDIR}"`};
: ${VERBOSE:="0"};	# 0, 1

: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${RUN_MODE:="parallel"};	# 'dry-run', 'parallel', 'sequential'
: ${MAX_LOAD:="95%"};



# @see https://stackoverflow.com/questions/16374028/unable-to-convert-mp3-to-m4a-using-ffmpeg
# @see https://trac.ffmpeg.org/wiki/CompilationGuide
#	@see https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
# @see https://trac.ffmpeg.org/wiki/Encode/AAC

# on Ubuntu you may do:
#	@see https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
#
#	sudo apt-get update -qq && sudo apt-get -y install autoconf automake build-essential cmake git-core libass-dev libfreetype6-dev libtool libvorbis-dev pkg-config texinfo wget zlib1g-dev nasm yasm libx264-dev libx265-dev libnuma-dev libvpx-dev libfdk-aac-dev libmp3lame-dev libopus-dev
#
#    mkdir ffmpeg_sources && \
#    cd ~/ffmpeg_sources && \
#    wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
#    tar xjvf ffmpeg-snapshot.tar.bz2 && \
#    cd ffmpeg && \
#    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
#      --prefix="$HOME/ffmpeg_build" \
#      --pkg-config-flags="--static" \
#      --extra-cflags="-I$HOME/ffmpeg_build/include" \
#      --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
#      --extra-libs="-lpthread -lm" \
#      --bindir="$HOME/bin" \
#      --enable-gpl \
#      --enable-libass \
#      --enable-libfdk-aac \
#      --enable-libfreetype \
#      --enable-libmp3lame \
#      --enable-libopus \
#      --enable-libvorbis \
#      --enable-libvpx \
#      --enable-libx264 \
#      --enable-libx265 \
#      --enable-nonfree && \
#    PATH="$HOME/bin:$PATH" make && \
#    make install && \
#    hash -r

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
	FILE_DIR="${FILE_DIR_AND_NAME_AND_EXT%/*}/"

	TMP_FILE=`mktemp "${TMPDIR}audio.XXXXXXXXXXXXXXXXXXXXXXX.m4a"`

	# DEBUGGING
	if [ "$VERBOSE" = "1" ]; then
		echo "FILE::$FILE_DIR_AND_NAME_AND_EXT"
		echo "    FILE_DIR:            $FILE_DIR"
		echo "    FILE_NAME_WITH_EXT:  $FILE_NAME_WITH_EXT"
		echo "    FILE_NAME:           $FILE_NAME"
		echo "    FILE_EXT:            $FILE_EXT"
	fi;

	# ffmpeg
	#  -c:a aac : lower quality, but free
	#  -c:a libfaac : lower quality, but free, old
	#  -c:a libfdk_aac : higher quality, but non-free
	#		also use -cutoff 18000

	# -vbr ${QUALITY_MAP_TO_KBS[$QUALITY]} : vbr, but aac code doesn;t cope well with this
	# -b:a ${QUALITY_MAP_TO_KBS[$QUALITY]} : cbr, seems to work as expected

	if [ "$QUALITY_AUTO" = "1" ]; then
		if [ "$FILE_EXT" = "mp3" ]; then	# this applies for mp3-conversion only
			#kbps=`file "${FILE_DIR_AND_NAME_AND_EXT}" | egrep -o "[0-9]+ kbps" | sed "s/kbps//"`
			kbps=`ffprobe -v quiet -print_format json -show_format "${FILE_DIR_AND_NAME_AND_EXT}" | jq ".format.bit_rate" | sed 's/"//g' | sed 's/null/0/'`
			kbps=$(( kbps/1000 ))

			QUALITY_NEW="${QUALITY}";
			if (( kbps > 300 )); then
				QUALITY_NEW="0";
			elif (( kbps > 150 )); then
				QUALITY_NEW="2";
			elif (( kbps > 100 )); then
				QUALITY_NEW="3";
			fi;

			QUALITY="$QUALITY_NEW"
		fi;
	fi


	CMD="(ffmpeg -loglevel panic -y -i \"${FILE_DIR_AND_NAME_AND_EXT}\" -c:a libfdk_aac -cutoff 18000 -vn -b:a ${QUALITY_MAP_TO_KBS[$QUALITY]} \"${TMP_FILE}\" && mv \"${TMP_FILE}\" \"${FILE_DIR}${FILE_NAME}.m4a\")"

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

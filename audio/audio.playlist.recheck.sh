#!/bin/bash

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${FILE:=""};
: ${OUTPUT:=""};
: ${TMP:="/tmp/audio.recheck.playlist.tmp"};

: ${VERBOSE:="0"};	# 0, 1

if [[ "$FILE" == "" ]]; then
   echo "Please specify either FILE=filename.m3u";
   exit;
fi


if [[ "$OUTPUT" == ""  ]]; then
	OUTPUT="$FILE.new";
fi;

SAVEIFS=$IFS
IFS=$'\n'
cp "$FILE" "$TMP";
dos2unix "$TMP";
echo "" > "$OUTPUT";
for F in `cat "$TMP"`; do
	# DEBUGGING
	if [ "$VERBOSE" = "1" ]; then
		echo "F: $F"
	fi;
	echo "test $F"

	# will only fill in $? if the command fails
	# ffprobe -v debug -fflags nobuffer "$F";
	ffprobe -hide_banner -v quiet -fflags nobuffer "$F";
	# ffprobe -v quiet -print_format json -show_format -show_streams  -fflags nobuffer;	# @see https://gist.github.com/nrk/2286511

	if [ $? -eq 0 ]; then
		echo "$F" >> "$OUTPUT";
        echo "  ..valid, written back to the file"
    else
        echo "  ..invalid, skip file writing"
    fi
done;
IFS=$SAVEIFS



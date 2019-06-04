#!/bin/bash

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   
	declare $KEY="$VALUE"
done

: ${QUALITY:="2"};
: ${MAX_LOAD:="95%"};
: ${THREADS:="4"};

FILELIST=""
while read URL; do
	if [ ! -z "${URL}" ]; then
		if [ ! -z "${FILELIST}" ]; then
			FILELIST+=$'\n';
		fi;
		FILELIST+="${URL}";
	fi;
done;

# echo "$FILELIST"  | parallel --no-notice --jobs $THREADS --load $MAX_LOAD -- "echo '--' {};";

echo "$FILELIST" | parallel --no-notice --bar --jobs $THREADS --load $MAX_LOAD -- "youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4 --write-description --encoding utf-8 {}";

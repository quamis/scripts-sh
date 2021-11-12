#!/bin/bash

# usage:
# 	video.is.AV1.sh FILE='xyz.mkv'

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${FILE:=""};

MATCHED=`ffprobe "$FILE" 2>&1 | egrep 'Stream.+Video: av1 '`;

if [ -z "$MATCHED" ]; then
    exit 0;
fi;

exit 1;

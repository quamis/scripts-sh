#!/bin/bash

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)
	declare $KEY="$VALUE"
done

: ${DB:="/tmp/ebooks.csv"};
: ${VERBOSE:="0"};	# 0, 1
: ${TMPDIR:="/tmp/"};

#!/bin/bash

# @requires
# apt install pdfimages
# @see https://askubuntu.com/questions/117143/is-there-a-command-line-tool-to-bulk-extract-images-from-a-pdf


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done


: ${FILE:=""};
# : ${OFILE:="$FILE-compressed,__SIZE__,v__INDEX__.pdf"};
: ${ODIR:="$FILE-resources"};
: ${TMPDIR:="/tmp/"};
: ${VERBOSE:="1"};	# 0, 1

: ${METHODS:="default"};


if [[ "$FILE" == "" ]]; then
   	echo "Please specify FILE=filename";
fi

# for qpdf usage, @see https://github.com/qpdf/qpdf/issues/306
mkdir -p "$ODIR";
pdfimages -all -p "$FILE" "$ODIR/";

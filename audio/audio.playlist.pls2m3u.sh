#!/bin/bash

# convert all .pls files with this:
#   for F in *.pls; do audio.playlist.pls2m3u.sh FILE="$F"; done;
#   rm *.old

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${FILE:=""};
: ${OUTPUT:=""};

: ${FILE:=""};

if [[ "$FILE" == "" ]]; then
   echo "Please specify either FILE=filename.m3u";
   exit;
fi

EXT=${FILE##*.};
: ${OUTPUT:="${FILE%.*}.m3u"};

cat "$FILE" | egrep "^File[0-9]+=" | sed -r "s/^File[0-9]+=//" > "$OUTPUT";
mv "$FILE" "$FILE.old";

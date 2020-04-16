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


TMPFILE=`mktemp --tmpdir="${TMPDIR}"`;
cat "$DB"  | sort | uniq > "$TMPFILE";
mv "$TMPFILE" "$DB";

# "author" "extract_author_title_v2" "$HASH" "$AUTHOR"
declare -A sum;
while IFS=, read S M HASH V; do
    ((sum["\"$V\""]+=1));
done < "$DB"

# echo "${!sum[@]}";

# for i in ${!sum[@]}; do
#      echo $i,${sum[$i]}
# done

TMPFILE=`mktemp --tmpdir="${TMPDIR}"`;
for i in "${!sum[@]}"; do
    echo "${sum[$i]},$i" >> "$TMPFILE";
done

cat "$TMPFILE" | sort -rn;

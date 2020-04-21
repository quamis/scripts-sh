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
declare -A GROUPS;
while IFS=, read S M HASH V; do
    ((GROUPS["\"$V\""]+=1));
done < "$DB"

# echo "${!GROUPS[@]}";

# for i in ${!GROUPS[@]}; do
#      echo $i,${GROUPS[$i]}
# done

TMPFILE=`mktemp --tmpdir="${TMPDIR}"`;
for i in "${!GROUPS[@]}"; do
    echo "${GROUPS[$i]},$i" >> "$TMPFILE";
done


# number of authors
AUTHORS_COUNT=`cat /tmp/ebooks.csv | grep -e "^author," | wc -l`;
AUTHORS_MEDIAN=`cat "$TMPFILE" | sort -rn | sed -n "$(( $AUTHORS_COUNT/2 ))p" | cut -d, -f1`;
AUTHORS_MEDIAN=$(( $AUTHORS_MEDIAN + 1 ));

echo > "$TMPFILE";
for i in "${!GROUPS[@]}"; do
    if (( ${GROUPS[$i]} > $AUTHORS_MEDIAN )); then
        echo "${GROUPS[$i]},$i" >> "$TMPFILE";
    fi;
done;
cat "$TMPFILE";


# as putea cauta pe wikipedia asa:
# curl -H "accept:application/json" -X GET 'https://en.wikipedia.org/w/api.php?action=opensearch&limit=500&search=Frattini&nbsp;Eric' | jq '.[3]' 
# chestia e ca trebuie sa incerc toate combinatiile de nume Ion Vasile, apoi Vasile Ion
# @see https://www.mediawiki.org/wiki/API:Opensearch


#!/bin/bash

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)
	declare $KEY="$VALUE"
done

: ${METHODS:="extract_author_title_v1,extract_author_title_v2"};
: ${DIR:="./"};
: ${DB:="/tmp/ebooks.csv"};
: ${RECURSE:="0"};
: ${VERBOSE:="0"};	# 0, 1


maxdepth="99999"
if [ "$RECURSE" = "0" ]; then
	maxdepth="1"
fi;




# sample:
#  echo "Lesage - Diavolul Schiop.epub" | awk '{match($0,/^([^-]+)-(.+).epub/,a);print sprintf("%s,%s", a[1],a[2])}'

extract_author_title_v1 () {
    local DB="$1"
    local HASH="$2"
    local FILE_NAME="$3"

    # FILE_NAME="Arthur C. Clarke - Odiseea - Vol 1 - 2001 O Odisee Spatiala"

    # fmt: Arthur C. Clarke - Odiseea - Vol 1 - 2001 O Odisee Spatiala
	# local AUTHOR=`echo "$FILE_NAME" | cut -d- -f1 | sed -e "s/[ ]*$//" -e "s/^[ ]*//"`;
    # local TITLE=`echo "$FILE_NAME" | cut -d- -f2- | sed -e "s/[ ]*$//" -e "s/^[ ]*//"`;
    local AUTHOR=${FILE_NAME%%-*};
    AUTHOR="${AUTHOR##*( )}";   # Trim leading whitespaces
    AUTHOR="${AUTHOR%%*( )}";    # Trim trailing whitespaces

    local TITLE=${FILE_NAME#*-};
    TITLE="${TITLE##*( )}";   # Trim leading whitespaces
    TITLE="${TITLE%%*( )}";    # Trim trailing whitespaces

    # echo "$AUTHOR"; echo "$TITLE"; exit;
    printf "\n%s,%s,%s,%s" "author" "extract_author_title_v2" "$HASH" "$AUTHOR" >> "$DB"
    printf "\n%s,%s,%s,%s" "title" "extract_author_title_v2" "$HASH" "$TITLE" >> "$DB"
}

extract_author_title_v2 () {
	local DB="$1"
    local HASH="$2"
    local FILE_NAME="$3"

    # FILE_NAME="Odiseea - Vol 1 - 2001 O Odisee Spatiala - Arthur C. Clarke"

    # fmt: Odiseea - Vol 1 - 2001 O Odisee Spatiala - Arthur C. Clarke
    local AUTHOR=${FILE_NAME%-*};
    AUTHOR="${AUTHOR##*( )}";   # Trim leading whitespaces
    AUTHOR="${AUTHOR%%*( )}";    # Trim trailing whitespaces

    local TITLE=${FILE_NAME##*-};
    TITLE="${TITLE##*( )}";   # Trim leading whitespaces
    TITLE="${TITLE%%*( )}";    # Trim trailing whitespaces

    # echo "$AUTHOR"; echo "$TITLE"; exit;
    printf "\n%s,%s,%s,%s" "author" "extract_author_title_v2" "$HASH" "$AUTHOR" >> "$DB"
    printf "\n%s,%s,%s,%s" "title" "extract_author_title_v2" "$HASH" "$TITLE" >> "$DB"
}


DIR=`realpath "${DIR}"`;
SAVEIFS=$IFS
IFS=$'\n'
for FILE in `find "${DIR}/" -maxdepth ${maxdepth} -type f`; do
	FILE_NAME=$(basename -- "${FILE}")
	FILE_DIR_AND_NAME_AND_EXT="${FILE}"
	FILE_EXT="${FILE_NAME##*.}"
	FILE_NAME="${FILE_NAME%.*}"
	FILE_NAME_WITH_EXT="${FILE_DIR_AND_NAME_AND_EXT##*/}"
	FILE_DIR="${FILE_DIR_AND_NAME_AND_EXT%/*}/"
    FILE_HASH=`echo "$FILE_NAME" | md5sum | sed -e "s/[ ]*-[ ]*//"`;

	# TMP_FILE=`mktemp "${TMPDIR}pdf.XXXXXXXXXXXXXXXXXXXXXXX.m4a"`

	# DEBUGGING
	if [ "$VERBOSE" = "1" ]; then
		echo "FILE::$FILE_DIR_AND_NAME_AND_EXT"
		echo "    FILE_DIR:            $FILE_DIR"
		echo "    FILE_NAME_WITH_EXT:  $FILE_NAME_WITH_EXT"
		echo "    FILE_NAME:           $FILE_NAME"
		echo "    FILE_EXT:            $FILE_EXT"
	fi;

    shopt -s extglob
    SAVEIFS1=$IFS; IFS=$' '; METHODS_ARR=(${METHODS//,/ }); IFS="$SAVEIFS1";
    for M in "${METHODS_ARR[@]}"; do
        # if [ "$VERBOSE" = "1" ]; then
        #     printf "\n%-*s: " 25 "$M"
        # fi;

        $M "$DB" "$FILE_HASH" "$FILE_NAME";
    done;
    shopt -u extglob
done;
IFS=$SAVEIFS

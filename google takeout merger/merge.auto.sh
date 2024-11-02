#!/bin/bash

# use as:
#      tar -xzvf ./1.tgz && tar -xzvf ./2.tgz
#     ./merge.auto.sh D1='/media/lucian/BIG2T1/tmp/google-takeout-quamis/Takeout/Google Photos' D2='/media/lucian/BIG2T1/picturesFromPhone/google-takeout-quamis' PROFILE="quamis" RUN_MODE=safe

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${D1:=""};
: ${D2:=""};
: ${PROFILE:=""};

: ${TMPDIR:="/tmp/"};
: ${TRASH:="./trash/"};
: ${RUN_MODE:="dry-run"};
: ${LOG:="./log-${RUN_MODE}-${PROFILE}.log"};
: ${LOGOLD:="./log-${RUN_MODE}-${PROFILE}.old.log"};

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

if [ -z "$D1" ]; then
    echo "Please specify D1, the new takeout source";
    exit;
fi;

if [ -z "$D2" ]; then
    echo "Please specify D2, the final, merged takeout destination";
    exit;
fi;

if [ -z "$PROFILE" ]; then
    echo "Please specify PROFILE, the profile name";
    exit;
fi;


TMP1=`mktemp --tmpdir="${TMPDIR}"`;
TMP2=`mktemp --tmpdir="${TMPDIR}"`;
TMP3=`mktemp --tmpdir="${TMPDIR}"`;
TMP4=`mktemp --tmpdir="${TMPDIR}"`;
TMP11=`mktemp --tmpdir="${TMPDIR}"`;
TMP21=`mktemp --tmpdir="${TMPDIR}"`;

rebuildImageList () {
    find "$D1" ! -name "*.json" -type f -printf '%P\t%s\n'| sort > "$TMP1";
    find "$D2" ! -name "*.json" -type f -printf '%P\t%s\n'| sort > "$TMP2";

    cat "$TMP1" | cut -d$'\t' -f1 | sort > "$TMP11";
    cat "$TMP2" | cut -d$'\t' -f1 | sort > "$TMP21";
}

extractLastLog () {
    cat "$LOGOLD" | sed -e "s/\x1b\[.\{1,5\}m//g" | egrep -i "move: '.+'" | sed -r "s/[ \t]*move:[ \t]*'(.*)'/\1/g" > "$TMP4";
}

custom_rm () {
    D1FILE="$1";
    REASON="$2";
    printf "\n%6s: '$D1FILE'" "delete";
    if [ ! "$REASON" = "" ]; then
        printf ", %s" "$REASON";
    fi;

    if [ "$RUN_MODE" = "dry-run" ]; then
        # do nothing
        :
    elif [ "$RUN_MODE" = "safe" ]; then
        mv "$D1FILE" "$TRASH";

    elif [ "$RUN_MODE" = "unsafe" ]; then
        rm -f "$D1FILE";
    else
        printf "\n invalid RUN_MODE";
        exit;
    fi;
}

custom_mkdir () {
    D="$1";
    REASON="$2";
    printf "\n%6s: '$D'" "mkdir";
    if [ ! "$REASON" = "" ]; then
        printf ", %s" "$REASON";
    fi;

    if [ "$RUN_MODE" = "dry-run" ]; then
        # do nothing
        :

    elif [ "$RUN_MODE" = "safe" ]; then
        mkdir -p "$D";

    elif [ "$RUN_MODE" = "unsafe" ]; then
        mkdir -p "$D";
    else
        printf "\n invalid RUN_MODE";
        exit;
    fi;
}

custom_mv () {
    D1FILE="$1";
    D2FILE="$2";
    REASON="$3";
    printf "\n%6s: '$D1FILE'" "move";
    printf "\n%6s: '$D2FILE'" "to";
    if [ ! "$REASON" = "" ]; then
        printf ", %s" "$REASON";
    fi;

    if [ "$RUN_MODE" = "dry-run" ]; then
        # do nothing
        :

    elif [ "$RUN_MODE" = "safe" ]; then
        mv "$D1FILE" "$D2FILE";

    elif [ "$RUN_MODE" = "unsafe" ]; then
        mv "$D1FILE" "$D2FILE";
    else
        printf "\n invalid RUN_MODE";
        exit;
    fi;
}

# rotate logs
if [ -f "$LOG" ]; then
    mv "$LOGOLD" "$LOGOLD-`date "+%Y-%m-%d %H:%M:%S"`.log";
    mv "$LOG" "$LOGOLD";
fi


{
    printf "\n\n\n";
    printf "\n${YELLOW}======================================================${NC}\n";
    printf "\nstarted at: %s" "`date "+%Y-%m-%d %H:%M:%S"`";

    if [ "$RUN_MODE" = "dry-run" ]; then
        printf "\nRUN_MODE:   ${YELLOW}%s${NC}" "$RUN_MODE";

    elif [ "$RUN_MODE" = "safe" ]; then
        printf "\nRUN_MODE:   ${GREEN}%s${NC}" "$RUN_MODE";
        printf "\n ... wait 5 seconds, in case you change your mind";
        sleep 5;

    elif [ "$RUN_MODE" = "unsafe" ]; then
        printf "\nRUN_MODE:   ${RED}%s${NC}" "$RUN_MODE";
        printf "\n ... wait 15 seconds, in case you change your mind";
        sleep 15;
    fi;

    # build the list of image and movies, ignoring json files
    rebuildImageList;

    # build a log of the last copied files
    extractLastLog;

    D1_FILES_COUNT=`cat "$TMP11" | wc -l`;
    D2_FILES_COUNT=`cat "$TMP21" | wc -l`;
    COMMON_FILES_COUNT=`comm --output-delimiter=""  -12 "$TMP11" "$TMP21" | wc -l`;
    IDENTICAL_FILES_COUNT=`comm --output-delimiter=""  -12 "$TMP1" "$TMP2" | wc -l`;

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;36m'
    NC='\033[0m' # No Color

    printf "\nD1 has:    %9d files" ${D1_FILES_COUNT};
    printf "\nD2 has:    %9d files" ${D2_FILES_COUNT};
    printf "\nCommon:    %9d files" ${COMMON_FILES_COUNT};
    printf "\nIdentical: %9d files" ${IDENTICAL_FILES_COUNT};

    # new files, only in D2. These are actually OLD files, and were deleted in D1
    #comm --output-delimiter=""  -13 "$TMP11" "$TMP21"

    # new files, only in D1. These should get copied over to D2
    #comm --output-delimiter=""  -23 "$TMP11" "$TMP21"
    printf "\n${YELLOW}======================================================${NC}\n";


    custom_mkdir "$TRASH";

    if [ ! -f "$D2/original_takeout.lock" ]; then
        printf "\n${RED}D2 should be the final merge target${NC}";
        printf "\nIf you are sure that's the final target, put the 'original_takeout.lock' in the root folder\n";
        exit;
    fi;

    # 1.1. delete identical files in D1
    printf "\n${GREEN}======================================================${NC}\n";
    printf "\n${GREEN}delete identical files from D1, also in D2${NC}";
    comm --output-delimiter=""  -12 "$TMP1" "$TMP2" | cut -d$'\t' -f1 | sort > "$TMP11";
    COUNT=$(( 0 ));
    IFS=$'\n';
    for F in `cat "$TMP11"`; do
        COUNT=$(( $COUNT + 1 ));
        D1FILE="$D1/$F";

        custom_rm "$D1FILE";
    done;
    unset IFS;
    printf "\n${YELLOW}%9d %s${NC}" $COUNT "files deleted";
    printf "\n";

    # 1.2. delete older files that were already moved
    printf "\n${GREEN}======================================================${NC}\n";
    printf "\n${GREEN}delete already moved files from D1, as reported in the last log${NC}";
    COUNT=$(( 0 ));
    IFS=$'\n';
    for F in `cat "$TMP4"`; do
        COUNT=$(( $COUNT + 1 ));
        D1FILE="$F";

        custom_rm "$D1FILE";
    done;
    unset IFS;
    printf "\n${YELLOW}%9d %s${NC}" $COUNT "files deleted";
    printf "\n";


    # 2. move new files from D1 to D2
    printf "\n${GREEN}======================================================${NC}\n";
    printf "\n${GREEN}move new files from D1 to D2${NC}";
    rebuildImageList;
    comm --output-delimiter=""  -23 "$TMP11" "$TMP21" > "$TMP3";
    COUNT=$(( 0 ));
    IFS=$'\n';
    for F in `cat "$TMP3"`; do
        COUNT=$(( $COUNT + 1 ));
        D1FILE="$D1/$F";
        D2FILE="$D2/$F";

        D2DIR=`dirname "$D2FILE"`;
        if [ ! -d "$D2DIR" ]; then
            custom_mkdir "$D2DIR"
        fi;

        custom_mv "$D1FILE" "$D2FILE";
    done;
    unset IFS;
    printf "\n${YELLOW}%9d %s${NC}" $COUNT "files moved";
    printf "\n";


    # 3. lookup changed files, move files if larger, delete if smaller
    printf "\n${GREEN}======================================================${NC}\n";
    printf "\n${GREEN}lookup changed files, move files to D2 if larger, delete from D1 if smaller${NC}";
    rebuildImageList;
    comm --output-delimiter=""  -12 "$TMP11" "$TMP21" > "$TMP3";
    COUNT1=$(( 0 ));
    COUNT2=$(( 0 ));

    IFS=$'\n';
    for F in `cat "$TMP3"`; do
        D1FILE="$D1/$F";
        D2FILE="$D2/$F";

        D2DIR=`dirname "$D2FILE"`;
        if [ ! -d "$D2DIR" ]; then
            custom_mkdir "$D2DIR";
        fi;

        F1SIZE=$( stat --format="%s" "$D1FILE" );
        F2SIZE=$( stat --format="%s" "$D2FILE" );

        if [ "$F1SIZE" -gt "$F2SIZE" ]; then
            COUNT1=$(( $COUNT + 1 ));
            custom_mv "$D1FILE" "$D2FILE";
        else
            COUNT2=$(( $COUNT + 1 ));
            if [ "$F1SIZE" -eq "$F2SIZE" ]; then
                custom_rm "$D1FILE" "equal filesizes";
            else
                custom_rm "$D1FILE" "`printf "%s vs %s"` $F1SIZE $F2SIZE";
            fi;
        fi;
    done;
    unset IFS;
    printf "\n${YELLOW}%9d %s, %d %s${NC}" $COUNT1 "files moved" $COUNT2 "files deleted";
    printf "\n";


    # next, we're left with json files, these should simply get copied over, As we can assume they're newer
    # build the list of files
    printf "\n${GREEN}======================================================${NC}\n";
    printf "\n${GREEN}we're left with json files, these should simply get copied over, as we can assume they're newer${NC}";
    find "$D1" -name "*.json" -type f -printf '%P\t%s\n'| sort > "$TMP1";
    cat "$TMP1" | cut -d$'\t' -f1 | sort > "$TMP3";
    COUNT=$(( 0 ));
    IFS=$'\n';
    for F in `cat "$TMP3"`; do
        COUNT=$(( $COUNT + 1 ));
        D1FILE="$D1/$F";
        D2FILE="$D2/$F";

        D2DIR=`dirname "$D2FILE"`;
        if [ ! -d "$D2DIR" ]; then
            custom_mkdir "$D2DIR";
        fi;

        custom_mv "$D1FILE" "$D2FILE";
    done;
    unset IFS;
    printf "\n${YELLOW}%9d %s,${NC}" $COUNT1 "files moved";
    printf "\nfinished at: %s" "`date "+%Y-%m-%d %H:%M:%S"`";

    rm -f "$TMP1";
    rm -f "$TMP2";
    rm -f "$TMP3";
    rm -f "$TMP4";
    rm -f "$TMP11";
    rm -f "$TMP21";

    printf "\n\n";
    printf "\n${YELLOW}script finished. Please inspect the trash folder, and any other leftover files";

    printf "\n\n\n\n";
}  2>&1 | tee -a "$LOG";

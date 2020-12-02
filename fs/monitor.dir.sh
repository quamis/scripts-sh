#!/bin/bash

# @requires
# inotifywait
#   apt install inotify-tools

# usage:
# 	monitor.dir.sh DIR='/home/user/dev/' CMD='echo "__FILE__"'


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${DIR:="./"};
: ${CMD:="echo \"__FILE__\""};
: ${WAIT:="5"};
: ${TMPDIR:="/tmp/"};
: ${SCRIPTFILE:=`mktemp --tmpdir="${TMPDIR}"`};
: ${PIDFILE:=`mktemp --tmpdir="${TMPDIR}"`};

QUIT=0;

trap mask_exit SIGINT
mask_exit() {
    echo "... quitting";
    QUIT=1
}

inotifywait -m -r -e move -e create -e modify -e delete --format "%e;%f" "$DIR" | while read NOTIFICATION; do
    OPERATION=`echo $NOTIFICATION | cut -d";" -f 1`;
    FILE=`echo $NOTIFICATION | cut -d";" -f 2-`;

    C=`echo "$CMD" | sed "s/__FILE__/${FILE}/g" | sed "s/__OPERATION__/${OPERATION}/g"`

    if [[ -z "$WAIT" ]]; then
        eval $C;
    else
        if [ -s "$PIDFILE" ]; then
            kill `cat "$PIDFILE"`;
        fi;

        echo "schedule in $WAIT seconds";
        echo "$C" > "$SCRIPTFILE";
        (sleep "$WAIT" && echo "...running" && bash "$SCRIPTFILE" && rm "$SCRIPTFILE" && rm "$PIDFILE" && echo "...done, waiting more changes")&
        echo $! > "$PIDFILE";
    fi;

    if [[ "$QUIT" -eq 1 ]]; then
        break;
    fi;
done;

echo "all done, quitting";
if [ -s "$PIDFILE" ]; then
    echo "cleaning up";
    kill `cat "$PIDFILE"`;
    rm "$SCRIPTFILE";
    rm "$PIDFILE";
fi;

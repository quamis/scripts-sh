#!/bin/bash

# usage:
# 	./waitUntil.sh CMD="./loadAvg.sh" UNTILABOVE=100 SLEEP=5 DEBUG=yes; echo "busy";
#   ./waitUntil.sh CMD="./loadAvg.sh" UNTILBELOW=50 SLEEP=5 DEBUG=yes; echo "idle";



# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${CMD:="no"};
: ${UNTILBELOW:=""};
: ${UNTILABOVE:=""};
: ${UNTILWHILE:=""};
: ${UNTILUNTIL:=""};
: ${SLEEP:="4"};
: ${DEBUG:="no"};


SHOULDQUIT=0
while (( $SHOULDQUIT==0 )); do
    RES=`eval "$CMD"`;

    if [[ "$UNTILUNTIL" != "" ]]; then
        if (( $UNTILUNTIL == $RES )); then
            SHOULDQUIT=1
        fi;
    fi;

    if [[ "$UNTILWHILE" != "" ]]; then
        if (( $UNTILWHILE != $RES )); then
            SHOULDQUIT=1
        fi;
    fi;

    if [[ "$UNTILABOVE" != "" ]]; then
        if (( $UNTILABOVE < $RES )); then
            SHOULDQUIT=1
        fi;
    fi;

    if [[ "$UNTILBELOW" != "" ]]; then
        if (( $UNTILBELOW > $RES )); then
            SHOULDQUIT=1
        fi;
    fi;

    if [[ "$DEBUG" == "yes" ]]; then
        echo -n "$RES, ";
    fi;

    if (( $SHOULDQUIT==0 )); then
        sleep $SLEEP;
    fi;
done;

echo "";

#!/bin/bash

LOAD=`cat /proc/loadavg | egrep -o "^[0-9\.]+" | sed "s/\\.//" | sed -r "s/^[0]+//"`;

if [[ "$LOAD" == "" ]]; then
    LOAD="0";
fi

echo $LOAD;

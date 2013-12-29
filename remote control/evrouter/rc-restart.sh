#!/bin/bash

# use evrouter to handle IO from the remote control
# @see http://www.bedroomlan.org/projects/evrouter


killall evrouter

PIDFILE="/tmp/.evrouter:0";

# most of the time, this file wont exist... for some reason it seems like evrouter exists cleanly from time to time:)
if [ -f  "$PIDFILE" ]; then 
    sudo rm "$PIDFILE"
    echo "removed PIDFILE at $PIDFILE";
else
    echo "evrouter wasn't running, $PIDFILE, no pidfile to remove";
fi;

evrouter --config="/home/lucian/git/scripts-sh/remote control/evrouter/extern/Boxee/evrouter-remote-TopSpeed.txt" /dev/input/event6

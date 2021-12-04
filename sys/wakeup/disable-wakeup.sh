#!/bin/bash

# do not allow wakeup by simply moving the mouse/click on the keyboard

for f in /sys/bus/usb/devices/*;  do
    if [ -f "$f/power/wakeup" ]; then
        echo "$f";
        echo "`cat "$f/manufacturer"`, `cat "$f/product"`";
        cat "$f/power/wakeup";
        echo ">> run ";
        echo ">>     echo 'disabled' > '$f/power/wakeup' ";
        echo "";
    fi;
done;


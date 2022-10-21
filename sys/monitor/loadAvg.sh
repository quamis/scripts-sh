#!/bin/bash

cat /proc/loadavg | egrep -o "^[0-9\.]+" | sed "s/\\.//" | sed -r "s/^[0]+//";


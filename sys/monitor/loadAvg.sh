#!/bin/bash

cat /proc/loadavg | egrep -o "^[0-9\.]+" | sed "s/\\.//";


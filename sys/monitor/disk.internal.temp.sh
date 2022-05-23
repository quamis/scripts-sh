#!/bin/bash

DEV="$1";
# hddtemp /dev/$DEV | sed -r "s/\\/dev\\/.+:.+: //" | sed "s/°C//";
/usr/sbin/hddtemp /dev/$DEV --numeric;

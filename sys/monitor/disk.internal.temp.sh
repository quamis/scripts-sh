#!/bin/bash

DEV="$1";
# hddtemp /dev/$DEV | sed -r "s/\\/dev\\/.+:.+: //" | sed "s/°C//";
hddtemp /dev/$DEV --numeric;

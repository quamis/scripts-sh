#!/bin/bash

DEV="sda";
# hddtemp /dev/$DEV | sed -r "s/\\/dev\\/.+:.+: //" | sed "s/°C//";
hddtemp /dev/$DEV --numeric

# smartctl -x /dev/sdb | grep "Current Temperature" | sed -r "s/Current Temperature: +//"| sed -r "s/ Celsius//"
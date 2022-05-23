#!/bin/bash

DEV="sda";
# hddtemp /dev/$DEV | sed -r "s/\\/dev\\/.+:.+: //" | sed "s/°C//";
hddtemp /dev/$DEV --numeric

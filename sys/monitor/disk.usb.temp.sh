#!/bin/bash

DEV="$1";
smartctl -x /dev/$DEV | grep "Current Temperature" | sed -r "s/Current Temperature: +//"| sed -r "s/ Celsius//"

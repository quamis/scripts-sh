#!/bin/bash

DIR=`dirname $0`;


HEADERS=( )
COLUMNS=( )

COLUMNS+=(`date -Iseconds`);                    HEADERS+=("Date")
COLUMNS+=(`$DIR/loadAvg.sh`);                   HEADERS+=("LoadAvg")
COLUMNS+=(`$DIR/apache.connections.sh`);        HEADERS+=("ApacheConnections")
COLUMNS+=(`$DIR/smb.connections.sh`);           HEADERS+=("SMBConnections")
COLUMNS+=(`$DIR/cpu.temp.sh`);                  HEADERS+=("CPUTemp")
COLUMNS+=(`$DIR/disk.internal.temp.sh sda`);    HEADERS+=("sdaTemp")
COLUMNS+=(`$DIR/disk.usb.temp.sh sdb`);         HEADERS+=("sdbTemp")
COLUMNS+=(`$DIR/disk.usb.temp.sh sdc`);         HEADERS+=("sdcTemp")

OUT="./monitor.csv";
if [ ! -f $OUT ]; then
    echo ${HEADERS[@]} | tr " " "," >> $OUT;
fi;

echo ${COLUMNS[@]} | tr " " "," >> $OUT;

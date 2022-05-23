#!/bin/bash

DIR=`dirname $0`;


COLUMNS=( )

COLUMNS+=(`date -Iseconds`);
COLUMNS+=(`$DIR/loadAvg.sh`);
COLUMNS+=(`$DIR/apache.connections.sh`);
COLUMNS+=(`$DIR/smb.connections.sh`);
COLUMNS+=(`$DIR/cpu.temp.sh`);
COLUMNS+=(`$DIR/disk.temp.sh`);

OUT="./monitor.csv";
echo ${COLUMNS[@]} | tr " " "," >> $OUT;

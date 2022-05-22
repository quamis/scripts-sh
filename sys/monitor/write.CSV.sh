#!/bin/bash

COLUMNS=( )

COLUMNS+=(`date -Iseconds`)
COLUMNS+=(`./loadAvg.sh`);
COLUMNS+=(`./apache.connections.sh`);
COLUMNS+=(`./smb.connections.sh`);
COLUMNS+=(`./cpu.temp.sh`);
COLUMNS+=(`./disk.temp.sh`);

OUT="./monitor.csv";
echo ${COLUMNS[@]} | tr " " "," >> $OUT;

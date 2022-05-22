#!/bin/bash

COLUMNS=( )

COLUMNS+=(`date -Iseconds`)
COLUMNS+=(`./loadAvg.sh`);
COLUMNS+=(`./apache.connections.sh`);
COLUMNS+=(`./smb.connections.sh`);
COLUMNS+=(`./cpu.temp.sh`);
COLUMNS+=(`./disk.temp.sh`);

for value in "${COLUMNS[@]}"; do
    echo $value;
done;

#!/bin/bash
DIRS=(  "/bin/" \
        "/sbin/" \
		"/usr/bin/" \
        "/usr/sbin/" \
)

#usage: ./scan-toshiro.sh sscan clam
#usage: ./scan-toshiro.sh sscan bdc

LOG="./log.log";

for i in `seq 1 10`; do
    echo "" >> "$LOG";
done;

echo "=============================================" >> "$LOG";
echo "=============================================" >> "$LOG";
echo "=============================================" >> "$LOG";
echo "Started at `date +"%Y-%m-%d %H:%I:%S"`" >> "$LOG";
 
source "helper-scan.sh";

echo "Finished at `date +"%Y-%m-%d %H:%I:%S"`" >> "$LOG";

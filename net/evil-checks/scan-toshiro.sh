#!/bin/bash
DIRS=(  "/bin/" \
        "/sbin/" \
		"/usr/bin/" \
        "/usr/sbin/" \
		#"/home/pi/" \
        "/var/www/nextcloud/data/lucian.sirbu/files/" \
        "/var/www/nextcloud/data/andreea.sirbu/files/" \
        "/media/ext1Tb/nextcloud/photos/files/" \
		"/media/ext1Tb/nextcloud/music/files/" \
		"/media/ext1Tb/nextcloud/ebook/files/" \
		"/media/ext1Tb/torrents/complete/" \
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

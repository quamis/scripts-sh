#!/bin/bash

for x in /sys/block/sd*
do
	dev=$(basename $x)
	host=$(ls -l $x | egrep -o "host[0-9]+")
	target=$(ls -l $x | egrep -o "target[0-9:]*")
	a=$(cat /sys/class/scsi_host/$host/unique_id)
	a2=$(echo $target | egrep -o "[0-9]:[0-9]$" | sed 's/://')
	serial=$(hdparm -I /dev/$dev | grep "Serial Number" | sed 's/^[ \t]*//')
	model=$(hdparm -I /dev/$dev | grep "Model Number" | sed 's/^[ \t]*//')
	size=$(hdparm -I /dev/$dev | grep "1000\*1000:" | egrep -o '[0-9]+ [GT]B')
	
	echo -e "/dev/$dev \t ata$a.$a2 \t $model \t size:$size \t $serial"
done;

#!/bin/bash

for x in /sys/block/sd*; do
	dev=$(basename $x)
	echo -e "/dev/$dev `hddtemp /dev/$dev | sed -r "s/\\/dev\\/.+:.+: //" | sed "s/°C//"`;"
done;

#!/bin/bash

DIR="$1";


TTL=0;
DIRS="$( ls "$DIR" | sort )";
DIRSTOTAL=`echo "$DIRS"|wc -l`;
DIRINDEX=0
IFS=$'\n';
for D in `echo "$DIRS"`; do
	if [ -d  "$DIR/$D/" ]; then
		printf "\n[% 2s%%] % 8sGb % 8sGb \t$DIR/$D/" "$((100*DIRINDEX/DIRSTOTAL))" "........" "........";
		
		SIZE=$(du --summarize --block-size=1 "$DIR/$D/" | cut -f1);
		TTL=$((TTL+SIZE));
		
		printf "\r[% 2s%%] % 8.2fGb % 8.2fGb \t$DIR/$D/" "$((100*DIRINDEX/DIRSTOTAL))" "$((100*TTL/1024/1024/1024))e-2" "$((100*SIZE/1024/1024/1024))e-2";
		DIRINDEX=$(( DIRINDEX+1 ));
	else  
		printf "\n skip  .        .        \t$DIR/$D/";
	fi;
done;
unset IFS;

printf "\n\n%d items, totalling %8.3fGb\n" "$DIRSTOTAL" "$((100*TTL/1024/1024/1024))e-2";

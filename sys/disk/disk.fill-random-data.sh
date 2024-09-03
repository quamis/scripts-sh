#!/bin/bash

OF="randomData";

TOF="/tmp/template-randomData.txt";
DST="$1";
# i=0; while [ $i -le 20000 ]; do openssl rand -out $OF.$i.txt -base64 $(( 4**30 )); ((i++)); done

openssl rand -out $TOF -base64 $(( 2**30 ));


i=0;
while [ $i -le 2000000 ]; do
    # cp "$TOF" "$DST/$OF.$i.txt" || { echo 'cp failed' ; exit 1; };
    # pv "$TOF" > "$DST/$OF.$i.txt" || { echo 'cp failed' ; exit 1; };
    # rsync --progress "$TOF" "$DST/$OF.$i.txt" || { echo 'cp failed' ; exit 1; };
    rsync --info=progress2 "$TOF" "$DST/$OF.$i.txt" || { echo 'cp failed' ; exit 1; };

    ((i++));
done


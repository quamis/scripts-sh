#!/bin/bash

OF="randomData";

TOF="/tmp/template-randomData.txt";
DST="$1";
# i=0; while [ $i -le 20000 ]; do openssl rand -out $OF.$i.txt -base64 $(( 4**30 )); ((i++)); done

openssl rand -out $TOF $(( 2**30 ));    # 1Gb of data
cat "$TOF" >  "$TOF.1";      # 1Gb of data
cat "$TOF" >> "$TOF.1";     # 2Gb of data
cat "$TOF" >> "$TOF.1";     # 3Gb of data
cat "$TOF" >> "$TOF.1";     # 4Gb of data
mv "$TOF.1" "$TOF";


i=0;
while [ $i -le 2000000 ]; do
    SFX=`date "+%Y%m%d%H%M%S"`;

    # cp "$TOF" "$DST/$OF.$i.txt" || { echo 'cp failed' ; exit 1; };
    # pv "$TOF" > "$DST/$OF.$i.txt" || { echo 'cp failed' ; exit 1; };
    # rsync --progress "$TOF" "$DST/$OF.$i.txt" || { echo 'cp failed' ; exit 1; };
    echo "$i: $OF.$SFX.txt"; rsync --info=progress2 "$TOF" "$DST/$OF.$SFX.txt" || { echo 'cp failed' ; exit 1; };

    ((i++));
done


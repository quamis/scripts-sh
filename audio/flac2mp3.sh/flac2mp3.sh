#!/bin/bash

# bin/flac2mp3.sh DIR='/media/BIG/nextcloud/data/lucian.sirbu/files/@muzica.mp3/testing/culese-din-cartier-prezinta-argatu-volumul-4/'; sudo -u www-data php /var/www/html/nextcloud/occ files:scan --path='/lucian.sirbu/files/@muzica.mp3/testing/' --verbose

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   
	declare $KEY="$VALUE"
done

: ${DIR:="./"};
: ${EXT:="flac,wav"};
: ${QUALITY:="2"};
: ${MAX_LOAD:="95%"};
: ${THREADS:="4"};

# sequential conversion
#for a in ./*.flac; do
#	ffmpeg -loglevel panic -i "$a" -qscale:a "$QUALITY" "${a[@]/%flac/mp3}"
#done

# use GNU parallel
#ls -1 ./*.flac | parallel --no-notice --bar --jobs $THREADS --load $MAX_LOAD -- "ffmpeg -loglevel panic -i {} -y -qscale:a $QUALITY {.}.mp3";

declare -A QUALITY_MAP_TO_KBS=( ['0']='320k' ['1']='256k' ['2']='224k' ['3']='192k' ['4']='160k' ['5']='128k' ['6']='112k' ['7']='96k' ['8']='80k' ['9']='64k'  )
regexpEXT=`echo "$EXT" | sed s/\,/\|/g`

# debug
#find "${DIR}/" -type f -print | egrep "\.(${regexpEXT})$" | parallel --no-notice --bar --jobs $THREADS --load $MAX_LOAD -- "echo '>>> {} -> {.}.mp3'";
find "${DIR}/" -type f -print | egrep "\.(${regexpEXT})$" | parallel --no-notice --bar --jobs $THREADS --load $MAX_LOAD -- "ffmpeg -loglevel panic -i {} -y -b:a ${QUALITY_MAP_TO_KBS[$QUALITY]} {.}.mp3";

#ls -1 ./*.flac | parallel --no-notice -j "1" -- "sleep 1; echo \"{}\";"

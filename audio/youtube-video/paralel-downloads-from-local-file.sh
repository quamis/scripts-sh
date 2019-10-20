#!/bin/bash
PLAYLISTFILE="$1";

youtube-dl -j --flat-playlist --batch-file "$PLAYLISTFILE" > "$PLAYLISTFILE.01.jqfile"
cat "$PLAYLISTFILE.01.jqfile" | jq -r '"https://youtu.be/"+ .id' > "$PLAYLISTFILE.02.videolinks"

THREADS=4
MAX_LOAD=4
cat "$PLAYLISTFILE.02.videolinks" | parallel --no-notice --bar --jobs $THREADS --load $MAX_LOAD -- "youtube-dl -f bestvideo+bestaudio {}";


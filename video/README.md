
# usage:
# 	video.autoCrop.sh FILE='xyz.mkv'

# list all AV1 files in a folder with this:
#   CMD='video.is.AV1.sh FILE="$1" && echo "$1"';
#   find . -type f -exec bash -c "$CMD" -- {} \;


# re-encode all AV1 files in a folder with this:
#   CMD='video.is.AV1.sh FILE="$1" && video.reencode.x264.sh FILE="$1"';
#   find . -type f -exec bash -c "$CMD" -- {} \;



# re-encode ALL files:
#   find . -type f -exec bash -c "video.reencode.x264.sh FILE='{}';" \;
# re-encode ALL files, hi-quality:
#   find . -type f -exec bash -c "video.reencode.x264.sh PRESET='libx264,20' FILE='{}';" \;

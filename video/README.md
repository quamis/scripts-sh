
# usage:
# 	video.autoCrop.sh FILE='xyz.mkv'

# list all AV1 files in a folder with this:
#   CMD='video.is.AV1.sh FILE="$1" && echo "AV1: $1" || echo "---: $1"';
#   find . -type f -exec bash -c "$CMD" -- {} \;


# re-encode all AV1 files in a folder with this:
#   CMD='video.is.AV1.sh FILE="$1" && video.reencode.x264.sh FILE="$1"';
#   find . -type f -exec bash -c "$CMD" -- {} \;



# re-encode ALL files:
#   find . -type f -exec bash -c "video.reencode.x264.sh FILE='{}';" \;
# re-encode ALL files, hi-quality:
#   find . -type f -exec bash -c "video.reencode.x264.sh PRESET='libx264,20' FILE='{}';" \;

# re-encode ALL files, low-quality:
#   find . -type f -exec bash -c "video.reencode.x264.sh PRESET='libx264,34' FILE='{}';" \;
# re-encode ALL files, re-scale:
#   find . -type f -exec bash -c "video.reencode.x264.sh RESCALE=720 FILE='{}';" \;
# re-encode ALL files, re-scale + low-quality:
#   find . -type f -exec bash -c "video.reencode.x264.sh RESCALE=720 PRESET='libx264,34' FILE='{}';" \;

# re-encode ALL files, remove old ones:
#   find . -type f -exec bash -c "video.reencode.x264.sh CLEANUP=yes FILE='{}';" \;

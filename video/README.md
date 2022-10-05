
# usage:
# 	video.autoCrop.sh FILE='xyz.mkv'

# re-encode all AV1 files in a folder with this:
#   find . -type f -exec bash -c "video.is.AV1.sh FILE='{}' && video.reencode.x264.sh FILE='{}';" \;

# re-encode ALL files:
#   find . -type f -exec bash -c "video.reencode.x264.sh FILE='{}';" \;

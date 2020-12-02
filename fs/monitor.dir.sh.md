monitor.dir.sh
=============

Monitor a folder and run a script (optionally with a delay) when a change occurs

Depends on `inotifywait`. Run `apt install inotify-tools` in console to install it on Ubuntu.

Syntax:
`monitor.dir.sh DIR='./staging-api/' CMD='echo "__FILE__"'`

Variables allowed in CMD :
- __FILE__ : changed file
- __OPERATION__ : operation, as reported by `inotifywait`


-----------


Examples:
-----------
 - echoes changed filename as it monitors:

    `monitor.dir.sh DIR='./staging-api/' CMD='echo "__FILE__"';`
 - sync local devel with real devel, after a short delay, using `rsync`:

    `monitor.dir.sh DIR='/home/work/dev/www/staging-api/' CMD='rsync -qrtDvz --exclude='/.git' --filter="dir-merge,- .gitignore" "staging-api/app/" "/run/user/1001/gvfs/smb-share:server=192.168.X.X,share=username/devel/staging-api/app/";' WAIT=1`
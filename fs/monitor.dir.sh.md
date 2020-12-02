
Variables:
- __FILE__ : changed file
- __OPERATION__ : operation, as reported by `inotifywait`

Sync local devel with real devel:
monitor.dir.sh DIR='/home/work/dev/www/staging-api/' CMD='echo "__FILE__"';


./monitor.dir.sh DIR='/home/work/dev/www/staging-api/' CMD='rsync -qrtDvz --exclude='/.git' --filter="dir-merge,- .gitignore" "/home/work/dev/www/staging-api/app/" "/run/user/1001/gvfs/smb-share:server=192.168.0.3,share=lucian.sirbu/devel/staging-api-devel/app/";' WAIT=1
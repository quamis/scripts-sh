GENERAL
-----------------------------------------
Use `cat /proc/bus/input/devices` too see a list of devices



HAL SETUP (you may not have HAL installed anyway)
-----------------------------------------
Use `lshal`, if its installed
Use `xmobmap -pk` to see a list of available key names

If you have HAL installed, put this XML in /usr/share/hal/fdi/policy/10osvendor/20-remotes.fdi (no necessarly this name)
<?xml version="1.0" encoding="UTF-8"?>
<deviceinfo version="0.2">
<device>
 <match key="info.product" contains_ncase="TopSeed Tech Corp">
  <merge key="info.ignore" type="bool">true</merge>
 </match>
</device>
</deviceinfo>



X(SERVER) SETUP (its to subborn to simply ignore stuff it wont correctly handle)
-----------------------------------------
The X server wasn't ignoring the rc and i had to do this in order to make it ignore it
Put this in xorg.conf so X will ignore a device:

Section "InputClass"
    Identifier   "My Class"
    MatchProduct "TopSeed"
    Option "Ignore" "true"
EndSection

@see ideea from https://bbs.archlinux.org/viewtopic.php?pid=929542



EVROUTER SETUP
-----------------------------------------
Use evrouter (or evrouter2, if it gets final) to map the rc-generated keycodes to X11 keypresses
@see http://www.bedroomlan.org/projects/evrouter2

I've setup SUID for evrouter

Run as root: 
killall evrouter
evrouter -d /dev/input/by-id/usb-TopSeed_Tech_Corp._USB_IR_Combo_Device*
evrouter -f --config=/home/lucian/.boxee/UserData/keymaps/evrouter-remote-TopSpeed.txt /dev/input/by-id/usb-TopSeed_Tech_Corp._USB_IR_Combo_Device*

# for production
evrouter --config=/home/lucian/.boxee/UserData/keymaps/evrouter-remote-TopSpeed.txt /dev/input/by-id/usb-TopSeed_Tech_Corp._USB_IR_Combo_Device*


@see default X keymappings https://github.com/xbmc/xbmc/blob/master/system/keymaps/keyboard.xml#L55 

#!/bin/bash

#@see http://www.d0wn.com/using-bash-and-gatttool-to-get-readings-from-xiaomi-mijia-lywsd03mmc-temperature-humidity-sensor/
#@see comments
#@see https://github.com/belkop-ghb/LYWSD03MMC/blob/master/writeToMqtt.sh

#@see https://lynxbee.com/using-hcitool-to-get-bluetooth-device-information/
#@see https://github.com/home-assistant/core/issues/44329

# run 
#   hcitool lescan
# to see available devices

#A4:C1:38:B2:6B:CA LYWSD03MMC
#A4:C1:38:29:2D:B2 LYWSD03MMC
#A4:C1:38:C3:EF:EE LYWSD03MMC

ADDR="A4:C1:38:B2:6B:CA"; NAME="Living";
#ADDR="A4:C1:38:29:2D:B2"; NAME="Radu";
#ADDR="A4:C1:38:C3:EF:EE"; NAME="Dormitor";
#ADDR="A4:C1:38:E9:C9:BA"; NAME="???";


retry=0
MAXRETRY=8 # 8 retries x 30s/retry = 4 minutes maximum timeout
TIMEOUT=30 # timeout
while true; do
    echo "Querying $NAME($ADDR) for temperature and humidity data."
    data=$(timeout $TIMEOUT gatttool -b $ADDR --char-write-req --handle='0x0038' --value="0100" --listen  | grep "Notification handle" -m 1)
    rc=$?
    if [ ${rc} -eq 0 ]; then
        break
    fi
    if [ $retry -eq $MAXRETRY ]; then
	    echo "$MAXRETRY attemps made, aborting."
        exit 1;
    fi

    retry=$((retry+1))
    echo "Connection failed, retrying $retry/$MAXRETRY... "
    sleep 1
done


echo "data: $data"

BATTERY_MIN=2100
BATTERY_MAX=3100

temphexa=$(echo $data | awk -F ' ' '{print $7$6}'| tr [:lower:] [:upper:] )
temperature100=$(echo "ibase=16; $temphexa" | bc)
temperature=$(echo "scale=1;$temperature100/100"|bc)

humhexa=$(echo $data | awk -F ' ' '{print $8}'| tr [:lower:] [:upper:])
humidity=$(echo "ibase=16; $humhexa" | bc)

bathexa=$(echo $data | awk -F ' ' '{print $10$9}'| tr [:lower:] [:upper:] )
bat1000=$(echo "ibase=16; $bathexa" | bc)
bat=$(echo "scale=2;$bat1000/1000" | bc)

echo "BAT1000: $bat1000"
echo "BAT: $bat"

if ((bat1000>BATTERY_MAX)); then
	bat_perc=100.0
else
	bat_perc=$(echo "scale=2;(($bat1000-$BATTERY_MIN) / ($BATTERY_MAX - $BATTERY_MIN)*100)" | bc)
fi

echo "Temperature: $temperature, Humidity: $humidity, Battery: $bat_perc%"


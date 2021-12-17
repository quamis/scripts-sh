#!/bin/bash

# use as: ./ipList-lookup.sh ./ipList.txt

# depends:
# 	jq
#	geoiplookup

source "helper-config.sh";

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)   
	declare $KEY="$VALUE"
done;


: ${INPUT:="./tmp.txt"};
: ${TMPLIST:="/tmp/ipList-lookup.tmp"};
: ${CACHE_DIR:="cache"};
: ${SCANNER:=""};

mkdir -p "$CACHE_DIR";

echo "" > "$TMPLIST";
while IFS= read -r IP; do
	case "$SCANNER" in
        country)
            X=`geoiplookup "$IP" | grep Country | sed -r "s/.*: //"`
			echo "$X, $IP" >> "$TMPLIST"
        ;;
        city)
            X=`geoiplookup "$IP" | grep City | sed -r "s/.*: //"`
			echo "$X, $IP" >> "$TMPLIST"
        ;;

		nslookup-live)
            nslookup "$IP";
        ;;
		nslookup)
            X=`nslookup "$IP" | tr "\n" ";" | sed -r "s/(;)+/; /g"`
			
			echo -n ".";
			echo "$IP, $X" >> "$TMPLIST"
        ;;
		
		host-live)
            host -a "$IP";
        ;;
		host)
            X=`host "$IP"`
			echo "$IP, $X" >> "$TMPLIST"
        ;;
		
		
		ping-live)
             ping -c 6 "$IP";
        ;;
		ping)
            X=`ping -i 0.3 -W 3 -c 3 "$IP" | tail -n 1`
			
			echo -n ".";
			echo "$IP, $X" >> "$TMPLIST"
        ;;
		
		abusedb)
			CACHEKEY="${IP}-abusedb@`date +"%Y%m"`.cache"
			if [ -f "${CACHE_DIR}/${CACHEKEY}" ]; then
				JSON=`cat "${CACHE_DIR}/${CACHEKEY}"`;
				echo -n "c";
			else
				JSON=`curl --silent -G https://api.abuseipdb.com/api/v2/check --data-urlencode "ipAddress=$IP" -d maxAgeInDays=90 -d verbose -H "Key: $ABUSEIP_KEY" -H "Accept: application/json"`;
				echo "${JSON}" > "${CACHE_DIR}/${CACHEKEY}";
				echo -n "L";
			fi;
			
			X1=`echo "$JSON" | jq '.data.totalReports'`;
			X2=`echo "$JSON" | jq '.data.abuseConfidenceScore'`;
			X3=`echo "$JSON" | jq '.data.usageType'`;
			X4=`echo "$JSON" | jq '.data.isp'`;
			X5=`echo "$JSON" | jq '.data.countryCode'`;
			
			echo "$X5, isp:$X4, reports:$X1, confidence:$X2, $IP, usage:$X3," >> "$TMPLIST"
		;;
		
		ipstack)
			CACHEKEY="${IP}-ipstack@`date +"%Y%m"`.cache"
			if [ -f "${CACHE_DIR}/${CACHEKEY}" ]; then
				JSON=`cat "${CACHE_DIR}/${CACHEKEY}"`;
				echo -n "c";
			else
				JSON=`curl --silent -G "http://api.ipstack.com/${IP}?access_key=${IPSTACK_KEY}&security=1&hostname=1" -d verbose -H "Accept: application/json"`;
				echo "${JSON}" > "${CACHE_DIR}/${CACHEKEY}";
				echo -n "L";
			fi;
			
			XL1=`echo "$JSON" | jq '.region_code' | sed 's/\"//g'`;
			XL2=`echo "$JSON" | jq '.country_code' | sed 's/\"//g'`;
			XL3=`echo "$JSON" | jq '.continent_code' | sed 's/\"//g'`;
			#XL4=`echo "$JSON" | jq '.security.threat_level' | sed 's/\"//g'`;	# free accounts do not support the security module, only the geolocation api
			
			echo "$XL3,$XL2,$XL1, $IP" >> "$TMPLIST"
		;;
		
		ipdata)
			CACHEKEY1="${IP}-ipdata@`date +"%Y%m"`-threat.cache"
			if [ -f "${CACHE_DIR}/${CACHEKEY1}" ]; then
				JSON1=`cat "${CACHE_DIR}/${CACHEKEY1}"`;
				echo -n "c";
			else
				JSON1=`curl --silent -G "https://api.ipdata.co/${IP}/threat?api-key=${IPDATA_KEY}" -d verbose -H "Accept: application/json"`;
				echo "${JSON1}" > "${CACHE_DIR}/${CACHEKEY1}";
				echo -n "L";
			fi;
			
			CACHEKEY2="${IP}-ipdata@`date +"%Y%m"`-asn.cache"
			if [ -f "${CACHE_DIR}/${CACHEKEY2}" ]; then
				JSON2=`cat "${CACHE_DIR}/${CACHEKEY2}"`;
				echo -n "c";
			else
				JSON2=`curl --silent -G "https://api.ipdata.co/${IP}/asn?api-key=${IPDATA_KEY}" -d verbose -H "Accept: application/json"`;
				echo "${JSON2}" > "${CACHE_DIR}/${CACHEKEY2}";
				echo -n "L";
			fi;
			
			X11=`echo "$JSON1" | jq '.is_threat' | sed 's/\"//g'`;
			X12=`echo "$JSON1" | jq '.is_tor' | sed 's/\"//g'`;
			X13=`echo "$JSON1" | jq '.is_known_attacker' | sed 's/\"//g'`;
			X14=`echo "$JSON1" | jq '.is_known_abuser' | sed 's/\"//g'`;
			
			X21=`echo "$JSON2" | jq '.type' | sed 's/\"//g'`;
			X22=`echo "$JSON2" | jq '.domain' | sed 's/\"//g'`;
			X23=`echo "$JSON2" | jq '.name' | sed 's/\"//g'`;
			
			echo "threat:$X11, tor:$X12, attacker:$X13, abuser:$X14, $X23($X22), $X21 $IP" >> "$TMPLIST"
		;;
		

		# PAID CRAP, didn't seem to offer anything above abuseDB
		#fraudguard)
		#	CACHEKEY="${IP}-fraudguard@`date +"%Y%m"`.cache"
		#	if [ -f "${CACHE_DIR}/${CACHEKEY}" ]; then
		#		JSON=`cat "${CACHE_DIR}/${CACHEKEY}"`;
		#		echo -n "c";
		#	else
		#		JSON=`curl --silent -u "${FRAUDGUARD_USER}:${FRAUDGUARD_PASS}" -G "https://@api.fraudguard.io/v2/ip/${IP}"`;
		#		echo $JSON;
		#	fi;
		#	
		#	X1=`echo "$JSON" | jq '.threat' | sed 's/\"//g'`;
		#	X2=`echo "$JSON" | jq '.risk_level' | sed 's/\"//g'`;
		#	X3=`echo "$JSON" | jq '.organization' | sed 's/\"//g'`;
		#	X4=`echo "$JSON" | jq '.isocode' | sed 's/\"//g'`;
		#	X5=`echo "$JSON" | jq '.connection_type' | sed 's/\"//g'`;
		#	
		#	echo "$X1/$X2, $X4, $X5,$X3, $IP" >> "$TMPLIST"
		#;;
		
		*)
			echo $"Usage: ./ipList-lookup.sh SCANNER={country|city|nslookup|nslookup-live|host|host-live|ping|ping-live|abusedb|ipstack|ipdata|fraudguard}";
            exit 1;
	esac;
done < "$INPUT";


cat "$TMPLIST" | sort > "$TMPLIST.1"
cat "$TMPLIST.1";

#!/bin/bash

antivir_update() {
	if [ "$ANTIVIRS" == "all" ] || [ "$ANTIVIRS" == "bdc" ] ; then
		/opt/BitDefender-scanner/bin/bdscan --update 2>&1
	fi;
	
	if [ "$ANTIVIRS" == "all" ] || [ "$ANTIVIRS" == "clam" ] ; then
		# automatically updated by OS
		echo "" 2>&1
	fi;
}

antivir_scan() {
	local DIR="$1";

	if [ "$ANTIVIRS" == "all" ] || [ "$ANTIVIRS" == "bdc" ] ; then
		#/opt/BitDefender-scanner/bin/bdscan --action=ignore --no-list "$DIR" grep -A 65536 "Results:" | head --lines=-1
		/opt/BitDefender-scanner/bin/bdscan --action=ignore --no-list "$DIR" 2>&1;
	fi;
	
	if [ "$ANTIVIRS" == "all" ] || [ "$ANTIVIRS" == "clam" ] ; then
		#clamscan --suppress-ok-results --recursive=yes "$DIR" | grep -A 65536 "SCAN SUMMARY"
		clamscan --suppress-ok-results --recursive=yes "$DIR"  2>&1;
	fi;
}


###############################################################
export PYTHONIOENCODING=utf-8
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color


ACTION="$1";
: ${ACTION:="update+sscan"};

ANTIVIRS="$2";
: ${ANTIVIRS:="all"};

CPUCOUNT=`lscpu -b -p=Core,Socket | grep -v '^#' | sort -u | wc -l`;

if [ "$ACTION" == "update+sscan" ] ; then
	antivir_update | tee -a "$LOG";
fi;
	
if [ "$ACTION" == "update+sscan" ] || [ "$ACTION" == "sscan" ] ; then
	DELAY="0.25";

	for DIR in "${DIRS[@]}"; do
		echo -e "\n\n" | tee -a "$LOG";
		echo -e "${GREEN}======================================================${NC}" | tee -a "$LOG";
		echo -e "${GREEN}${DIR}${NC}" | tee -a "$LOG";
		
		antivir_scan "$DIR" | tee -a "$LOG";
		
		echo -e "${GREEN}......................................................${NC}" | tee -a "$LOG";
		
		sleep $DELAY;
	done;
fi;

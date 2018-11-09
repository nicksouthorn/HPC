#!/bin/bash

DATE=$(date "+%d%m%y","%H%M")
POSITIONAL=()
while [[ $# -gt 0 ]]
do 
	key="$1"

case $key in
	-b|--battery)
	# VARS

	UPOWER="/usr/bin/upower -i"
	BAT0_PATH=/org/freedesktop/UPower/devices/battery_BAT0
	BAT1_PATH=/org/freedesktop/UPower/devices/battery_BAT1

	echo "BAT0,"$DATE","$($UPOWER $BAT0_PATH | grep "percentage" | sed -e "s/[a-zA-Z]//g" -e "s/://g"  -e "s/^[ \t]*//;s/[ \t]*$//")
	echo "BAT1,"$DATE","$($UPOWER $BAT1_PATH | grep "percentage" | sed -e "s/[a-zA-Z]//g" -e "s/://g"  -e "s/^[ \t]*//;s/[ \t]*$//")
	shift
	;;
	-c|--cputemp)
	# VARS
	SENSORS="/usr/bin/sensors"
	NUM_CORES=$($SENSORS | grep Core | wc -l)
	NUM_CORES1=$(expr $NUM_CORES - 1)

	for i in `seq 0 $NUM_CORES1`;
	do
		echo "Core$i,$DATE,"$($SENSORS | grep  "Core $i" | awk '{FS=":"}{print $3}' | sed -s "s/+//g")
	done
	shift
	;;
	-h|--help)
	echo "================= HELP =================="
	echo ""
	echo "Type metricmon.sh --usage to show options"	
	echo "" 
	echo "========================================="
	shift
	;;
	-u|--usage)
	echo "================ USAGE =================="
	echo ""
	echo "Show remaining battery percentage"
	echo "metricmon.sh -b|--battery"
	echo ""
	echo "Show CPU temperatures"
	echo "metricmon.sh -c|cputemp"
	echo ""
	echo "========================================="
	shift
	;;
	*)
	POSITIONAL+=("$1")
	shift
	;;
esac
done
set -- "${POSITIONAL[@]}"

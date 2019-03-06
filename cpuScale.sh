#!/bin/bash
# ====================================================================================
# Name: cpuScale.sh
# Description: Script to show current CPU scaling settings and modify them
# Author: Nick Southorn
# Last mod: 05/04/19
#           Updated help file
# ====================================================================================
# Source external functions, such as printHr
. ~/bin/functions
# Check script being run as root
if [[ $EUID -ne 0 ]]; then
	printHr
	echo "You need to be root in order to view/modify CPU scaling settings"
	printHr
	exit 1
fi
if [[ $# -eq 0 ]]; then
	printHr
	echo "You need to provide an option. See -h|--help for examples"
	printHr
fi

while test $# -gt 0; do
	case "$1" in
		-h|--help)
			printHr
			echo "Usage: cpuScale [options]"
			echo " "
			echo "Options:"
			echo "-h|--help 		  Show help"
			echo "-s|--show-current         Show current cpu scaling governance settings"
			echo "-v|--powersave            Set CPU powersave mode"
			echo "-f|--performance          Set CPU performance mode"
			echo ""
			echo "Example: cpuScale --show-current"
			echo "Will show the current cpu scaling governance settings"
			echo " "
			printHr
			exit 0
			;;
		-s|--show-current)
			printHr
			echo "Current CPU scaling governor setting:"
			cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
			printHr
			exit 0
			;;
		-v|--powersave)
			printHr
			echo "Setting powersave mode"
			echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
			printHr
			exit 0
			;;
		-f|--performance)
			printHr
			echo "Setting performance mode"
			echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
			printHr
			exit 0
			;;
		*)
			break
			;;
	esac

done

#=====================================================================================
# END OF FILE
#=====================================================================================


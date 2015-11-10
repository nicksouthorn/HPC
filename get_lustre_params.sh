#!/bin/bash -
#title          :get_lustre_params.sh
#description    :Script to capture current Lustre settings
#author         :Nick Southorn
#date           :20151110
#version        :1.0
#usage          :./get_lustre_params.sh
#notes          :
#bash_version   :4.1.17(0)-release
#============================================================================

# TODO: Add verbosity options 
display_usage() { 
	echo "This script is non-intrusive and does not change any Lustre parameters." 
	echo -e "\nUsage:\n$0 [arguments] \n" 
	} 

# Quick check to see if the LFS command exists
if ! [ "$(type -t /usr/bin/lfs)" ]
then 
/usr/bin/clear
cat << EOF 
===================================== COMMAND NOT FOUND =====================================

The Lustre File System utility program is not installed on this system or cannot be found.

It should be installed in /usr/bin/lfs before running this program. 

=============================================================================================
EOF
/usr/bin/sleep 5
exit

fi

	
for Lustre_NID in $(lfs df | grep MDT | awk -F "-MDT0" '{print $1}')
	do
	echo -e "\n======== Lustre $Lustre_NID Settings ========"
	echo -e "\tchecksums: `cat /proc/fs/lustre/osc/${Lustre_NID}-OST0000-*/checksums` "
	echo -e "\tchecksum_type: `cat /proc/fs/lustre/osc/${Lustre_NID}-OST0000-*/checksum_type` "
	echo -e "\tmax_rpcs_in_flight: `cat /proc/fs/lustre/osc/${Lustre_NID}-OST0000-*/max_rpcs_in_flight` "
	echo -e "\tmax_pages_per_rpc: `cat /proc/fs/lustre/osc/${Lustre_NID}-OST0000-*/max_pages_per_rpc` "
	echo -e "\tmax_dirty_mb: `cat /proc/fs/lustre/osc/${Lustre_NID}-OST0000-*/max_dirty_mb` "
	echo -e "\tmax_read_ahead_mb: `cat /proc/fs/lustre/llite/${Lustre_NID}*/max_read_ahead_mb` "
	echo -e "\tmax_read_ahead_per_file_mb: `cat /proc/fs/lustre/llite/${Lustre_NID}*/max_read_ahead_per_file_mb` "
	echo -e "\tmax_read_ahead_whole_mb: `cat /proc/fs/lustre/llite/${Lustre_NID}*/max_read_ahead_whole_mb` "
	echo "======== End of Lustre Settings ========"
	done
## end of script


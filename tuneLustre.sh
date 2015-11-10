#!/bin/bash -
#title          :tuneLustre.sh
#description    :Script to tune Lustre settings
#author         :Nick Southorn
#date           :20150410
#version        :1.0
#usage          :./tuneLustre.sh
#notes          :
#bash_version   :4.1.17(0)-release
#============================================================================
#============================================================================

#============================================================================
# FUNCTIONS
#============================================================================

# Check to see if the LCTL command exists
check_lctl(){
if ! [ "$(type -t /usr/sbin/lctl)" ]
then
/usr/bin/clear
cat << EOF

===================================== COMMAND NOT FOUND =====================================

The Lustre Control program is not installed on this system or cannot be found.

It should be installed in /usr/sbin/lctl before running this program.

lctl can only be run as root

=============================================================================================
EOF
/usr/bin/sleep 2
exit
fi
}

# Check to see if the LFS command exists
check_lfs(){
if ! [ "$(type -t /usr/bin/lfs)" ]
then
/usr/bin/clear
cat << EOF

===================================== COMMAND NOT FOUND =====================================

The Lustre File System Utility program is not installed on this system or cannot be found.

It should be installed in /usr/bin/lfs before running this program.

=============================================================================================
EOF
/usr/bin/sleep 2
exit
fi
}


# Display current Lustre settings
display_settings(){
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
}

# Resetting settings back to default
reset_lustre(){
cat << EOF
=============================================================================================

Setting to default Lustre settings

=============================================================================================
EOF


sysctl -w lnet.debug=0
lctl set_param osc.lustre*.checksums=1
lctl set_param osc.lustre*.max_rpcs_in_flight=8
lctl set_param osc.lustre*.max_dirty_mb=32
lctl set_param osc.lustre*.max_pages_per_rpc=256
lctl set_param llite.lustre*.max_read_ahead_mb=40
lctl set_param llite.lustre*.max_read_ahead_per_file_mb=40
lctl set_param llite.lustre*.max_read_ahead_whole_mb=2
}

# Tuning settings for Abaqus
tune_for_abaqus(){
cat << EOF
=============================================================================================

Tuning Lustre for Abaqus....
Settings provided by Scott Shaw - SGI Ltd.

=============================================================================================
EOF

sysctl -w lnet.debug=0
lctl set_param osc.lustre*.checksums=1
lctl set_param osc.lustre*.max_rpcs_in_flight=128
lctl set_param osc.lustre*.max_dirty_mb=512
lctl set_param osc.lustre*.max_pages_per_rpc=1024
lctl set_param llite.lustre*.max_read_ahead_mb=512
lctl set_param llite.lustre*.max_read_ahead_per_file_mb=512
lctl set_param llite.lustre*.max_read_ahead_whole_mb=2
}

check_root(){
if [[ $EUID -ne 0 ]]
then
/usr/bin/clear
cat << EOF
=============================================================================================

Changes to Lustre must be run as root

=============================================================================================

EOF
/usr/bin/sleep 2
exit

fi
}


#============================================================================
# MENU OPTIONS
#============================================================================
 
echo "Select Option:

1) Display current Lustre settings
2) Reset Lustre settings to default
3) Tune Lustre for Abaqus
4) Exit
"

read n
case $n in
1) 
check_lfs
display_settings
;;

2)
check_root
check_lctl
#reset_lustre
;;

3)
check_root
check_lctl
#tune_for_abaqus
;;

4)
/usr/bin/clear
echo "Exiting..."
sleep 1
exit
;;

*) 
/usr/bin/clear
echo "Invalid option selected. Exiting..."
;;
esac


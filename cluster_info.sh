#!/bin/bash
################################################################################
#
# Version: 2.5
# Born Date: 1/28/2008
# Last Updated: 6/22/2010
# Author: Scott Shaw, sshaw at sgi.com
# Script Name: cluster_info
#
#  This work is held in copyright as an unpublished work by
#  Silicon Graphics, Inc., 2006-2008.  All rights reserved.
#
# NOTE: for x86_64 platforms only
#
# The cluster_info script is intended to gather specific information from
# each node/blade to determine the how many processors, memory, HCA interconnect, 
# model numbers...   The Cluster Info script is setup to execute parallel 
# ssh shell vs gathering of data serially with ssh commands.  
#
# The output of the script can be used for a banner info for each pbs job or to 
# gather quick snapshots of the cluster configuration. If this data was prepended
# to the PBS output file the user can quickly reference this data and determine 
# the configuration of the cluster at the time the PBS job was executed.  A useful
# side affect of the script will output differences between nodes if found.  For 
# instance, if a node was booted and there was bad memory module the script 
# will output the difference.
#
# The script should reside on shared storage file system on the service or head 
# node of a cluster and should only be executed as root.
#
# At the moment this script has been tested on...
#   - ICE SuSE Clusters which is Tempo managed
#   - XE SuSE Clusters 1200 and 1300 series clusters which are scali managed
#   - XE 1200 RedHat Clusters scali managed
#
# ssh access to each blade is determine by the name resolution of the hostname
# and IP address.  For ICE clusters the IB0 fabric is used.  On XE Clusters
# the Ethernet GigE fabric is used.
#
# usage: cluster_info [-ch]
#
#        cluster_info       # Cluster Mode, which is executed from headnode
#        cluster_info -c    # Capture current node/server configuration
#        cluster_info -p    # preserve the output collection under /tmp
#        cluster_info -h    # Print this usage
#
#
################################################################################
# History
#  3/24/08 Michel: added scali cmd to query the hosts
#  3/24/08 Scott: added changes to DMI FSB and corrected typos
#  4/17/08 Scott: added error statement when the cluster_info can not be found
#             - fixed the detection of a Scali manage XE/ICE condition check
#             - updated Version and date


# The following function will spawn an ssh shell and we redirect output to the 
# master ssh node.
function spawn ()
{
        if [[ `jobs | grep  -v Done | wc -l` -ge $1 ]]; then
                wait
        fi
        shift
        LOGFILE="${TMPFILEPATH}/${HOSTNAME}"
        echo -en "\033[K\033[20DChecking $3"

        $@  </dev/null 2>&1 >${LOGFILE} &

## If user notification is require and the term does not support esc chars uncomment
## the following two lines.
#      if [ "${STATFLAG}" = "O" ]; then STATFLAG="+" ; else STATFLAG="O"; fi 
#      echo -en "${STATFLAG}\b"
# 
}

# The exec_cmd function will control how many ssh shells to spawn and command line 
# and wait until each process sucessfully completes.
function exec_cmd ()
{
CMDLINEOPT="-c"

   if [ ! -f  "${SCRIPT_ROOT}/${SCRIPT_NAME}" ]; then 
       echo -e "\nERROR: ${SCRIPT_NAME} not found. \n"
       echo -e "PATH to ${SCRIPT_NAME} is currently set to: ${SCRIPT_ROOT} \n"
       echo -e "Edit cluster_info and change SCRIPT_ROOT= to the absolute path of script. \n\n"
    exit -1
   else
      CMDLINE="${SCRIPT_ROOT}/${SCRIPT_NAME} ${CMDLINEOPT}"
   fi

   mkdir ${TMPFILEPATH}
   echo -n "Running "
   for HOSTNAME in ${TARGET_NODE}
   do
      spawn 128 ssh ${SSHOPTS} ${HOSTNAME} ${CMDLINE}
   done
   wait
   echo -e "\b Done."
}

# The following function are the commands which are executed on each node. Surely this 
# can be cleaned up but for now it works.
exec_local_cmds ()
{
# get the linux distrabution are we running using an rpm query of %_vendor
LINUX_DIST=`rpm --eval "%_vendor"`
SNOOP_FILTER_FLAG="true"

   if [ ${LINUX_DIST} = "suse" ]; then
       OS_REL_VER=`cat /etc/SuSE-release| perl -pe 's/\s+/ /g'`
       MEM_SPEED=`dmidecode -t memory | grep -i speed | uniq | perl -pe 's/^\s+//g'`
       BIOS_DATE=`dmidecode -s bios-release-date`
       if [ -f /usr/bin/ofed_info ]; then OFED_REL=`ofed_info | grep OFED`; fi

       DMI_MFG=`dmidecode -s baseboard-manufacturer`
       DMI_PRODNAME=`dmidecode -s system-product-name`
       DMI_PRODVER=`dmidecode -s system-version`
       DMI_PROD=`dmidecode -s baseboard-product-name`

       if [ ${DMI_PROD} = "X8DTT-BloomerS" ]; then SNOOP_FILTER_FLAG=false; fi

       if [ "${SNOOP_FILTER_FLAG}" = "true"  ]; then 
          CURVAL=`/sbin/lspci -xxxx -s 0:10.0 2>/dev/null | /usr/bin/grep -e "^f0:" | \
           sed -e 's,f0: ,,g' -e 's,^\(..\).*$,0x\1,g'`
          if [ $(($CURVAL)) -ne 0 ] ; then 
               $CURVAL=$($CURVAL&4)
               SNOOP_FILTER="DISABLED"
          else 
               SNOOP_FILTER="ENABLED"
          fi
       fi
   elif [ ${LINUX_DIST} = "redhat" ]; then
       OS_REL_VER=`cat /etc/redhat-release| perl -pe 's/\s+/ /g'`
   else 
       OS_REL_VER="Unknown"
   fi

   MEMINFO=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | awk '{print $1}'`

   CPUINFO=`grep -w "model name" /proc/cpuinfo  | sort -u | cut -d ":" -f 2 \
           | perl -pe 's/\s+/ /g'| perl -pe 's/^\s+//'`

   PROCESSOR_COUNT=`grep "physical id" /proc/cpuinfo | sort -u | wc -l`
   PROCESSOR_MODEL=`grep "model name" /proc/cpuinfo | awk '{print $7}' | sort -u | perl -pe 's/\s+//'`
   PROCESSOR_CORES=`grep "cpu cores" /proc/cpuinfo | uniq | cut -d ":" -f 2 \
             | perl -pe 's/^\s+//'`

   PROCESSOR_SERIES=`grep "model name" /proc/cpuinfo | awk '{print $7}' | sort -u | perl -pe 's/[A-Z]|\s+//' | cut -c -2`

   DMI_FSB=""  # if the processor type is not found set FSB to nothing

      if [ ${PROCESSOR_MODEL} == "X5365" ]; then
           DMI_FSB="1333MHz"
      elif [ ${PROCESSOR_MODEL} == "X5355" ]; then
           DMI_FSB="1333MHz"
      elif [ ${PROCESSOR_MODEL} == "E5345" ]; then
           DMI_FSB="1333MHz"
      elif [ ${PROCESSOR_MODEL} == "5150" ]; then
           DMI_FSB="1333MHz"
      elif [  ${PROCESSOR_MODEL} == "5160" ]; then
           DMI_FSB="1333MHz"
      elif [ ${PROCESSOR_MODEL} == "E5420" ]; then
           DMI_FSB="1333MHz"
      elif [ ${PROCESSOR_MODEL} == "E5440" ]; then
           DMI_FSB="1333MHz"
      elif [ ${PROCESSOR_MODEL} == "E5472" ]; then
           DMI_FSB="1600MHz"
      else
           DMI_FSB=""
      fi

   HYPERTHREAD_FLAG=`cat /sys/devices/system/cpu/cpu0/topology/thread_siblings | cut -d "," -f 4 | cut -c 6`
   if [ ${HYPERTHREAD_FLAG} ]; then HYPERTHREAD=Enabled; else HYPERTHREAD=Disabled;fi

   CPU_COUNT=`grep -w "model name" /proc/cpuinfo  |  wc -l`
   KERNEL_REL=`uname -r`
   SGI_SOFTWARE=`cat /etc/sgi-*`
   FILESYS_TYPES=`mount | egrep "nfs|lustre|rdma" | egrep -v "rootfs|per-host" | cut -d":" -f 2 | awk '{print $1,$2,$3,$4,$5}' | sort -u`

## Collect memory DIMM configuration if memlogd is installed.
#if [ -f /usr/sbin/memlogd ]; then
#let index=0
#  for socket in $(/usr/sbin/memlogd -c 2>&1 |grep DIMM | awk '{print $1}' | sort -u); do
#    for dimm in $(/usr/sbin/memlogd -c 2>&1 |grep DIMM | grep "^ ${socket}" | awk '{print $4}' | sort -u); do
#       MEM_CNT=`/usr/sbin/memlogd -c 2>&1 |grep DIMM | awk '{print $1 " " $4}' | egrep ^${socket} | grep -c ${dimm}`
#       MEM_ARRAY[$index]="Socket ${socket}: ${MEM_CNT} DIMMs x $dimm MB"
#       ((index++))
#    done
#  done
#fi

# Output the variables in the following format.
echo "  Product Type: ${DMI_PRODVER}"
echo "  Product Name: ${DMI_PRODNAME}"
echo -e "     Board MFG: ${DMI_MFG} \t\tBoard Model: ${DMI_PROD}"
#if [ ${DMI_PROD} == "X8DTT-BloomerS" ]; then 
if $(grep -q '^model name.*5[5-7][0-9][0-9].*' /proc/cpuinfo); then
   echo -e "     BIOS Date: ${BIOS_DATE} \t\tHyperThread: ${HYPERTHREAD}   "
      PROCESSOR_CACHE=`grep "cache size" /proc/cpuinfo | awk '{print $4}' | sort -u`
else 
   echo -e "     BIOS Date: ${BIOS_DATE} "
      PROCESSOR_CACHE=`grep "cache size" /proc/cpuinfo | awk '{print $4}' | sort -u`
fi

if [ -f /usr/bin/ofed_info ]; then
   echo "      Ofed Rel: ${OFED_REL}"
   echo -n "  IB Device(s): "
   for i in $( ls -d /sys/class/infiniband/* ); 
     do 
       echo ${i} | cut -d "/" -f 5 ; 
       echo -n "FW=`cat ${i}/fw_ver` "; 
       echo "Rate=`cat ${i}/ports/?/rate` "; 
     done | perl -pe 's/\s+/ /g'
    echo ""
fi
if [ -n "${DMI_FSB}" ]; then
    echo "    Processors: ${PROCESSOR_COUNT} x ${PROCESSOR_CORES} Cores ${CPUINFO}${PROCESSOR_CACHE}KB Cache FSB:${DMI_FSB}"
 else 
    echo "    Processors: ${PROCESSOR_COUNT} x ${PROCESSOR_CORES} Cores ${CPUINFO}${PROCESSOR_CACHE}KB Cache"
fi
echo "     Total Mem: ${MEMINFO} KB    ${MEM_SPEED}"

let index=0
while [ "$index" -lt ${#MEM_ARRAY[@]} ]
do    # List all the elements in the array.
  echo "      ${MEM_ARRAY[$index]}"
       ((index++))
done

echo "    OS Release: ${OS_REL_VER}"
echo "    Kernel Ver: ${KERNEL_REL}"
echo "  SGI Software: ${SGI_SOFTWARE}"
echo 
echo "Following are the file system types detected."
echo "--------------------------------------------------------------------------------"
echo "${FILESYS_TYPES}"

}

# Parse the output files and sort based on unique lines.  This is useful to 
# determine if a configuration of a node/blade is different from the others
# which might indicate a problem.
function output_file ()
{

    if [ ${COLLECT} -eq 0 ]; then 
       if [ ${CLUSTER_NAME} == "Unknown" ]; then
           CLUSTER_NAME=`/bin/hostname`
       fi
       echo 
       echo "The ${CLUSTER_NAME} cluster with ${NODE_COUNT} cnodes has the following"
       echo "configuration based on `date` snapshot."
       echo 
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Product Type"  | sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Product Name"  | sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Board MFG"  | sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "BIOS" | sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Ofed" | sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "IB Device" | sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Processors"| sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Total Mem" | sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Socket" | sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "OS Release"| sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Kernel Ver"| sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "SGI Software"|sort -u
       echo
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "Following"|sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "\-------"|sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "type nfs"|sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "type lustre"|sort -u
       cat ${TMPFILEPATH}/${NODE_PREFIX}* | grep "type rdma"|sort -u
       echo
    fi
    # Remove the temporary location of the output files.

    if [ ${PRESERVE_TMPFILES} -eq 0 ]; then
       rm -rf  ${TMPFILEPATH}
    else
       echo -e "Preserve temp files under ${TMPFILEPATH}\n\n"
    fi
}

function usage ()
{
cat << USAGE
${SCRIPT_NAME}: Capture a snapshot of the cluster configuration.

 usage: ${SCRIPT_NAME} [-ch]

        ${SCRIPT_NAME}       # Cluster Mode, which is executed from headnode
        ${SCRIPT_NAME} -c    # Capture current node/server configuration
        ${SCRIPT_NAME} -h    # Print this usage
        ${SCRIPT_NAME} -p    # preserve the output files for user parsing

USAGE
exit 0
}

### main()
# set the following defaults
SSHOPTS="-oConnectTimeout=6"
TMPFILEPATH="/tmp/${USER}_$$"
SCRIPT_ROOT="/lustre/sgi/abaqus/cases"
SCRIPT_NAME="cluster_info"
CLUSTER_NAME="Unknown"

# Initialize the following variables to null or zero
TARGET_NODE=""
NODE_PREFIX=""
NODE_COUNT=0
COLLECT=0   # used as a flag to determine if script is collecting data or master
            # spawning ssh shells on the cnodes/cblades.
PRESERVE_TMPFILES=0

## only on x86_64 platforms
test "$(uname -m)" != "x86_64" \
	&& echo "ERROR: ${SCRIPT_NAME} is supported only on x86_64 platform. Exiting." \
	&& exit 1

while getopts :chp OPTS
do
  case $OPTS in
     c)  COLLECT=1;;
     h)  usage;; 
     p)  PRESERVE_TMPFILES=1;; 
   esac
done

CMDLINE=$*

if [ $(id -un) != root ]; then
   echo
   echo "ERROR: This script requires the ROOT user id for execution "
   echo "       since some of the commands to obtain cluster details"
   echo "       require root access." 
   echo
   exit -1
fi


# The following conditional check is to determine which platform the 
# script is being executed on and how many nodes are available within
# the cluster. 
if [ -f /etc/c3.conf ] ; then   # must be ICE tempo cluster
   NODE_PREFIX="r"
   for NODE in $( awk '{ print $1}' /etc/c3.conf | egrep ^r) 
     do 
         TARGET_NODE="${TARGET_NODE} ${NODE}"
         let NODE_COUNT++
     done
# Is this a scali managed cluster? if true at some point we need to determine if XE or ICE
elif [ -f /opt/scali/bin/scalimanage-cli ]; then  
   CLUSTER_NAME=`hostname`
   # egrep below covers rXXiYYnZZ and clXnYYY
   for NODE in $( /opt/scali/bin/scahosts -1z \
   		  | egrep '^[[:alpha:]]+[[:digit:]]+n[[:digit:]]+$|^r[[:digit:]]+i[[:digit:]]+n[[:digit:]]+$' \
                  | sort -n)
     do
         TARGET_NODE="${TARGET_NODE} ${NODE}"
         let NODE_COUNT++
     done
#Checking if ISLE managed cluster
elif [ -f /etc/machines ]; then
   for NODE in $( awk '{ print $1}' /etc/machines)
     do
         TARGET_NODE="${TARGET_NODE} ${NODE}"
         let NODE_COUNT++
     done

else
    # If not running the configuration collect command exit with an error status other 
    # than zero
    if [ ${COLLECT} -eq 0 ]; then   
     echo "This is not a Tempo or Scali Managed cluster."
     echo "ERROR: Unable to determine which nodes to execute on."
     exit -1
    fi
fi

if [ ${COLLECT} -eq 1 ]; then 
   exec_local_cmds
else
   exec_cmd
fi
output_file


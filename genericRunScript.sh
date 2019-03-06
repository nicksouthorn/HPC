#!/bin/bash
# $URL: file:///hosts/gbc.engr.sgi.com/store/sshaw/svn/abaqus_files/run_abq_bmark $
# $Rev: 5 $
# $Author: sshaw $
# $Date: 2011-09-01 14:38:05 -0500 (Thu, 01 Sep 2011) $
# $Id: run_abq_bmark 5 2011-09-01 19:38:05Z sshaw $
# $Copyright$

# This script will launch a series of Abaqus jobs based on core count and other
# parameters passed below.  I tried to make this script fault proof but I can not
# take responsibility if something goes horribily wrong ;)  Make sure you check
# the PBS output files for any errors to troubleshoot any issues.  Any questions
# about this script please contact sshaw at sgi.com.  I used an "at" vs a @ to keep
# email spamers from grabing my email address.

#  This work is held in copyright as an unpublished work by
#  Silicon Graphics, Inc., 2006-2011.  All rights reserved.


# Specify the total number of cores for the PBS job including any hypertreads
CoreCounts="72"
#CoreCounts="48 24 72  96 12"
#CoreCounts="144 " # 120 96 72 48 24"


# Specify the total number of cores per node with/without hyperthreads
# Compute node with 12phys cores plus 12vthreads, set PPN=12 only using phys
# cores. If using phys cores plus hyperthreads set PPN=24.
PPN=24

# Specify the scratch location where the job will run on the compute node
# if a local drive exists on the compute node then use the /scratch file system
# for large jobs which are I/O bound.  A "./" will write to the current NFS directory.
SCRATCH_LOC="/nas/sshaw"

# Estimate the termination wallclock time in HH:MM:SS
EST_WALLCLOCK_HH_MM_SS="4:0:0"

# Specify the full path location of the Abaqus binary
# Path choices are:
#ABQ_BIN=/nas/sshaw/v614-1_x8664/6.14-1/code/bin/abq6141
#ABQ_BIN=/nas/sshaw/v613-2_x8664/6.13-2/code/bin/abq6132
#ABQ_BIN=/nas/sshaw/v613-1_x8664/6.13-1/code/bin/abq6131
ABQ_BIN=/nas/sshaw/v613-3_x8664/6.13-3/code/bin/abq6133

# Do you want to preserve the result files like *.prt,*.odb,*.stt,*.abq,*.res,*.sim?
# Unless the customer requests above files then set PRESERVE_RESULT_FILES=1 (true=yes)
# The above files can be GBs in size so the default is 0 (false=no)
PRESERVE_RESULT_FILES=0

# To specify additional group options like vnode or mem required for the job
# Valid options to pass are: ":vnode=[node]", ":mem=[mem in kb]" or "" for nothing
# Examples are: ":vnode=n031", ":mem=99197516kb" or "" for nothing
PBS_SELECT_GRP=""

# list the input file for each job seperated with a space ie. job1.inp job2.inp
#MASTER_INP="s2a.inp s4b.inp"
MASTER_INP="Block_Stud_28-84kn.inp "

# list the following include files below seperated with a space or by \
# examples:
#ADDITIONAL_BMARKFILES="ABQ_test_AFRAME.include ABQ_test_BC.include"
# Or the following is valid
#ADDITIONAL_BMARKFILES=" \
#   ABQ_test_AFRAME.include \
#   ABQ_test_BC.include "

ADDITIONAL_BMARKFILES=""

# list any additional abaqus support file needed to be part of the job
ABA_SUPPORT_FILES="abaqus_v6.env"

#PBS queue
#queue=f3067

#####################################################
##### do not modify anything below this comment line #####
#####################################################
TIMEFMT="--format=Elapsed: %e User: %U System: %S (U+S)/E: %P MaxRSS: %M"

Create_QUEFILE()
{
cat <<PBS > qs_aba_${NPES}c_${TCASE}
#!/bin/bash
#PBS -N Mercedes_${NPES}c
#PBS -l select=${NNODES}:ncpus=${PPN}:mpiprocs=${PPN}:sales_op=none
#PBS -l place=scatter:excl
#PBS -l walltime=${EST_WALLCLOCK_HH_MM_SS}
#PBS -j oe
#PBS -q f2601noHT

cd \${PBS_O_WORKDIR}

. /usr/share/modules/init/bash

module purge
module load intel-tools-13

ORIG_PBS_O_WORKDIR=\${PBS_O_WORKDIR}
NEW_PBS_O_WORKDIR=${SCRATCH_LOC}/\${PBS_JOBID}
# Create a new working directory
if [ ! -d "\${NEW_PBS_O_WORKDIR}" ]; then
mkdir -vp \${NEW_PBS_O_WORKDIR}
if [ \$? -ne 0 ]; then
echo -e "\nERR: failed to create new working directory, \${NEW_PBS_O_WORKDIR}. Exiting...\n"
exit
fi
fi

# Copy input & support files to new working directory
err_stat=0
for aba_file in ${MASTER_INP} ${ADDITIONAL_BMARKFILES} ${ABA_SUPPORT_FILES}
do
if [ -f \${aba_file} ]; then
cp -vp \${aba_file} \${NEW_PBS_O_WORKDIR}
if [ \$? -ne 0 ]; then
echo -e "\nERR:  An error occured while copying \${aba_file} file. \n"
err_stat=\$(( \${err_stat} + 1 ))
fi
else
echo -e "\nERR:  File \${aba_file} does not exist. \n"
err_stat=\$(( \${err_stat} + 1 ))
fi
done
if [ \${err_stat} -ne 0 ]; then
echo -e "\nFATAL ERROR: \${err_stat} failures occured during the copying of files. Exiting...\n"
exit
fi

# Set PBS working directory to new location
export PBS_O_WORKDIR=\${NEW_PBS_O_WORKDIR}

# Change directory to new location
cd \${PBS_O_WORKDIR}

#Run Abaqus
(/usr/bin/time "${TIMEFMT}" ${ABQ_BIN} j=${TCASE}_${comment} interactive  input=${INPFILE} cpus=${NPES} scratch='./' ) >& ${TCASE}_${comment}.log

# Cleanup and copy result files back to orignal PBS Wk dir
if [ ${PRESERVE_RESULT_FILES} ]; then
rm -f *.mdl *.pac *.prt *.odb *.sel *.stt *.abq *.res *.fil *.sim *023
fi
cp -p ${TCASE}_${comment}* \${ORIG_PBS_O_WORKDIR}
rm -vrf \${NEW_PBS_O_WORKDIR}

#
export PBS_O_WORKDIR=\${ORIG_PBS_O_WORKDIR}
cd \${PBS_O_WORKDIR}

PBS
}

DEPEND=""
dependcnt=0
NoJOBS=$( echo ${MASTER_INP} | wc -w )

echo -e "\nSubmitting ${NoJOBS} jobs to PBS Queue.\n"

for INPFILE  in ${MASTER_INP}
do
for NPES in ${CoreCounts}
do
dependcnt=$(( $dependcnt + 1))
NNODES=$(( ($NPES + $PPN - 1 ) / $PPN ))
comment=sgi_${NPES}c_\${PBS_JOBID}
TCASE=$( echo ${INPFILE} | cut -d'.' -f1 )
Create_QUEFILE
if [ $dependcnt -gt 2 ]; then
CMD="qsub ${DEPEND} qs_aba_${NPES}c_${TCASE}_gpu"
else
CMD="qsub  qs_aba_${NPES}c_${TCASE}"
fi
PrevJOBID=$( ${CMD} | cut -f1 -d'.' )
DEPEND="-W depend=afterany:${PrevJOBID}"
printf "Parameters passed:\n"
printf "\t    Num Cores: ${NPES}\n"
printf "\t   Cores/Node: ${PPN}\n"
printf "\t    Num Nodes: ${NNODES}\n"
printf "\t    PBS Queue: ${queue}\n"
printf "\t  Scratch Loc: ${SCRATCH_LOC}\n"
printf "\t Est Walltime: ${EST_WALLCLOCK_HH_MM_SS}\n"
printf "\t   Master INP: ${INPFILE}\n"
printf "\tAbaqus Binary: ${ABQ_BIN}\n"
printf "\tAbaqus Support Files: ${ABA_SUPPORT_FILES}\n"
printf "\t    Additional Files: ${ADDITIONAL_BMARKFILES}\n"
printf "\n"
done
dependcnt=0
done


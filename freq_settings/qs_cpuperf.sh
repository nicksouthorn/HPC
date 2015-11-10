#!/bin/bash
#PBS -N cpuperf
#PBS -l select=8:ncpus=24:mpiprocs=24
#PBS -l place=scatter:excl
#PBS -l walltime=1:0:0
#PBS -j oe
#PBS -q cae

cd ${PBS_O_WORKDIR}

. /usr/share/modules/init/bash
module load mpt

export OMP_NUM_THREADS=1
export MPI_DSM_DISTRIBUTE=

mpiexec_mpt -v  ./cpuperf_hsw_static -G 4 -i 50


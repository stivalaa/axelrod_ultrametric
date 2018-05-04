#!/bin/bash

#PBS -N compute_gamma_random_data
#PBS -q fast
#PBS -l nodes=1:ppn=16
#PBS -l walltime=1:0:0

cd $PBS_O_WORKDIR
set CONV_RSH = ssh

# OpenMP version, use all 16 cores on node
export OMP_NUM_THREADS=16

# PBS script to compute Murtagh gamma on 
# random data with same dimensions as Eurobaraometer tech fields
# ie q = 12 states (0,1,2,...11), F = 162 fieldw , n = 6000 forws
#

# this version generates its own  new random data  not saved data 

${HOME}/culture_evolution/scripts/generate_random_csv.py -q 12 -F 162 -n 6000 | time ${HOME}/culture_evolution/murtagh/murtagh_gamma

times


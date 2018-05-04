#!/bin/bash

#PBS -N compute_rammal_d_permuted_50samples_eurobarometer
#PBS -q fast
#PBS -l nodes=1
#PBS -l walltime=8:0:0

cd $PBS_O_WORKDIR
set CONV_RSH = ssh


Rscript scripts/compute_rammal_D_permuted.R

times


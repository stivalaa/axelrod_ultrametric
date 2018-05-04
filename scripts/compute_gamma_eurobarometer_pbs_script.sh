#!/bin/bash

#PBS -N compute_gamma_50samples_eurobarometer
#PBS -q fast
#PBS -l nodes=1:ppn=16
#PBS -l walltime=4:0:0

cd $PBS_O_WORKDIR
set CONV_RSH = ssh

# OpenMP version, use all 16 cores on node
export OMP_NUM_THREADS=16

# PBS script to compute Murtagh gamma on Eurobarometer data fields
# v180 through v341 (the science/technology opionno data)
#
# run from culture_evolution/ root directory (parent of scripts)

cat data/EuroBarometer/Eurobarometer1992analysis_50samples.csv |  cut -d, -f182-343 | time murtagh/murtagh_gamma

times


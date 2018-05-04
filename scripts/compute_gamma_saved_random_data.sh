#!/bin/bash

#PBS -N compute_gamma_random_saved_data
#PBS -q fast
#PBS -l nodes=1:ppn=16
#PBS -l walltime=4:0:0

cd $PBS_O_WORKDIR
set CONV_RSH = ssh

# OpenMP version, use all 16 cores on node
export OMP_NUM_THREADS=16

# PBS script to compute Murtagh gamma on Eurobarometer data fields
# v180 through v341 (the science/technology opionno data), 
# with colums randomly permuted
#
# run from culture_evolution/ root directory (parent of scripts)


#${HOME}/culture_evolution/scripts/generate_random_csv.py -q 12 -F 162 -n 6000 | time ${HOME}/culture_evolution/murtagh/murtagh_gamma

# use saved permuted data for reproducibility
time murtagh/murtagh_gamma < data/EuroBarometer/randomdata_500samples.csv

times


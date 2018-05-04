#!/bin/bash

#PBS -N axelrod_mpi_model_0
#PBS -q parallel
#PBS -l nodes=16:ppn=1
#PBS -l walltime=50:00:00

cd $PBS_O_WORKDIR
set CONV_RSH = ssh

# first example from http://ww2.cs.mu.oz.au/~pfauj/physicaa2012/
# exectute multiple simulation runs for each parameter setting for a max
# number of iterations as specified in main.py and record summary statistics
# at every specified iteration

time mpirun -np 16 python /home/stivalaa/culture_evolution/physicaa2012-python-mpi/src/axelrod/geo/expphysicstimeline/main.py /home/stivalaa/culture_evolution/physicaa2012-cpp-modified/model 25 125 500

times


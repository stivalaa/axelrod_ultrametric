#!/bin/bash

#PBS -N axelrod_random_euro_50samples_end_oddtheta
#PBS -l procs=16
#PBS -l walltime=400:00:00

cd $PBS_O_WORKDIR
set CONV_RSH = ssh

# derived from second example from http://ww2.cs.mu.oz.au/~pfauj/physicaa2012/
# exectute multiple simulation runs for each parameter setting until
# convergence and record summary statistics at end only
# This uses my modified version that inistaed of uniform random culture
# vector initialization it reads the Eurobaraometer data 
# as per Valori et al 2011 (see specially Supplmentary Information).

echo -n "started at: "; date

time  mpirun -np 16 --mca mpi_warn_on_fork 0 python ~/culture_evolution/physicaa2012-python-mpi/src/axelrod/geo/expphysicstimeline/main_oddtheta.py read_init_culture:${HOME}/culture_evolution/data/EuroBarometer/randomdata_50samples.csv ~/culture_evolution/physicaa2012-cpp-end-modified/model end


times
echo -n "ended at: "; date


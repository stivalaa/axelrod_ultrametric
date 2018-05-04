#!/bin/sh

# concatenate all the reults from each MPI task results?-ultrametricity.csv
# file into one file (results-ultrametricity.csv)
# with header as first line
# WARNING: clobbers results-ultrametricity.csv
# ADS 12Mar2013

if [ $# -ne 0 ]; then
  echo "usage: $0" >&2
  exit 1
fi

OUTFILE=results-ultrametricity.csv

echo 'n,m,F,phy_mob_a,beta_p,soc_mob_a,beta_s,r,s,tolerance,q,theta,init_random_prob,run,time,cophenetic_cc' > $OUTFILE

cat results/*/results?-ultrametricity.csv results/*/results??-ultrametricity.csv  results/*/results???-ultrametricity.csv >> $OUTFILE



#!/bin/sh

# concatenate all the reults from each MPI task into one file (results.csv)
# with header as first line
# WARNING: clobbers results.csv
# ADS 25Oct2012

if [ $# -ne 0 ]; then
  echo "usage: $0" >&2
  exit 1
fi

OUTFILE=results.csv

echo 'n,m,F,phy_mob_a,beta_p,soc_mob_a,beta_s,r,s,tolerance,q,theta,init_random_prob,run,time,avg_path_length,dia,avg_degree,cluster_coeff,corr_soc_phy,corr_soc_cul,corr_phy_cul,num_cultures,size_culture,overall_diversity,ass,num_components,largest_component,within_component_diversity,between_component_diversity,component_diversity_ratio,num_communities,largest_community,within_community_diversity,between_community_diversity,community_diversity_ratio,social_clustering,social_closeness,physical_closeness,overall_closeness,physicalStability,socialStability,culturalStability,num_culture_components' > $OUTFILE

cat results/*/results?.csv results/*/results??.csv results/*/results???.csv >> $OUTFILE



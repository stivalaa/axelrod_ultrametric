#!/bin/sh

# concatenate results( from collect_results.sh in each directory)
# from multiple "mode 1" (run to equilibrium/convergence "end") runs
# with header as first line
# output is to stdout
#
# Usage: collect_multi_end_results.sh directory-list
#
# list must be in label order: "real", "permuted", "random"
#
# ADS 04Feb2013

if [ $# -ne 3 ]; then
  echo "usage: $0 real_dir permuted_dir random_dir" >&2
  exit 1
fi


echo 'n,m,F,phy_mob_a,beta_p,soc_mob_a,beta_s,r,s,tolerance,q,theta,init_random_prob,run,time,avg_path_length,dia,avg_degree,cluster_coeff,corr_soc_phy,corr_soc_cul,corr_phy_cul,num_cultures,size_culture,overall_diversity,ass,num_components,largest_component,within_component_diversity,between_component_diversity,component_diversity_ratio,num_communities,largest_community,within_community_diversity,between_community_diversity,community_diversity_ratio,social_clustering,social_closeness,physical_closeness,overall_closeness,physicalStability,socialStability,culturalStability,num_culture_components,initial' 

for dir in $*
do
  if [ `expr "${dir}" : ".*init.*"` -ne 0 ]; then
    dirlabel="real"
  elif [ `expr "${dir}" : ".*permuted.*"` -ne 0 ]; then
    dirlabel="permuted"
  elif [ `expr "${dir}" : ".*random.*"` -ne 0 ]; then
    dirlabel="random"
  else
    dirlabel="UNKNOWN" # should not happen
  fi
  # for some reason there are ^M chars on end of results.csv lines, have to
  # remove them first (even though everythin done on UNIX)
  tr -d \\015 < "${dir}"/results.csv | awk -v FS=, -v OFS=, -v label="${dirlabel}" 'NR > 1 {print $0,label}'
done



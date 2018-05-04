#!/bin/sh

# concatenate results from build_culture_connected_compionents_results.py
# from multiple "mode 1" (run to equilibrium/convergence "end") runs
# with header as first line
# output is to stdout
#
# Usage: collect_culture_components_multi_end_results.sh csvfile-list
#
# list must be in label order: "real", "permuted", "random"
#
# ADS 04Feb2013

if [ $# -ne 3 ]; then
  echo "usage: $0 real_csvresults permuted_csvresults random_csvresults" >&2
  exit 1
fi



for csvfile in $*
do
  if [ `expr "${csvfile}" : ".*init.*"` -ne 0 ]; then
    csvlabel="real"
  elif [ `expr "${csvfile}" : ".*permuted.*"` -ne 0 ]; then
    csvlabel="permuted"
  elif [ `expr "${csvfile}" : ".*random.*"` -ne 0 ]; then
    csvlabel="random"
  else
    csvlabel="UNKNOWN" # should not happen
  fi
  # for some reason there are ^M chars on end of results.csv lines, have to
  # remove them first (even though everythin done on UNIX)
  tr -d \\015 < "${csvfile}" | awk -v FS=, -v OFS=, -v label="${csvlabel}" 'NR > 1 {print $0,label}'
done



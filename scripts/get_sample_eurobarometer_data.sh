#!/bin/sh
#
# File:    get_sample_eurobarometer_data.sh
# Author:  Alex Stivala
# Created: December 2012
#
# get_sample_eurobaraometer_data.sh - generate 500 random samples (rows) for
#                                     each country in the eurobaraometer data
#                                     set.
#
# Usage: get_sample_eurobarometer_data.sh [-s samplesize] Eurobarometer1992analysis.csv
#
# Input is read from suppleid filename and output is to stdout. 
# Uses scripts in this directory so they must be in PATH.
#
# Note input is from filename not stdin as we go through the file twice,
# first time extracts the country codes (rather than hardcoding them here)
# It is assumed the first line is header information (column labels) so
# is discarded.
# Actually we read the input file multiple times also, once for each country,
# just to make it easier since we have alrady abandoned use of stdin
#


# See Valori et al 2011 S.I.: max sample size is 500
DEFAULT_SAMPLE_SIZE=50

sample_size=$DEFAULT_SAMPLE_SIZE

while getopts 's:' opt
do
    case $opt in
    s) sample_size="$OPTARG"
    ;;
    ?)
    echo "Usage: $0 [-s samplesize] Eurobataometer1992analsysi.csv" >&2
    exit 1
    ;;
    esac
done
shift `expr $OPTIND - 1`

if [ $# -ne 1 ]; then
  echo "Usage: $0 [-s samplesize] Eurobataometer1992analsysi.csv" >&2
  exit 1
fi

infile=$1

# 2-characer country code is column 6
# note we combine countries with subdivisions denoted by '-' i.e.
# DE-E and DE-W are combined as is GB-NIR and GB-UK
for country in `awk "NR > 1" $infile | cut -d, -f6 | cut -d- -f1 | sort | uniq`
do
  # note use awk variable not shell variable to avoid shell/awk quoting nightmare
  echo $country >&2
  awk -F , -v awkcountry="${country}" 'substr($6, 1, 2) == awkcountry' $infile | sample_csv_rows.py $sample_size
done


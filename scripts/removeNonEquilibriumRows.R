#!/usr/bin/Rscript
#
# Remove rows from results that are at end (time > 0) but did not actually
# reach equilibrium.
# Necessary for old runs includings beta_s > 1 too slow to converge and
# also had original test for termination only on no change since last check
# rather than actual equilibrium test
#
# Usage:
#   Rscript removeNonEquilibriumRows.R infilename.csv outfilename.csv
#
# WARNING: overwites outfilename.csv 
#
# ADS 26March2013

args <- commandArgs(trailingOnly=TRUE)
in_filename <- args[1]
out_filename <- args[2]


D <- read.table(in_filename, header=TRUE, sep=",",stringsAsFactors=FALSE)

D <- subset(D, time == 0 | 
               within_community_diversity == 0 &
                   (between_community_diversity == 0 |
                    between_community_diversity == 1 |
                    between_community_diversity > theta) 
           )

write.csv(D, out_filename, row.names=FALSE, quote=FALSE)



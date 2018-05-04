#!/usr/bin/Rscript
#
# R script to compute the cophenetic correlation coefficient for supplied
# set of vectors CSV data on stdin
#
# Usage:
#
# Rscript compute_cophenetic_cc.R 
#
#
# Alex Stivala
# January 2013
#

#cophenetic correlation coefficient, given a dist object
cophenetic_cc <- function(d)
{
  # d is a dist object
  return( cor(d, cophenetic(hclust(d, method='single'))) )
}

# Hamming distance between all (row) vectors in a matrix
# Returns dist object
hamming_dist <- function(m)
{
  n <- dim(m)[1]
  F <- dim(m)[2]
  return( as.dist(outer(1:n, 1:n,
                  FUN = Vectorize(function(i, j) sum(m[i,] != m[j,]) / F))) )
}

#
# main
#
vecframe <- read.csv(file("stdin"), header=F)
d <- hamming_dist(as.matrix(vecframe)) 
cc <- cophenetic_cc(d) 
print(cc)



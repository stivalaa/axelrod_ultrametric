#!/usr/bin/Rscript
#
# File:    compute_ramal_D.R
# Author:  Alex Stivala
# Created: December 2012
#
# R script to compute the Rammal D measure of ultrametricity (Rammal et al 1985)
#
# Input is CSV on stdin, each row is a vector
#

vecdata <- read.csv(file("stdin"), header=FALSE)
vecdata_matrix <- as.matrix(vecdata)

n <- dim(vecdata_matrix)[1]
F <- dim(vecdata_matrix)[2]


# matrix of Hamming distances between each pair of vectors
dissimilarity_vecdata <- outer(1:n, 1:n,
                               FUN = Vectorize(function(i,j)
                                   sum(vecdata_matrix[i,] != vecdata_matrix[j,])
                                   )
                               )

# The Rammal D (actually fancy cursive D but can't type that) is a measure
# of the degree of distortion from the subdominant ultrametric.
# The latter is just the cophenetic distance from single linkage clustering
# (or equivalently the minimal spanning tree)
dissimilarity_vecdata_dist <- as.dist(dissimilarity_vecdata)
D_vecdata <- sum(dissimilarity_vecdata_dist -
                 cophenetic(hclust(dissimilarity_vecdata_dist,method='single'))
                 ) / sum(dissimilarity_vecdata_dist)

print(D_vecdata)

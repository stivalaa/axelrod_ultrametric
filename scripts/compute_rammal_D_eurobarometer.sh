#!/usr/local/R/2.14.1-gcc/bin/Rscript
#
# File:    compute_ramal_D.R
# Author:  Alex Stivala
# Created: December 2012
#
# R script to compute the Rammal D measure of ultrametricity (Rammal et al 1985)
#
# At the moment it is just hardcoded to read the Eurobarometer data and
# do computations on it
#


#euro <- read.csv('~/culture_evolution/data/EuroBarometer/Eurobarometer1992analysis_500samples.csv',header=FALSE)
euro <- read.csv('~/culture_evolution/data/EuroBarometer/Eurobarometer1992analysis_50samples.csv',header=FALSE)

# extracdt columns 182 through 343 (inclusive), the science/tech opionion
# data used in Valori et al 2011 (see S.I.)
euro_tech <- euro[,paste("V",182:343,sep="")]

F <- length(euro_tech)
n <- length(euro_tech$V182)

euro_tech_matrix <- as.matrix(euro_tech)


system.time(dissimilarity_euro_tech <- outer(1:n, 1:n, FUN = Vectorize(function(i,j) sum(euro_tech_matrix[i,] != euro_tech_matrix[j,])/F)))

# The Rammal D (actually fancy cursive D but can't type that) is a measure
# of the degree of distortion from the subdominant ultrametric.
# The latter is just the cophenetic distance from single linkage clustering
# (or equivalently the minimal spanning tree)
dissimilarity_euro_tech_dist <- as.dist(dissimilarity_euro_tech)
system.time(D_euro_tech <- sum(dissimilarity_euro_tech_dist - cophenetic(hclust(dissimilarity_euro_tech_dist,method='single'))) / sum(dissimilarity_euro_tech_dist) )

print(D_euro_tech)



#
# simulate_data.R - functions to genrated data with same correlations
#                   as given real data
#
# Alex Stivala
# July 2013
#

library(Hmisc)

# datafile: input csv opionoin data file 
# returns random opionin matrix
# with same covariance structure as input opinion data
gen_simulated_data <-function(datafile)
{
    opinionmatrix <- as.matrix(read.csv(datafile, header=FALSE))
    F <- ncol(opinionmatrix)
    N <- nrow(opinionmatrix)
    q <- max(opinionmatrix)
    r <- chol(cor(opinionmatrix))
    sim_opinionmatrix <- matrix(as.integer(
        cut2(t(t(r) %*% matrix(rnorm(N * F), nrow=F, ncol=N)),
             g=q)), ncol=F)
    return(sim_opinionmatrix)
}


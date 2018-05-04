# cultureComponentsGraph.R - function to build culture components graph
# 
# Alex Stivala
# May 2013

library(igraph)

# 
# buildCultureGraph() 
#
# given distance object (distances between opinion vectors in initital 
# conditions ie original opionin data, as returned by hamming_dist()
# in ultrametric.R), and theta value,
# return culture graph with threshold theta.
#
# The culture graph for a given value of theta is the graph wher any two
# cultures with similarity >= theta (ie distance < 1-theta) are connected
# by an edge.
#
buildCultureGraph<- function(dist, theta)
{
    distmatrix <- as.matrix(dist)
    stopifnot(nrow(dist) == ncol(dist))
    num_agents <- nrow(distmatrix)
    edges <- as.vector(t(which(distmatrix < 1- theta, arr.ind=TRUE)))
    # on some (but not all, on the systems I am using) version of igraph,
    # the node numbering is 0-based, but on others it seems to be
    # 1-based. If it is 0-based, then
    # 1 is subtracted from edges vector to make graphis igraph node  
    # numbering is 0-based not 1-based like R usuaully is
    # simplify is just to remove loops (self-edges)
    zero_or_one = 0
    test_g <- graph(edges=c(1,2,2,3))
    if (length(V(test_g)) == 4) {
       # this version of igraph uses 0-based vertex numberingg
#       print('igraph is using 0-based node indexing')
       zero_or_one = 1 # so we have to subtract 1 from our node ids
    }
    else if (length(V(test_g)) == 3) {
       # this versino of igraph uses 1-based vertex numbering
#       print('igraph is using 1-based node indexing')
       zero_or_one = 0 # so we do not subtract 1
    }
    else {
      stopifnot(TRUE) # somethign very wrong with igraph, shouldn't happen
    }

    g <- simplify(graph(edges - zero_or_one, directed=FALSE, n=num_agents))
    return( g )
}



# 
# buildCultureGraphDataFrame() 
#
# given distance object (distances between opinion vectors in initital 
# conditions ie original opionin data, as returned by hamming_dist()
# in ultrametric.R),  return data frame
# with number of culture graph components, clustering coefficient etc.
# for differetn values of the culture similarity threshold theta
#
# The culture graph for a given value of theta is the graph wher any two
# cultures with similarity >= theta (ie distance < 1-theta) are connected
# by an edge.
#
buildCultureGraphDataFrame <- function(dist)
{
    num_agents <- attr(dist, "Size")
    f <-data.frame()
    for (theta in seq(0.0, 1.0, 0.01)) {
      g <- buildCultureGraph(dist, theta)
      comps <- decompose.graph(g)
      cluster_coeffs <- sapply(comps, FUN = function(x) transitivity(x, type='global'))
      mean_cluster_coeff <- mean(cluster_coeffs[is.finite(cluster_coeffs)])
      local_cluster_coeffs <- unlist(sapply(comps, FUN = function(x) transitivity(x, type='local')))
      mean_local_cluster_coeff <- mean(local_cluster_coeffs[is.finite(local_cluster_coeffs)])
      f <- rbind(f, c(theta, length(comps), length(comps)/num_agents, mean_cluster_coeff, transitivity(g, type='global'), mean_local_cluster_coeff))

    }
    names(f) <- c('theta','num_components', 'normalized_num_components', 'mean_cluster_coeff', 'global_cluster_coeff', 'mean_local_cluster_coeff')
    return( f )
}


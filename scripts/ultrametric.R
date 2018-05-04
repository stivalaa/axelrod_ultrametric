# R functions for computing indices of ultrametricity

# Alex Stivala
# January 2013

library(clue)


# Rammal D index (deviation frmo subdominant ultrametric) given a distance object
rammal_D <- function(d) 
{
  # d is  a dist object
  return( sum(d - cophenetic(hclust(d, method='single'))) / sum ( d) )
}


# deviation from best fit ultrmatric, given  a distance object
fitultra_deviation <- function(d)
{
  #(could take a long time to compute, does heuristic minimization)
  d_ultra <- ls_fit_ultrametric(d) 

  return( sum(d - d_ultra ) / sum(d) )

}

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


# Permute all columns. NB each column permuted with it own random permutation,
# permuting all columns the same can be done with  just
# m[,sample(ncol(m))]
permute_columns <- function(m)
{
  apply(m, 1, FUN = function(v) v[sample(length(v))])
}


# Pearson correlation with best fit ultrmatric, given  a distance object
fitultra_cc <- function(d)
{
  #(could take a long time to compute, does heuristic minimization)
  d_ultra <- ls_fit_ultrametric(d) 

  return( cor(d, d_ultra) )
}



# Run the murtagh_gamma C program to compute Murtagh's gamma index,
# given a data frame (each row is a vector)
murtagh_gamma <- function(dataframe)
{
  gamma_program <- paste(Sys.getenv("HOME"), "/culture_evolution/murtagh/murtagh_gamma", sep='')
  tmpfilename <- tempfile()
  write.table(dataframe, tmpfilename, row.names=FALSE, col.names=FALSE, sep=',')
  #output <- shell(paste(gamma_program, "<", tmpfilename), mustWork=TRUE, intern=TRUE)
  output <- system(paste(gamma_program, "<", tmpfilename),  intern=TRUE)
  mgamma <- as.numeric(unlist(strsplit(output[1], '='))[2])
  #print( output)
  unlink(tmpfilename)
  return ( mgamma )
}


# Run the count_ultrametric_triangles C program to count ultrametric
# (isocelees and equilateral) triangles, given a data frame
# (each row is a vector)
# (Note the program is multitrheaded using OpenMP so OMP_NUM_THREADS
# environemtn vairable can be used to determine number of threads it can use)
#
# Parmeters:
#   dataframe - data frame with each row a vector
# Return value:
#   named list with 2 elements:
#      ultrametric_triangle_fraction - fraction of triangles that are
#                                      ultrametric (equillateral or isoceles)
#      isoceles_triangle_fraction - fraction of triangles that are isoceles
count_ultrametric_triangles <- function(dataframe)
{
  trianglecount_program <- paste(Sys.getenv("HOME"), "/culture_evolution/murtagh/count_ultrametric_triangles", sep='')
  if (!file.exists(trianglecount_program)) {
      trianglecount_program <- '/cygdrive/c/Users/stivalaa/Documents/culture_evolution/murtagh/count_ultrametric_triangles'#XXX
  }
  tmpfilename <- tempfile()
  write.table(dataframe, tmpfilename, row.names=FALSE, col.names=FALSE, sep=',')
  output <- system(paste(trianglecount_program, "<", tmpfilename),  intern=TRUE)
  ultrafrac <- as.numeric(unlist(strsplit(grep("^ultrametric_triangle_fraction =",output, value=TRUE), '='))[[2]])
  isofrac <- as.numeric(unlist(strsplit(grep("^isoceles_tri_fraction =",output, value=TRUE), '='))[[2]])
  unlink(tmpfilename)
  return (list(ultrametric_triangle_fraction = ultrafrac,
               isoceles_triangle_fraction = isofrac))
}


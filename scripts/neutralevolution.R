# Alex Stivala
# January 2013


#
# Neutral evolution from an initial vector to 2^power2 vectors as rows in matrix
#
# Arguments:
#   c0 - initial integer vector
#   q  - possible range of each element (0:(q-1))
#   cmatrix - initial matrix (usually NULL for caller)
#   power2 - 2^power2 rows will be generated
#   p1 - probability of a mutation in one element at each step (left subtree)
#   p2 probability of a mutation in one element at each step (right subtree)

#
evolve <- function(c0, q, cmatrix, power2, p1, p2) 
{
	if (power2 == 0) {
		return   ( rbind(cmatrix, c0) )
	}
	else {
		c1 <- c0
		c2 <- c0
		if (runif(1) < p1) {
			i <- sample(1:length(c0), 1)
			c1[i] <- sample(0:(q-1), 1)
		}
		if (runif(1) < p2) {
			j <- sample(1:length(c0), 1)
			c2[j] <- sample(0:(q-1), 1)
		}
		return (rbind(cmatrix, evolve(c1, q, cmatrix, power2-1, p1, p2),
						evolve(c2, q, cmatrix, power2-1, p2, p2)))
	}
}


# Change each element in the matrix m to a random value in 0:(q-1)
# with probability p
perturb <- function(m, q, p)
{
  apply(m, c(1,2), FUN = function(x) { if (runif(1) < p) sample(0:(q-1), 1)
                                        else x } )
}



#
# Neutral evolution from an initial vector to 2^power2 vectors as rows in matrix
#
# Arguments:
#   c0 - initial integer vector
#   q  - possible range of each element (0:(q-1))
#   cmatrix - initial matrix (usually NULL for caller)
#   power2 - 2^power2 rows will be generated
#   k - max number of elements to randomly chagne each step
#
evolve2 <- function(c0, q, cmatrix, power2, k) 
{
	if (power2 == 0) {
		return   ( rbind(cmatrix, c0) )
	}
	else {
		c1 <- c0
		c2 <- c0
		for (s in 1:k) {
			i <- sample(1:length(c0), 1)
			c1[i] <- sample(0:(q-1), 1)
		}
		for (s in 1:k) {
			j <- sample(1:length(c0), 1)
			c2[j] <- sample(0:(q-1), 1)
		}
		return (rbind(cmatrix, evolve2(c1, q, cmatrix, power2-1, k),
						evolve2(c2, q, cmatrix, power2-1, k)))
	}
}


#
# Create set of culture vectors based on k initial prototypes,
# by radomly changing small enough fraction of traits so that new
# vectors are close to a (randomly chosen) prototype vector
#
# Arguments:
#    F - vector dimension
#    q - number of values a trait can take (integer 0..q-1)
#    n - number of vectors to create (total including k prototypes)
#    k - number of prototypes
#    t - max number of traits to mutate frmo prototype for new vector
#
# Returns vectors as rows in a matrix # (prototypes are first k rows)
#
prototype_evolve <- function(F, q, n, k, t)
{
  stopifnot(t < F)
  cmatrix <- NULL
  # create k prototypes as first k rows
  for (i in 1:k) {
    cmatrix <- rbind(cmatrix, sample(0:(q-1), F, replace=TRUE))
  }

  # create the rest of the vectors by choosing a prototype and making
  # a new vector with up to t of its traits mutated
  for (i in 1:(n-k)) {
    prototype <- cmatrix[sample(1:k, 1), ]
    cnew <- prototype
		for (s in 1:t) {
			j <- sample(1:F, 1)
			cnew[j] <- sample(0:(q-1), 1)
		}
    cmatrix <- rbind(cmatrix, cnew)
  }
  return(as.matrix(cmatrix))
}




#
#   Create set of culture vectors that are perfectly ultrametric,
#   by generating orthognal vectors (and their multiples)
#   of dimension F, so that it generates (q-1)*F vectors, and 
#   then randomly sample n of these (without replacement).
#   Note that therefore must have n <= (q-1)*F
#  
#   They are perfectly ultrametric (wrt Hamming distance)
#   but it is something of a trivial
#   case in that each vector only has 2 traits different between
#   each other vector (so Hamming distance is always 2 between any
#   pair of vectors)
#
#   Arguments:
#      F - vector dimension
#      q - number of values a trait can take (integer 0..q-1)
#      n - number of vectors to create 
#  
#    Return value:
#      list of n vectors that satisfy ultrametric inequality
#
trivial_ultrametric <- function(F, q, n) {
  stopifnot(n <= (q-1)*F)
  vmatrix <- matrix(data=0, nrow=(q-1)*F, ncol=F)
  rowidx <- 1
  for (i in 1:(q-1)) {
    for (j in 1:F) {
      vmatrix[rowidx, j] <- i
      rowidx <- rowidx + 1
    }
  }
  return (vmatrix[sample.int(nrow(vmatrix), size=n, replace=FALSE),])
}



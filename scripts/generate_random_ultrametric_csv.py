#!/usr/bin/env python
##############################################################################
#
# generate_random_ultrametric.py - generate uniform random integer vectors
#                              that all satisfy ultrametric inequality
#
# File:    generate_random_ultrametric.py
# Author:  Alex Stivala
# Created: December 2013
#
##############################################################################

"""

 
Generate a CSV file of specified number of rows and columns with random
integer values in specified number of possibilties, keeping ultrametric
inequalty true.

Usage:
    generate_random_ultrametric.py -q states -F columns -n rows

    -q specifies the number of possible values of each field (0,1,2...q-1)
    -F specifies the number of columns
    -n specirifes the number of rows


NB this is a very crude naive method that just generates uniform random
vectors then checks that the ultrametric inequality 
d(x,y) <= max{d(x,z), d(z,y)}
is satisified for the new vector and all vectors currently in the pool,
and if not just gets another random vector and tries again
Hence all vectors have to be kept in memory until end and incredibly
inefficient, time to check increasing with each new vector.

"""

import sys
import getopt
import random
import csv
import numpy
from time import localtime,strftime


#-----------------------------------------------------------------------------
#
# Functions
#
#-----------------------------------------------------------------------------

def hamming_dist(u, v):
    """
    Calculate Hamming distance between vectors u and v

    Parmaeters:
        u - numpy vector
        v - numpy vector

    Return value:
       Hamming distance between u and v (number of elements that differ)
    """
    return (numpy.count_nonzero(u != v))
                 
#-----------------------------------------------------------------------------
#
# main
#
#-----------------------------------------------------------------------------

def usage(progname):
    """
    print usage msg and exit
    """
    sys.stderr.write("usage: " + progname + " -q states -F cols -n rows\n")
    sys.exit(1)

def main():
    """
    See usage message in module header block
    """
   
    F = None
    q = None
    n = None

    try:
        opts,args = getopt.getopt(sys.argv[1:], "q:F:n:")
    except:
        usage(sys.argv[0])
    for opt,arg in opts:
        if opt == '-q':
          q = int(arg)
        elif opt == '-F':
          F = int(arg)
        elif opt == '-n':
          n = int(arg)
        else:
          usage(sys.argv[0])

    if len(args) != 0:
        usage(sys.argv[0])

    if q == None or F == None or n == None:
        sys.stderr.write('must specify all of -q -F -n\n')
        usage(sys.argv[0])

    sys.stderr.write("%s start\n"
                     %(strftime("%d%b%Y-%H:%M:%S", localtime())))
    pool= []
    pool.append([random.randrange(0, q) for k in xrange(F)])
    csv.writer(sys.stdout).writerow(pool[0])
    num_tested = 1
    num_accepted = 1
    num_duplicate = 0
    
    while num_accepted < n:
        newvector = numpy.array([random.randrange(0, q) for k in xrange(F)])
        num_tested += 1
        if num_tested % 100000 == 0:
            sys.stderr.write("%s num_tested = %d, num_accepted = %d\n"
                             %(strftime("%d%b%Y-%H:%M:%S", localtime()),
                               num_tested,num_accepted))
        all_satisfied = True
        duplicate = False
        for s in xrange(len(pool)):
            if numpy.array_equal(newvector, pool[s]):
              duplicate = True
              num_duplicate += 1
              break
            for t in xrange(s, len(pool)):
                d1 = hamming_dist(newvector, pool[s])
                d2 = hamming_dist(newvector, pool[t])
                d3 = hamming_dist(pool[s], pool[t])
                if not (d1 <= max(d2,d3) and d2 <= max(d1,d3) and d3 <= max(d1,d2)):
                    all_satisfied = False
                    break
            if not all_satisfied:
                break
        if all_satisfied and not duplicate:
            #sys.stderr.write("%d %d %d\n"%(d1,d2,d3))#XXX
            pool.append(newvector)
            num_accepted += 1
            csv.writer(sys.stdout).writerow(newvector)
            #sys.stderr.write("ACCEPTED %d\n" %(num_accepted))
            sys.stdout.flush()

    sys.stderr.write("%s end num_tested = %d, num_duplicate = %d, num_accepted = %d (%f%%)\n" %
                       (strftime("%d%b%Y-%H:%M:%S", localtime()),
                        num_tested, num_duplicate, num_accepted,
                        float(num_accepted) / float(num_tested)*100))
        

if __name__ == "__main__":
    main()



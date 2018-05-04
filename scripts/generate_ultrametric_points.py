#!/usr/bin/env python
##############################################################################
#
# generate_ultrametric_pointspy - generate points that satify ultrametric
#                                 inequality
#
# File:    generate_random_ultrametric.py
# Author:  Alex Stivala
# Created: January 2014
#
##############################################################################

"""

 
Generate a CSV file of specified number of columns (vector dimension F) with
integer values in specified number of possibilties (q), keeping ultrametric
inequalty true, by generating orthognal vectors (and their multiples)
of dimension F, so that it generates (q-1)*F vectors

Usage:
    generate_random_ultrametric.py -q states -F columns 

    -q specifies the number of possible values of each field (0,1,2...q-1)
    -F specifies the number of columns
"""

import sys
import getopt
import csv


                 
#-----------------------------------------------------------------------------
#
# main
#
#-----------------------------------------------------------------------------

def usage(progname):
    """
    print usage msg and exit
    """
    sys.stderr.write("usage: " + progname + " -q states -F cols\n")
    sys.exit(1)

def main():
    """
    See usage message in module header block
    """
   
    F = None
    q = None


    try:
        opts,args = getopt.getopt(sys.argv[1:], "q:F:")
    except:
        usage(sys.argv[0])
    for opt,arg in opts:
        if opt == '-q':
          q = int(arg)
        elif opt == '-F':
          F = int(arg)
        else:
          usage(sys.argv[0])

    if len(args) != 0:
        usage(sys.argv[0])

    if q == None or F == None:
        sys.stderr.write('must specify all of -q -F\n')
        usage(sys.argv[0])

    for i in xrange(1,q):
        for j in xrange(F):
            v = F*[0]
            v[j] = i
            csv.writer(sys.stdout).writerow(v)

if __name__ == "__main__":
    main()



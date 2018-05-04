#!/usr/bin/env python
##############################################################################
#
# generate_random_csv.py - Generate CSV with random values
#
# File:    generate_random_csv.py
# Author:  Alex Stivala
# Created: December 2012
#
##############################################################################

"""
Generate a CSV file of specified number of rows and columns with random
integer values in specified number of possibilties.

Usage:
    generate_random_csv.py -q states -F columns -n rows

    -q specifies the number of possible values of each field (0,1,2...q-1)
    -F specifies the number of columns
    -n specirifes the number of rows
    
"""

import sys
import getopt
import random
import csv


#-----------------------------------------------------------------------------
#
# Functions
#
#-----------------------------------------------------------------------------

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
    
    for i in xrange(n):
        csv.writer(sys.stdout).writerow([random.randrange(0, q) for k in xrange(F)])

        

if __name__ == "__main__":
    main()

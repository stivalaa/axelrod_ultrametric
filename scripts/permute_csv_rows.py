#!/usr/bin/env python
##############################################################################
#
# permute_csv_rows.py - Randomly Permute rows of a CSV file
#
# File:    permute_csv_rows.py
# Author:  Alex Stivala
# Created: December 2012
#
##############################################################################

"""
Read a CSV file from stdin and write to stdout with the rows randomly
permuted. (Note each column is permuted separately with its own random
permutation, not the same one applied to each column.)
That is (possibly misleading script name), it does NOT just shuffle the
rows in a CSV file: in each column, the values are permuted ranomdly
with a different random permutation in each column.

NB unlke permute_csv_columns (which works on any data),
this assumes values are integers as it converts to numpy array
to do transpose.

Usage:
    permute_csv_rows.py < input.csv 
    
"""

import sys
import io
import getopt
import csv
import numpy

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
    sys.stderr.write("usage: " + progname + " < input.csv\n");
    sys.exit(1)

def main():
    """
    See usage message in module header block
    """
    
    try:
        opts,args = getopt.getopt(sys.argv[1:], "")
    except:
        usage(sys.argv[0])
    for opt,arg in opts:
        usage(sys.argv[0])

    if len(args) != 0:
        usage(sys.argv[0])

    A = numpy.genfromtxt(io.open(sys.stdin.fileno(), "rb"), dtype='i8', delimiter=',')

    # tricky (dodgy?): A and tranpose(A) are the same data, random.shuffle()
    # is in-place so value of map(...) is irrelevaltn, and both A and B
    # are shuffled - but because we shuffled values in rows of transpose(A),
    # that shuffles values in columns of A.
    Atranspose = numpy.transpose(A)
    map(numpy.random.shuffle, Atranspose)

    csvwriter = csv.writer(sys.stdout)
    map(csvwriter.writerow, A)
    
if __name__ == "__main__":
    main()

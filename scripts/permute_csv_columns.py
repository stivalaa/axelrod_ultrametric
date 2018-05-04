#!/usr/bin/env python
##############################################################################
#
# permute_csv_columns.py - Randomly Permute columns of a CSV file
#
# File:    permute_csv_columns.py
# Author:  Alex Stivala
# Created: December 2012
#
##############################################################################

"""
Read a CSV file from stdin and write to stdout with the columns randomly
permuted. (Note each row is permuted separately with its own random
permutation, not the same one applied to each row.)

Usage:
    permute_csv_columns.py < input.csv 
    
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

    csvwriter = csv.writer(sys.stdout)
    
    for row in csv.reader(sys.stdin):
        random.shuffle(row)
        csvwriter.writerow(row)
    
if __name__ == "__main__":
    main()

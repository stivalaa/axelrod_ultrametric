#!/usr/bin/env python
##############################################################################
#
# sample_csv_rows.py - simple random sample of rows in a CSV file 
#
# File:    sample_csv_rows.py
# Author:  Alex Stivala
# Created: December 2012
#
##############################################################################

"""
Read a CSV file from stdin and write to stdout a simple random sample of
a given size (no replacement) of the rows in the input

Usage:
    sample_csv_rows.py n < input.csv 
    
    n is the size of the sample
    
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
    sys.stderr.write("usage: " + progname + " n < input.csv\n");
    sys.stderr.write("   n is the size of the sample\n");
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

    if len(args) != 1:
        usage(sys.argv[0])

    n = int(args[0])

    
    csv.writer(sys.stdout).writerows(random.sample(list(csv.reader(sys.stdin)), n))
    
if __name__ == "__main__":
    main()


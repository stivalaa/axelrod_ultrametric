#!/usr/bin/env python
##############################################################################
#
# build_culture_connected_components_results.py - build CSV with results on
#                                               connected components of
#                                               culture similaraity graph
#
# File:    build_culture_connected_components_results.py
# Author:  Alex Stivala
# Created: December 2012
#
#
# This script now only needed on older output runs since (as of 21Feb2013)
# added num_culture_components to normal rseults.csv output as a new column
#
##############################################################################

"""
Reads .C CSV output results files from axelrod model output and computes
culture similarity graph for initial cultures to find connected components
(at the value of theta for that data)

Usage:
    build_culture_connected_components_results.py results_root_dir

    results_root_dir is root of axelrod model run results directory

Output is to stdout

Example:
    build_culture_connected_component_results.py /vlsci/VR0261/stivalaa/axelrod_theta_eurobarometer_50samples_permuted1_end_mpi/results
    
    
"""

import sys
import getopt
import csv
import glob
import os
import itertools
from numpy import array
import igraph

sys.path.append( os.path.join(os.path.abspath(os.path.dirname(sys.argv[0])).replace('/scripts',''), 'physicaa2012-python-mpi','src','axelrod','geo') )
import hackmodel


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
    sys.stderr.write("usage: " + progname + " resultsdir\n");
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

    resultsdir= args[0]

    run = 0    # .S (and .C etc.) files only written on run=0
    F = None   # obtained from size of culture vectors read from .S files
    
    # get value of m (lattice size) by reading from the results0.csv file
    firstrow = list(itertools.islice(csv.reader(open(glob.glob(os.path.join(resultsdir, '*', 'results0.csv'))[0])),1))[0]
    m = int(firstrow[1])

    sys.stdout.write('n,m,F,beta_p,beta_s,q,theta,init_random_prob,run,time,num_culture_components\n')
    csvwriter = csv.writer(sys.stdout)

    # example filename format:
    #results/600/results15-n600-q12-beta_p10-beta_s1-theta0.2-init_random_probNone-430000000.S
    
    sfiles = glob.glob(os.path.join(resultsdir, '*', 
                'results*-n*-q*-beta_p*-beta_s*-theta*-init_random_prob*-*.S'))
    for sfile in sfiles:
        sfilename = os.path.splitext(os.path.basename(sfile))[0]
        splitname = sfilename.split('-')
        modelmpirank = int(splitname[0][len('results'):])# not needed just check
        n = int(splitname[1][1:])
        q = int(splitname[2][1:])
        beta_p = int(splitname[3][len('beta_p'):])
        beta_s = int(splitname[4][len('beta_s'):])
        theta = float(splitname[5][len('theta'):])
        try:
            init_random_prob = float(splitname[6][len('init_random_prob'):])
        except ValueError:
            init_random_prob = 'NA'
        time = int(splitname[7])


        # read in .S csv file, build culture graph with
        # edges where culture similarity  >=  theta

        cultures = []
        for row in csv.reader(open(sfile)):
            culture_vector = array([int(x) for x in row[1][1:-1].split()])
            cultures.append(culture_vector)
            if F == None:
                F = len(culture_vector)
            else:
                assert len(culture_vector) == F
 
        culture_graph = igraph.Graph(len(cultures))
        culture_graph.add_edges(
              [(i, j) for i in xrange(len(cultures)) for j in xrange(i)
                  if hackmodel.similarity(cultures[i], cultures[j]) >= theta] )
        normalized_num_components = float(len(culture_graph.components())) / n

        csvwriter.writerow([n,m,F,beta_p,beta_s,q,theta,init_random_prob,run,time,normalized_num_components])


if __name__ == "__main__":
    main()


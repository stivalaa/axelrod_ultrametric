#  Copyright (C) 2011 Jens Pfau <jpfau@unimelb.edu.au>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# modified by ADS to use MPI and seed srand with time+pid and to also 
# ensure unique tmp files so safe for parallel execution with MPI Python
# NB this involved extra command line pameter to model to not compatible
# with unmodified versions

import os, re, glob, sys
from random import randrange, random
from igraph import Graph, ADJ_UNDIRECTED
from numpy import array, nonzero, zeros
from stats import ss, lpearsonr, mean



import time

#import model
import hackmodel

import csv
import commands
import ConfigParser

# location of R scripts to run
SCRIPTPATH = os.path.abspath(os.path.dirname(sys.argv[0])) + '/../../../../../scripts'

# Randomly draw one element from s based on the distribution given in w.
def randsample(s,w):
    cum = 0.0
    randTmp = random() * sum(w)
    
    for i in range(len(w)):
        cum += w[i]
        if randTmp <= cum:
            return s[i]






# Calculates the assortativity for the given graph.
def assortativity(graph, degrees=None):
    if degrees is None: degrees = graph.degree()
    degrees_sq = [deg**2 for deg in degrees]

    m = float(graph.ecount())
    
    if m == 0:
        return 0
    
    num1, num2, den1 = 0, 0, 0
    for source, target in graph.get_edgelist():
        num1 += degrees[source] * degrees[target]
        num2 += degrees[source] + degrees[target]
        den1 += degrees_sq[source] + degrees_sq[target]

    num1 /= m
    den1 /= 2*m
    num2 = (num2 / (2*m)) ** 2

    if (den1 - num2) == 0:
        return 0

    return (num1 - num2) / (den1 - num2)


# Returns a culture-dependent membership vector of the nodes in vector c and
# the number of cultures found overall among agents in c.
def cultures_in(C,c):
    # Label all nodes with their culture, whereby agents with the same culture
    # get the same label
    vertex_label = list([0]*len(c))
    
    cultures = list()
    
    vertex_label[0] = 0
    cultures.append(C[c[0]])
    current_label = 1
    for i in range(1,len(c)):        
        prev = -1
        for j in range(i):
            if len(nonzero(C[c[i]]-C[c[j]])[0]) == 0:
                prev = j
                break
        if prev >= 0:
            vertex_label[i] = vertex_label[prev]
        else:
            vertex_label[i] = current_label
            cultures.append(C[c[i]])
            current_label = current_label + 1
    
    
    # The number of cultures can be determined by the current pointer to the
    # label to be assigned next
    return vertex_label, current_label, cultures

# Calculates the diversity within those agents' cultures in C that are given in
# the list cluster.
def calcDiversityOfCluster(C, cluster):
    n = len(cluster)
    
    diversity = 0.0
    for i in range(n):
        for j in range(i):
            diversity += 1.0 - hackmodel.similarity(C[cluster[i]], C[cluster[j]])
    
    if n == 1:
        return 0.0
    else:
        return diversity / (n*(n-1)/2)


# Calculates the modal/prototype culture among the group of agents in C that is
# determined by the list cluster.
def calcModal(C, cluster, F, q):
    M = zeros((F, q))
    
    modal = array([0] * F)
    
    for i in range(len(cluster)):
        for j in range(F):
            M[j, C[cluster[i]][j]] += 1
    
    for i in range(F):
        max = 0
        maxJ = 0
        for j in range(q):
            if M[i,j] > max:
                maxJ = j
                max = M[i,j]
            modal[i] = maxJ
            
    return modal


# Calculates the within-cluster and between-cluster diversity as well as
# the within-/-between-cluster diversity ratio and the mapping of cluster size
# to diversity of the clusters given in the list clusters, whose cultures are
# defined in C.
def calcDiversity(C, clusters, F, q):
    wcd = 0.0
    modals = list()
    size_x_div = list()
   
    for i in range(len(clusters)):
        div = calcDiversityOfCluster(C, clusters[i])
        wcd += div
        modals.append(calcModal(C, clusters[i], F, q))
        size_x_div.append([len(clusters[i]), div])
        
    wcd = wcd / len(clusters)
    bcd = calcDiversityOfCluster(modals, range(len(modals)))
    
    if wcd == 0.0 or wcd == float('nan'):
        diversity_ratio = float('nan')
    else:
        diversity_ratio = bcd / wcd
    
    return wcd, bcd, diversity_ratio, size_x_div
    

# Calculates the Pearson correlation between two list, left and right.
def calcCorrelation(network, left, right):
    if network and ss(left) != 0 and ss(right) != 0 and max(left) != 0 and max(right) != 0:
        return lpearsonr(left,right)[0]
    else:
        return float('nan')    


# Calculate cophenetic correlation coefficient (runs external R script -
# easier than getting r2py to work)
def calc_cophenetic_cc(C):
    """
    Calcualte cophenetic correlation coefficient
    Parameters:
       C - list of numpy.array vectors
    Return value:  
       cophnetic correlation coefficient

    Expects output of R script to be a single line like:
 
    cophenetic_cc =  0.4546
    """
    tmpcsvfile = os.tempnam()
    csv.writer(open(tmpcsvfile, 'w')).writerows(C)
    r_out = os.popen('Rscript ' + SCRIPTPATH + '/' + 'compute_cophenetic_cc.R ' +
                     tmpcsvfile, 'r')
    cc = None
    for line in r_out:
        sline = line.split()
        if len(sline) == 3 and sline[0] == 'cophenetic_cc':
            try:
                cc = float(sline[2])
            except ValueError:
                cc = float('NaN')
    r_out.close()
    os.unlink(tmpcsvfile)
    return cc


# Calculate the number of connected components in the culture graph at
# value of theta, i.e. the graph where any two cultures with similarity
# >= theta are connected by an edge
def calcCultureNumComponents(cultures, theta, n):
    """
    Calculate the number of connected components in the culture graph at
    value of theta, i.e. the graph where any two cultures with similarity
     >= theta are connected by an edge

    Parametrs:
       cultures - list of numpy.array vectors
       theta - value of culture similarity threshold theta
       n - number of agents

    Return value:  
      Number of connected components in culture graph with edges
      when similarity >= theta (normalized by dividing by number of agens)
      nb also must have similarity > 0 since that is required for any
      interaction in Axelrod model
    """
    assert(len(cultures) == n)
    culture_graph = Graph(len(cultures))
    culture_graph.add_edges(
            [(i, j) for i in xrange(len(cultures)) for j in xrange(i)
                if (hackmodel.similarity(cultures[i], cultures[j]) >= theta
                     and hackmodel.similarity(cultures[i], cultures[j]) > 0.0) ]
                           )
    normalized_num_components = float(len(culture_graph.components())) / n
    return normalized_num_components


# Gets all relevant statistics about the graph, about culture and location of agents
# and writes this information to a file.
def writeStatistics(statsWriter, F, phy_mob_a, phy_mob_b, soc_mob_a, soc_mob_b,
                    r, s, t, q, theta, init_random_prob, run, G, L, C, m, toroidal, network, timestep=-1, lastG = None, lastL = None, lastC = None,
                    componentClusterWriter = None, communityClusterWriter = None, cultureClusterWriter = None, ultrametricWriter =None, correlation = False, differences = None, noise = -1):
    n = G.vcount()
    
    if init_random_prob == None:
        init_random_prob = "NA"

    pre = [n, m, F, phy_mob_a, phy_mob_b, soc_mob_a, soc_mob_b, r, s, t, q, theta, init_random_prob, run]
    
    if noise != -1:
        pre.append(noise)    
    
    if timestep != -1:
        pre.append(timestep)     
    
    # Calculate graph metrics
    first = time.clock()
    avg_path_length = G.average_path_length(unconn=False)
    print 'path length: ', time.clock() - first
    
    first = time.clock()
#    if correlation:
#        dia = G.diameter()
#    else:
#        dia = float('nan')
    dia = float('nan')
    print 'diameter: ', time.clock() - first
    #den = float(G.ecount())/(n*(n-1)/2)
    
    first = time.clock()
    avg_degree = mean(G.degree(range(n)))
    print 'avg degree: ', time.clock() - first
    
    first = time.clock()
    cluster_coeff = G.transitivity_undirected()
    print 'cluster: ', time.clock() - first
    
    first = time.clock()
    ass = assortativity(G)
    print 'assortativity: ', time.clock() - first
    
    first = time.clock()
    # Calculate correlation between different spaces
    if correlation:
        k = 0
        physical = [0] * (n*(n-1)/2)
        social = [0] * (n*(n-1)/2)
        culture = [0] * (n*(n-1)/2)
        for i in range(n):
            for j in range(i):
                physical[k] = 1.0 - hackmodel.distance(L[i], L[j], m, toroidal)[1]
                social[k] = G.es[G.get_eid(i,j)]["weight"] if G.are_connected(i,j) else 0
                culture[k] = hackmodel.similarity(C[i], C[j])
                k = k+1
        
        corr_soc_phy = calcCorrelation(network, social, physical)
        corr_soc_cul = calcCorrelation(network, social, culture)
        corr_phy_cul = calcCorrelation(network, physical, culture)  
    else:
        corr_soc_phy = float('nan')
        corr_soc_cul = float('nan')
        corr_phy_cul = float('nan')
    print 'correlation: ', time.clock() - first
        
    first = time.clock()
    # Find the cultural clustering and the number of cultures
    vertex_label, num_cultures, cultures = cultures_in(C, range(n))
    
    num_cultures = float(num_cultures) / n
    
    overall_diversity = calcDiversityOfCluster(C, range(n))
 
    
    # The size of the largest culture can be determined by finding the
    # vertex label that appears most often
    size_culture = 0
    for i in range(len(vertex_label)):
        if vertex_label.count(i) > size_culture:
            size_culture = vertex_label.count(i)
    
    size_culture = float(size_culture) / n   
    print 'cultures: ', time.clock() - first
    
    first = time.clock()
    # Calculate components etc
    if network:
        components = G.components()
        num_components = float(len(components)) / n
        
        largest_component = float(max(components.sizes())) / n
        
        if G.ecount() > 0:
            communities = G.community_fastgreedy(weights="weight")
#            num_communities = float(len(communities)) / n
            num_communities = float(len(communities.as_clustering())) / n
            largest_community = float(max(communities.as_clustering().sizes())) / n 
            communities = communities.as_clustering()
        else:
            communities = [[x] for x in range(n)] 
            num_communities = 1.0
            largest_community = 1.0 / n
            
        
        # calculate intra-component diversity 
        within_component_diversity, between_component_diversity, component_diversity_ratio, component_size_x_div = calcDiversity(C, components, F, q)
                    
            
        # calculate intra-community diversity
        within_community_diversity, between_community_diversity, community_diversity_ratio, community_size_x_div = calcDiversity(C, communities, F, q)
        
           
        
        if componentClusterWriter != None:
            for tmp in component_size_x_div:
                componentClusterWriter.writerow(pre + tmp)        

        if communityClusterWriter != None:
            for tmp in community_size_x_div:
                communityClusterWriter.writerow(pre + tmp)
        
        if cultureClusterWriter != None:
            accounted_for = set([])
            for i in range(len(vertex_label)):
                if vertex_label[i] not in accounted_for:
                    cultureClusterWriter.writerow(pre + [vertex_label.count(vertex_label[i])])
                    accounted_for.add(vertex_label[i])               

        if ultrametricWriter != None:
            # calculate degree of ultrametricity of the culture vectors
            cophenetic_cc = calc_cophenetic_cc(C)
            ultrametricWriter.writerow(pre + [cophenetic_cc])


        
        # Calculate social clustering of culture as the modularity of the network
        # based on cultural membership
        if G.ecount() > 0:
            social_clustering = G.modularity(vertex_label, weights="weight")
        else:
            social_clustering = float('nan')
            
        social_closeness = 0.0
        overall_closeness = 0.0                      
            
    else:
        num_components = float('nan')
        largest_component = float('nan')
        num_communities = float('nan')
        largest_community = float('nan')
        within_component_diversity = float('nan')
        within_community_diversity = float('nan')
        between_component_diversity = float('nan')
        between_community_diversity = float('nan')
        component_diversity_ratio = float('nan')
        community_diversity_ratio = float('nan')
        social_clustering = float('nan')
        overall_closeness = float('nan')
        social_closeness = float('nan')
        overall_closeness = float('nan')  
    print 'communities: ', time.clock() - first       
    

    physical_closeness = 0.0  
    
    # indices 0 - 9
    stats = [avg_path_length, dia, avg_degree, cluster_coeff, corr_soc_phy, corr_soc_cul, corr_phy_cul, num_cultures, size_culture, overall_diversity, ass]    
    
    # indices 10 - 12
    stats = stats + [num_components, largest_component, within_component_diversity, between_component_diversity, component_diversity_ratio]
    
    # indices 13 - 15
    stats = stats + [num_communities, largest_community, within_community_diversity, between_community_diversity, community_diversity_ratio]
    
    # indices 16 - 19
    stats = stats + [social_clustering, social_closeness, physical_closeness, overall_closeness]
    
    
    
    physicalStability = 0.0
    socialStability = 0.0
    culturalStability = 0.0
    
    first = time.clock()
    if lastG is not None:
        
        for i in range(n):
            physicalStability += 1 - hackmodel.distance(L[i], lastL[i], m, toroidal)[1]
            culturalStability += hackmodel.similarity(C[i], lastC[i])
            
            for j in range(i):        
                socialStability += 1.0 - abs((G.es[G.get_eid(i,j)]["weight"] if G.are_connected(i,j) else 0)
                                       - (lastG.es[lastG.get_eid(i,j)]["weight"] if lastG.are_connected(i,j) else 0))   
        
        physicalStability = physicalStability / n
        culturalStability = culturalStability / n
        socialStability = socialStability / (n*(n-1)/2)    
    print 'stability: ', time.clock() - first
                
        
    stats = stats + [physicalStability, socialStability, culturalStability]

    first = time.clock()
    num_culture_components = calcCultureNumComponents(C, theta, n)
    print 'culture components:', time.clock() - first

    stats += [num_culture_components]
            
    # Add distribution over cultural differences in every step
    if differences is not None:
        stats += differences
            
    
    if statsWriter != None:
        statsWriter.writerow(pre + stats)

    return stats







# Write a given degree distribution to a file.
def writeHist(dir, fname, d, n):
    f = open(os.path.join(dir, fname + '.hist'), 'w')
    writer = csv.writer(f)
    writer.writerow(d)
    f.close()
    
    
    
    
    
# Write the network, culture and location of agents to a file.    
def writeNetwork(G, L, C, dir, fname):
    # Write adjacency matrix of graph with weights
    G.write(os.path.join(dir , fname + '.adj'), format="adjacency", attribute="weight", default=0.0)
    
    # Write the locations of agents
    f = open(os.path.join(dir, fname + '.L'), 'wb')
    writer = csv.writer(f)
    
    for i in range(len(L)):
        writer.writerow(L[i])
    
    f.close()
    
    # Write the culture of agents
    f = open(os.path.join(dir, fname + '.C'), 'wb')
    writer = csv.writer(f)
    
    for i in range(len(C)):
        writer.writerow(C[i])
    
    f.close()
    
    # Write the present cultures
    f = open(os.path.join(dir, fname + '.S'), 'wb')
    writer = csv.writer(f)

    i = 0
    for c in cultures_in(C, range(G.vcount()))[2]:
        writer.writerow([i, c])
        i = i+1
    f.close()    
    

# Determines the svn revisions for all files in this working copy
# and write this information to the provided configuration file.   
def findRevisions(config, path):
    config.add_section('revisions')
    for file in [x for x in index(path) if 'svn' not in x and 'pyc' not in x]:
        #out = commands.getoutput('svn info ' + file)
        #revMatch = re.search('Revision: ([0-9.-]*)', out)
        out = commands.getoutput('cd ' + path + '; git log --oneline ' + file + '|head -1')
        revMatch = re.search('^([0-9a-fA-F]+)', out)
        fileMatch = re.search('[\S]*(\/axelrod\/[\S]*)', file) 
        if revMatch != None:
            config.set('revisions', fileMatch.group(1), revMatch.group(1))
        else:
            config.set('revisions', fileMatch.group(1), 'n/a')
 
 
    
# Lists all files in the directory recursively.  
def index(directory):
    # like os.listdir, but traverses directory trees
    stack = [directory]
    files = []
    while stack:
        directory = stack.pop()
        for file in os.listdir(directory):
            fullname = os.path.join(directory, file)
            files.append(fullname)
            if os.path.isdir(fullname) and not os.path.islink(fullname):
                stack.append(fullname)
    return files


# Determines the diff between the working copy and the latest svn revision
# for all files in this project.
def findDiffs(path, outpath):
    out = commands.getoutput('svn diff ' + path)
    file = open(outpath + 'svn.diff', 'w')
    file.write(out)
    file.close()



# Loads agents' locations, cultures, and the social network from files in
# the directory given by the argument path.
def loadNetwork(path, network = True, end = False):   
    L = list()
    reader = csv.reader(open(path + '.L'))                
    for row in reader:
        L.append((int(row[0]), int(row[1])))
    
    C = list()
    reader = csv.reader(open(path + '.C'))          
    for row in reader:
        C.append(array([int(x) for x in row]))
        
    if end:    
        infile = open(path + '.Tend', "r")
        tend = infile.readline()
    else:
        tend = 0
        
    if network:
        G = Graph.Read_Adjacency(path + '.adj', attribute="weight", mode=ADJ_UNDIRECTED)
    else:
        G = Graph(len(C))        
    if G.ecount() == 0:
        G.es["weight"] = []        
        
    
    if os.path.exists(path + '.D') and os.path.isfile(path + '.D'):
        reader = csv.reader(open(path + '.D'))
        for row in reader:
            D = [int(x) for x in row]

    else:
        D = None
        
    
    return G, L, C, D, tend
        
    
    
# Runs the C++ version of the model.
def modelCpp(G,L,C,tmax,n,m,F,q,r,s,toroidal,network,t,directedMigration,
             phy_mob_a, phy_mob_b, soc_mob_a, soc_mob_b, modelpath,
             r_2, s_2, phy_mob_a_2, phy_mob_b_2, soc_mob_a_2, soc_mob_b_2, modelCallback = None, noise = -1, end = False, k = 0.01, theta = 0.0,
             no_migration = False):
    
    if toroidal: 
        toroidalS = '1'
    else:
        toroidalS = '0'
        
    if network: 
        networkS = '1'
    else:
        networkS = '0'         
        
    if directedMigration: 
        directedMigrationS = '1'
    else:
        directedMigrationS = '0'

    tmpdir = os.tempnam(None, 'exp')
    os.mkdir(tmpdir)
    writeNetwork(G, L, C, tmpdir, 'tmp')
    
    # If all cells are occupied, there cannot need to be any migration
    if n == m*m:
        s = 0.0

    if no_migration:  # if no_migration is set, disable migration 
        s = 0.0
    
    options = [tmax,n,m,F,q,r,s,toroidalS,networkS,t,directedMigrationS,
               phy_mob_a, phy_mob_b, soc_mob_a, soc_mob_b, 
               r_2, s_2, phy_mob_a_2, phy_mob_b_2, soc_mob_a_2, soc_mob_b_2, k,
               tmpdir + '/' + 'tmp', theta]
    
    if noise != -1:
        options.append(noise)
        
    
    if modelCallback is not None:
        f = open(tmpdir + '/tmp.T', 'wb')
        writer = csv.writer(f)
        writer.writerow([len(modelCallback.call_list)])
        writer.writerow(modelCallback.call_list)        
        f.close()        
        #options += modelCallback.call_list            
    
    first = time.clock()
    output = commands.getoutput(modelpath + ' ' + ' '.join([str(x) for x in options]))
    print output
    print 'model: ', time.clock() - first
    
    if modelCallback is not None:
        for iteration in modelCallback.call_list:
            if iteration != tmax:
                G2, L2, C2, D2, tmp = loadNetwork(tmpdir + '/tmp-' + str(iteration), network, end = False)
                if D2 is not None:
                    modelCallback.call(G2, L2, C2, iteration, D2)
                else:
                    modelCallback.call(G2, L2, C2, iteration)
    
    G2, L2, C2, D2, tend = loadNetwork(tmpdir + '/tmp', network, end = end)    
    
    for filename in glob.glob(os.path.join(tmpdir, "*")):
        os.remove(filename)
    os.rmdir(tmpdir)
    
    if D2 is not None:
        return G2, L2, C2, D2
    elif end:
        return G2, L2, C2, tend
    else:
        return G2, L2, C2, tmax
    
    
    

        

#    # Run single runs for drawing networks
#    for n in n_list:
#        G = Graph(n)     
#    
#        # Set random positions of agents
#        L = list()
#        for i in range(n):
#            while True:
#                x = (randrange(m), randrange(m))
#                if x not in L:
#                    L.append(x)
#                    break
#       
#        G.es["weight"] = []
#          
#        for (r,s) in rs_list:         
#            for t in t_list:                 
#                for q in q_list:
#                    # Create culture vector for all agents
#                    C = [array([randrange(q) for k in range(F)]) for l in range(n)]
#                    
#                    # Run the model                  
#                    if cppmodel is not None:
#                        G2, L2, C2 = modelCpp(G.copy(),list(L),C,tmax,n,m,F,q,r,s,toroidal,network,t,
#                                              directedMigration,phy_mob_a, phy_mob_b, soc_mob_a, soc_mob_b, cppmodel)                                                             
#                    else:     
#                        G2, L2, C2 = model.model(G.copy(),list(L),C,tmax,m,r,s,toroidal,network,
#                                               phy_mob_a, phy_mob_b, soc_mob_a, soc_mob_b,t,directedMigration)                    
#                                   
#                    
#                    # Print network and write out statistics
#                    file = 'results-n' + str(n) + '-r' + str(r) + '-s' + str(s) + '-t' + str(t) + '-q' + str(q)
#                    writeNetwork(G2,L2,C2,dir + str(n) + '/', file)
     
            
        

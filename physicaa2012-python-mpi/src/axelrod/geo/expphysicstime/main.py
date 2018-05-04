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

# TODO FIXME merge MPI and theta changes from expphysicstimeline/main.py into here
import sys
import os
sys.path.append( os.path.abspath(os.path.dirname(sys.argv[0])).replace('/expphysicstime','') )

from numpy import array
from igraph import Graph
from random import randrange

import lib
#import model
import csv
import ConfigParser
import commands



class ModelCallback:
    def __init__(self, time_list, dir, filename):
        self.call_list = time_list
        self.filename = filename   
        self.dir = dir
        
    def call(self, G, L, C, iteration):
        # Print network and write out statistics                    
        lib.writeNetwork(G,L,C, self.dir, self.filename + '-' + str(iteration))        
        
            
          


def writeConfig(scriptpath, runs, dir, tmax, F, m, toroidal, network, 
             beta_p_list, beta_s_list, 
             n_list, q_list, 
             directedMigration, cppmodel = None, time_list = None):
    # Write out current configuration       
    for n in n_list:
        if not os.path.exists(dir + str(n)):
            os.mkdir(dir + str(n))
            
        # Save the diff between the current working copy and the latest svn revision
        lib.findDiffs(scriptpath, dir + str(n) + '/')

        # Write out the parameters for this experiment
        config = ConfigParser.RawConfigParser()
        
        # Determine the svn revisions of all files and write them into the config file
        lib.findRevisions(config, scriptpath)

        # Write out all parameters
        config.add_section('paras')
        if cppmodel is not None:
            config.set('paras', 'cpp', commands.getoutput(cppmodel + ' -v'))
        else:
            config.set('paras', 'cpp', False)
        config.set('paras', 'runs', str(runs))
        config.set('paras', 'tmax', str(tmax))
        config.set('paras', 'F', str(F))
        config.set('paras', 'm', str(m))
        config.set('paras', 'toroidal', str(toroidal))
        config.set('paras', 'network', str(network))
        config.set('paras', 'beta_p_list', ','.join([str(x) for x in beta_p_list]))
        config.set('paras', 'beta_s_list', ','.join([str(x) for x in beta_s_list]))        
        config.set('paras', 'n', str(n))
        config.set('paras', 'directed_migration', str(directedMigration))
        config.set('paras', 'q_list', ','.join([str(x) for x in q_list]))
        if time_list is not None:
            config.set('paras', 'time_list', ','.join([str(x) for x in time_list]))
        config.write(open(dir + str(n) + '/' + 'parameter.cfg', 'wb'))   
      





def scenario(scriptpath, dir, tmax, F, m, toroidal, network, 
             beta_p_list, beta_s_list, 
             n_list, q_list, time_list,
             directedMigration=True, cppmodel = None):   
    
    if cppmodel is not None:
        print "Using c++ version with ", cppmodel
    else:
        print "Using python version"
    
    if not os.path.exists(dir):
        os.mkdir(dir)       
      
  
    writeConfig(scriptpath, 0, dir, tmax, F, m, toroidal, network, 
             beta_p_list, beta_s_list,
             n_list, q_list, 
             directedMigration, cppmodel, time_list)
    
 
                     
    for n in n_list:
    
        # Create the graph
        G = Graph(n)
        G.es["weight"] = []
        
        # Set random positions of agents
        startL = [(x,y) for x in range(m) for y in range(m)]
        L = list()
        for j in range(n):
            idx = randrange(len(startL))
            L.append(startL[idx])
            del startL[idx]
        
        # Create the file into which statistics are written
        file = open(dir + str(n) + '/results.csv', 'w')
        statsWriter = csv.writer(file)
            
        for q in q_list:
            for beta_p in beta_p_list:
                for beta_s in beta_s_list:                                 
                    
                    filename = 'results-n' + str(n) + '-q' + str(q) + '-beta_p' + str(beta_p) + '-beta_s' + str(beta_s)
                    graphCallback = ModelCallback(time_list, dir + str(n) + '/', filename)   
                    
                    # Create culture vector for all agents
                    C = [array([randrange(q) for k in range(F)]) for l in range(n)]
                                            
                    print n, beta_p, beta_s, q
                    
                    # Create culture vector for all agents
                    C = [array([randrange(q) for k in range(F)]) for l in range(n)]
                    
                    # Run the model
                    G2, L2, C2, tend = lib.modelCpp(G.copy(),list(L),C,tmax,n,m,F,q,1,1,toroidal,network,-1,
                                          directedMigration, 1, beta_p, 1, beta_s, cppmodel,
                                          1, 1, 1, beta_p, 1, beta_s, graphCallback)                                                             
    
                    # Print network and write out statistics                    
                    lib.writeNetwork(G2,L2,C2,dir + str(n) + '/', filename + '-' + str(tmax))
                    
                    # Get statistics for this run
                    lib.writeStatistics(statsWriter,F, 1, beta_p, 1, beta_s,1,1,-1,q,0,G2,L2,C2,m,toroidal,network, correlation=False)      
        

        file.close()
              




if __name__ == '__main__':   

    try:
        import psyco
        #psyco.log()
        psyco.full()
    except ImportError:
        print "Psyco not installed or failed execution."

    # Find the path to the source code
    scriptpath = os.path.abspath(os.path.dirname(sys.argv[0])).replace('/geo/expphysicstime', '/')     
         
    try:
        import psyco
        #psyco.log()
        psyco.full()
    except ImportError:
        print "Psyco not installed or failed execution."    

    # Find the path to the source code
    scriptpath = os.path.abspath(os.path.dirname(sys.argv[0])).replace('/geo/expphysicstime', '/')     
  

    q_list = [2,3,5,8,10,15,20,25,30,35,40,50,70,100] 

  
    beta_p_list = [10]#[10]#[1, 10, 100]
    beta_s_list = [1,5,10]
    

    tmax = 100000000
    time_list = [0, 5000, 10000, 20000, 50000, 100000, 500000, 1000000, 2000000, 5000000, 10000000]

    m = 25
    F = 5

    
    directedMigration = True
    
    cppmodel = None
    
    n_list = []    
    
         
    for arg in sys.argv[1:]:
        if arg == 'undirected':
            directedMigration = False   
            print 'Undirected/Random migration'
                      
        elif arg.isdigit():
            n_list.append(int(arg))


        else:
            cppmodel = arg
            if not os.path.isfile(cppmodel):
                print 'Model executable not found.'
                sys.exit()        
            
    if n_list == None:
        print 'Please provide n values'
        sys.exit()
        
    if cppmodel == None:
        print 'Model executable not found.'
        sys.exit()  
    
    scenario(scriptpath, 'results/', tmax, F, m, False, True,
                                      beta_p_list, beta_s_list, 
                                      n_list, q_list, time_list, directedMigration, 
                                      cppmodel)            

    
    
    
    
    


    
    

 

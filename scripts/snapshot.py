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

import matplotlib
matplotlib.use("Agg")

from igraph import Graph, ADJ_UNDIRECTED

from numpy import array

import csv, commands, random, os


def loadNetwork(path):   
  L = list()
  reader = csv.reader(open(path + '.L'))                
  for row in reader:
      L.append((int(row[0]), int(row[1])))

  C = list()
  reader = csv.reader(open(path + '.C'))          
  for row in reader:
      C.append(array([int(x) for x in row]))
      
      
  G = Graph.Read_Adjacency(path + '.adj', attribute="weight", mode=ADJ_UNDIRECTED)
  if G.ecount() == 0:
      G.es["weight"] = []        
	  
  return G, L, C


def header(f):
  f.write('\\documentclass{minimal}\n \
    \\usepackage[utf8x]{inputenc}\n \
    \\usepackage{graphicx}\n \
    \\usepackage{tikz}\n \
    \\usetikzlibrary{trees,positioning}\n \
    \\usetikzlibrary{matrix,fit,backgrounds,shadows}\n \
    \\usetikzlibrary{shapes.geometric}\n \
    \\definecolor{c1}{rgb}{0.89, 0.10, 0.11}\n \
    \\definecolor{c2}{rgb}{0.30, 0.38, 0.76}\n \
    \\definecolor{c3}{rgb}{0.20, 0.65, 0.48}\n \
    \\definecolor{c4}{rgb}{0.35, 0.64, 0.33}\n \
    \\definecolor{c5}{rgb}{0.56, 0.33, 0.64}\n \
    \\definecolor{c6}{rgb}{0.87, 0.33, 0.22}\n \
    \\definecolor{c7}{rgb}{1.00, 0.75, 0.00}\n \
    \\definecolor{c8}{rgb}{0.96, 0.97, 0.20}\n \
    \\definecolor{c9}{rgb}{0.67, 0.44, 0.13}\n \
    \\definecolor{c10}{rgb}{0.79, 0.33, 0.45}\n \
    \\definecolor{c11}{rgb}{1.00, 0.60, 0.85}\n \
    \\definecolor{c12}{rgb}{0.60, 0.60, 0.60}\n \
    \\tikzstyle{background}=[shape=rectangle,rounded corners,\n \
			    fill=blue!10,semitransparent,\n \
			    draw=blue!100,\n \
			    inner sep=0.04cm]\n \
    \\tikzstyle{agents}=[shape=circle,inner sep=0.08cm,shade,drop shadow={opacity=0.2,shadow xshift=.2ex,shadow yshift=-.2ex}]\n \
    \\begin{document}\n \
    \\thispagestyle{empty} \
    \\begin{tikzpicture}[transform shape] \
    \\\pgfmathparse{rnd}')

    #\\tikzstyle{background}=[shape=ellipse,\n \
			    #fill=c12!10,semitransparent,\n \
			    #draw=c12!100,\n \
			    #inner sep=0.01cm]\n \
    
    
# Set1 extrapolated    
#"#E41A1C"  rgb(89%,10%,11%)
#"#4C61C2"  rgb(30%,38%,76%)
#"#33A67A"  rgb(20%,65%,48%)
#"#58A254"  rgb(35%,64%,33%)
#"#8F54A3"  rgb(56%,33%,64%)
#"#DD5339"  rgb(87%,33%,22%)
#"#FFC000"  rgb(100%,75%,0%)
#"#F6F834"  rgb(96%,97%,20%)
#"#AB7022"  rgb(67%,44%,13%)
#"#CA5472"  rgb(79%,33%,45%)
#"#FF98DA"  rgb(100%,60%,85%)
#"#999999"  rgb(60%,60%,60%)
     
    


    
def footer(f):
  f.write('\\end{tikzpicture}\n \
    \\end{document}\n')
    
def agents(f,cultures,location,colours):
  for i in range(len(cultures)):
    x = location[i][0] * 0.3
    y = (50 - location[i][1]) * 0.3
    f.write('\\node (' + str(i) +') [agents,top color=white!80!' + str(cultures[i]) + ', bottom color=' + str(cultures[i]) + '!100, draw=black!75] at (' + str(x) + ',' + str(y) + ') {};\n')
    
def background(f,G,communities):
  
  f.write('\\begin{pgfonlayer}{background}\n')
  
  # L = 25
  f.write('\\draw [step=0.3,lightgray,very thin] (0,7.8) grid (7.2,15) ;\n')
  
  # L = 50
  #f.write('\\draw [step=0.3,lightgray,very thin] (0,0.3) grid (14.7,15) ;\n')
  
#  for i in range(len(communities)):
  for i in range(len(communities.as_clustering())):
    nodes = ''
#    for j in range(len(communities[i])):
    for j in range(len(communities.as_clustering()[i])):
#      nodes = nodes + ' ('+ str(communities[i][j]) +')'
      nodes = nodes + ' ('+ str(communities.as_clustering()[i][j]) +')'
    f.write('\\node [background, fit=' + nodes + '] {};\n')
	
	
  for i in range(len(G.get_edgelist())):
    if random.random() < 0.5:
      bending = 'left'
    else:
      bending = 'right'
    f.write('\\draw[line width=' + str(G.es[i]["weight"]*0.5+0.1) + 'pt,draw=black!100] (' + str(G.get_edgelist()[i][0]) + ') to[bend '+ bending +'] (' + str(G.get_edgelist()[i][1]) + ');\n')

  f.write('\\end{pgfonlayer}\n')



def snapshot(dataPath, dataFile):
  f = open('./snapshot.' + dataFile + '.tex', 'w')

  G, location, culture = loadNetwork(dataPath + dataFile)
  
  colours=['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12']
 
  cultures = {}
  
  n = G.vcount()    
  
  culture_labels = list([0]*n)       
      
  current_label = len(cultures)
      
  for i in range(0,n):      
      if str(culture[i]) in cultures:
	  culture_labels[i] = cultures[str(culture[i])]
      else:	  
	  culture_labels[i] = current_label
	  cultures[str(culture[i])] = current_label
	  current_label += 1
	  
  communities = G.community_fastgreedy(weights="weight")
  
  header(f)
  
  for c in xrange(len(culture_labels)):
    #f.write('\\xdefinecolor{' + str(c) + '}{hsb}{\pgfmathresult, 1.0, 1.0}\n')
    
    f.write('\\edef\R{\pdfuniformdeviate 255}')
    f.write('\\edef\G{\pdfuniformdeviate 255}')
    f.write('\\edef\B{\pdfuniformdeviate 255}')
    f.write('\\xdefinecolor{' + str(c) + '}{RGB}{\R,\G,\B}')

  
  agents(f,culture_labels,location,colours)
  background(f,G,communities)    
  footer(f)
  
  f.close()
  
# can't get all these packages installed/working, do it manually on PC
#  print commands.getoutput('latex snapshot.' + dataFile + '.tex')
#  print commands.getoutput('dvips snapshot.' + dataFile + '.dvi')
#  print commands.getoutput('ps2pdf -dEPSCrop snapshot.' + dataFile + '.ps')
#  print commands.getoutput('pdfcrop snapshot.' + dataFile + '.pdf')
#  print commands.getoutput('mv snapshot.' + dataFile + '-crop.pdf ../img/snapshot.' + dataFile + '.pdf')

  #print commands.getoutput('pdf2ps snapshot.tmp-crop.pdf')
  #print commands.getoutput('mv snapshot.tmp-crop.ps ../img/snapshot.eps')

if __name__ == '__main__':
  #if not os.path.exists('../img'):
  #  os.makedirs('../img')  

  snapshot('/vlsci/VR0261/stivalaa//axelrod_new_theta_initprototype_equilibrium_F100_n125/results/125/','results2-n125-q100-beta_p10-beta_s1-theta0.5-init_random_prob0.0-0')
  snapshot('/vlsci/VR0261/stivalaa//axelrod_new_theta_initprototype_equilibrium_F100_n125/results/125/','results2-n125-q100-beta_p10-beta_s1-theta0.5-init_random_prob0.0-500000')

  #snapshot('/vlsci/VR0261/stivalaa//axelrod_theta_initneturalevolution0_mpi/results/125/','results4-n125-q100-beta_p10-beta_s10-theta0.0-init_random_prob0.0-0')
  #snapshot('/vlsci/VR0261/stivalaa//axelrod_theta_initneturalevolution0_mpi/results/125/','results4-n125-q100-beta_p10-beta_s10-theta0.0-init_random_prob0.0-100000000')

  #n=500 social links too dense, makes a mess
  #snapshot('/vlsci/VR0261/stivalaa/axelrod_theta_initneturalevolution0_mpi/results/500/','results4-n500-q100-beta_p10-beta_s10-theta0.0-init_random_prob0.0-0')
  #snapshot('/vlsci/VR0261/stivalaa/axelrod_theta_initneturalevolution0_mpi/results/500/','results4-n500-q100-beta_p10-beta_s10-theta0.0-init_random_prob0.0-100000000')

  #snapshot('/home/stivalaa/axelrodtest_theta_randominit0_mpi/results/125/','results22-n125-q15-beta_p10-beta_s10-theta0.0-100000000')
  #snapshot('../data-snapshot/', 'results-n100-q2-beta_p10-beta_s5-10000000')
  #snapshot('../data/', 'results-n125-q3-beta_p10-beta_s10-10000000')
  #snapshot('../data/new/125/', 'results-n125-q100-beta_p10-beta_s1-100000')
  #snapshot('../data/new/125/', 'results-n125-q2-beta_p10-beta_s10-10000000')
  #snapshot('../data/new/125/', 'results-n125-q2-beta_p10-beta_s10-1000000')
  #snapshot('../data/new/125/', 'results-n125-q2-beta_p10-beta_s10-2000000')
  #snapshot('../data/new/125/', 'results-n125-q2-beta_p10-beta_s10-5000000')
  #snapshot('../data/new/125/', 'results-n125-q3-beta_p10-beta_s10-10000000')
  #snapshot('../data/new/125/', 'results-n125-q40-beta_p10-beta_s1-100000')
  #snapshot('../data/new/125/', 'results-n125-q40-beta_p10-beta_s1-500000')
  #snapshot('../data/new/125/', 'results-n125-q40-beta_p10-beta_s1-50000')
  #snapshot('../data/new/125/', 'results-n125-q50-beta_p10-beta_s1-100000')
  #snapshot('../data/new/125/', 'results-n125-q50-beta_p10-beta_s1-50000')
  #snapshot('../data/new/125/', 'results-n125-q70-beta_p10-beta_s1-500000')


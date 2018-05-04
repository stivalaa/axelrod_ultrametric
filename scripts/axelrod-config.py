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
  f.write('\\documentclass[final,3p,times]{elsarticle}\n \
    \\usepackage[utf8x]{inputenc}\n \
    \\usepackage{graphicx}\n \
    \\usepackage{tikz}\n \
    \\usetikzlibrary{trees,positioning,fadings,patterns}\n \
    \\usetikzlibrary{matrix,fit,backgrounds,arrows,shadows,decorations.pathreplacing}\n \
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
    \\tikzstyle{agents1}=[shape=circle,inner sep=0.08cm,shade,drop shadow={opacity=0.2,shadow xshift=.2ex,shadow yshift=-.2ex}]\n \
    \\tikzstyle{agents2}=[shape=diamond,inner sep=0.07cm,shade,drop shadow={opacity=0.2,shadow xshift=.2ex,shadow yshift=-.2ex}]\n \
    \\tikzstyle{agents3}=[shape=rectangle,inner sep=0.113cm,shade,drop shadow={opacity=0.2,shadow xshift=.2ex,shadow yshift=-.2ex}]\n \
    \\tikzstyle{features}=[shape=rectangle,minimum size=0.3cm,rounded corners=1.5,shade, top color=white,bottom color=blue!50!black!20, draw=blue!40!black!60,drop shadow={opacity=0.2,shadow xshift=.2ex,shadow yshift=-.2ex}]\n \
    \\tikzstyle{featuresfaded}=[dashed,shape=rectangle,minimum size=0.3cm,rounded corners=1.5,shade, top color=white,bottom color=blue!50!black!20, draw=blue!40!black!60,drop shadow={opacity=0.2,shadow xshift=.2ex,shadow yshift=-.2ex}]\n \
    \\begin{document}\n \
    \\thispagestyle{empty}\n \
    \\begin{tikzfadingfrompicture}[name=fade right]\n \
    \\shade[left color=transparent!100, right color=transparent!30,shading=axis,shading angle=45] (0.1,-2) grid (4,3.2);\n  \
    \\end{tikzfadingfrompicture}\n \
    \\begin{tikzpicture}\n \
    \\\pgfmathparse{rnd}\n')
    
    #shade=ball, inner color=white,outer color=blue!50!black!20, draw=blue!40!black!60
    

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
    
def agents(f,culture_labels,location,colours,cultures):
  # Draw lattice
  for i in range(len(culture_labels)):
    x = 0.4+location[i][0] * 0.4
    y = 0.4+(location[i][1]) * 0.4
    f.write('\\node (' + str(i) +') [agents' + str(culture_labels[i]+1) + ',top color=white!80!c' + str(culture_labels[i]+1) + ',bottom color=c' + str(culture_labels[i]+1) + '!100,draw=black!75] at (' + str(x) + ',' + str(y) + ') {};\n')
    
  # Draw agent nodes next to feature vectors
  f.write('\\node (culture29) [agents2,inner sep=0.08cm,top color=white!80!c2,bottom color=c2!100,draw=black!75] at(5,3.15) {};\n')
  f.write('\\node (culture94) [agents3,inner sep=0.16cm,top color=white!80!c3,bottom color=c3!100,draw=black!75] at(5,2.15) {};\n')
  f.write('\\node (culture90) [agents1,inner sep=0.113cm,top color=white!80!c1,bottom color=c1!100,draw=black!75] at(5,1.15) {};\n')
  
  #f.write('\\path[-latex] (culture29) edge [thick,bend right=45] (29);\n')
  #f.write('\\path[-latex] (culture94) edge [thick,bend left] (94);\n')
  #f.write('\\path[-latex] (culture90) edge [thick,bend left] (90);\n')
  
  # Draw feature vectors
  for i in [29,94,90]:
    x = -1
    for j in xrange(len(cultures[i])):
      f.write('\\node (' + str(i) + '-' + str(j) + ') [features,right=of culture' + str(i) + ', xshift=' + str(x) + 'cm] {' + str(cultures[i][j]) + '};')
      x += 0.41
      
  #f.write('\\node[above right=of 99,xshift=-5,yshift=-5] (bracket1a) {};')
  #f.write('\\node[right=-0.1 of 92] (bracket1b) {};')
  #f.write('\\draw[decorate,decoration={brace},thick] (bracket1a) to node[midway,right] (bracket1b) {} (bracket1b);')
      
  # Draw links between features
  f.write('\\draw[arrows=square-square,thin,color=blue!40!black!60] (29-1) --++ (94-1);\n')
  f.write('\\draw[arrows=square-square,thin,color=blue!40!black!60] (29-2) --++ (94-2);\n')
  f.write('\\draw[arrows=square-square,thin,color=blue!40!black!60] (94-3) --++ (90-3);\n')
  
  
  ## Draw step 3 of process
  #f.write('\\node (p3Culture29) [agents2,inner sep=0.08cm,top color=white!80!c2,bottom color=c2!100,draw=black!75] at(5,2) {};\n')
  #x = -1
  #for j in xrange(len(cultures[29])):
    #f.write('\\node (p3-29-' + str(j) + ') [features,right=of p3Culture29, xshift=' + str(x) + 'cm] {' + str(cultures[29][j]) + '};')
    #x += 0.41  
   
  #f.write('\\node (p3Culture94) [agents3,inner sep=0.16cm,top color=white!80!c3,bottom color=c3!100,draw=black!75] at(8,2) {};\n')
  #x = -1
  #for j in xrange(len(cultures[94])):
    #f.write('\\node (p3-94-' + str(j) + ') [features,right=of p3Culture94, xshift=' + str(x) + 'cm] {' + str(cultures[94][j]) + '};')
    #x += 0.41    
 
 
  ## Draw step 2
  #f.write('\\node (p2Culture29) [agents2,inner sep=0.08cm,top color=white!80!c2,bottom color=c2!100,draw=black!75] at(5,3) {};\n')
  #x = -1
  #for j in xrange(len(cultures[29])):
    #f.write('\\node (p2-29-' + str(j) + ') [features,right=of p2Culture29, xshift=' + str(x) + 'cm] {' + str(cultures[29][j]) + '};')
    #x += 0.41   
 

  #x = -0.05
  #for j in xrange(len(cultures[94])):
    #f.write('\\node (p2-?-' + str(j) + ') [featuresfaded,right=of p2-29-4, xshift=' + str(x) + 'cm] {?};')
    #x += 0.4
    
  ## Draw step 1
  #x = -0.05
  #for j in xrange(len(cultures[94])):
    #f.write('\\node (p1-?-' + str(j) + ') [featuresfaded, xshift=' + str(x) + 'cm] at (5.42,4) {?};')
    #x += 0.4    
  
  #x = -0.05
  #for j in xrange(len(cultures[94])):
    #f.write('\\node (p1-?-' + str(j) + ') [featuresfaded, xshift=' + str(x) + 'cm] at (8.42,4) {?};')
    #x += 0.4  
  
  
  
    
def background(f): 
  f.write('\\begin{pgfonlayer}{background}\n')
  
  # L = 25
  #f.write('\\draw [step=0.3,lightgray,very thin] (0,7.8) grid (7.2,15) ;\n')
  
  # L = 50
  f.write('\\draw [step=0.4,lightgray,thin] (0.1,0.1) grid (4.3,4.3) ;\n')
	
  f.write('\\end{pgfonlayer}\n')
  
  #f.write('\\fill[white,path fading=fade right,fit fading=false] (0.1,-2) rectangle (4,3.2);\n')
  



def snapshot(dataPath, dataFile):
  f = open('./axelrod-config.' + dataFile + '.tex', 'w')

  G, location, culture = loadNetwork(dataPath + dataFile)

  colours=['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12']
 
  cultures = {}
  
  n = 100
  
  culture_labels = list([0]*n)       
      
  current_label = len(cultures)
      
  for i in range(0,n):      
      if str(culture[i]) in cultures:
	  culture_labels[i] = cultures[str(culture[i])]
      else:	  
	  culture_labels[i] = current_label
	  cultures[str(culture[i])] = current_label
	  current_label += 1
	  
  
  header(f)
  agents(f,culture_labels,location,colours,culture)
  #f.write('\\fill[white,path fading=fade right] (0,0) rectangle (1,1);')
  background(f)    
  footer(f)
  
  f.close()
  
  print commands.getoutput('pdflatex axelrod-config.' + dataFile + '.tex')
  #print commands.getoutput('dvips axelrod-config.' + dataFile + '.dvi')
  #print commands.getoutput('pdf2ps axelrod-config.' + dataFile + '.pdf')
  #print commands.getoutput('ps2pdf -dEPSCrop axelrod-config.' + dataFile + '.ps')
  #print commands.getoutput('pdfcrop --bbox "92 630 180 720" axelrod-config.' + dataFile + '.pdf axelrod-config.' + dataFile + '-crop.pdf')
  #print commands.getoutput('pdfcrop --bbox "145 500 350 620" axelrod-config.' + dataFile + '.pdf axelrod-config.' + dataFile + '-crop.pdf')  
  print commands.getoutput('pdfcrop axelrod-config.' + dataFile + '.pdf axelrod-config.' + dataFile + '-crop.pdf') 
  print commands.getoutput('mv axelrod-config.' + dataFile + '-crop.pdf ../img/axelrod-config.' + dataFile + '.pdf')

  #print commands.getoutput('pdf2ps snapshot.tmp-crop.pdf')
  #print commands.getoutput('mv snapshot.tmp-crop.ps ../img/snapshot.eps')

if __name__ == '__main__':
  if not os.path.exists('../img'):
    os.makedirs('../img')

  snapshot('/home/stivalaa/axelrodtest_theta_randominit0_mpi/results/500/','results20-n500-q15-beta_p10-beta_s1-theta0.0-100000000')
  #snapshot('/home/stivalaa/axelrodtest_theta_randominit0_mpi/results/125/','results22-n125-q15-beta_p10-beta_s10-theta0.0-100000000')
  #snapshot('../data-axelrod/', 'results')
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


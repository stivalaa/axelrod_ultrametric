#!/usr/bin/Rscript

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

# This version reads filename of results.csv file from command line
# and plots cophenetic cc at start vs cophenetic cc at equilibrium
#
# Usage:
#
# Rscript initialUltrametricityFinal.R results_csv_filename.csv  results_ultrametricity_csv_filename.csv
#
#
# Output .eps file in img/ is named with suffix based on y axis variable e.g.
# initialultrametricity-qF-cophenetic_cc.eps etc. 
# (facets on q, F; fixed values of N/L^2, theta, beta_s)
#
# ADS February 2013


library(methods) 
require(gplots)
library(ggplot2)
library(doBy)
#library(tikzDevice)
library(lattice)
library(latticeExtra)
library(reshape)
library(scales)

create_dir <- function(directory) {
  if (!file.exists(directory)) {
    dir.create(directory)
  }
}


bla <- function(variable, value) {

    # note use of bquote(), like a LISP backquote, evaluates only inside
    # .()
# http://stackoverflow.com/questions/4302367/concatenate-strings-and-expressions-in-a-plots-title
# but actually it didn't work, get wrong value for beta_s (2, even though no
   # such beta_s exists ?!? some problem with efaluation frame [couldn't get
# it to work by chaning where= arugment either), so using
# substitute () instead , which also doesn't work, gave up.
# --- turns out problem was I'd forgotten that all these vsariables have
# been converted to factors, so have to do .(levels(x)[x]) not just .(x)
    sapply      (value, FUN=function(xval ) 
        if (variable == "beta_s") {
          print(xval)
          bquote(beta[s]==.(levels(xval)[xval]))
        }
        else if (variable == "theta") {
          bquote(theta ==.(levels(xval)[xval]))
        }
        else if (variable == "n") {
          bquote(N/L^2==.(levels(xval)[xval]))
        }
        else {
          bquote(.(variable) == .(levels(xval)[xval]))
        }
      )
}




#ns = c(25,125,500,625)
ns = c(125)
#beta_ss <- c(1,10)
beta_ss <- c(1 )

stats <- c("initial_cophenetic_cc", "n", "m",  "beta_s",  "q", "F",  "theta", "init_random_prob", "run", "time", "num_communities", "within_community_diversity", "between_community_diversity", "num_cultures", "num_components", "largest_component", "ass", "cluster_coeff", "social_clustering", "avg_degree" , "cophenetic_cc")

responses=c("Number of communities", "Intra-community diversity", "Inter-community diversity", "Number of cultures", "Number of connected components", "Largest connected component","Assortativity","Clustering coefficient","Modularity", "Mean degree", "Cophenetic correlation coefficient")

qs = c(2,10,30,100)


#thetas = c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0)
#thetas = c(0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0)
thetas <- c(0.0)


init_random_probs <- c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0)

#Fs <- c(100)
Fs <- c(5, 10, 50, 100)

args <- commandArgs(trailingOnly=TRUE)
results_filename <- args[1]
ultrametricity_filename <- args[2]

# read the results file and reduce to columns that we are interested in
D <- read.table(results_filename, header=TRUE, sep=",",stringsAsFactors=FALSE)
D <- D[which(D$q %in% qs),]
D <- D[which(D$theta %in% thetas),]
D <- D[which(D$init_random_prob %in% init_random_probs),]
D <- D[which(D$beta_s %in% beta_ss),]
D <- D[which(D$n %in% ns),]
D <- D[which(D$F %in% Fs),]

idcolnames <- c("n", "m", "F", "beta_s", "q", "theta",  "run", "init_random_prob")
idcolnamesTime <- c(idcolnames, "time")


# read the ultrametricity results file and reduce to columns that we are interested in
E <- read.table(ultrametricity_filename, header=TRUE, sep=",",stringsAsFactors=FALSE)

E <- E[which(E$q %in% qs),]
E <- E[which(E$theta %in% thetas),]
E <- E[which(E$init_random_prob %in% init_random_probs),]
E <- E[which(E$beta_s %in% beta_ss),]
E <- E[which(E$n %in% ns),]

# join the results with ultrametericy results on id columns
D <- merge(D, E, by=idcolnamesTime)

# initial culture vector cophenetic cc is value at time=0
initUltrametricityFrame <- D[which(D$time == 0),c(idcolnamesTime, 'cophenetic_cc')]
D <- merge(D, initUltrametricityFrame, by=idcolnames) # NB no time in merge

# rename merged column name to something better
names(D)[names(D)=='cophenetic_cc.y'] <- 'initial_cophenetic_cc'
names(D)[names(D)=='cophenetic_cc.x'] <- 'cophenetic_cc'

# and also for time (and remove time.y which is always 0)
names(D)[names(D)=='time.x'] <- 'time'
D <- subset(D, select = -c(time.y))

# now get rid of the time=0 rows
D <- D[which(D$time > 0),]


D$n <- D$n / (D$m * D$m)
noverlsquared <- D$n

head(D)#XXX

D <- D[stats]
D <- melt(D, id=c(idcolnamesTime, "initial_cophenetic_cc"))

D$n <- factor(D$n)
D$q <- factor(D$q)
D$F <- factor(D$F)
D$theta <- factor(D$theta)
D$beta_s <- factor(D$beta_s)
D$init_random_prob <- factor(D$init_random_prob)
D$variable <- factor(D$variable, labels=responses)


create_dir("img/")

base_size = 10


my.theme <- ggplot2like()
my.theme$layout.heights <- list(
	  top.padding = 0.5,
	  bottom.padding = 0,
	  main.key.padding = 0,
	  key.axis.padding = 0,
	  key.top = 0,
	  axis.bottom = 0,
	  axis.xlab.padding = 0,
	  key.bottom = 0)
my.theme$layout.widths <- list(
	  left.padding = -0.4,
	  right.padding = 0.8)







for (r in 1:length(responses)) {
  response <- responses[r]
  Dst <- D[which(D$variable == response),]

  # EPS suitable for inserting into LaTeX
  postscript(paste("img/initialultrametricity-qF-", stats[r+10], ".eps", sep=''), 
             onefile=FALSE,paper="special",horizontal=FALSE, 
             width = 9, height = 6)

  

  Dst <- D[which(D$variable == response),]
  p <- ggplot(Dst, aes(x=initial_cophenetic_cc, y=value, colour=as.factor(init_random_prob), linetype=as.factor(init_random_prob))) + opts(title=bquote(list(N/L^2 == .(noverlsquared), beta[s] == .(beta_ss[1]), theta == .(thetas[1]) )))
  p <- p + geom_point()
  p <- p + scale_x_continuous(breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2))
  if (response != "Mean degree") {
      p <- p + scale_y_continuous(limits=c(0,1), breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0))
  }
  p <- p + xlab("Initial cophenetic correlation coefficient")
  p <- p + ylab(response)  
  p <- p + facet_grid(q ~ F, labeller =  bla)
  p <- p + theme_bw()
  p <- p + opts(plot.margin = 	    unit(c(0,0,0,0), "lines"),
		axis.text.x =       theme_text(size = 8, colour = "black", lineheight = 0.2),
		axis.text.y =       theme_text(size = 8, colour = "black", lineheight = 0.2),
		axis.title.x =       theme_text(size = 10, colour = "black", lineheight = 0.2),
		axis.title.y =       theme_text(angle = 90, size = 10, colour = "black", lineheight = 0.2),

	      strip.text.x =	theme_text(size = 10, colour = "black"),
	      strip.text.y =	theme_text(angle = -90, size = 10, colour = "black"),
	      legend.text = 	theme_text(size = 10, colour = "black"),
	      legend.key =  	theme_rect(fill = "white", colour = "white"),

		axis.ticks =        theme_segment(colour = "black"),
		axis.ticks.length = unit(0.1, "cm"),
		strip.background =  theme_rect(fill = "white", colour = "white"),
		panel.grid.minor =  theme_blank(),
		panel.grid.major =  theme_blank(),
		panel.border =      theme_rect(colour = "black"),
		axis.ticks.margin = unit(0.1, "cm")
  )
  p <- p + scale_colour_brewer("Initial perturbation probability", palette = "Set1")
  p <- p + scale_linetype("Initial perturbation probability")

  print(p)
}

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

# This script plots nubmre of cultures at end against number of
# cultural components at start.
# This version uses the new init mode (multiruninitmain.py instead of main.py)
# which does multiple (50) runs with SAME random initial state instead
# of new initial state each time, to make getting error bars only
# on equilibirum state stats easier.
#
# Usage:
#
# Rscript initialCultureComponentsFinalMultilineErrorBars.R results_csv_filename.csv
#
# (or R -f initialCultureComponentsFinalMultilineErrorBars.R --args results_csv_filenme.csv)
#
# E.g.:
#  Rscript  ../../scripts//initialCultureComponentsFinalMultilineErrorBars.R multiendresults.csv 
#
# Output .eps file in img/ has filename based on
# type of graph, with -nXXX for value of n, e.g.
#      initcultureconnectedcomponents-multilineerrorbars-num_cultures-n125.csv
#
# ADS July 2013


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
          bquote(beta[s]==.(levels(xval)[xval]))
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
#ns = c(25,125,500)
ns = c(   125    )
#beta_ss <- c(1,10)
beta_ss <- c(1)
stats <- c("n", "m", "F", "beta_p","init_random_prob", "beta_s", "q", "theta", "run", "time", "num_communities", "within_community_diversity", "between_community_diversity", "num_cultures", "num_components", "largest_component" , "initial_num_culture_components")

responses=c("Number of communities", "Intra-community diversity", "Inter-community diversity", "Number of cultures", "Number of connected components", "Largest connected component")

qs = c(2,10,30,100)


#thetas = c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0)
#thetas = c(0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0)
#thetas <- c(0.0  ,  0.05,  0.1 ,  0.15,  0.2 ,  0.25,  0.3 ,  0.35,  0.4 , 0.45,  0.5 ,  0.55,  0.6 ,  0.65,  0.7 ,  0.75,  0.8 ,  0.85, 0.9 ,  0.95, 1.0)


init_random_probs <- c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0)

args <- commandArgs(trailingOnly=TRUE)
results_filename <- args[1]


for (n in ns) {

  # read the results file and reduce to columns that we are interested in
  D <- read.table(results_filename, header=TRUE, sep=",",stringsAsFactors=FALSE)
  D <- D[which(D$q %in% qs),]
#  D <- D[which(D$theta %in% thetas),]
  D <- D[which(D$init_random_prob %in% init_random_probs),]
  D <- D[which(D$beta_s %in% beta_ss),]

  D <- D[which(D$n == n),]
  D$n <- D$n / (D$m * D$m)
  noverlsquared <- D$n

  idcolnames <- c("n", "m", "F", "beta_p", "beta_s", "q", "theta",  "run", "init_random_prob")
  idcolnamesTime <- c(idcolnames, "time")
# initial number of cultural graph components is number at time=0
  initNumCultureComponentsFrame <- D[which(D$time == 0),c(idcolnamesTime, 'num_culture_components') ]
  D <- merge(D, initNumCultureComponentsFrame, by=idcolnames) # NB no time in merge
# rename merged to something better
  names(D)[names(D)=='num_culture_components.y'] <- 'initial_num_culture_components'
  names(D)[names(D)=='num_culture_components.x'] <- 'num_culture_components'
# and also for time (and remove time.y which is always 0)
  names(D)[names(D)=='time.x'] <- 'time'

# now get rid of the time=0 rows
  D <- D[which(D$time > 0),]


  D <- D[stats]
  D <- melt(D, id=c(idcolnamesTime, "initial_num_culture_components"))
  D$n <- factor(D$n)
  D$q <- factor(D$q)
  D$F <- factor(D$F)
  D$beta_s <- factor(D$beta_s)
###D$init_random_prob < factor(D$init_random_prob)
  D$variable <- factor(D$variable, labels=responses)

  D <- summaryBy(value ~ n + beta_s + F + q + theta + init_random_prob + initial_num_culture_components + variable, data=D, FUN=c(mean,sd)) 

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
    postscript(paste("img/initcultureconnectedcomponents-multilineerrorbars-", stats[r+10], '-n', n, ".eps", sep=''), 
              onefile=FALSE,paper="special",horizontal=FALSE, 
              width = 8, height = 6)

    

    Dst <- D[which(D$variable == response),]

    p <- ggplot(Dst, aes(x=initial_num_culture_components, y=value.mean, colour=as.factor(init_random_prob), linetype=as.factor(init_random_prob))) 
    p <- p + opts(title=bquote(list(N/L^2 == .(noverlsquared), beta[s] == .(beta_ss[1])                )))
    p <- p + geom_line() + geom_errorbar(aes(ymin=value.mean - value.sd, ymax=value.mean + value.sd), width=0.1)
    p <- p + geom_line() 
    p <- p + scale_y_continuous(breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2))
    p <- p + scale_x_continuous(breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2))
    p <- p + xlab("Initial number of connected cultural components")
    p <- p + ylab(response)  
    p <- p + facet_grid(q ~ F , labeller =  bla)
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
    p <- p + scale_colour_brewer(expression(p)                      , palette = "Set1")
    p <- p + scale_linetype(expression(p)                     )

    print(p)
  }

}


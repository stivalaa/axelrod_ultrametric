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
# This version reads filename of results.csv (model end results)
# and culturecmoponents.csv (data from model end processed by
# build_culture_connected_components.py) files from command line
# As of changes on 21Feb2003 though, num_culture_components is now added
# to the normal results.csv output file so this version is no longer necessary
# for new output, can just use thetaInitRandomprobCultueComponents.R
#
#
# Usage:
#
# Rscript thetaInitialCultureConnectedComponents.R  connected_components_csv_filename.csv
#
# (or R -f thetaInitialCultureConnectedComponents.R --args  connected_compoents_csv_filename.csv)
#
# E.g.:
#  Rscript  ../../scripts/thetaInitialCultureConnectedComponents.R culturecomponentsmultiendresults.csv
#
# Output .eps file in img/theta-initcultureconnectedcomponents.csv
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
        else if (variable == "n") {
          bquote(N/L^2==.(levels(xval)[xval]))
        }
        else {
          bquote(.(variable) == .(levels(xval)[xval]))
        }
      )
}



args <- commandArgs(trailingOnly=TRUE)
culturecomponents_filename <- args[1]

#ns = c(25,125,500,625)
ns = c(25)  # have F and q as facets, can only have one n
#beta_ss <- c(1,10)
beta_ss <- c(1) # not eve relevant fo rthis plot, onlyinitial conditions used
qs = c(2,10,30,100)
thetas = c(0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0)
init_random_probs <- c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0)

Fs <- c(5, 100)

# read the results file and reduce to columns that we are interested in
D <- read.table(culturecomponents_filename, header=TRUE, sep=",",stringsAsFactors=FALSE)


# we only want the time=0 rows
D <- D[which(D$time == 0),]


D <- D[which(D$q %in% qs),]
D <- D[which(D$theta %in% thetas),]
D <- D[which(D$init_random_prob %in% init_random_probs),]
D <- D[which(D$beta_s %in% beta_ss),]
D <- D[which(D$n %in% ns),]
D <- D[which(D$F %in% Fs),]


create_dir("img/")

base_size = 10


D <- melt(D, id=c("n", "beta_s", "q", "F", "theta", "init_random_prob", "run", "time"))

D$n <- factor(D$n)
D$F <- factor(D$F)
D$q <- factor(D$q)
D$beta_s <- factor(D$beta_s)
D$init_random_prob <- factor(D$init_random_prob)


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



  # EPS suitable for inserting into LaTeX
  postscript("img/theta-initcultureconnectedcomponents.eps",
             onefile=FALSE,paper="special",horizontal=FALSE, 
             width = 9, height = 6)
  

  Dst <- D[which(D$variable == "num_culture_components"),]


  p <- ggplot(Dst, aes(x=theta, y=value,                  colour=as.factor(init_random_prob), linetype=as.factor(init_random_prob))) 
  p <- p + geom_point()
  #p <- p + geom_line() + geom_errorbar(aes(ymin=value.mean - value.sd, ymax=value.mean + value.sd), width=0.1)
  p <- p + geom_line() 
  p <- p + opts(title = bquote(n == .(ns[1])))
  p <- p + scale_y_continuous(breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2))
  p <- p + scale_x_continuous(breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2))
  p <- p + ylab("Initial number of connected cultural components")
  p <- p + xlab(expression(theta))  
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







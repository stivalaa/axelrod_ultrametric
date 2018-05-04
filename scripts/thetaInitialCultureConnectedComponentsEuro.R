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
#
# Usage:
#
# Rscript thetaInitialCultureConnectedComponentsEuro.R  connected_components_csv_filename.csv
#
# (or R -f thetaInitialCultureConnectedComponentsEuro.R --args  connected_compoents_csv_filename.csv)
#
# E.g.:
#  Rscript  ../../scripts/thetaInitialCultureConnectedComponentsEuro.R culturecomponentsmultiendresults.csv
#
# Output .eps file in img/theta-initcultureconnectedcomponents.csv
#
# This version is for Eurobarometer data: uses initial real/initial/permuted
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



args <- commandArgs(trailingOnly=TRUE)
culturecomponents_filename <- args[1]


# read the results file and reduce to columns that we are interested in
D <- read.table(culturecomponents_filename, header=TRUE, sep=",",stringsAsFactors=FALSE)

idcolnames <- c("n", "m", "F", "beta_p", "beta_s", "q", "theta",  "run", "initial")
idcolnamesTime <- c(idcolnames, "time")

# we only want the time=0 rows
D <- D[which(D$time == 0),]

# fix lattice size
D <- D[which(D$m == 25),]

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



  # EPS suitable for inserting into LaTeX
  postscript("img/theta-initcultureconnectedcomponents.eps",
             onefile=FALSE,paper="special",horizontal=FALSE, 
             width = 9, height = 6)
  

  Dst <- D

  p <- ggplot(Dst, aes(x=theta, y=num_culture_components, colour=as.factor(initial), linetype=as.factor(initial))) #+ opts(title=bquote(q == .(qs[1])))
  p <- p + geom_point()
  #p <- p + geom_line() + geom_errorbar(aes(ymin=value.mean - value.sd, ymax=value.mean + value.sd), width=0.1)
  p <- p + geom_line() 
  p <- p + scale_y_continuous(breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2))
  p <- p + scale_x_continuous(breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2))
  p <- p + ylab("Initial number of connected cultural components")
  p <- p + xlab(expression(theta))  
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
  p <- p + scale_colour_brewer("Initial culture", palette = "Set1")
  p <- p + scale_linetype("Initial culture")

  print(p)







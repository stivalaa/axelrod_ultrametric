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

#
# This version plots critical value of q depending on theta
#
# Usage:
#
# Rscript q_transitino_theta results_csv_filename.csv
#
#
# Output .pdf file in img/ is qc-theta.pdf
#
# ADS 4April2013
# 

library(methods) 
library(doBy)
require(gplots)
library(ggplot2)
#library(tikzDevice)
library(lattice)
library(latticeExtra)
library(plyr)
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
        else if (variable == "init_random_prob") {
          bquote(p==.(levels(xval)[xval]))
        }
        else {
          bquote(.(variable) == .(levels(xval)[xval]))
        }
      )
}


results_filename <- commandArgs(trailingOnly=TRUE)

thetas <- c(0.0, 0.1, 0.2, 0.3,  0.4 ,0.5, 0.6, 0.7, 0.8, 1.0)
thetas <- c(0.0  ,  0.05,  0.1 ,  0.15,  0.2 ,  0.25,  0.3 ,  0.35,  0.4 , 0.45,  0.5 ,  0.55,  0.6 ,  0.65,  0.7 ,  0.75,  0.8 ,  0.85, 0.9 ,  0.95, 1.0)

#init_random_probs <- c(0.0, 0.1, 0.2, 0.3,  0.4 ,0.5, 0.6, 0.7, 0.8, 0.9, 1.0)
init_random_probs <- c(0.0)
Fs <- c(5, 10, 50, 100)
#ms = c(20,25,30)
ms = c(   25   )
#ns = c(0.04,0.2,0.4,0.8,0.96,1)
ns = c(0.2                     )
#qs = c(2,3,5,8,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,140,145,150)
stats = c("n", "m", "beta_s", "q", "F", "theta", "init_random_prob", "run", "time", "num_communities", "largest_community", "between_community_diversity")

responses=c("Number of communities", "Largest community", "Inter-community diversity")
# 

# read the results file and reduce to columns that we are interested in
D <- read.table(results_filename, header=TRUE, sep=",")
D <- D[which(D$time > 0),]
D <- D[which(D$init_random_prob %in% init_random_probs),]
D <- D[which(D$F %in% Fs),]
D <- D[which(D$beta_s == 1),]
D <- D[which(D$m %in% ms),]
#D <- D[which(D$q %in% qs),]
D$n <- D$n / (D$m * D$m)
D <- D[which(D$n %in% ns),]

noverlsquared <- D$n


D <- D[stats]
D <- melt(D, id=c("n", "m", "beta_s", "q", "F", "theta", "init_random_prob", "run", "time"))


D2 <- summaryBy(value ~ n + m + beta_s + q + F + theta + init_random_prob + variable, data=D, FUN=c(mean)) 



D2 <- D2[which(D2$variable == "between_community_diversity" ),] 
D2$blub <- 0
D2$blub <- 1.0 > D2$value.mean & D2$value.mean > 0.0
D2[which(D2$blub == FALSE),"blub"] <- 0
D2[which(D2$blub == TRUE),"blub"] <- 1

D3 <- summaryBy(value ~ n + m + beta_s + q + F + theta + init_random_prob + variable, data=D, FUN=c(mean, sd)) 
D3 <- D3[which(D3$variable == "largest_community"),] 
D3$blub <- D2$blub


D$init_random_prob <- factor(D$init_random_prob)
D$theta <- factor(D$theta)

D$n <- factor(D$n)
D$m <- factor(D$m)
D$F <- factor(D$F)
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



Dline = data.frame(theta = rep(thetas, length(Fs)), F = rep(Fs, each=length(thetas)), loc = rep(thetas, length(Fs)))
Dline$F <- as.factor(Dline$F)
for (k in Fs){
  for (l in thetas) {
    tmp <- D3[which(D3$theta == l & D3$F == k),]
    Dline$loc[which(Dline$theta == l & Dline$F == k)] <- tmp$q[which.max(tmp$value.sd)]
  }
}






#tikz(paste("img/qc.tex", sep=''), standAlone = TRUE, width=3, height=2, documentDeclaration = "\\documentclass[final,times]{elsarticle}")

# PDF suitable for inserting into LaTeX, don't use postscript as shading doesn't work
pdf("img/qc-theta.pdf")
p <- ggplot(Dline, aes(x=theta, y=loc, shape=F, colour=F, linetype=F))

p <- p + opts(title=bquote(list(p == .(init_random_probs[1]), N/L^2 == .(noverlsquared))))
#p <- p + geom_line() + geom_point(size=1.6)
p <- p + geom_point(size=1.6)
  p <- p + geom_smooth(method = "loess", se = FALSE) 

p <- p + scale_x_continuous(breaks=c(0.0,0.2,0.4,0.6,0.8,1.0))
p <- p + xlab(expression(theta)) + ylab(expression(q[c]))
p <- p + theme_bw()
p <- p + opts(plot.margin = 	    unit(c(0,0,0,0), "lines"),
	      axis.text.x =       theme_text(angle = 90, size = 8, colour = "black", lineheight = 0.2),
	      axis.text.y =       theme_text(size = 8, colour = "black", lineheight = 0.2),
	      axis.title.x =       theme_text(size = 10, colour = "black", lineheight = 0.2),
	      axis.title.y =       theme_text(size = 10, colour = "black", lineheight = 0.2),

	      strip.text.x =	theme_text(size = 10, colour = "black"),
	      strip.text.y =	theme_text(size = 10, colour = "black"),
	      legend.text = 	theme_text(size = 10, colour = "black"),
	      legend.key =  	theme_rect(fill = "white", colour = "white"),

	      axis.ticks =        theme_segment(colour = "black"),
	      axis.ticks.length = unit(0.1, "cm"),
	      strip.background =  theme_rect(fill = "white", colour = "white"),
	      panel.grid.minor =  theme_blank(),
	      panel.grid.major =  theme_blank(),
#		panel.background =  theme_rect(colour = "grey80"),
	      panel.border =      theme_rect(colour = "black"),
	      axis.ticks.margin = unit(0.1, "cm")
)
p <- p + scale_colour_brewer(expression(F), palette = "Set1")
p <- p + scale_linetype(expression(F))
p <- p + scale_shape(expression(F))
print(p)


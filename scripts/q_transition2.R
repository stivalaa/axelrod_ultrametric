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
# This version uses facets to have different values of initial perturbation
# probabily (p) on different graphs on same plot, but no room for any other
# variabgles (F, N/L^2) on same page so outputs in separate files
#   byq-Fxxx-nxxx.pdf
# fro different values of F and n
#

# NB problemt with ggplot2 stat_summary, depending on version of ggplot2
# end up with no lines for num. communities or largest community
# and " geom_path: Each group consist of only one observation. Do you need to adjust the group aesthetic?" error message:
# https://github.com/hadley/ggplot2/issues/search?q=739
# I find it doesn't work on bruce.vlsci.unimelb.edu.au and had to run it on
# Windows/cygwin to get it to work.
# ADS 22April2013

library(methods) 
require(gplots)
library(ggplot2)
library(doBy)
#library(tikzDevice)
library(lattice)
library(latticeExtra)
library(plyr)
library(reshape)
library(scales)
library(Hmisc)


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

init_random_probs <- c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0)
Fs <- c(5, 10, 50, 100)
betas = c(1  )
ms = c(25)
ns = c(25, 125, 500)
qs = c(2,3,5,8,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,140,145,150)
stats = c("n", "m", "beta_s", "q", "F", "init_random_prob", "run", "time", "num_communities", "largest_community", "between_community_diversity")

responses=c("Number of communities", "Largest community", "Inter-community diversity")

create_dir("img/")

for (n in ns) {
  for (F in Fs) {
# read the results file and reduce to columns that we are interested in
    D <- read.table(results_filename, header=TRUE, sep=",")
#E <- read.table("results-betas2.csv", header=TRUE, sep=",")
#D <- rbind(D, E)

    D <- D[which(D$theta == 0),]
    D <- D[which(D$time > 0),]
    D <- D[which(D$init_random_prob %in% init_random_probs),]
    D <- D[which(D$beta_s %in% betas),]
    D <- D[which(D$m %in% ms),]
    D <- D[which(D$q %in% qs),]
    D <- D[which(D$F == F   ),]
    D <- D[which(D$n == n   ),]

    if (nrow(D) == 0) {
      cat('warning: no data for F = ', F, ' n = ', n, '; skipping\n')
      next
    }

    noverlsquared <- D$n / (D$m*D$m)
    thetavalue <- D$theta

    D <- D[stats]
    D <- melt(D, id=c("n", "m", "beta_s", "q", "F", "init_random_prob", "run", "time"))


    D2 <- summaryBy(value ~ n + m + beta_s + q + F + init_random_prob + variable, data=D, FUN=c(mean)) 



    D2 <- D2[which(D2$variable == "between_community_diversity" ),] 
    D2$blub <- 0
    D2$blub <- 1.0 > D2$value.mean & D2$value.mean > 0.0
    D2[which(D2$blub == FALSE),"blub"] <- 0
    D2[which(D2$blub == TRUE),"blub"] <- 1

    D3 <- summaryBy(value ~ n + m + beta_s + q + F +init_random_prob + variable, data=D, FUN=c(mean, sd)) 
    D3 <- D3[which(D3$variable == "largest_community"),] 
    D3$blub <- D2$blub

    D$init_random_prob <- factor(D$init_random_prob)

    D$n <- factor(D$n)
    D$m <- factor(D$m)
    D$variable <- factor(D$variable, labels=responses)



    # Use PDF not postscript so transparency works (not supported on postscript)
    pdf(paste("img/byq", "-F", F, "-n", n, ".pdf", sep=''))


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


    Drect = data.frame(init_random_prob = rep(init_random_probs, length(ms)), m = rep(ms, each=length(init_random_probs)), left = rep(c(0), length(ms)*length(init_random_probs)), right = rep(c(0), length(ms)*length(init_random_probs)))
    for (k in ms) {
        for (irp in init_random_probs) {
          tmp <- D2[which(D2$variable == "between_community_diversity" & D2$init_random_prob == irp & D2$m == k & D2$blub == 1),]
          qmin <- tmp$q[which.min(tmp$q)]
          if (length(qmin) == 0) { # catches integer(0) value when no min
            cat('warning: no min value of largest_community for m = ', k, ' n = ', n, ' init_random_prob = ', irp, ' F = ',F,'; skipped\n')
            next
          }
          Drect$left[which(Drect$init_random_prob == irp & Drect$m == k)] <- qmin
          Drect$right[which(Drect$init_random_prob == irp & Drect$m == k)] <- tmp$q[which.max(tmp$q)]
        }
    }


    Dline = data.frame(init_random_prob = rep(init_random_probs, length(ms)), m = rep(ms, each=length(init_random_probs)), loc = rep(c(0), length(ms)*length(init_random_probs)))
    Dline$m <- as.factor(Dline$m)
    for (k in ms){
        for (irp in init_random_probs) {
          tmp <- D3[which(D3$init_random_prob == irp & D3$m == k),]
          Dline$loc[which(Dline$init_random_prob == irp & Dline$m == k)] <- tmp$q[which.max(tmp$value.sd)]
        }
    }







    p <- ggplot()

    p <- p + stat_summary(data=D[which(D$m == 25 & D$variable == "Number of communities"),], mapping=aes(x=q, y=value, colour=variable,linetype=variable), fun.data = "mean_sdl", geom="errorbar")
    p <- p + stat_summary(data=D[which(D$m == 25 & D$variable == "Number of communities"),], mapping=aes(x=q, y=value, colour=variable, linetype=variable, shape=variable), fun.data = "mean_sdl", geom="line")

    p <- p + stat_summary(data=D[which(D$m == 25 & D$variable == "Largest community"),], mapping=aes(x=q, y=value, colour=variable,linetype=variable), fun.data = "mean_sdl", geom="errorbar")
    p <- p + stat_summary(data=D[which(D$m == 25 & D$variable == "Largest community"),], mapping=aes(x=q, y=value, colour=variable, linetype=variable, shape=variable), fun.data = "mean_sdl", geom="line")

    p <- p + geom_point(data=D[which(D$m == 25 & D$variable == "Inter-community diversity"),], mapping=aes(x=q, y=value, colour=variable, linetype=variable, shape=variable), size=1)
#p <- p + scale_x_continuous(formatter="comma", trans="log2")
#  p <- p + scale_x_continuous(trans = log2_trans(), 
#			      breaks = trans_breaks("log2", function(x) 2^x),
#			      labels = trans_format("log2", math_format(2^.x)))
    p <- p + opts(title=bquote(list(theta == .(thetavalue), F == .(F), N/L^2 == .(noverlsquared))))
    p <- p + scale_x_continuous ()
    p <- p + scale_y_continuous(breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0))
    p <- p + xlab(expression(q)) + ylab("")
    p <- p + theme_bw()
    p <- p + opts(plot.margin = 	    unit(c(0,0,0,0), "lines"),
            axis.text.x =       theme_text(size = 8, colour = "black", lineheight = 0.2),
            axis.text.y =       theme_text(size = 8, colour = "black", lineheight = 0.2),
            axis.title.x =       theme_text(size = 10, colour = "black", lineheight = 0.2),
            axis.title.y =       theme_text(angle = 90, size = 10, colour = "black", lineheight = 0.2),

            strip.text.x =	theme_text(size = 10, colour = "black"),
            strip.text.y =	theme_text(size = 10, colour = "black"),
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

    colours = brewer.pal(name="Set1", n=nlevels(D$variable))
    names(colours)= levels(D$variable)

    p <- p + scale_colour_manual(name="", values=colours, guide = guide_legend(reverse=TRUE))
    p <- p + scale_linetype_manual(name="", values=c(0,2,1), guide = guide_legend(reverse=TRUE))
    p <- p + scale_shape_manual(name="", values=c(20,20,20), guide = guide_legend(reverse=TRUE))


    p <- p + geom_rect(data=Drect[which(Dline$m == 25 ),], aes(xmin = left, xmax = right, ymin=-Inf, ymax=Inf), alpha=0.1, inherit.aes = FALSE)
    p <- p + geom_vline(data=Dline[which(Dline$m == 25  ),], aes(xintercept = loc), linetype=3)
    p <- p + geom_text(data=Dline[which(Dline$m == 25 ),], aes(x = loc), y=0.24, label="q[c]", parse=T, size=3.6, hjust=-0.2)

    p <- p + facet_grid(  init_random_prob ~ . , labeller = bla)

    print(p)
    dev.off()
  }
}

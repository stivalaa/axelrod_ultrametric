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

library(methods)
require(gplots)
library(doBy)
library(ggplot2)
#library(tikzDevice)
library(lattice)
library(latticeExtra)
library("RColorBrewer")
library(reshape)


mypanel <- function(x,y,z,...) {
  view <- list(z = -60, x = -65)
  a = 1
  panel.wireframe(x,y,z,screen = view, alpha = a,...)

}

ms = c(20,25,30)
ns = c(0.04,0.2,0.4,0.8,1)
qs = c(2,3,5,8,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,140,145,150)

stats = c("m", "n", "q", "run", "num_cultures")



# read the results file and reduce to columns that we are interested in
D <- read.table("results.csv", header=TRUE, sep=",")
D <- D[which(D$beta_s == 1),]
D <- D[which(D$q %in% qs),]
D <- D[which(D$m %in% ms),]
D$n <- D$n / (D$m * D$m)

D <- D[stats]
D <- melt(D, id=c("m", "n", "q", "run"))


D$m <- factor(D$m, labels=c('$L = 20$', '$L = 25$', '$L = 30$'))



D <- summaryBy(value ~ m + n + q + variable, data=D, FUN=c(mean,sd)) 


attach(D)
D <- D[order(variable, m, n, q),]






brewer.div <- colorRampPalette(brewer.pal(3, "BuGn"), interpolate = "spline")




my.theme <- ggplot2like()
my.theme$layout.heights <- list(
	  top.padding = 0,
	  bottom.padding = 0,
	  main.key.padding = 0,
	  key.axis.padding = 0,
	  key.top = 0,
	  axis.bottom = 0,
	  axis.xlab.padding = 0,
	  key.bottom = 0)
my.theme$layout.widths$left.padding <- 0.0
my.theme$layout.widths$right.padding <- 0.0
my.theme$layout.widths$axis.key.padding <- 0
my.theme$layout.widths$key.ylab.padding <- 0


my.theme$strip.background <- list(
	  alpha = 1,
	  col = "transparent", "black", "black")
my.theme$strip.border <- list(alpha=1, col="transparent", lwd=0)
my.theme$panel.background <- list(col="transparent")
my.theme$axis.line <- list(col="black", alpha=1, lty=1, lwd=1)

#trellis.device("tikz", theme = my.theme, file="img/surface.tex", width=6, height=2, standAlone = TRUE, documentDeclaration = "\\documentclass[aps,pre]{elsarticle}", pointsize=10)

# EPS suitable for inserting into LaTeX
trellis.device("postscript", theme = my.theme, file="img/surface.eps",
             onefile=FALSE,paper="special",horizontal=FALSE, 
             width = 9, height = 6)

p <- wireframe(value.mean ~ n*q|m, data = D, zlim=c(0,1), xlab = list("$N/L^2$", vjust=1.2, hjust=0.96, cex=0.8), ylab = list("$q$", vjust=0.1, hjust=0.1, cex=0.8), zlab = "", drape = TRUE, colorkey = FALSE, scales=list(z = "same", arrows=FALSE, cex=0.6, tck=c(1.5,1.5)), layout=c(3,1), between=list(x=0.2, y=0.0), between.columns = 0, panel = mypanel, zoom=0.9, 
strip = strip.custom(), mgp = c (1.5 ,0.75 ,0),
col.regions = brewer.div(200))



print(p)
dev.off()







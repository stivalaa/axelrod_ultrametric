Ultrametric distribution of culture vectors in an extended Axelrod model of cultural dissemination
# Ultrametric distribution of culture vectors in an extended Axelrod model of cultural dissemination

## Software

Imported from https://sites.google.com/site/alexdstivala/home/ultrametric_axelrod

Also available from Zenodo with DOI: [![DOI](https://zenodo.org/badge/132073080.svg)](https://doi.org/10.5281/zenodo.17993338)


This software is free under the terms of the GNU General Public License.
It is a modified version of the 
[code originally written by Jens Pfau](http://www.csse.unimelb.edu.au/~pfauj/physicaa2012/),
extended to include bounded confidence, support for external initial 
conditions data and other methods of generating initial conditions, 
and parallelization using MPI (with [mpi4py](http://mpi4py.scipy.org/)). It also requires the Python libraries [NumPy](http://www.numpy.org/) (part of the [SciPy package](http://www.scipy.org/)) and 
[igraph](http://igraph.sourceforge.net/), and uses  code written in
[R](http://www.r-project.org/) to compute cophenetic 
correlation coefficients.

The Python code was run with NumPy version 1.7.1, SciPy version 0.12.0, igraph version 0.6 and mpi4py version 1.3.1 under Python version 2.7.5 on a cluster running CentOS 5 (Linux 2.6.32-358.18.1.el6.x86_64) with Open MPI version 1.6.5.
The C++ code was compiled with gcc version 4.4.7. R version 2.15.3 was used
for running R scripts.


The scripts are mostly written in [R](http://www.r-project.org/) and use the following R libraries, which can be installed from the [CRAN repository](http://cran.r-project.org/) with the R install.packages() command: RColorBrewer, clue, doBy, ggplot2, gplots, grid, gridExtra, Hmisc, igraph, lattice, laticeExtra, methods, plyr, reshape, scales. Note that it may not be necessary to install all these libraries explicitly; some of them are dependencies of the others. The two major libraries used are [ggplot2](http://ggplot2.org/) (version 0.9.3.1) for generating plots and [igraph](http://igraph.sourceforge.net/) (version 0.6.5-2) for network analysis.

## Reference

If you use our software, data, or results in your research, please cite:

- Stivala, A., Robins, G., Kashima, Y., and Kirley, M. (2014). [Ultrametric distribution of culture vectors in an extended Axelrod model of cultural dissemination.](http://www.nature.com/srep/2014/140502/srep04870/full/srep04870.html)Scientific Reports4:4870. [doi:10.1038/srep04870](http://dx.doi.org/doi:10.1038/srep04870)
- Pfau, J., Kirley, M., and Kashima, Y. (2013). The co-evolution of cultures, social network communities, and agent locations in an extension of Axelrod's model of cultural dissemination. Physica A: Statistical Mechanics and its Applications.392(2):381-391. [doi:10.1016/j.physa.2012.09.004](http://dx.doi.org/10.1016/j.physa.2012.09.004)


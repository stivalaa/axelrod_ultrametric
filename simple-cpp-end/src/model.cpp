/*  Copyright (C) 2011 Jens Pfau <jpfau@unimelb.edu.au>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <iostream>
#include <sstream>
#include <fstream>
#include <cstdlib>
#include <cmath>
#include <vector>
#include <list>
#include <string>
#include <limits>
#include <cassert>
#include <unistd.h> // for getpid()


#include "model.hpp"

#define SVN_VERSION_MODEL_CPP "simple model rev 1"


// modified by ADS to seed srand with time+pid and to also 
// ensure unique tmp files so safe for parallel execution with MPI Python
// NB this involved extra command line pameter to model to not compatible
// with unmodified versions
// Also added theta parameter as threshold for bounded confidence model

static char *tempfileprefix = NULL;


// TODO implement accelaration of convergence by maintaingin "active agents"
// list as per Barbosa & Fontanari (2009). This is basically the list of
// agents that can possibly interact (as per the test in stop2()), so only
// search this instead of all agents on each step.


// Read the time_list---the iterations at which the stats of the simulation are
// to be printed out---from a temporary file.
int read_time_list(int** time_list, int* n) {
        std::ifstream inFile ((toString(tempfileprefix) + ".T").c_str());

	if (inFile) {
		std::string line;

		// Get the first line and read out the number of time steps in the list
		if (!getline(inFile, line))
			return -1;

		*n = convert<int>(line);
		int* tmplist = new int[*n];

		// Get the list itself
		if (!getline(inFile, line))
			return -1;

		// Read every item of the list
		std::istringstream linestream(line);
		std::string item;
		int i = 0;
		while (getline (linestream, item, ',') and i < *n) {
			tmplist[i] = convert<int>(item);
			i++;
		}

		if (i != *n)
			return -1;

		*time_list = tmplist;
	} else {
		*n = 0;
	}

	return 0;
}


// Calculate the Euclidean distance on the lattice between agents and and b.
// Do not use sqrt as this function is only used for comparision.
inline int abs_distance(int x1, int y1, int x2, int y2, int m, bool toroidal) {
	return (x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2);
}


// Calculate the Euclidean normalized distance on the lattice between agent a
// and the tile at coordinates (x,y).


inline double distance(int x1, int y1, int x2, int y2, int m, bool toroidal, double iMaxDistance) {
    return sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2)) * iMaxDistance;
}




// Init the lattice, the social network, and the culture of individuals.
void init(Grid<int>& L, Grid<int>& O, Grid<int>& C, int m, int n , int F, int q) {

	std::cout << "Initializing agent locations:" << std::endl;
	std::cout << "n = " << n << ", m = " << m << std::endl;

	// Randomly assign agents to positions on the m x m size lattice defined
	// by L.
	int tmpCell[2];
	for (int i = 0; i < n; i++) {
		do {
			tmpCell[0] = rand() % m;
			tmpCell[1] = rand() % m;
		} while (O(tmpCell[0], tmpCell[1]) == 1);
		L(i,0) = tmpCell[0];
		L(i,1) = tmpCell[1];
		O(tmpCell[0], tmpCell[1]) = 1;
	}

	std::cout << "Agents located on the grid." << std::endl;

	// Randomly assign a culture to each agent, stored in the n x F array C.
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < F; j++) {
			C(i,j) = rand() % q;
		}
	}

	std::cout << "Agents assigned cultures" << std::endl;

}


// Calculate the cultural similarity between agents a and b as the proportion of
// features they have in common.
inline double similarity(Grid<int>& C, const int F, const int a, const int b) {
	double same = 0.0;
	for (int i = 0; i < F; i++)
		if (C(a,i) == C(b,i))
			same += 1.0;
	return same/F;
}



void save(Grid<int>& lastC, Grid<double>& lastG, Grid<int>& C, Grid<double>& G, int n, int F) {
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < n; j++) {
			lastG(i,j) = G(i,j);
		}

		for (int j = 0; j < F; j++) {
			lastC(i,j) = C(i,j);
		}
	}
}


// test for equilbrium, return true if no more change is possible
bool stop2(Grid<int>& C, int n, int F, double theta) {
    // at equilibrium, all agents must have either identical culture, or
    // or completely distinct culture (no traits in common, similarity = 0), or
    // cultures with similarity < theta.
    assert(theta >= 0.0 && theta <= 1.0);
    for (int i = 0; i < n; i++)  {
        for (int j = i+1; j < n; j++) { // symmetric, only need i,j where j > i
            double sim = similarity(C, F, i, j);
            assert(sim >= 0.0 && sim <= 1.0);
            // NB using >= and <= not == to for floating point comparison
            // with 0 or 1 since floating point == is dangerous, but
            // values cannot be < 0 or > 1, as just asserted so equivalent
            // to equality
            if ( !((sim >= 1.0 ) ||
                   (sim < theta )) ) { // includes case of sim <= 0.0
                return false;
            }
        }
    }
    return true;
}


unsigned long long model(Grid<int>& L, Grid<int>& O, Grid<int>& C, int tmax, int n, int m, int F,
		int q, double r, double s,
		bool toroidal, bool network, double tolerance, bool directed_migration,
		double phy_mob_a, double phy_mob_b, double soc_mob_a, double soc_mob_b,
		double r_2, double s_2, double phy_mob_a_2, double phy_mob_b_2, double soc_mob_a_2, double soc_mob_b_2,
		double k, int timesteps[], int time_list_length, std::ofstream& log, 
    double theta) {
       srand(time(NULL)+(unsigned int)getpid()); // so processes started at same time have different seeds (time is only second resolution)



	std::cout << "tmax: " << tmax << std::endl;
	std::cout << "n: " << n << std::endl;
	std::cout << "m: " << m << std::endl;
	std::cout << "F: " << F << std::endl;
	std::cout << "q: " << q << std::endl;


    double w[n];

    double sumw = 0.0;


	double nw[n];
	double cw[m*m];

    int a, b, idx;

	// run model
    for (unsigned long long t = 0; true; t++) {
    	// If this iteration is in the time list, write out the current state
    	// of the simulation.
    	if (t == 50000 || t == 100000 || t == 500000 || t == 1000000 || (t > 0 && t % 10000000 == 0)) {
    		std::cout << "Reaching " << t << " iterations." << std::endl;
//			save(lastC, lastG, C, G, n, F);
			  if (stop2(C, n, F, theta)) {
  		  		std::cout << "Stopping after " << t << " iterations." << std::endl;
   		  		return t;
  			}
    	}


    	// Draw one agent randomly.
    	a = rand() % n;


        // Draw one other agent randomly. Not using neighbourhood here,
        // assuming agent can interact with any other agent (as in 
        // Valori et al. (2012))
    	do {
          b = rand() % n;
    	} while (a == b);

        // With the probability of their attraction,
        // a and b interact successfully.
        double sim = similarity(C, F, a, b);
        // "bounded confidence" with theta as threshold:
        // unsuccesful interaction if similarity is less than theta
//      printf("X0 sim = %f\n", sim);
        if (sim >= theta && rand()/(float)RAND_MAX < sim) {
//        printf("X1 successful interaction\n");
          // Randomly decide on one feature that a and b do not have in common yet.
          if (sim < 1.0) {
            do {
              idx = rand() % F;
            } while (C(a,idx) == C(b, idx));

          // Let a copy this feature from b.
            C(a,idx) = C(b,idx);
          }
        }
    }
    return tmax;
}




int main(int argc, char* argv[]) {
	std::ofstream log("log.txt");

	// If the binary file is called with the argument -v, only the svn version
	// this binary was compiled from is printed.
	if (argc == 2 and argv[1][0] == '-' and argv[1][1] == 'v') {
		std::cout << "model.hpp: " << SVN_VERSION_MODEL_HPP << ", model.cpp: " << SVN_VERSION_MODEL_CPP << std::endl;
		return 0;
	}


	// Otherwise set default model arguments.
	int n = 625, m = 25, F = 5, q = 100;

	int tmax = 100000;
	double r = 1;
	double s = 1;

	bool toroidal = false;
	bool network = true;

    double tolerance = -1;
    bool directed_migration = true;

    double phy_mob_a = 1;
    double phy_mob_b = 10;
    double soc_mob_a = 1;
    double soc_mob_b = 10;

	double r_2 = r;
	double s_2 = s;

    double phy_mob_a_2 = phy_mob_a;
    double phy_mob_b_2 = phy_mob_b;
    double soc_mob_a_2 = soc_mob_a;
    double soc_mob_b_2 = soc_mob_b;

    double k = 0.01;

   double theta = 0.0;

    // If there are arguments, assume they hold model arguments in the following
    // order.
	if (argc > 1) {
		int index = 1;
		tmax = atoi(argv[index++]);
		n = atoi(argv[index++]);
		m = atoi(argv[index++]);
		F = atoi(argv[index++]);
		q = atoi(argv[index++]);
		r = atof(argv[index++]);                     // not used
		s = atof(argv[index++]);                     // not used
		toroidal = atoi(argv[index++]);              // not used
		network = atoi(argv[index++]);               // not used
		tolerance = atof(argv[index++]);             // not used
		directed_migration = atoi(argv[index++]);    // not used
		phy_mob_a = atof(argv[index++]);             // not used
		phy_mob_b = atof(argv[index++]);             // not used
		soc_mob_a = atof(argv[index++]);             // not used
		soc_mob_b = atof(argv[index++]);             // not used

		r_2 = atof(argv[index++]);                   // not used
		s_2 = atof(argv[index++]);                   // not used
		phy_mob_a_2 = atof(argv[index++]);           // not used
		phy_mob_b_2 = atof(argv[index++]);           // not used
		soc_mob_a_2 = atof(argv[index++]);           // not used
		soc_mob_b_2 = atof(argv[index++]);           // not used

		k = atof(argv[index++]);                     // not used

		tempfileprefix = argv[index++];
                theta = atof(argv[index++]);
	}

    if (toroidal) {
    	std::cout << "alarm, toroidal not supported at the moment" << std::endl;
    	return -1;
    }

	// Try to read the list of iterations that determine when statistics are to
	// be created from a temporary file.
	int* time_list = NULL;
	int time_list_length = 0;
	int res = read_time_list(&time_list, &time_list_length);
	if (res == -1) {
		std::cout << "The time list file could not be read or there was a problem with its format." << std::endl;
		return -1;
	}

	Grid<int> L(n,2,-1);
	Grid<int> C(n,F,0);
	Grid <int> O(m,m,0);

	if (argc == 1) {
		init(L, O, C, m, n, F, q);
	} else {
		// load data from file
          //G.read((toString(tempfileprefix) + ".adj").c_str(), ' ');
 	        L.read((toString(tempfileprefix) + ".L").c_str(), ',');
	        C.read((toString(tempfileprefix) + ".C").c_str(), ',');
	}

	for (int i = 0; i < n; i++)
		O(L(i,0), L(i,1)) = 1;

	// Call the model
    unsigned long long tend = model(L, O, C, tmax, n, m, F, q, r, s, toroidal, network, tolerance, directed_migration,
    		phy_mob_a, phy_mob_b, soc_mob_a, soc_mob_b,
    		r_2, s_2, phy_mob_a_2, phy_mob_b_2, soc_mob_a_2, soc_mob_b_2, k,
    		time_list, time_list_length, log, theta);

        std::cout << "Last iteration: " << tend << std::endl;
    
        // Write out the state of the simulation
	Grid<double> G(n,n,0.0); // not used for simple model, but needed in python code, so just write empty graph 
        G.write((toString(tempfileprefix) +  ".adj").c_str(), ' ');
        L.write((toString(tempfileprefix) + ".L").c_str(), ',');
        C.write((toString(tempfileprefix) + ".C").c_str(), ',');

	std::ofstream outFile((toString(tempfileprefix) + ".Tend").c_str());
	outFile << tend;


	delete[] time_list;
	time_list = NULL;

	std::cout << "Fin" << std::endl;
	return 0;
}

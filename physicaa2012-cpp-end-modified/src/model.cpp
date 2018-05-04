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


#include "model.hpp"
#include "PowFast.hpp"

#define SVN_VERSION_MODEL_CPP "Derived From Rev 942:  MODIFIED-SRAND-TMP THETA EQULIBRIUM_TEST THETA_UNSUCCESSFUL_INTERACTION"


// modified by ADS to seed srand with time+pid and to also 
// ensure unique tmp files so safe for parallel execution with MPI Python
// NB this involved extra command line pameter to model to not compatible
// with unmodified versions
// Also added theta parameter as threshold for bounded confidence model

static char *tempfileprefix = NULL;


static const PowFast p(18);


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



// Calculate the proximity between agent a and all other agents.
inline double proximity(double w[], const Grid<double>& G, const Grid<int>& L,
		const Grid<int>& C, const int n, const int m, const int F, const int a,
		const bool toroidal, const bool network, const double soc_mob_a, const double soc_mob_b,
		const double k, const double iMaxDistance, const double socialDistances[]) {
	double sumw = 0.0;

	for (int i = 0; i < n; i++) {
		if (i != a) {
			w[i] = std::max(G(a,i), k) * socialDistances[abs(L(a,0) - L(i,0))*m + abs(L(a,1) - L(i,1))];
		} else {
			w[i] = 0.0;
		}
		sumw = sumw + w[i];
	}
	return sumw;
}





//inline int randsample(int n, double w[], double sum) {
//    double r = sum * rand()/(float)RAND_MAX;
//
//	int min = 0;
//	int max = n - 1;
//	int mid;
//	int element = -1;
//
//	do {
//		mid = min + (max-min)/2;
//		if (r > w[mid]) {
//			min = mid + 1;
//		} else if (r <= w[mid] and r > w[mid - 1]) {
//			return mid;
//		} else if (r <= w[mid]) {
//			max = mid - 1;
//		}
//	} while (true);
//	return element;
//}


// Draw one position from a range of length n randomly based on the weight
// provided by the array w of length n with total weight sum.
inline int randsample(int n, const double w[], double sum) {
	double cum = 0.0;

	unsigned int randTmp = 0;
	do {
		randTmp = rand();
	} while (randTmp == 0 or randTmp == RAND_MAX);

	double rndm = sum*randTmp/(double)RAND_MAX;

    for (int i = 0; i < n; i++) {
		cum += w[i];
		if (rndm <= cum)
			return i;
    }
    return n-1;
}


// Init the lattice, the social network, and the culture of individuals.
void init(Grid<double>& G, Grid<int>& L, Grid<int>& O, Grid<int>& C, int m, int n , int F, int q) {

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



// Increase the strength of the social tie between agents a and b.
inline void increase_link(Grid<double>& G, int a, int b) {
	G(a,b) = std::min(G(a,b) + 0.1, 1.0);
	G(b,a) = G(a,b);
}


// Decrease the strength of the social tie between agents a and b.
inline void decrease_link(Grid<double>& G, int a, int b) {
	G(a,b) = std::max(G(a,b) - 0.1, 0.0);
	G(b,a) = G(a,b);
}






// Migrate agent a to another cell.
int migrate(const Grid<double>& G, Grid<int>& L, Grid<int>& O, const int m,
		const int n, const int a, const bool toroidal, const bool directed_migration,
		const double phy_mob_a, const double phy_mob_b, const double iMaxDistance,
		double nw[], double cw[], const double physicalDistances[]) {

	double sum = 0.0;
	int num_cand = 0;

    if (directed_migration) {
    	int num_n = 0;
    	for (int i = 0; i < n; i++) {
    		if (G(a,i) > 0.0) {
    			num_n++;
    			nw[i] = G(a,i);
				sum += nw[i];
    		} else {
    			nw[i] = 0;
    		}
    	}

    	if (num_n > 0) {
    		int b = randsample(n, nw, sum);
    		sum = 0;
    		for (int x = 0; x < m; x++) {
    			for (int y = 0; y < m; y++) {
    				if (O(x,y) == 0 and abs_distance(L(b,0), L(b,1), x, y, m, toroidal) < abs_distance(L(a,0), L(a,1), L(b,0), L(b,1), m, toroidal)) {
    					cw[x*m+y] = physicalDistances[abs(L(a,0) - x)*m + abs(L(a,1) - y)];
    					num_cand++;
    					sum += cw[x*m+y];
    				} else {
    					cw[x*m+y] = 0.0;
    				}
    			}
    		}
    	} else {
    		num_cand = 0;
    		sum = 0.0;
    		for (int x = 0; x < m; x++) {
    			for (int y = 0; y < m; y++) {
    				if (O(x,y) == 0) {
    					cw[x*m+y] = physicalDistances[abs(L(a,0) - x)*m + abs(L(a,1) - y)];
    					num_cand++;
    					sum += cw[x*m+y];
    				} else {
    					cw[x*m+y] = 0.0;
    				}
    			}
    		}
    	}
    } else {
		num_cand = 0;
		sum = 0.0;
		for (int x = 0; x < m; x++) {
			for (int y = 0; y < m; y++) {
				if (O(x,y) == 0) {
					cw[x*m+y] = physicalDistances[abs(L(a,0) - x)*m + abs(L(a,1) - y)];
					num_cand++;
					sum += cw[x*m+y];
				} else {
					cw[x*m+y] = 0.0;
				}
			}
		}
    }

    if (num_cand > 0) {
    	int c = randsample(m*m, cw, sum);
    	O(L(a,0), L(a,1)) = 0;
    	L(a,0) = c/m;
    	L(a,1) = c%m;
    	O(L(a,0), L(a,1)) = 1;
    }

    return num_cand;
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


// this is the original termination (equilbrium) test, which is not entirely
// correct as it is just checking for changes since last test, it is
// not necessarily true that no change means equilibrium has been reached
// ADS 18march2013
bool stop(Grid<int>& lastC, Grid<double>& lastG, Grid<int>& C, Grid<double>& G, int n, int F) {
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < n; j++) {
			if (lastG(i,j) != G(i,j))
				return false;
		}

		for (int j = 0; j < F; j++) {
			if (lastC(i,j) != C(i,j))
				return false;
		}
	}
	return true;
}

// test for equilbrium, return true if no more change is possible
bool stop2(Grid<int>& C, Grid<double>& G, int n, int F, double theta) {
    // at equilibrium, all agents must have either identical culture
    // and social link weight = 1, or
    // or completely distinct culture (no traits in common, similarity = 0)
    // and social link weight = 0, or
    // cultures with similarity < theta and social link wegith = 0
    for (int i = 0; i < n; i++)  {
        for (int j = i+1; j < n; j++) { // symmetric, only need i,j where j > i
            double sim = similarity(C, F, i, j);
            double linkw = G(i, j);
            assert(sim >= 0.0 && sim <= 1.0);
            // NB using >= and <= not == to for floating point comparison
            // with 0 or 1 since floating point == is dangerous, but
            // values cannot be < 0 or > 1, as just asserted so equivalent
            // to equality
            if ( !((sim >= 1.0 && linkw >= 1.0) ||
                   (sim <= 0.0 && linkw <= 0.0) ||
                   (sim < theta && linkw <= 0.0)) ) {
                return false;
            }
        }
    }
    return true;
}


unsigned long long model(Grid<double>& G, Grid<int>& L, Grid<int>& O, Grid<int>& C, int tmax, int n, int m, int F,
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
	std::cout << "r: " << r << std::endl;
	std::cout << "s: " << s << std::endl;
	std::cout << "toroidal: " << toroidal << std::endl;
	std::cout << "network: " << network << std::endl;
	std::cout << "tolerance: " << tolerance << std::endl;
	std::cout << "directed_migration: " << directed_migration << std::endl;
	std::cout << "phy_mob_a: " << phy_mob_a << std::endl;
	std::cout << "phy_mob_b: " << phy_mob_b << std::endl;
	std::cout << "soc_mob_a: " << soc_mob_a << std::endl;
	std::cout << "soc_mob_b: " << soc_mob_b << std::endl;
	std::cout << "k: " << k << std::endl;


    double w[n];

    double sumw = 0.0;


	double nw[n];
	double cw[m*m];

    int a, b, idx;

    // calculate maximum possible distance on the board
    double iMaxDistance = 1.0f/sqrt(2 * (m-1)*(m-1));

    double socialDistances[m*m];
    double physicalDistances[m*m];
    double d;
    for (int xdiff = 0; xdiff < m; xdiff++)
    	for (int ydiff = 0; ydiff < m; ydiff++) {
    		d = distance(0, 0, xdiff, ydiff, m, toroidal, iMaxDistance);
    		socialDistances[xdiff*m + ydiff] = soc_mob_a * p.r(::log(d), -soc_mob_b);
    		physicalDistances[xdiff*m + ydiff] =  phy_mob_a * exp(-phy_mob_b * d);
    	}



	// run model
    for (unsigned long long t = 0; true; t++) {
    	// If this iteration is in the time list, write out the current state
    	// of the simulation.
    	if (t == 50000 || t == 100000 || t == 500000 || t == 1000000 || (t > 0 && t % 10000000 == 0)) {
    		std::cout << "Reaching " << t << " iterations." << std::endl;
//			save(lastC, lastG, C, G, n, F);
			  if (stop2(C, G, n, F, theta)) {
  		  		std::cout << "Stopping after " << t << " iterations." << std::endl;
   		  		return t;
  			}
    	}


    	// Draw one agent randomly.
    	a = rand() % n;

    	// Determine the social and geographical proximity between this agent
    	// and all other. Needs to take care that the weight for agent a is 0.
    	sumw = proximity(w, G, L, C, n, m, F, a, toroidal, network, soc_mob_a, soc_mob_b, k, iMaxDistance, socialDistances);


		// Based on the proximity, draw one agent randomly.
    	do {
    		b = randsample(n, w, sumw);
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

        // With probability r, the link strength between both agents is
        // increased.
        if (network and (r == 1 or rand()/(float)RAND_MAX < r))
          increase_link(G,a,b);
      } else {
        // With probability r, the link strength between both agents is
        // decreased.
        if (network and (r == 1 or rand()/(float)RAND_MAX < r))
          decrease_link(G,a,b);

        // With probability s, agent a migrates to another empty cell.
        if (tolerance == -1 and (s == 1 or rand()/(float)RAND_MAX < s))
          migrate(G, L, O, m, n, a, toroidal, directed_migration, phy_mob_a, phy_mob_b, iMaxDistance, nw, cw, physicalDistances);

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
		r = atof(argv[index++]);
		s = atof(argv[index++]);
		toroidal = atoi(argv[index++]);
		network = atoi(argv[index++]);
		tolerance = atof(argv[index++]);
		directed_migration = atoi(argv[index++]);
		phy_mob_a = atof(argv[index++]);
		phy_mob_b = atof(argv[index++]);
		soc_mob_a = atof(argv[index++]);
		soc_mob_b = atof(argv[index++]);

		r_2 = atof(argv[index++]);
		s_2 = atof(argv[index++]);
		phy_mob_a_2 = atof(argv[index++]);
		phy_mob_b_2 = atof(argv[index++]);
		soc_mob_a_2 = atof(argv[index++]);
		soc_mob_b_2 = atof(argv[index++]);

		k = atof(argv[index++]);

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

	Grid<double> G(n,n,0.0);
	Grid<int> L(n,2,-1);
	Grid<int> C(n,F,0);
	Grid <int> O(m,m,0);

	if (argc == 1) {
		init(G, L, O, C, m, n, F, q);
	} else {
		// load data from file
 	        G.read((toString(tempfileprefix) + ".adj").c_str(), ' ');
 	        L.read((toString(tempfileprefix) + ".L").c_str(), ',');
	        C.read((toString(tempfileprefix) + ".C").c_str(), ',');
	}

	for (int i = 0; i < n; i++)
		O(L(i,0), L(i,1)) = 1;

	// Call the model
    unsigned long long tend = model(G, L, O, C, tmax, n, m, F, q, r, s, toroidal, network, tolerance, directed_migration,
    		phy_mob_a, phy_mob_b, soc_mob_a, soc_mob_b,
    		r_2, s_2, phy_mob_a_2, phy_mob_b_2, soc_mob_a_2, soc_mob_b_2, k,
    		time_list, time_list_length, log, theta);

        std::cout << "Last iteration: " << tend << std::endl;
    
        // Write out the state of the simulation
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

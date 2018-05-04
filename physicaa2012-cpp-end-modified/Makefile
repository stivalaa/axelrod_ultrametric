CXXFLAGS = -Wall -Wextra -O3 --fast-math -fno-strict-aliasing
CXXFLAGS_DEBUG = -Wall -Wextra -O1 -pg --fast-math -fno-strict-aliasing

model: model.o PowFast.o
	g++ model.o PowFast.o -o model
    
model.o: src/model.cpp 
	g++ $(CXXFLAGS) -c src/model.cpp

PowFast.o: src/PowFast.cpp
	g++ $(CXXFLAGS) -c src/PowFast.cpp

debug:
	g++ $(CXXFLAGS_DEBUG) -c src/model.cpp
	g++ $(CXXFLAGS_DEBUG) -c src/PowFast.cpp
	g++ $(CXXFLAGS_DEBUG) model.o PowFast.o -o model

clean:
	rm model model.o PowFast.o
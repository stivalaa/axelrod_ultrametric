CXXFLAGS = -Wall -Wextra -O3 --fast-math -fno-strict-aliasing
CXXFLAGS_DEBUG = -Wall -Wextra -O1 -pg --fast-math -fno-strict-aliasing

model: model.o 
	g++ model.o -o model
    
model.o: src/model.cpp 
	g++ $(CXXFLAGS) -c src/model.cpp


debug:
	g++ $(CXXFLAGS_DEBUG) -c src/model.cpp
	g++ $(CXXFLAGS_DEBUG) model.o -o model

clean:
	rm model model.o 

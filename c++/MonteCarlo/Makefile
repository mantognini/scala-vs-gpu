all: mc1 mc2

bindir:
	mkdir -p bin/

mc1: bindir
	clang++ -O3 montecarlo.cpp -o bin/montecarlo -framework sfml-system -std=c++11 -stdlib=libc++ -I ../../common/include


mc2: bindir
	clang++ -O3 montecarlo2.cpp -o bin/montecarlo2 -framework sfml-system -std=c++11 -stdlib=libc++ -I ../../common/include



all: triangularmatrix

bindir:
	mkdir -p bin/

triangularmatrix: bindir triangularmatrix.cpp
	clang++ -O3 triangularmatrix.cpp -o bin/triangularmatrix -framework sfml-system -std=c++11 -stdlib=libc++ -I ../../common/include
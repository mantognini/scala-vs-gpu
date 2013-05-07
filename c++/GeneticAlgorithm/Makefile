all: release

release: bindir
	clang++ -Wall -Wextra -O3 ga.cpp -o bin/ga -framework sfml-system -std=c++11 -stdlib=libc++ -I ../../common/include

bindir:
	mkdir -p bin/ tmp/



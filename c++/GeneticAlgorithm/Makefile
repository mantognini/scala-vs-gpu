all: release debug

release: bindir
	clang++ -Wall -Wextra -O3 ga.cpp -o bin/ga -framework sfml-system -std=c++11 -stdlib=libc++ -I ../../common/include

debug: bindir
	clang++ -Wall -Wextra -g ga.cpp -o bin/ga-d -framework sfml-system -std=c++11 -stdlib=libc++ -I ../../common/include

bindir:
	mkdir -p bin/ tmp/



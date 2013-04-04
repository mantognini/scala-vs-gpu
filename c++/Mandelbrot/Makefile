all: release release_si

release: bindir
	clang++ -Wall -Wextra -O3 mandelbrot.cpp -o bin/mandelbrot -framework sfml-system -std=c++11 -stdlib=libc++ -I ../../common/include

release_si: bindir
	clang++ -Wall -Wextra -O3 mandelbrot.cpp -o bin/mandelbrot-si -framework sfml-system -std=c++11 -stdlib=libc++ -I ../../common/include -framework sfml-window -framework sfml-graphics -DSAVE_IMAGE

bindir:
	mkdir -p bin/ tmp/



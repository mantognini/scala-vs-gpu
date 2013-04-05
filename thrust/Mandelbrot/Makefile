all: release release_si debug

bindir:
	mkdir -p bin/ tmp/

release: bindir mandelbrot.cu
	nvcc -O3 mandelbrot.cu -o bin/mandelbrot -lsfml-system -I ../../common/include

release_si: bindir mandelbrot.cu
	nvcc -O3 mandelbrot.cu -o bin/mandelbrot-si -lsfml-system -lsfml-window -lsfml-graphics -I ../../common/include -DSAVE_IMAGE

debug: bindir mandelbrot.cu
	nvcc mandelbrot.cu -o bin/mandelbrot-d -lsfml-system -I ../../common/include -DTHRUST_DEBUG


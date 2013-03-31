all:
	mkdir -p bin
	nvcc -O3 montecarlo.cu -arch=sm_30 -o bin/montecarlo -lsfml-system -I ../../common/include


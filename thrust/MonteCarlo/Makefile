all: mc1 mc2

bindir:
	mkdir -p bin

mc1: bindir montecarlo.cu
	nvcc -O3 montecarlo.cu -arch=sm_30 -o bin/montecarlo -lsfml-system -I ../../common/include

mc2: bindir montecarlo2.cu
	nvcc -O3 montecarlo2.cu -arch=sm_30 -o bin/montecarlo2 -lsfml-system -I ../../common/include



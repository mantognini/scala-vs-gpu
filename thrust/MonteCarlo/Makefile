all:
	mkdir -p bin
	nvcc montecarlo.cu -arch=sm_30 -o bin/montecarlo -lsfml-system -I ../../common/include

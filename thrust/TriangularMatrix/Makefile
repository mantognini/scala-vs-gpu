all: triangularmatrix

bindir:
	mkdir -p bin/

triangularmatrix: bindir triangularmatrix.cu
	nvcc -O3 triangularmatrix.cu -arch=sm_30 -o bin/triangularmatrix -lsfml-system -I ../../common/include
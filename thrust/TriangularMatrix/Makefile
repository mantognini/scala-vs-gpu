all: triangularmatrix

bindir:
	mkdir -p bin/

triangularmatrix: bindir triangularmatrix.cu
	nvcc -g triangularmatrix.cu -o bin/triangularmatrix -lsfml-system -I ../../common/include


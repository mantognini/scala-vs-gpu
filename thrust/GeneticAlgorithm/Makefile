all: release debug

release: bindir ga.cu
	nvcc -O3 ga.cu -o bin/ga -lsfml-system -I ../../common/include

debug: bindir ga.cu
	nvcc ga.cu -o bin/ga-d -lsfml-system -I ../../common/include -DTHRUST_DEBUG

bindir:
	mkdir -p bin/ tmp/



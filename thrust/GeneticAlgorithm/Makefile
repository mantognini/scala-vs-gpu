all: release

release: bindir ga.cu
	nvcc -O3 ga.cu -o bin/ga -lsfml-system -I ../../common/include -gencode arch=compute_30,code=compute_30 -gencode arch=compute_30,code=sm_30

debug: bindir ga.cu
	nvcc ga.cu -o bin/ga-d -lsfml-system -I ../../common/include -DTHRUST_DEBUG -gencode arch=compute_30,code=compute_30 -gencode arch=compute_30,code=sm_30

tbb: bindir ga.cu
	clang++ -x c++ -std=c++11 -stdlib=libc++ -O3 ga.cu -o bin/ga-tbb -I ../../common/include -I /Developer/NVIDIA/CUDA-5.0/include -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_TBB -ltbb -framework sfml-system

bindir:
	mkdir -p bin/ tmp/



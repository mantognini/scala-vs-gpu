all: release release-tbb

release: bindir ga.cu ga2.cu
	nvcc -O3 ga.cu -o bin/ga -lsfml-system -I ../../common/include -gencode arch=compute_30,code=compute_30 -gencode arch=compute_30,code=sm_30
	nvcc -O3 ga2.cu -o bin/ga2 -lsfml-system -I ../../common/include -gencode arch=compute_30,code=compute_30 -gencode arch=compute_30,code=sm_30

release-tbb: bindir ga.cu ga2.cu
	clang++ -O3 -x c++ ga.cu -o bin/ga-tbb -lsfml-system -I ../../common/include -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_TBB -ltbb -I/Developer/NVIDIA/CUDA-5.0/include
	clang++ -O3 -x c++ ga2.cu -o bin/ga2-tbb -lsfml-system -I ../../common/include -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_TBB -ltbb -I/Developer/NVIDIA/CUDA-5.0/include

bindir:
	mkdir -p bin/ tmp/



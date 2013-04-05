#!/bin/sh

export DYLD_LIBRARY_PATH=/Developer/NVIDIA/CUDA-5.0/lib

make

./bin/mandelbrot | tee data.csv


#!/bin/sh

make

./bin/montecarlo1 | tee data1.csv

./bin/montecarlo2 | tee data2.csv

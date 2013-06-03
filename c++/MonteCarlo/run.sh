#!/bin/sh

make

./bin/montecarlo | tee data1.csv

./bin/montecarlo2 | tee data2.csv

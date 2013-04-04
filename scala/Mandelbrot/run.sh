#!/bin/sh

rm -f data.precsv
rm -fr tmp
mkdir -p tmp

sbt run | tee data.precsv


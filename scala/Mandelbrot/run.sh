#!/bin/sh

rm -f data.precsv
rm -fr tmp
mkdir -p tmp

sbt compile

sbt run | tee data.precsv


#!/bin/sh

mkdir -p tmp

sbt compile

sbt run | tee log.txt


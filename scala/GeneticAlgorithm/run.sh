#!/bin/sh

rm -f data.precsv
rm -fr tmp
mkdir -p tmp

sbt compile

javaopts="-Xmx8G -XX:+UseConcMarkSweepGC -XX:MaxPermSize=8G -XX:+UseCondCardMark -server"
workstealingopts="-Dstep=1 -DincFreq=1 -DmaxStep=4096 -Drepeats=1 -Dstrategy=FindMax$ -Ddebug=true -Dpar=8"

EXTLIBS="`dirname $0`/../../common/scala/lib"

# Benchmarks

java $javaopts \
     -cp "$HOME/.sbt/boot/scala-2.10.1/lib/scala-library.jar":"$EXTLIBS/workstealing_2.10-0.1.jar":"$EXTLIBS/workstealing_2.10-0.1-test.jar":"`dirname $0`/target/scala-2.10/classes/" \
     $workstealingopts \
     "GeneticAlgorithmBenchmark" \
| tee data.csv
   

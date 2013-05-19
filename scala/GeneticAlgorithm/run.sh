#!/bin/sh

rm -f data.precsv
rm -fr tmp
mkdir -p tmp

sbt compile

javaopts="-Xmx8G -XX:+UseConcMarkSweepGC -XX:MaxPermSize=8G -XX:+UseCondCardMark -server"
workstealingopts="-Dstep=1 -DincFreq=1 -DmaxStep=4096 -Drepeats=1 -Dstrategy=FindMax$ -Ddebug=true -Dpar=8"

EXTLIBS="`dirname $0`/../../common/scala/lib"

# settings

size=1000
K=100
M=50
N=50
CO=50

runs=100

# Benchmarks

java $javaopts \
     -cp "$HOME/.sbt/boot/scala-2.10.1/lib/scala-library.jar":"$EXTLIBS/workstealing_2.10-0.1.jar":"$EXTLIBS/workstealing_2.10-0.1-test.jar":"`dirname $0`/target/scala-2.10/classes/" \
     $workstealingopts \
     -Dsize=$size -DK=$K -DM=$M -DN=$N -DCO=$CO \
     "workstealing.GeneticAlgorithmBenchmark" $runs \
| tee data.precsv
   

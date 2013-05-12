#!/bin/sh

rm -f data.precsv
rm -fr tmp
mkdir -p tmp

sbt compile

javaopts="-Xmx8G -XX:+UseConcMarkSweepGC -XX:MaxPermSize=8G -XX:+UseCondCardMark -server"

## Workstealing benchmarks (with new parallel collection)

# Settings

range="-1.72,1.2,1.0,-1.2"
size=2000
iter=1000

# Benchmarks

for target in "MandelbrotMASpecific" "MandelbrotMAPC" "MandelbrotSpecific" "MandelbrotPC"
do
    java $javaopts \
         -cp "$HOME/.sbt/boot/scala-2.10.1/lib/scala-library.jar":"`dirname $0`/lib/workstealing_2.10-0.1.jar":"`dirname $0`/lib/workstealing_2.10-0.1-test.jar":"`dirname $0`/target/scala-2.10/classes/" \
         -Dsize=$size \
         -Dthreshold=$iter \
         -Dbounds=$range \
         -Dstep=1 -DincFreq=1 -DmaxStep=4096 -Drepeats=1 -Dstrategy=FindMax$ -Ddebug=true -Dpar=8 \
         "workstealing.$target" 20 \
    | tee "data.${target}.txt"
done



## Benchmark using custom csv exporter (with current parallel collection)

java $javaopts \
     -cp "$HOME/.sbt/boot/scala-2.10.1/lib/scala-library.jar":"`dirname $0`/lib/workstealing_2.10-0.1.jar":"`dirname $0`/target/scala-2.10/classes/" \
     "Mandelbrot" \
| tee data.precsv
   

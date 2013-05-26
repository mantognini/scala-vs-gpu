#!/bin/sh

for file in *.precsv;
do
	sed -e '/#rounds = [1,2]$/,/.*/d;/#/d' "$file" > "`basename -s .precsv "$file"`.csv"
done


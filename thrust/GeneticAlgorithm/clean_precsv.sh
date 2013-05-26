#!/bin/sh

for file in *.precsv;
do
	sed -e '/#/d' "$file" > "`basename -s .precsv "$file"`.csv"
done


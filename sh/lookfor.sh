#!/bin/bash

sed 's/\"//g' -i $1

touch path.txt

while read -r line
do
 if echo ${line}| grep -qv '#';then
 path=$(printf "${line}"|awk -F $'\t' '{print $1}')
 chip=$(printf "${line}"|awk -F $'\t' '{print $2}')
 lane=$(printf "${line}"|awk -F $'\t' '{print $3}')
 barcode=$(printf "${line}"|awk -F $'\t' '{print $4}')
 sample=$(printf "${line}"|awk -F $'\t' '{print $5}')
 echo ${sample}
   for r in $(echo ${barcode}|sed 's/,/ /g')
   do
   list=$(find ${path}/${chip}/${lane} -name "${chip}_${lane}_${r}.fq.gz"|sort)
   echo ${list}
   list=$(find ${path}/${chip}/${lane} -name ${chip}_${lane}_${r}_?.fq.gz|sort)
   echo ${list}
   done
 echo "------"
 fi
done < $1 > path.txt

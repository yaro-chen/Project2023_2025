#!/bin/bash

target="AMR_gene_list.txt"
AMR=$(cut -f1 $target|grep -v '#'|sort -u)
trc=$(date +%y%m%d)
touch log_${trc}
echo "Execution time: $(date)" > log_${trc}
echo -e "AMR genes: \n${AMR} " | tee -a log_${trc}


for i in ${AMR}
do
list=$(grep $i ${target}|cut -f4)
datasets download gene accession ${list} --filename "${i}.zip" && ( echo -e "\n${i}.zip was downloaded"|tee -a log_${trc})
done

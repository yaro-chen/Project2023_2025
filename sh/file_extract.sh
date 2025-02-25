#!/bin/bash

ziplist=$(ls *.zip)
index_name=$1

echo ${ziplist}
mkdir -p ~/ncbi_datasets/${index_name}_index
output="/home/yrc/ncbi_datasets/${index_name}_index"

for i in ${ziplist}
do
filename=$(echo ${i%.*})
echo ${filename}
unzip $i && mv ncbi_dataset ${filename}
mv ${filename}/data/* "${output}" && rm -rf ${filename}/data
done



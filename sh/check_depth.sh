#!/bin/bash

if [[ $1 == "--help" || $1 == "-h" ]];then
  echo '$1 is the file path of your query genelist, genes are separated by ',''
  echo '$2 is the prefix for output files'
  echo '$3 is the file path of bam file list to calculate sequencing performance, if given 'True',new bam files will be collected'
  exit 0
fi

query=$(realpath $1)
prefix="$2"

if [[ $3 == "True" || $3 == "true" ]];then
 read -p "Enter keyword for searching WES bam files : " keyword
 echo "${keyword} checked."
 find ${folderpath} -name "*${keyword}*.bam"|grep -v 'cnv' >> bamfile_${keyword}_list
 bam=${bamfile_${keyword}_list}
else
 bam=$(realpath $3)
fi

echo "${bam} checked"

dir=$(dirname $1)
cd ${dir}

NOTIN=$(sed 's/,/ /g' ${query})

for i in ${NOTIN}
do
  bedregion=$(awk -v gene="${i}" '$4 == gene {print}' ${bedfile})
  if [[ $(echo "${bedregion}"|wc -w) -eq 0 ]];then
    echo "Check the name of ${i} gene in the bed file" | tee -a depth_gene_check.log
  else
    printf "%s\n" "${bedregion}"|while read -r line;do printf "%s\n" "${line}" >> target_region.temp.bed ;done
  fi
done

(sort -u target_region.temp.bed > ${prefix}_target_region.bed) && rm -vf target_region.temp.bed

while read -r line
do
  sambamba depth base -c 0 -F "" -L ${prefix}_target_region.bed -t 16 -q 20 ${line} >> ${prefix}_basedepth.txt
done < ${bam}

echo -e "#Gene\tChr\tRegion\tBase_average_depth\tPercent(depth>=20)"|tee -a ${prefix}_base_stats.txt

for i in ${NOTIN}
do
 start=$(grep -w "${i}" ${prefix}_target_region.bed|cut -f2|sort -n|head -n 1)
 end=$(grep -w "${i}" ${prefix}_target_region.bed|cut -f3|sort -n|tail -n 1)
 chr=$(grep -w "${i}" ${prefix}_target_region.bed|cut -f1|uniq)

    all=$(awk -v chr=${chr} -v min=${start} -v max=${end} '$1 == chr && $2 >= min && $2 <= max {print $3}' ${prefix}_basedepth.txt)
    all_count=$(echo ${all}|wc -w)
    all_avg=$(echo ${all}|awk '{for (i = 1; i <= NF; i++) sum += $i} END {if (NF > 0) printf "%.2f",sum/NF}')
    gt20=$(awk -v chr=${chr} -v min=${start} -v max=${end} '$1 == chr && $2 >= min && $2 <= max && $3 >=20 {print $3}' ${prefix}_basedepth.txt)
    gt20_count=$(echo ${gt20}|wc -w)
    gt20_percent=$(echo ${gt20_count} ${all_count}|awk '{printf "%.2f%",100*$1/$2}')
    echo -e "${i}\t${chr}\t${start}-${end}\t${all_avg}\t${gt20_percent}"|tee -a ${prefix}_base_stats.txt
done 


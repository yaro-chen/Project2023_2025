#!/bin/bash

less MANE.GRCh38.v1.4.summary.txt.gz|grep -v '#'|grep -i 'MANE Select'|while read -r line;do
   info=$(printf "${line}"|awk -F '\t' '{print $4"\t"$6}')
   printf "${info}\n"|tee -a hg38_MANE_type2.txt
done

echo "-------------------------------------------------------------------------------"

less MANE.GRCh38.v1.4.summary.txt.gz|grep -v '#'|grep -i 'MANE plus'|while read -r line;do
  gene=$(printf "${line}"|awk -F '\t' '{print $4}')
  plus=$(printf "${line}"|awk -F '\t' '{print $6}')
  old_info="$(awk -F '\t' -v gene=${gene} '$1 == gene' hg38_MANE_type2.txt)"
  if [[ ${old_info} != "" ]];then
  echo ${old_info} ${plus}
  echo "s|${old_info}|${old_info}/${plus}|g"
  sed -i "s|${old_info}|${old_info}/${plus}|g" hg38_MANE_type2.txt
  else
  echo -e "$4\t$6"|tee -a hg38_MANE_type2.txt
  fi

done






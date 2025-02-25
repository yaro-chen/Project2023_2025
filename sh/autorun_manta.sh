#!/bin/bash

help(){
echo ' $1 is the absolute path of bam file '
echo ' $2 is the name for the output directory '
}

if [[ $1 == "--help" || $1 == "-h" ]];then
 echo ""
 help
 exit 0
fi

echo "Bam file : $1"

/manta-exec/bin/configManta.py --bam $1 \
--referenceFasta /tmp/Ref_samples/hg19/hg19.fa \
--exome \
--runDir /mnt/execute_py/$2 \
--generateEvidenceBam \
--callRegions ${bedfile}


if [ $? -eq 0 ];then
/mnt/execute_py/$2/runWorkflow.py -j 8
else
echo "something wrong during configuration"
fi

output="/mnt/execute_py/$2/results/variants"

for i in $(ls ${output}/*.vcf.gz|sort -r);do
   if echo ${i}|grep -q 'diploidSV';then
      java -Xmx8g -jar /snpEff/snpEff.jar -v hg19 ${i} -stats ${output}/${2}_diploidSV -htmlStats ${output}/${2}_diploidSV.html > ${output}/${2}_diploidSV.snpeff.vcf
   elif echo ${i}|grep -q 'candidateSV';then
      java -Xmx8g -jar /snpEff/snpEff.jar -v hg19 ${i} -stats ${output}/${2}_candidateSV -htmlStats ${output}/${2}_candidateSV.html > ${output}/${2}_candidateSV.snpeff.vcf
   elif echo ${i}|grep -q 'SmallIndels';then
      java -Xmx8g -jar /snpEff/snpEff.jar -v hg19 ${i} -stats ${output}/${2}_SmallIndels -htmlStats ${output}/${2}_SmallIndels.html > ${output}/${2}_SmallIndels.snpeff.vcf
   else
      echo "can not find expected vcf files !"
   fi
done


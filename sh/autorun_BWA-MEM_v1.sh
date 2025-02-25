#!/bin/bash

help(){
 echo "General usage: bash $(realpath $0) -f [config] -i [index] -o [output]"
 echo "    Options:"
 echo "         -f   Full or relative path of your config (in .txt); "
 echo "              please refer to config_STAR_demo.txt for the format."
 echo "              Note that multiple fq files should be separated by ',' ; fill 'NA' if there is no reverse fq files."
 echo "         -i   Full or relative path of the indexed fasta ;"
 echo "              e.g. the index for all antimicrobial resistence genes: AMR_genes_Ref"
 echo "         -o   The directory (Full or relative path) that will be created (if not exists) or used to store mapping results"
 echo ""
}


if [[ $1 == "--help" || $1 == "-h" ]];then
 echo ""
 help
 exit 0
fi

if [ "${BASH_SOURCE[0]}" == "${0}" ];then
  while getopts ":f:i:o:" option; do
     case $option in
     f)
       config="$OPTARG"
       ;;
     i)
       Index="$OPTARG"
       ;;
     o)
       Output="$OPTARG"
       ;;
     ?)
       echo "Invalid option: -${OPTARG}"
       exit 1
       ;;
     esac
  done
elif [ "${BASH_SOURCE[0]}" != "${0}" ];then
    config="$1"
    Index="$2"
    Output="$3"
fi

sed -i 's/\"//g' ${config};sed -i 's/\/\t//g' ${config}; sed -i 's/ //g' ${config}
index=$(realpath ${Index}); echo -e "\nCheck index: ${Index}"
output=$(realpath ${Output}); echo "Check output: ${Output}"
cwd=$(realpath ${config}|xargs dirname)
name_cwd="${cwd##/*/}"
 
if [[ -d ${output} ]];then
 echo "${output} already exits"
else
 mkdir -p ${output} && echo "${output} was created as the main destination"
fi

t=$(date +%y%m%d%H%M)
config_name=$(basename ${config}|cut -d '.' -f1)

function mk_folder {

mkdir -p ${output}/${i}_mapping && echo "${output}/${i}_mapping was created to store mapping results."

declare -g result="${output}/${i}_mapping"
declare -g trc=$(date +%y%m%d%H%M)
touch ${result}/autorun_log_${i}_${trc}

}

mkdir -p /mnt/dell5820/yrc/PFI_temp/${name_cwd}
temp="/mnt/dell5820/yrc/PFI_temp/${name_cwd}"
echo "Temp for storing merged fq : ${temp}"

function exist {
 declare -g Existcheck=$(find ${temp} -name *${i}*merge_clean*.fq.gz)
 declare -g Paircheck=$(echo ${Reverse}|grep -vw 'NA'|wc -l)
}

function lookfor {

 if [ -f $1 ] && [ $(lsof -w $1|wc -l) == 0 ];then
 echo -e "[$(date +%H:%M:%S)]\n$1 was completely uploaded "| tee -a ${result}/autorun_log_${i}_${trc}
 else
 echo "$1 is not yet found or still uploading !"
 fi

}

function concatenation {

 if [[ ${Paircheck} -eq 1 ]];then
  echo "Paired End analysis"
  echo "Concatenating fq files..."
  OriP1=$(echo ${Forward}|sed 's/,/ /g')
    for j in ${OriP1}
    do
    lookfor ${j}
    done
  touch ${temp}/${i}_pair1_merge.fq.gz && truncate -s 0 ${temp}/${i}_pair1_merge.fq.gz
  cat ${OriP1} >> ${temp}/${i}_pair1_merge.fq.gz && (echo "Fq pair1 concatenation was done" |tee -a ${result}/autorun_log_${i}_${trc}) || (echo "ERROR during pair1 concatenation !" |tee -a ${result}/autorun_log_${i}_${trc})
  OriP2=$(echo ${Reverse}|sed 's/,/ /g')
    for k in ${OriP2}
    do
    lookfor ${k}
    done
  touch ${temp}/${i}_pair2_merge.fq.gz && truncate -s 0 ${temp}/${i}_pair2_merge.fq.gz
  cat ${OriP2} >> ${temp}/${i}_pair2_merge.fq.gz && (echo "Fq pair2 concatenation was done" |tee -a ${result}/autorun_log_${i}_${trc}) || (echo "ERROR during pair2 concatenation !" |tee -a ${result}/autorun_log_${i}_${trc} )
  fastp -i ${temp}/${i}_pair1_merge.fq.gz -o ${temp}/${i}_pair1_merge_clean.fq.gz -I ${temp}/${i}_pair2_merge.fq.gz -O ${temp}/${i}_pair2_merge_clean.fq.gz -w 16 && rm -v fastp.html fastp.json
 elif [[ ${Paircheck} -eq 0 ]];then
  echo "Single End analysis"
  OriP=$(echo ${Forward}|sed 's/,/ /g')
  echo "Concatenating fq files..."
    for j in ${OriP}
    do
    lookfor ${j}
    done
  touch ${temp}/${i}_merge.fq.gz && truncate -s 0 ${temp}/${i}_merge.fq.gz
  cat ${OriP} >> ${temp}/${i}_merge.fq.gz
  echo "Fq concatenation was done" >> ${result}/autorun_log_${i}_${trc}
  fastp -i ${temp}/${i}_merge.fq.gz -o ${temp}/${i}_merge_clean.fq.gz -w 16 && rm -v fastp.html fastp.json
 else
 echo -e "\nError while concatenation !!!" | tee -a ${result}/autorun_log_${i}_${trc}
 exit 1
 fi

}

function mapping {

  if [[ ${Paircheck} -eq 1 ]];then
   bwa mem -t 16 ${index} ${temp}/${i}_pair1_merge_clean.fq.gz ${temp}/${i}_pair2_merge_clean.fq.gz | samtools sort -@ 16 -o ${result}/${i}_sorted.bam
  	if [ $(sambamba view ${result}/${i}_sorted.bam|wc -l) -gt 1 ];then
 	echo -e "[$(date +%H:%M:%S)]\nBWA mapping was successful: Paired" |tee -a ${result}/autorun_log_${i}_${trc}
        echo -e " [COMMAND] : bwa mem -t 16 ${index} ${temp}/${i}_pair1_merge_clean.fq.gz ${temp}/${i}_pair2_merge_clean.fq.gz \ \n | samtools sort -@ 16 -o ${result}/${i}_sorted.bam " >> ${result}/autorun_log_${i}_${trc}
	samtools index -@ 16 ${result}/${i}_sorted.bam
	else
 	echo -e "[$(date +%H:%M:%S)]\nERROR during bwa-mem mapping process!" | tee -a ${result}/autorun_log_${i}_${trc}
        mappingError=true
        fi
  elif [[ ${Paircheck} -eq 0 ]];then
   bwa mem -t 16 ${index} ${temp}/${i}_merge_clean.fq.gz | samtools sort -@ 16 -o ${result}/${i}_sorted.bam
        if [ $(sambamba view ${result}/${i}_sorted.bam|wc -l) -gt 1 ];then
        echo -e "[$(date +%H:%M:%S)]\nSTAR mapping was successful: Single" |tee -a ${result}/autorun_log_${i}_${trc}
        echo " [COMMAND] : bwa mem -t 16 ${index} ${temp}/${i}_merge_clean.fq.gz | samtools sort -@ 16 -o ${result}/${i}_sorted.bam " >> ${result}/autorun_log_${i}_${trc}
        samtools index -@ 16 ${result}/${i}_sorted.bam
        else
        echo -e "[$(date +%H:%M:%S)]\nERROR during bwa-mem mapping process!" | tee -a ${result}/autorun_log_${i}_${trc}
        mappingError=true
        fi
  fi

  index_name=$(dirname ${index}|xargs basename)

  sambamba depth region -L "$(dirname ${index}).bed" -c 0 ${result}/${i}_sorted.bam|sort > ${result}/${i}_cov.txt
  echo "BED file : $(dirname ${index}).bed "
  echo -e "\nSample : ${i}" >> ${output}/Summary_${config_name}_${t}

  if [[ $(cat ${result}/${i}_cov.txt|wc -l) -gt 1 ]];then
  echo "Annotation file : $(dirname ${index})_Annotation.txt " 
  (head -n 1 ${result}/${i}_cov.txt && join ${result}/${i}_cov.txt "$(dirname ${index})_Annotation.txt" -t $'\t' |sort -nk 4,4 -r ) > ${result}/${i}_Coverage.txt
  echo "[$(date +%H:%M:%S)]" >> ${result}/autorun_log_${i}_${trc}
  awk '{if( NR>1 && $5 > 0){print $7 " was detected with mean coverage : " $5 }}' ${result}/${i}_Coverage.txt | tee -a ${result}/autorun_log_${i}_${trc} >> ${output}/Summary_${config_name}_${t}
  echo "" >> ${result}/autorun_log_${i}_${trc}
  elif [[ "${mappingError}" = true ]];then
  echo "ERROR !!! Check your config ! " >> ${output}/Summary_${config_name}_${t}
  else
  echo -e "[$(date +%H:%M:%S)] No gene was detected \n" |tee -a ${result}/autorun_log_${i}_${trc} >> ${output}/Summary_${config_name}_${t}
  fi
}


function serialrun {
  local i=$1

  if [ -s ${output}/${i}_mapping/${i}_cov.txt ];then
   echo "${i} has been mapped to the index ; skip running ${i}"
  else
   touch ${output}/Summary_${config_name}_${t}
   mk_folder ; exist

   if [[ $(echo ${Existcheck}|wc -w) -ge 1 ]];then
    echo -e "\nRunning Sample: ${i}" | tee -a ${result}/autorun_log_${i}_${trc}
    echo -e "[$(date +%H:%M:%S)]\nFq files of ${i} have already been merged : " |tee -a ${result}/autorun_log_${i}_${trc}
    echo ${Existcheck}|xargs -n 1 echo | tee -a ${result}/autorun_log_${i}_${trc}
    mapping
   elif [[ $(echo ${Existcheck}|wc -w) -eq 0 ]];then
    echo -e "Running Sample: ${i}\n" | tee -a ${result}/autorun_log_${i}_${trc}
    concatenation
    mapping
   else
    echo "ERROR while checking the existence of old fastq in the temp !!!" |tee -a ${result}/autorun_log_${i}_${trc}
    exit 1
   fi

  fi
}


while read -r line
 do
  if [ "${BASH_SOURCE[0]}" == "${0}" ] && [ -n "$(echo ${line}| grep -ve 'NTC' -ve 'D6311' -ve '#'|grep 'JB')" ] ;then
   echo -e "\nline check : \n${line}"
   echo -e "\nExecuting the script directly..."
   i=$(printf "${line}"|awk -F $'\t' '{print $1}')
  elif [ "${BASH_SOURCE[0]}" != "${0}" ] && [ -n "$(echo ${line}| grep -ve 'NTC' -ve 'D6311' |grep 'JB')" ];then
   echo -e "\nExecuting the script from source..."
   echo -e "\nline check : \n${line}"
   i=$(printf "${line}"|awk -F $'\t' '{print $1}'|sed 's/\#//g')
  else
  echo -e "\nskip ${line}"
  continue 
  fi 
   echo "Mapping ${i}"
   Forward=$(printf "${line}"|awk -F $'\t' '{print $2}')
   Reverse=$(printf "${line}"|awk -F $'\t' '{print $3}')
   serialrun ${i}
 done < ${config}


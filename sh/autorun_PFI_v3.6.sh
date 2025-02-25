#!/bin/bash
# The aim of this bash execution: run kraken2 and bracken to assign microbiome taxonomy

help(){
 echo "General usage: bash $(realpath $0) [run_batch,cfd_check]"
 echo ""
 echo "***[ User Guide1 ]*** : choose [run_batch] when you want to set customized values for confidence and run sample(s) at a time"
 echo ""
 echo "   Usage: bash $(realpath $0) run_batch -f [config] "
 echo "     Options:"
 echo "           -f    FULL path of your config (either in .txt or .yml) ; "
 echo "                 please refer to either config_demo.yaml or config_demo.txt for the format."
 echo "                    Confidence: a value between 0 and 1; multiple values must be separated by ',' (e.g. 0.3,0.4)"
 echo "                    Database: kraken2_SD or Eupath46 or FDA"
 echo "                    PC: if the sample is your positive control, give it 'True'; otherwise 'False'"
 echo "                    Forward/Reverse : if the sample is single-ended, give <Reverse> - NA "
 echo "           -q    (optional) DISABLE the generation of QC report"
 echo "           -r    (optional) DISABLE antimicrobial resistence gene detection"
 echo ""
 echo -e "***[ User Guide2 ]*** : choose [cfd_check] when you want to test multiple confidence values for the positive control \n\t\t\t\t\t prior to running samples with the best-fitting confidence\n"
 echo "   Usage: bash $(realpath $0) cfd_check -f [config] -d [database] -c [confidence] "
 echo "     Options:"
 echo "           -f    FULL path of your config; please refer to either config_demo.yaml or config_demo.txt for the format;"
 echo "                 give Confidence and Database 'NA' in the config for [cfd_check]."
 echo "           -d    NAME of database (i.e. Eupath46 or kraken2_SD or All );"
 echo "                 note that once 'All' is chosen, confidence can only set to be 'AUTO'."
 echo "           -c    Multiple CONFIDENCE settings for kraken2, separated by ',' (e.g. 0.9,0.8) ;"
 echo "                 or you can choose 'AUTO' to run (0.9 to 0.3 for kraken2_SD, 0.3 to 0.1 for Eupath46)"
 echo "           -q    (optional) DISABLE the generation of QC report"
 echo "           -r    (optional) DISABLE antimicrobial resistence gene detection"
 echo -e "\n REMEMBER to activate conda environment for kraken2 usage : conda activate kraken2\n"
}

if [[ $1 == "--help" || $1 == "-h" ]];then
 echo ""
 help
 exit 0
elif [[ $1 != "cfd_check" && $1 != "run_batch" ]];then
 echo "invalid input : $1"
 echo -e "\n\033[31mPlease choose either cfd_check or run_batch function to run !!!\033[0m\n"
 help
 exit 1
fi


QC=true
AMR=true

cfd_check(){
while getopts ":f:c:d:qr" option; do
  case $option in
   f)
    Config="$OPTARG"
    ;;
   c)
    confidence="$OPTARG"
    ;;
   d)
    database="$OPTARG"
    ;;
   q)
    QC=false
    ;;
   r)
    AMR=false
    ;;
 esac
done

if [[ ${database} == "Kraken2_SD" ]];then
database="${database,}"
echo "Decapitalized the first letter for the name of Kraken2 database : ${database}!!!"
fi

if [[ ${confidence} != "AUTO" && $(echo ${confidence}|grep -E "0.[0-9]" |wc -l) != 0 ]];then
cfd=$(echo ${confidence}|sed 's/,/ /g')
echo -e "\nconfidence settings: ${cfd}"
elif [[ ${confidence} == "AUTO" && (${database} == "kraken2_SD" || ${database} == "Kraken2_SD") ]];then
cfd=$(seq 0.9 -0.2 0.3)
echo -e "\nconfidence settings:\n${cfd}"
elif [[ ${confidence} == "AUTO" && ${database} == "Eupath46" ]];then
cfd=$(seq 0.3 -0.1 0.1)
elif [[ ${confidence} == "AUTO" && ${database} == "All" ]];then
database="Eupath46 kraken2_SD"
echo -e "\nconfidence settings:\n${confidence}"
else
echo "ERROR in your confidence input"
exit 1
fi

}


run_batch(){
while getopts ":f:qr" option; do
  case $option in
   f)
    Config="$OPTARG"
    ;;
   q)
    QC=false
    ;;
   r)
    AMR=false
    ;;
 esac
done

}

"$@"

start=$(date +%s)

conac=$(echo $CONDA_DEFAULT_ENV)
if [[ ${conac} != "kraken2" ]];then
source /home/yrc/miniconda3/etc/profile.d/conda.sh
conda activate kraken2 && echo -e "\nconda environment was just activated ! Next time remember to activate kraken2 before running "
fi

if [[ $(echo ${Config##*/}|awk -F. '{print $NF}') == 'yaml' || $(echo ${Config##*/}|awk -F. '{print $NF}') == 'yml' ]];then
config=$(echo ${Config}|sed -E 's/yml|yaml/txt/')
python3 /home/yrc/test_sg/kraken2_run/configuration_v1.py -i ${Config} -o ${config}
elif [[ $(echo ${Config##*/}|awk -F. '{print $NF}') == 'txt' ]];then
sed -i -E -e 's/\"//g' -e '/^ *$|^$/d' -e 's/ //g' ${Config}
config=${Config}
else
echo "Error in the file extension; must be .txt or .yml !"
exit 1
fi

echo ""
samplelist=$(less ${config}|grep -v '^[[:space:]]*$'|awk -F'\t' '{print $1}'|grep -v '#'|sort -u|paste -s -d ' ')

echo "Samples : ${samplelist}"
cwd=$(dirname ${config})
if [[ ${cwd} == "." ]];then
cwd=$(pwd)
fi

echo "Current working directory: ${cwd}"

name_cwd="${cwd##/*/}"
mkdir -p /mnt/dell5820/yrc/PFI_temp/${name_cwd}
temp="/mnt/dell5820/yrc/PFI_temp/${name_cwd}"
echo "Temp for merged fq : ${temp}"

function mk_folder {

mkdir -p ${cwd}/${database}/${i}_c${cfd}
declare -g output="${cwd}/${database}/${i}_c${cfd}"
echo -e "\noutput dir: ${output}"
declare -g trc=$(date +%y%m%d%H%M)
touch ${output}/log_${trc}

}

function lookfor {
 local files=$(echo $1 |sed 's|,| |g')
for j in ${files}
do
 echo "look for files : $j"
 if [[ ! -f $j || $(lsof -w $j|wc -l) != 0 ]];then
  echo -e "$j is not found or still uploading ! "
  declare -g keep=false #skip this sample and continue with the next sample
 elif [[ -f $j && $(lsof -w $j|wc -l) == 0 ]];then
  echo -e "[$(date +%H:%M:%S)] \n$j was completely uploaded "| tee -a ${output}/log_${trc}
  declare -g keep=true
 fi
done
}

#run QC
function fastpQC {

if [ "${QC}" = true ];then

echo -e "\nRun QC analysis..."

mkdir -p ${cwd}/QC_report

  if [ -f ${cwd}/QC_report/${i}.html ];then
     echo -e "${i} QC report already exists, skip running ${i}\n"
  elif [ ! -f ${cwd}/QC_report/${i}.html ];then 
     list=$(find ${temp} -name ${i}*fq.gz)
     if [[ $(echo ${list}|wc -w) -eq 2 ]];then
        f1="${temp}/${i}_pair1_merge.fq.gz"
        f2="${temp}/${i}_pair2_merge.fq.gz"
        echo -e "${i} QC check:\n${f1} and ${f2}" 
        fastp -i ${f1} -o ${temp}/${i}_pair1_merge_clean.fq.gz -I ${f2} -O "${temp}/${i}_pair2_merge_clean.fq.gz" -h ${cwd}/QC_report/${i}.html -j ${cwd}/QC_report/${i}.json -w 16 
        echo -e "${i} QC report can be found at /home/yrc/test_sg/QC_report/${name_cwd}\n" | tee -a ${output}/log_${trc}
     elif [[ $(echo ${list}|wc -w) -eq 1 ]];then
        echo -e "${i} QC check:\n${list}" |tee -a ${log}
        fastp -i ${list} -o $(echo ${list}|sed "s/${i}_merge/${i}_merge_clean/") -h ${cwd}/QC_report/${i}.html -j ${cwd}/QC_report/${i}.json -w 16
        echo -e "${i} QC report can be found at /home/yrc/test_sg/QC_report/${name_cwd}\n" | tee -a ${output}/log_${trc} 
     else
        echo -e "ERROR in looking for ${i} fq files\n" | tee -a ${output}/log_${trc}
     fi
  else
    echo -e "ERROR while checking if ${i} QC report exists\n"|tee -a ${output}/log_${trc}
  fi

find ${cwd}/QC_report -type f -empty -print -delete

else

echo -e "\nQC report generation is disabled.\n"

fi

}


function concatenation {
 if [[ ${Paircheck} -eq 1 ]];then
  echo "Paired End analysis"
  echo "Concatenating fq files..."
    OriP1=${Forward}
    lookfor "${OriP1}"
    if [ "${keep}" = true ];then
      touch ${temp}/${i}_pair1_merge.fq.gz && truncate -s 0 ${temp}/${i}_pair1_merge.fq.gz
      echo ${OriP1}|sed 's|,| |g'|xargs -n 1 cat >> ${temp}/${i}_pair1_merge.fq.gz
      echo "Forward fastq concatenation was done" >> ${output}/log_${trc}
      OriP2=${Reverse}
      lookfor "${OriP2}"
        if [ "${keep}" = true ];then
          touch ${temp}/${i}_pair2_merge.fq.gz && truncate -s 0 ${temp}/${i}_pair2_merge.fq.gz
          echo ${OriP2}|sed 's|,| |g'|xargs -n 1 cat >> ${temp}/${i}_pair2_merge.fq.gz
          echo "Reverse fastq concatenation was done" >> ${output}/log_${trc}
          fastpQC
        fi
    else
     echo "fq files are still missing ! skip running ${i}"
    fi
  #echo ${OriP1} ${OriP2}|xargs -n 1 echo "fq files of ${i} : " | tee -a ${output}/log_${trc}
 elif [[ ${Paircheck} -eq 0 ]];then
  echo "Single End analysis"
  OriP=$(echo ${Forward})
  echo "Concatenating fq files..."
    lookfor "${OriP}"
  if [ "${keep}" = true ];then
  touch ${temp}/${i}_merge.fq.gz && truncate -s 0 ${temp}/${i}_merge.fq.gz
  echo ${OriP}|sed 's|,| |g'|xargs -n 1 cat >> ${temp}/${i}_merge.fq.gz
  echo "Fastq concatenation was done" >> ${output}/log_${trc}
  fastpQC
  fi
 else
 echo -e "\nError while concatenation !!!" | tee -a ${output}/log_${trc}
 fi
}


function kraken2_exec {

 if [[ ${database} == "kraken2_SD" || ${database} == "Kraken2_SD" ]];then
  DB="/mnt/dell5820/yrc/kraken2_standardDB_latest/kraken2_database_new"
  taxidLibrary="/home/yrc/test_sg/taxid_library"
 elif [[ ${database} == "Eupath46" ]];then
  DB="/mnt/dell5820/yrc/EuPathDB46"
  taxidLibrary="/mnt/dell5820/yrc/EuPathDB46_summary"
 elif [[ ${database} == "FDA" ]];then
  DB="/mnt/dell5820/PFI/PFI_database/database_FDA_ARGOS_20230828"
  taxidLibrary="/home/yrc/test_sg/taxid_library"
 else
  echo -e "\nError in the name of database !!!" |tee -a ${output}/log_${trc}
  exit 1
 fi

 echo "Database : ${database}"|tee -a ${output}/log_${trc}
 echo "[ COMMAND ] : " >> ${output}/log_${trc}
 if [[ ${Paircheck} -eq 1 ]];then
 printf "%s" \
 "kraken2 --db ${DB} --paired ${temp}/${i}_pair1_merge_clean.fq.gz ${temp}/${i}_pair2_merge_clean.fq.gz --threads 16 --gzip-compressed \
 --report ${output}/${i}_${cfd}_report.txt --confidence ${cfd} --output - --report-minimizer-data"|tee -a ${output}/log_${trc}|sh \
 && echo -e "\n\nKraken2 execution was successful : paired, confidence is ${cfd}" | tee -a ${output}/log_${trc}
 elif [[ ${Paircheck} -eq 0 ]];then
 printf "%s" \
 "kraken2 --db ${DB} ${temp}/${i}_merge_clean.fq.gz --threads 16 --gzip-compressed --report ${output}/${i}_${cfd}_report.txt --confidence ${cfd} \
 --output - --report-minimizer-data"|tee -a ${output}/log_${trc}|sh \
 && echo -e "\n\nKraken2 execution was successful : single, confidence is ${cfd}" | tee -a ${output}/log_${trc}
 else
 echo -e "\nError while checking PE/SE !!!" |tee -a ${output}/log_${trc}
 exit 1
 fi

 ###Bracken execution
 echo -e "\n[$(date +%H:%M:%S)]" >> ${output}/log_${trc}
 bracken -d ${DB} -i ${output}/${i}_${cfd}_report.txt -o ${output}/${i}_${cfd}_bracken.txt -w ${output}/${i}_${cfd}_report_withra.txt
 declare -g brackenCheck=$(find ${output} -name "${i}_${cfd}_bracken.txt"|wc -l)

 if [[ ${brackenCheck} -eq 1 ]];then
  echo -e "Bracken execution was successful" | tee -a ${output}/log_${trc} \
  && echo -e "[ COMMAND ]: bracken -d ${DB} -i ${output}/${i}_${cfd}_report.txt \ \n\t -o ${output}/${i}_${cfd}_bracken.txt -w ${output}/${i}_${cfd}_report_withra.txt" >> ${output}/log_${trc}
  (head -n 1 ${output}/${i}_${cfd}_bracken.txt && tail --lines +2 ${output}/${i}_${cfd}_bracken.txt | sort -t $'\t' -r -k 6,6 -n ) > ${output}/${i}_${cfd}_bracken_sorted.txt \
  || (echo "ERROR while sorting !!!" | tee -a ${output}/log_${trc})
  echo -e "\nkraken2 report: ${output}/${i}_${cfd}_report.txt "
  echo "kraken2 report with relative abundace: ${output}/${i}_${cfd}_report_withra.txt "
  echo "bracken report(sorted): ${output}/${i}_bracken_sorted.txt "
  #use Rscript to classify different microbes of kingdoms
  echo -e "\nRunning R for taxonomy classification..."
  brackenReport="${output}/${i}_${cfd}_bracken_sorted.txt"
  Rscript /home/yrc/test_sg/kraken2_run/PFI_classification_all_v1.1.R ${output} ${brackenReport} ${taxidLibrary} ${i} ${database} ${cfd}
  Routput=$(find ${output} -name *${database}_${i}_${cfd}*.txt|wc -l)
  	if [[ ${Routput} -eq 6 || ${Routput} -eq 7 ]];then
  	echo -e "\nRscript execution was successful" >> ${output}/log_${trc}
  	else
	echo "ERROR while Rscript execution !!!" | tee -a ${output}/log_${trc}
        fi
 else
  echo -e "\nNo bracken output !!!" | tee -a ${output}/log_${trc}
 fi


}

function serialrun {
   local i=$1
   local cfd=$2

   mk_folder
   Existcheck=$(find ${temp} -name *${i}*merge_clean*.fq.gz|wc -l)
   Paircheck=$(echo ${Reverse}|grep -vw 'NA'|wc -l)

 if [[ ${Existcheck} -ge 1 ]];then
   echo "Execution time : $(date)" > ${output}/log_${trc}
   echo -e "\nRunning Sample: ${i}" | tee -a ${output}/log_${trc}
   echo -e "\n[$(date +%H:%M:%S)]" >> ${output}/log_${trc}
   echo "fq files of ${i} have already been merged : " |tee -a ${output}/log_${trc}
   find ${temp} -name *${i}*merge_clean*.fq.gz|xargs -n 1 echo |tee -a ${output}/log_${trc} #major difference in this if-else statement
   declare -g keep=true
   echo -e "\n[$(date +%H:%M:%S)]" >> ${output}/log_${trc}
   kraken2_exec
   echo -e "\n[$(date +%H:%M:%S)]" >> ${output}/log_${trc}
   end=$(date +%s)
   echo -e "\nTotal running time: $((end-start)) seconds"
   echo -e "Finish running kraken2 execution of ${i} \n" | tee -a ${output}/log_${trc}
 elif [[ ${Existcheck} -eq 0 ]];then
   echo "Execution time : $(date)" > ${output}/log_${trc}
   echo -e "\nRunning Sample: ${i}" | tee -a ${output}/log_${trc}
   ##(find /mnt/dell5820/yrc/PFI_temp -maxdepth 1 -mindepth 1 -type d -not -name "${name_cwd}"|xargs -n 1 rm -rvf)
   concatenation ${i}
   if [ "${keep}" = true ];then
     echo -e "\n[$(date +%H:%M:%S)]" >> ${output}/log_${trc}
     kraken2_exec
     echo -e "\n[$(date +%H:%M:%S)]" >> ${output}/log_${trc}
     end=$(date +%s)
     echo -e "\nTotal running time: $((end-start)) seconds"
     echo -e "Finish running kraken2 execution of ${i} \n" | tee -a ${output}/log_${trc}
   else
     echo "Errors in finding fastq files of ${i}"
   fi 
 else
   echo -e "\n ERROR while checking the existence of old fastq in the temp " |tee -a ${output}/log_${trc}
 fi

}

function Others_run {
  local cfd=$1
  for c in ${cfd}
    do
      while read -r line
       do
         if echo ${line}|grep -v '#'|grep -qwv ${PC};then
           i=$(printf "${line}"|awk -F $'\t' '{print $1}')
           Forward=$(printf "${line}"|awk -F $'\t' '{print $2}')
           Reverse=$(printf "${line}"|awk -F $'\t' '{print $3}')
           serialrun ${i} ${c}
           if [ "${keep}" = true ]; then
             printf "${line}\n"|sed "s/\(${i}\)/#\1/g" >> ${config}.temp
           else
             echo "Could not find fq files of ${i} !"
             printf "${line}\n" >> ${config}.temp
             continue
           fi
         fi
       done < ${config}
    done
}

function QC_test {

 local database=$1

 et=$(date +%y%m%d%H%M)
 mkdir -p ${cwd}/${database}
 touch ${cwd}/${database}/log_confidence_${et}
 echo "Execution time : $(date)" >> ${cwd}/${database}/log_confidence_${et}

 PC=$(awk '{if ($6 == "True" || $6 == "TRUE" || $6 == "true" ) print $1}' ${config})

 if [[ ! ${PC} ]];then
 echo "You forgot to determine positive control for cfd_check !!!"
 echo "Program stopped"
 exit 1
 fi

 for c in ${cfd}
   do
      while read -r line
      do
	echo ${line}
        if echo ${line}|grep -v '#'|grep -qw ${PC};then
           Forward=$(printf "${line}"|awk -F $'\t' '{print $2}')
           echo ${Forward}
           Reverse=$(printf "${line}"|awk -F $'\t' '{print $3}')
           echo ${Reverse}
           serialrun ${PC} ${c}
           PCkeep=${keep}
           if [ "${PCkeep}" = true ];then
             printf "${line}\n"|sed "s/\(${PC}\)/#\1/g" >> ${config}.temp 
           elif [ "${PCkeep}" = false ];then
             echo "Could not find fq files of positive control!"
             printf "${line}\n" >> ${config}.temp
             break 2
           fi
        elif ${PCkeep} && ${repeat} && echo ${line}|grep -v '#'|grep -qvw ${PC};then
           PC=$(echo ${PC}|sed 's/\#//')
           QCcheck=$(grep "${PC}_${c}" ${cwd}/${database}/Confidence_list.txt|sort -u|cut -f14)
           echo "Confidence ${c} QC score: ${QCcheck}"
             if [[ "${QCcheck}" == "10" ]];then
                i=$(printf "${line}"|awk -F $'\t' '{print $1}')
                Forward=$(printf "${line}"|awk -F $'\t' '{print $2}')
                Reverse=$(printf "${line}"|awk -F $'\t' '{print $3}')
                serialrun ${i} ${c}
                  if [ "${keep}" = true ]; then
                     printf "${line}\n"|sed "s/\(${i}\)/#\1/g" >> ${config}.temp
                  else
                     echo "Could not find fq files of ${i} !"
                     printf "${line}\n" >> ${config}.temp
                     continue
                  fi
             else
                echo "QC was not perfect, skipping runnning other samples for this round in confidence ${c}"
                printf "${line}\n" >> ${config}.temp
                continue 
             fi
        elif ${PCkeep} && ${repeat} && echo ${line}|grep -q '#';then
              printf "${line}\n" >> ${config}.temp
        elif echo ${line}|grep -q '#';then
              printf "${line}\n" >> ${config}.temp
        fi
      done < ${config}

      if [[ "${repeat}" == "false" && ${brackenCheck} == "1" ]];then
        echo "[$(date +%H:%M:%S)]" >> ${cwd}/${database}/log_confidence_${et}
        echo "Running Rscript for confidence check..."
        Rscript /home/yrc/test_sg/kraken2_run/PC_check_v1.1.R ${cwd}/${database} ${output} ${PC} ${c}
        echo ""
        echo "check ${PC} QC with confidence ${c} : "| tee -a ${cwd}/${database}/log_confidence_${et}
        QCresult=$(cut -f14 ${cwd}/${database}/${PC}_${c}_QC.txt|sed -n '2p') ; rm -v ${cwd}/${database}/${PC}_${c}_QC.txt
           if [[ ${QCresult} == '10' ]];then
             echo "QC was passed ! Run other samples in the config" |tee -a ${cwd}/${database}/log_confidence_${et}
             samplelist_others=$(cut -f1 ${config}|grep -v '#'|grep -v ${PC})
             echo ${samplelist_others}
             Others_run ${c}
           else
             echo "QC may be better with other confidence; skip running remaining samples"|tee -a ${cwd}/${database}/log_confidence_${et}
           fi
      elif [[ "${repeat}" == "false" && ${brackenCheck} != "1" ]];then
         echo -e "[$(date +%H:%M:%S)]" >> ${cwd}/${database}/log_confidence_${et}
         echo "No bracken output !!! Confidence ${c} may be too high" | tee -a ${cwd}/${database}/log_confidence_${et}
      elif [[ "${repeat}" == "true" ]];then
       echo "QC in confidence ${c} has already been checked !"
       rm -f -v ${cwd}/${database}/log_confidence_${et}
      fi
 done

 if [ "${PCkeep}" = true ];then
  checkQC=$(tail --lines +2 ${cwd}/${database}/Confidence_list.txt|sort -u|cut -f14)
  checkConta=$(tail --lines +2 ${cwd}/${database}/Confidence_list.txt|sort -u|cut -f12)
    if [[ $(echo ${checkQC}|xargs -n 1 echo|grep -w '10'|wc -l) -eq 0 && $(echo ${checkConta}|xargs -n 1 echo|grep -i 'Likely'|wc -l ) -le 2 ]];then
      echo -e "\n[$(date +%H:%M:%S)]" | tee -a ${cwd}/${database}/log_confidence_${et}
      choice=$(tail --lines +2 ${cwd}/${database}/Confidence_list.txt|sort -u|sort -t $'\t' -k 14,14 -n -r|head -n 2|cut -f1|awk -F'_' '{print $NF}'|paste -s -d ' ')
      echo -e "\nNo confidence is perfect; choose confidence with the top 2 QC : ${choice}" | tee -a ${cwd}/${database}/log_confidence_${et}
      samplelist_others=$(cut -f1 ${config}|grep -v '#'|grep -vw ${PC})
      echo ${samplelist_others}
      Others_run "${choice}"
    elif [[ $(echo ${checkQC}|xargs -n 1 echo|grep -w '10'|wc -l) -eq 0 && $(echo ${checkConta}|xargs -n 1 echo|grep -i 'Likely'|wc -l ) -ge 3 ]];then
      echo -e "\n[$(date +%H:%M:%S)]" | tee -a ${cwd}/${database}/log_confidence_${et}
      choice=$(tail --lines +2 ${cwd}/${database}/Confidence_list.txt|sort -u |cut -f1|awk -F'_' '{print $NF}'|sort -nr|head -n 2|paste -s -d ' ')
      echo "Likely contamination !!! Choose the 2 highest confidence : ${choice} " | tee -a ${cwd}/${database}/log_confidence_${et}
      samplelist_others=$(cut -f1 ${config}|grep -v '#'|grep -vw ${PC})
      Others_run "${choice}"
    fi
     echo -e "\n Convert confidence list to .xlsx "
     python3 /home/yrc/test_sg/kraken2_run/txt2xls.py "${cwd}/${database}"
 elif [[ "${PCkeep}" = false && $((runtime-start)) -lt 86400 ]];then
    while read -r line
    do
      if echo ${line}|grep -v '#'|grep -qwv ${PC};then
         i=$(printf "${line}"|awk -F $'\t' '{print $1}')
         echo "Positive control has not yet been found ! Skip running ${i}"
         echo "${line}"
         printf "${line}\n" >> ${config}.temp
      fi
    done < ${config}
 elif [[ "${PCkeep}" = false && $((runtime-start)) -gt 86400 ]];then
     echo "fq files of the positive control were not found for a long time!"
     echo "Run samples except the Positive control in all confidences: ${cfd}" |tee -a ${cwd}/${database}/log_confidence_${et}
     Others_run "${cfd}"
 fi

}


if [[ $1 == "run_batch" ]];then

 execution(){
  while read -r line
  do
   if echo ${line}| grep -qv '#';then
     i=$(printf "${line}"|awk -F $'\t' '{print $1}')
     Forward=$(printf "${line}"|awk -F $'\t' '{print $2}')
     Reverse=$(printf "${line}"|awk -F $'\t' '{print $3}')
     cfd=$(printf "${line}"|awk -F $'\t' '{print $4}'|sed 's/ //g'|sed 's/,/ /g')
     database=$(printf "${line}"|awk -F $'\t' '{print $5}')
     if [[ ${database} == "Kraken2_SD" ]];then
     database="${database,}"
     echo "Convert the first letter to lowercase for the name of kraken2_SD database: ${database}"
     fi
       for c in ${cfd}
       do
         serialrun ${i} ${c}
         if [ "${keep}" = false ];then
           echo "fq files has not been completely uploaded or found, skipping running ${i}"
           printf "${line}\n" >> ${config}.temp
           continue 2
         fi
       done
    printf "${line}\n" | sed "s/\(${i}\)/#\1/g" >> ${config}.temp
   elif  echo ${line}| grep -q '#';then
     printf "${line}\n" >> ${config}.temp
   fi
  done < ${config}
 }

 while true
 do
   touch ${config}.temp
   execution
   mv ${config}.temp ${config}
   runtime=$(date +%s)
    if [[ $(grep '#' ${config}|wc -l) == $(less ${config}|wc -l) ]];then
     echo "Finish running all samples !"
     break
    elif [[ $((runtime-start)) -gt 86400 ]];then
     yet=$(cut -f1 ${config}|grep -v '#'|paste -s -d " ")
     for i in ${yet};do
       cat ${cwd}/*/*${i}*/*log* >> ${cwd}/log_summary_${i}
       ls ${cwd}/*/*${i}*/*log*|grep -v 'summary'|xargs -n 1 rm
     done
     echo -e "\n\033[31mPlease refer to the config to check sample ${yet}, which have not yet been run\033[0m\n"
     break
    fi
 sleep 3600 && echo -e "\n\033[31mSleep is over and start a new search\033[0m\n"
 done

elif [[ $1 == "cfd_check" ]];then

 run(){

  declare -g circle=$((${circle}+1))
  if [[ ${circle} > 1 ]];then
    declare -g repeat=true
    echo -e "\nstarting a new loop ! "
  else
    declare -g repeat=false
  fi

   if [[ $(echo ${database}|wc -w) -eq 1 ]];then
     QC_test ${database}
   elif [[ $(echo ${database}|wc -w) -ge 2 ]];then
     for d in ${database}
     do
       if [[ ${d} == 'Eupath46' ]];then
         cfd=$(seq 0.3 -0.1 0.1)
         QC_test ${d}
       else
         cfd=$(seq 0.9 -0.2 0.3)
         QC_test ${d}
       fi
     done
   fi
 }

 circle=0

 while true
 do
   touch ${config}.temp
   run
   mv ${config}.temp ${config}
   awk -i inplace '!seen[$0]++' ${config}
   runtime=$(date +%s)
    if [[ $(grep '#' ${config}|wc -l) == $(less ${config}|wc -l) ]];then
     echo "Finish running all samples !"
     break
    elif [[ $((runtime-start)) -gt 86400 ]];then
     yet=$(cut -f1 ${config}|grep -v '#'|paste -s -d " ")
     for i in ${yet};do
       cat ${cwd}/*/*${i}*/*log* >> ${cwd}/log_summary_${i}
       ls ${cwd}/*/*${i}*/*log*|grep -v 'summary'|xargs -n 1 rm
       if echo ${i}|grep -q 'D6311' ;then
         cat ${cwd}/*/*log_confidence* >> ${cwd}/log_confidence_summary
         ls ${cwd}/*/*log_confidence* |grep -v 'summary'|xargs -n 1 rm
       fi
     done
     echo -e "\n\033[31mPlease refer to the config to check ${yet}, which have not yet been run\033[0m\n"
     break
    fi
 sleep 3600 && echo -e "\n\033[31mSleep is over and start a new search\033[0m\n"
 done

fi


#Antibiotic resistance gene detection

if [ "${AMR}" = true ];then

echo -e "\nRun Antibiotic resistance gene detection..."
echo "config : ${config}"
echo "output : ${cwd}/AMR_detection"

source /home/yrc/ncbi_datasets/autorun_BWA-MEM_v1.sh ${config} "/home/yrc/ncbi_datasets/BWA_AMR_gene_index/AMR_genes_Ref/AMR_genes_Ref.fasta" "${cwd}/AMR_detection"

else

echo -e "\nAMR detection is disabled.\n"

fi



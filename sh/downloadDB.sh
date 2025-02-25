#!/bin/bash

start=$(date +%s)

cd /opt/

touch ./log_$(date +%s)

log="./log_$(date +%s)"

echo "Running start : $( date +%Y/%m/%d" "%H:%M:%S) " > ${log}

#Download reference genomes (Prokaryotes and Viruses) from BVBRC database

function db_archaea(){
p3-all-genomes --eq superkingdom,$1 --in host_group,Human --in host_group,undefined --in genome_status,Complete \
               --ne genome_quality,Poor --attr genome_id --attr taxon_id --attr assembly_accession --attr genus --attr species --attr strain \
               --attr superkingdom --attr reference_genome --attr refseq_accessions --attr genome_quality --attr host_group --attr genbank_accessions \
               --attr genome_status > $1_metadata_Humanhost.txt
result=$(echo $?)

 if [ ${result} -eq 0 ]
 then
 echo -e "\n[$(date +%H:%M:%S)] ${i}_metadata was downloaded" | tee -a ${log}
 else
 echo -e "\nERROR while downloading ${i} metadata" | tee -a ${log}
 exit 0
 fi

echo "Running statistics using R..."
Rscript Metadata_statistics.R Pro /opt/ ${i}_metadata_ref.txt ${log}

}



#Download reference genomes (Eukaryotes) from VEuPathoDB

echo ""
python3 VeuPathoDB_parse.py

Eupatho=$(ls *.csv)

if [ $(echo $?) -eq 0 ]
then
csvtool -t COMMA -u TAB cat ${Eupatho} > Eupatho_metadata.txt
echo -e "\n[$(date +%H:%M:%S)] Eukaryotic pathogen database was downloaded" | tee -a ${log}
(head -n 1 Eupatho_metadata.txt && awk -F '\t' '$12=="yes"||$12=="Yes" {print $0}' Eupatho_metadata.txt|sort -t $'\t' -nk 15 ) > Eupatho_metadata_ref.txt

 if [ $(cut -f 12 Eupatho_metadata_ref.txt|grep -i 'yes'|wc -l) -gt 300 ]
 then
 echo -e "\n[$(date +%H:%M:%S)] Eukaryotic pathogen ref database was created " | tee -a ${log}
 else
 echo -e "\n ERROR while creating Eukaryotic pathogen database, check the VEuPathoDB website or the downloaded csv file" | tee -a ${log}
 exit 0
 fi

echo "Running statistics using R..."
Rscript Metadata_statistics.R Eu /opt/ Eupatho_metadata_ref.txt ${log}

else
echo -e "\n ERROR while downloading Eukaryotic pathogen database" | tee -a ${log}
exit 0
fi


end=$(date +%s)

echo -e "\nTotal running time: $((end-start)) seconds" >> ${log}

echo "...finish" >> ${log}

### IF there is any need to replace Blank cell to NULL value...use the following command
##awk 'BEGIN{FS=OFS="\t"} {for(i=1;i<=NF;i++){if($i==""){$i="NULL"}}} 1' ${i}_metadata_ref.txt > ./${i}_metadata_ref_modified.txt


fasta=$(ls *Ref.fasta)

echo ${fasta}

for i in ${fasta}
do
 fastaname=$(echo ${i}|cut -d '.' -f1)
 while read -r line
  do
   if echo ${line}|grep -q '>';then
   length=$(echo ${line}|awk -F' ' '{print $1}'|awk -F':' '{print $2}'|sed 's/c//g'|awk -F'-' '{print $2 - $1}'|sed 's/-//')
   info=$(echo ${line}|awk -F' ' -v i=${length} '{print $1"\t"0"\t"i}'|sed 's/>//')
   printf "${info}\n"
   fi
  done < ${i} > ${fastaname}.bed
done

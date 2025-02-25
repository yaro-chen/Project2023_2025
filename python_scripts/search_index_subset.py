# -*- coding: utf-8 -*-
"""
Created on Tue Apr 16 16:56:51 2024

@author: yr.chen
"""
import os
import gzip
import json

os.chdir('D:\\others\\TaiwanBioBank_search\\')

with gzip.open('D:\\others\\TaiwanBioBank_search\\TaiwanBioBank_population_allelefreq.1517.tsv.gz','rb') as file :
    ori_file = file.readlines()
    
test = ori_file[:10]+ ori_file[5000000:5000030]+ori_file[8000000:8000020]+ori_file[13600000:13600020]
    
    #while line is not None and line != '':
     #   print(line) 

#chrnum = ['chr'+str(i) for i in range(1,23)] + ['chrX','chrY']

Twb = {'Header':[]}
header = ori_file[0].decode().split("\t")
header_dic = {str(header[0].replace("chr","")+":"+header[1]):header[3:15]}
Twb['Header'].append(header_dic)

chrnext = 2

order = []
for i,line in enumerate(test):
 if i > 0:
  line = line.decode("utf-8").split("\t")
  chrnum = line[0] 
  rs = list(set(line[2].split(',')))
  order.append(chrnum)
  length = len(set(order))
  new_line = {str(chrnum.replace("chr",""))+":"+str(line[1]):line[3:15]}
  print(new_line)
  Twb.setdefault(chrnum,[]).append(new_line) 
  
  if length == chrnext :
    done = length-1
    if done == 23:
     done = 'X'
    chrdone = 'chr'+str(done)
    print(chrdone, 'was all done !',sep = ' ')
    with open('TaiwanBiobank_dictionary'+'_'+chrdone+'.txt','w') as output:
     json.dump(Twb['Header']+Twb[chrdone],output)
    print(chrdone,'dictionary was constructed !')
    del Twb[chrdone]
    chrnext = chrnext+1

with open('TaiwanBiobank_dictionary'+'_'+'chrY'+'.txt','w') as output:
  json.dump(Twb['Header']+Twb['chrY'],output)
  print('chrY','dictionary was constructed !')

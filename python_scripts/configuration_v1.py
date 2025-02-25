# -*- coding: utf-8 -*-
"""
Created on Tue Jan 16 13:38:35 2024

@author: yr.chen
"""

import yaml
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i","--input",type=str)
parser.add_argument("-o","--output",type=str)
args = parser.parse_args()

print(args.input)

exit 

with open(args.input, 'r') as f:
    data = yaml.safe_load(f)
with open(args.output, "w") as newfile:
    newfile.write('#Sample' + '\t' + 'Forward' + '\t' + 'Reverse' + '\t' + 'Confidence' + '\t' + 'Database' + '\t' + 'PC' + '\n')

for i in data.keys():
    List = []
    if data[i]:
        List.append(i)
    for j in data[i].keys():
        if data[i][j] :
            List.append(data[i][j])
        elif data[i][j] is False :
            List.append(str(data[i][j]))
        else:
            List.append('NA')
    print(List)
    with open(args.output, "a") as newfile:
      k = 0
      while k <= len(List)-1 :
          if type(List[k]) is str :
              newfile.write(List[k] + '\t')
          elif type(List[k]) is list :
              newfile.write(','.join(List[k]) + '\t')
          elif type(List[k]) is float :
              newfile.write(str(List[k]) + '\t')
          elif type(List[k]) is bool :
              newfile.write(str(List[k]))
          else :
              newfile.write('Error' + '\t')
          k = k + 1
      newfile.write('\n')

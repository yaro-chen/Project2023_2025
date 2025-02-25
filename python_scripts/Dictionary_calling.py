# -*- coding: utf-8 -*-
"""
Created on Fri Apr 19 11:44:56 2024

@author: yr.chen
"""

import os
import ijson
import sys
import argparse
import time

parser = argparse.ArgumentParser(prog=sys.argv[0], description="search for genotypig population data from Taiwan Biobank")
subparsers = parser.add_subparsers(dest = 'command', help= 'sub-command help')
parser_m = subparsers.add_parser('multiple', help = '-i INPUT is required ; suitable for multiple queries')
parser_m.add_argument("-i","--input", help = "path of .csv or .xlsx file", type=str)

parser_d =  subparsers.add_parser('direct',help = 'your query will pop on screen; suitable for only 1 or few queries ')  

args = parser.parse_args()

header = ["Chrom:Position","dbSNPid", "Ref.", "AA", "AC", "AG", "AT", "CC", "CG", "CT", "GG", "GT", "TT", "Others"]

def direct():
    from pandas import DataFrame
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    os.chdir(script_dir)
    Chr = str(input("Chromosome number (e.g. 1) : ")).strip()
    Pos = str(input("Position (e.g. 10007) : ")).strip()
    start_time = time.time()
    key = Chr+":"+Pos
    key_item = key+".item"
    file = 'TaiwanBioBank_dictionaries/TaiwanBiobank_dictionary_'+'chr'+Chr+'.json' 
    parser = ijson.items(open(file,'rb'),key_item) 
    result = list(parser)
    if not result:
        print("Your query does NOT exist !")
        return
    elif type(result[0]) == list:
        for i in result:
          i.insert(0, key)
        df = DataFrame(result,columns=header)
      #print(df)
    elif type(result[0]) == str:
        result.insert(0, key)
        df = DataFrame([result],columns=header)
    else:
        print("Error occurred in your query !")
    print(df)
    end_time = time.time()
    print("\nElapsed time : ", round(end_time-start_time,2),"seconds")

def multiple():
    import csv
    start_time = time.time()
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    os.chdir(script_dir)
    output = open(args.input.replace(".txt","_Genotype.xls"),"a", newline='')
    writer = csv.writer(output, delimiter ="\t")
    writer.writerows([header])
    with open(args.input, 'r') as query:
      keys = query.readlines()
      for i in keys:
          if not i.startswith("#"):
              key = i.replace(" ", "").strip()
              print("Search",key)
              key_item = key+".item"
              Chr = key.split(":")[0]
              file = 'TaiwanBioBank_dictionaries/TaiwanBiobank_dictionary_'+'chr'+Chr+'.json'
              parser = ijson.items(open(file,'rb'),key_item) 
              result = list(parser)
              if not result:
                  print("Your query does NOT exist !")
                  result = [[key,"N/A"]]
              elif type(result[0]) == list:
                for j in result:
                    j.insert(0, key)
                #print(df)
              elif type(result[0]) == str:
                result.insert(0, key)
                result = [result]
              print(result)
              writer.writerows(result)
    output.close()           
    end_time = time.time()
    print("\nElapsed time : ", round(end_time-start_time,2),"seconds")     

if args.command == 'multiple':
    print('.txt as input')
    multiple()
    print("\nDone !")
elif args.command =='direct':
  while True:
    direct()
    print('\n')
    still = str(input("Continue query ? (Y/N) ")).strip()
    if still == 'Y' or still =='y':
        pass
    elif still == 'N' or still =='n':
        print('Program stop!')
        break
    else:
        print('Wrong input')
        continue
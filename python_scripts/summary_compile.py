# -*- coding: utf-8 -*-
"""
Created on Mon May 27 17:56:58 2024

@author: yr.chen
"""

from glob import glob
import pandas as pd
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-m","--main", help="the folder name")
parser.add_argument("-d","--database", type=str, help="the name of database used for analysis",choices=['E','K','F'])
parser.add_argument("-c","--confidence", type=str, help="the confidecne used for analysis")
args = parser.parse_args()


mainfolder = args.main
print(mainfolder)
confidence = args.confidence

database = args.database

os.chdir(mainfolder+"/"+args.database)

filename = "Summary"+"_"+database+"_"+confidence+".xlsx"

def compile(X):
    df = pd.DataFrame()
    filelist = glob(os.getcwd()+"/**/"+"*"+confidence+"_"+X+".txt",recursive=True)
    filelist.sort()
    print(f"\n filelist for {X}: \n")
    print("\n".join(filelist))
    order = ['JB','NTC','D6311','PC']
    targets = [i for j in order for i in filelist if (j in os.path.basename(i))]

    for i in targets:
        print("loading " + i + "...")
        sample = os.path.basename(os.path.dirname(i)).split('_c')[0]
        rows = os.popen(f'less {i}|wc -l')
        length = int(rows.read())
        rows.close()
        if length > 1 :
            test = pd.read_csv(i, sep="\t").get(['name','new_est_reads','fraction_in_percent'])
            test['new_est_reads'] = test['new_est_reads'].astype(str).str.replace(',','')
            test['new_est_reads'] = pd.to_numeric(test['new_est_reads'])
            test = pd.concat([test.columns.to_frame().T, test], ignore_index=True)
            test.loc[-1] = [sample,"",""] ; test.index = test.index + 1 ; test.sort_index(inplace = True)
            test.insert(len(test.columns),"","")
            df = pd.concat([df,test],axis=1)
        else :
            test = pd.DataFrame([sample,"not detected"])
            test.insert(len(test.columns), "", "")
            df = pd.concat([df,test],axis=1)
        df.to_excel(writer, sheet_name=X, index=False,header=False)

writer = pd.ExcelWriter(filename)
compile('bacteria')
compile('fungi')

if database == "E" :
    compile('virus')
    compile('nonfungiEu')
elif database in ["K","F"] :
    compile('viral')
    compile('protozoa')
else :
    print("Error in your database input!")
    exit()
    
writer.close() 
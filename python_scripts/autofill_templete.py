# -*- coding: utf-8 -*-
"""
Created on Mon Jun 17 15:19:53 2024

@author: yr.chen
"""

import os
import sys
import pandas as pd
from glob import glob
import yaml

script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
os.chdir(script_dir)

def convert(file):
    chipID = input("ChipID : ").strip()
    print(f"Check ChipID: {chipID}")
    end = input("Pair or single End ? (PE/SE) : ").strip()
    print(f'Check End: {end}')
    where = input("G400 or G50 ? : ").strip()

    folder = {'G400':'R100400180088', 'G50':'R1003A0180020'}
    target = folder[where]
    print(f'the main folder for data storage: {target}')
    
    df = pd.read_excel(file).filter(regex = 'Sample ID|DNB ID|Index')

    Dict = {}

    for i in range(len(df)):
        sample = df.iloc[i,0]
        lane = 'L0{}'.format(str(df.iloc[i,1]).split('_')[-1])
        barcode = df.iloc[i, 2]
        print(sample,lane,barcode)
        if end == 'PE' :
            if sample not in Dict :
                Dict[sample] = {'Forward' : [f'{target}/{chipID}/{lane}/{chipID}_{lane}_{barcode}_1.fq.gz'], 'Reverse' : [f'{target}/{chipID}/{lane}/{chipID}_{lane}_{barcode}_2.fq.gz']}
            else :
                Dict[sample]['Forward'].append(f'{target}/{chipID}/{lane}/{chipID}_{lane}_{barcode}_1.fq.gz')
                Dict[sample]['Reverse'].append(f'{target}/{chipID}/{lane}/{chipID}_{lane}_{barcode}_2.fq.gz')
        elif end == 'SE' :
            if sample not in Dict :
                Dict[sample] = {'Forward' : [f'{target}/{chipID}/{lane}/{chipID}_{lane}_{barcode}.fq.gz'], 'Reverse' : ['NA']}
            else :
                Dict[sample]['Forward'].append(f'{target}/{chipID}/{lane}/{chipID}_{lane}_{barcode}.fq.gz')
        else:
            print("Error in your sequencing end info, please check it again")
            exit()
    out_txt = f"config_{chipID}.txt"
    with open(out_txt,'w+') as output:
        output.write('#Sample\tForward\tReverse\tConfidence\tDatabase\tPC\n')
        for k,v in Dict.items():
            flist = ','.join(v['Forward'])
            rlist = ','.join(v['Reverse'])
            output.write(f'{k}\t{flist}\t{rlist}\tfloat\tName\tBoolean\n')
    print(f"config_{chipID}.txt was created.")
    out_yml = f"config_{chipID}.yml"
    with open(out_yml,'w+') as output:
        for k,v in Dict.items():
            Dict[k]['Confidence'] = '<float>'
            Dict[k]['Database'] = '<DatabaseName>'
            Dict[k]['PC'] = '<True/False>'
        yaml.dump(Dict,output, sort_keys=False)
    print(f"config_{chipID}.yml was created.")
for file in glob("*.xlsx"):
    print(f"check xlsx file: {file}")
    convert(file)
    
    





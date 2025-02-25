# -*- coding: utf-8 -*-
"""
Created on Tue Sep  3 09:38:25 2024

@author: yr.chen
"""

import pandas as pd
import glob

def convert(x,y):
    filesearch = f"{x}/*.{y}"
    files = glob.glob(filesearch)
    print(files)
    
    if y == 'call.cns' :
        for i in files:
            df = pd.read_csv(i,sep='\t')
            sort_df = df.sort_values(by = 'p_ttest', ascending = True)
            sort_df.to_excel(f'{i}.xlsx',index = False)
    elif y == 'bintest.cns':
        for i in files:
            df = pd.read_csv(i,sep='\t')
            df.to_excel(f'{i}.xlsx',index = False)
    else:
        print("Error in extension name")
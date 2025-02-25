# -*- coding: utf-8 -*-
"""
Created on Thu Sep 12 10:20:25 2024

@author: yr.chen
"""

import pandas as pd

genelist = pd.read_excel("D:\\Others\\ND_genelist\\ND_genelist.xlsx")
clinvar = pd.read_csv("D:\\Others\\ND_genelist\\20240912_clinvar_star_pheno.xls", sep= '\t').drop(columns = ['1-star','0-star'])
df = genelist.replace(r'\n','',regex = True).replace('\s*\\|\s*','|',regex = True).replace('\r','',regex = True)

def clinvar_check():

    comp = []
    for i in df.values.tolist():
        print(i)
        for j in i[2].split(','):
            gene = j.strip()
            kwd = i[1]
            disease = i[0]
            comp.append([disease,kwd,gene])

    panel = "D:\\Others\\ND_genelist\\WES_certificate_gene.txt"
    with open(panel, 'r') as file:
        panelgenes = file.read().split(',')

    output = open("D:\\Others\\ND_genelist\\ND_disease-gene_check.xls",'w+',encoding='UTF-8')
    output.write("Disease\tKeywords\tgene\tIN_panel\tClinvar_2star\tinfo_from_Clinvar\n")

    for i in comp:
        candidate = i[2]
        clvinfo = clinvar.loc[clinvar['gene'] == candidate, '4-star':'2-star']
        kwds = i[1]
        print(f"Check {candidate} with {kwds}")
        
        if candidate in panelgenes:
            i.append('IN panel')
        else:
            i.append('NOT in panel')
            
        check = {}
        for k in clvinfo.columns:
            if clvinfo[k].str.contains(kwds,case = False,regex = True).any():
                check[k] = True
                print(f"found {k} level evidence for {candidate}-{kwds}")
            else:
                check[k] = False
        if any(check.values()):
            i.append('V')
            disease_info = [k for k,v in check.items() if v == True]
            i.append(';'.join([(l +':'+clvinfo[l].values[0]) for l in disease_info]))
        else:
            i.append('X')
            print("OK! False")
            disease_info = [k for k,v in check.items() if v == False]
            i.append('N/A for no strong enough evidence')
        output.write('\t'.join(i)+'\n')

    output.close()
    
clinvar_check()
            
###### merge with previous information

new_df = pd.read_csv("D:\\Others\\ND_genelist\\ND_disease-gene_check.xls",sep='\t')

ref_info = pd.read_excel("D:\\Others\\ND_genelist\\ND帶因篩選整理.xlsx")

merged = pd.merge(new_df.assign(Disease = new_df['Disease'].str.title()),ref_info.assign(Disease = ref_info['Disease'].str.title()),on =['Disease','gene'],how = "left")

merged.drop_duplicates(inplace = True)

output_excel = "D:\\Others\\ND_genelist\\ND_disease-gene_check_final.xlsx"

merged.T.reset_index().T.to_excel(output_excel,index=None,header = None)
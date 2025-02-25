# -*- coding: utf-8 -*-
"""
Created on Thu May  9 11:47:09 2024

@author: yr.chen
"""

def verified_gene(X):
    with open("D:\\ACMG_report\\Verified_genes.txt","r") as f:
        s = f.read()
        test = ','.join(s.split())
    check = [str(i) for i in test.split(',')]
    #nonredunant=sorted(list(set(check)))
    #print(nonredunant)
    if str(X) in check:
        print("IN panel")
    else:
        print("NOT in panel")

verified_gene("ABCA4")

def RNA_panel(X):
    with open("","r") as f:  #RNA fusion gene list
        s = f.read()
        test = ','.join(s.split(';'))
    check = [str(i) for i in test.split(',')]
    fusion = f'{X}'.split('-')
    genenumber = len(fusion)
    #nonredunant=sorted(list(set(check)))
    #print(nonredunant)
    for i in check:
        if genenumber > 1:
            if ((str(fusion[0]) in i) and (str(fusion[1]) in i)) :
                print(i)
            else:
                continue
        else:
            if str(fusion[0]) in i:
                print(i)
#RNA_panel('NTRK3')
#RNA_panel('ETV6-NTRK3')

# -*- coding: utf-8 -*-
"""
Created on Mon Aug 26 16:44:03 2024

@author: yr.chen
"""
import sys
import os

if sys.argv[1] in ["--help","-h"]:
    print("\n\tPurpose: Check if genes are in verified genelist, if not, output the genes")
    print(f"\n\tUsage:{sys.argv[0]} $1 $2")
    print("\t  $1 : The absolute/relative path of the genelist you want to query (comma-separated)")
    print("\t  $2 : Name for your output file, the output would be '$2_NOTIN.txt' \n")
    exit(0)
    
dir_path = os.path.dirname(os.path.realpath(__file__))
genelist = os.path.abspath((sys.argv[1]))
print(f"Import:{genelist}\n")

with open(genelist) as file:
    line = file.read()
line_item = line.split(',')
    
with open(os.path.join(dir_path,"Verified_genes.txt")) as v:
    v_item = v.read()
verifygenes = v_item.split(',')

INpanel = []
NOTIN = []
for check in line_item:
    if check not in verifygenes:
        NOTIN.append(check)
    elif check in verifygenes:
        INpanel.append(check)
    else:
        print(f"ERROR in {check}")

print(f"In panel: {INpanel}\n")
print(f"NOT in panel: {NOTIN}\n")
output_name = sys.argv[2]+'_NOTIN.txt'


with open(os.path.join(dir_path,output_name),"w+") as output:
    output.write(','.join(NOTIN))
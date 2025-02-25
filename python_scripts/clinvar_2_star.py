# -*- coding: utf-8 -*-
"""
Created on Fri Dec 13 09:39:33 2024

@author: yr.chen
"""

import sys
import argparse

def star_check():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--prefix", help = "Prefix for the output file",type=str)
    args = parser.parse_args()
    prefix = args.prefix.strip()
    if not sys.stdin.isatty():
        input_data = sys.stdin.buffer.read().decode("utf-8", errors="replace")
    star = '★'
    lines2 = []
    lines1 = []
    for line in input_data.split("\n"):
        if line:            
            if line.count(star) >= 2:
                newline = [s.encode("ascii", "replace").decode("ascii") for s in line.split("\t")[4:10]]
                lines2.append('\t'.join(newline)+'\n')
            elif line.count(star) == 1:
                newline = [s.encode("ascii", "replace").decode("ascii") for s in line.split("\t")[4:10]]
                lines1.append('\t'.join(newline)+'\n')
        else:
            break
    if lines2:
        with open(f"{prefix}_clinvar_2star.temp",'a+',encoding = 'utf-8') as file:
            file.writelines(lines2)
        print({'clin-star':'2', 'lines':lines2})
    elif lines1:
        with open(f"{prefix}_clinvar_1star.temp",'a+',encoding = 'utf-8') as file:
            file.writelines(lines1)
        print({'clin-star':'1','lines':lines1})
    else:
        print("No clinvar output")
    
if __name__ == '__main__':
       star_check()
    
                

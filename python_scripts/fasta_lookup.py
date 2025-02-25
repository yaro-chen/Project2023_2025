# -*- coding: utf-8 -*-
"""
Created on Tue Oct 15 16:52:25 2024

@author: yr.chen
"""

import subprocess
import argparse
import os

parser = argparse.ArgumentParser(description="Usage: Look up fasta sequence around the specific position")
parser.add_argument('-p','--position',help = 'eg. chr13:20763612',type=str)
parser.add_argument('-v','--fasta', help='Reference fasta',choices=['hg19','hg38'],type=str)
parser.add_argument('-o', '--output', help = 'File name for the output fasta sequence',type=str)
args = parser.parse_args() 

pos = args.position.replace(" ", "")
version = args.fasta.replace(" ", "")

chrN = pos.split(':')[0][0].lower()+pos.split(':')[0][1:]

point = int(pos.split(':')[1])

pos_range = [point-500, point+500]

if version == 'hg19':
    fasta = 'hg19.fa'
elif version == 'hg38':
    fasta = 'hg38.fa'
else:
    print("Error in the name of reference fasta")
    print("Progam stop.")
    exit()

command = ['samtools', 'faidx', fasta, f"{chrN}:{pos_range[0]}-{pos_range[1]}"]
print(command)
lookup = subprocess.run(command, stdout = subprocess.PIPE, check=True)
out = lookup.stdout.decode("utf-8")

opname = args.output.strip()

outfa = open(f"{opname}.txt","w")

sequence = ""
for line in out.split('\n'):
    if '>' in line:
        print(line)
        outfa.write(f"{line}\n")
    else:
        sequence += line
pointseq = sequence[:500]+f"[{sequence[500]}]"+sequence[501:]
print(pointseq)
outfa.write(f"{pointseq}\n")
outfa.close()
print(f"\nThe query is saved in {os.getcwd()}/{opname}.txt")




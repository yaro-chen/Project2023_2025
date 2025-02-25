# -*- coding: utf-8 -*-
"""
Created on Mon Dec 18 13:49:52 2023

@author: yr.chen
"""
import csv
import sys
from pathlib import Path

import openpyxl

directory = Path(sys.argv[1])
input_file = directory / "Confidence_list.txt"
output_file = directory / "Confidence_list.xlsx"

wb = openpyxl.Workbook()
ws = wb.worksheets[0]

with open(input_file, 'r') as data:  # read in text mode
    reader = csv.reader(data, delimiter='\t')
    for row in reader:
        ws.append(row)

wb.save(output_file)
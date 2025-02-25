# -*- coding: utf-8 -*-
"""
Created on Wed Jul 31 14:37:47 2024

@author: yr.chen
"""

import json
import csv
import os
import argparse
import logging
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
from datetime import datetime

now = datetime.now().strftime("%m%d%H%M%S")

parser = argparse.ArgumentParser()
parser.add_argument("-j", "--json", help = "",type=str)
parser.add_argument("-t", "--stats",help = "", type=str)
parser.add_argument("-f", "--flag",help = "", type=str)
parser.add_argument("-v", "--vcfsum",help = "", type=str)
parser.add_argument("-b", "--bamdst",help = "", type=str)
parser.add_argument("-c", "--coverage",choices = ['20','500'],help = "", type=int)
parser.add_argument("-s","--sample", help ="",type=str)
args = parser.parse_args()

LOGGING_FORMAT = '%(asctime)s %(levelname)s: %(message)s'
DATE_FORMAT = '[%Y%m%d %H:%M:%S]'

file = os.path.abspath(args.json) #input1
samtools_stats = os.path.abspath(args.stats) #input2
sambamba_flag = os.path.abspath(args.flag) #input3
vcf_sum = os.path.abspath(args.vcfsum)
bamdst = os.path.abspath(args.bamdst)

filename = args.sample
directory = os.path.dirname(file)

    
logging.basicConfig(level=logging.INFO, format= LOGGING_FORMAT, datefmt= DATE_FORMAT,
                    handlers=[logging.FileHandler(f'{directory}/QClog.{now}'),logging.StreamHandler()])

logging.info(f"Json input checked: {file}")
logging.info(f"Samtools stats checked: {samtools_stats}")
logging.info(f"Sambamba flag checked: {sambamba_flag}")
logging.info(f"Vcf summary report checked:{vcf_sum}")
logging.info(f"Folder where bamdst reports are located: {bamdst}")


print(f"\nParsing {filename} QC data")
output = f"{directory}/{filename}_QCreport.xls"
print(f'Read {file} ...')

try:
    with open(file, 'r') as f:
        data = json.load(f)
    logging.info("loading fastp json data")
except:
    logging.warning("Fastp json data could not be found, check the file path again !", exc_info=True)
#### parse json QC data

summary = ['Read_length','Read_raw','Read_clean','Read_clean_Rate']    
summary_value = []
for i in summary:
    try:
        if i == 'Read_length':
            summary_value.append(str(data['summary']['before_filtering']['read1_mean_length'])+':'+str(data['summary']['before_filtering']['read2_mean_length']))
        elif i == 'Read_raw':
            summary_value.append('{:,}'.format(data['summary']['before_filtering']['total_reads']))
        elif i == 'Read_clean':
            summary_value.append('{:,}'.format(data['summary']['after_filtering']['total_reads']))
        elif i == 'Read_clean_Rate':
            summary_value.append('{:.2%}'.format(int(summary_value[2].replace(',',''))/int(summary_value[1].replace(',','')))) 
    except: 
        summary_value.append('N/A')
print(summary, summary_value, sep='\n')

items_raw = ['Q20_raw','Q20_read1_raw','Q20_read2_raw','Q30_raw','Q30_read1_raw','Q30_read2_raw','GC_raw']
items_clean = ['Q20_clean','Q20_read1_clean','Q20_read2_clean','Q30_clean','Q30_read1_clean','Q30_read2_clean','GC_clean']
    
def quality(x, y):
    print(y)
    value = []
    for i in y:
        try:
            length = len(i.split('_'))
            if length == 2 and "GC" not in i :
                A = i.split('_')[0]
                value.append('{:.2%}'.format(data['summary'][x][f'{A.lower()}_rate']))
            elif length == 2 and "GC" in i:
                A = i.split('_')[0]
                value.append('{:.2%}'.format(data['summary'][x][f'{A.lower()}_content']))
            elif length == 3:
                A,B= i.split('_')[:2]
                value.append('{:.2%}'.format(data[f'{B}_{x}'][f'{A.lower()}_bases']/data[f'{B}_{x}']['total_bases']))
        except:
            value.append('N/A')
            logging.warning(f'{i} cound not be found, please check json format!', exc_info=True)
    return value
items_value = quality('before_filtering', items_raw) 
items_value.extend(quality('after_filtering', items_clean))
print(items_value)

#### Plot base distribution
    
element = [f"{j}_{k}" for j in ['before','after'] for k in ['content','quality']]

def data_get(y,z):
    
    reads = ['read1','read2']
    length ={}
    for i in reads:
        raw = data[f"{i}_{y}_filtering"][f"{z}_curves"]
        length[i] = int(data[f"{i}_{y}_filtering"]["total_cycles"])
        if i == 'read1':
            merge = raw
    for j in raw.keys():
        merge[j].extend(raw[j])
        
    xmax = max([len(i) for i in merge.values()])
    ymax = float(max(sum(merge.values(),[])))
    ymin = float(min(sum(merge.values(),[])))
    if z == 'content':
        mean_values = ['{:.3%}'.format(sum(j)/sum(length.values())) for j in merge.values()]
        legend_labels = [f"{k} ({m})" for k,m in zip(merge.keys(),mean_values)]
        merge_adj = dict(zip(legend_labels,merge.values()))
        return {f'dict_{z}':merge_adj, 'xmax':xmax, 'ymax':ymax, 'ymin':ymin,'r1cycle':length['read1']}
    else:
        return {f'dict_{z}':merge, 'xmax': xmax, 'ymax':ymax, 'ymin':ymin, 'r1cycle':length['read1'] }
    
plt_dict_content = {}
plt_dict_quality = {}

lim_content = {'xmax':[],'ymin':[],'ymax':[]}
lim_quality = {'xmax':[],'ymin':[],'ymax':[]}

def dict_create(x,y):
    if b not in x:
        x[b] = opt[f'dict_{c}']
    else:
        x[b] = [x[b],opt[f'dict_{c}']]
    for k in y.keys():
        y[k].append(f'{b}:{opt[k]}')


for i in element:
    try:
        b,c = i.split('_')
        opt = data_get(b, c)
        if c == 'content':
            dict_create(plt_dict_content, lim_content)
        else:
            dict_create(plt_dict_quality, lim_quality)
        logging.info(f"Extracting data for base {c} ({b} filtering)")
    except:
        logging.warning(f"Unable to extract data for base {c} ({b} filtering) !", exc_info=True)

def plot_depth(y,z):
    try:
        if y == plt_dict_content:
            colors = ['royalblue', 'darkGreen', 'black', 'darkorange','red','sienna']
            markers = ['.','*','.','*','x','+']
            colors_c = ['goldenrod', 'crimson', 'mediumpurple', 'deepskyblue','dimgrey','limegreen']            
            
            ymax = float(max([ymx.split(':')[1] for ymx in lim_content['ymax']]))
            ymin = float(min([ymi.split(':')[1] for ymi in lim_content['ymin']]))
            xmax = float(max([xmx.split(':')[1] for xmx in lim_content['xmax']]))
            
            fig,ax = plt.subplots()
            plt.gcf().set_size_inches(16, 6)        
            c=-1
            for i, j in plt_dict_content['after'].items():
                c +=1
                p1, = ax.plot(range(1,len(j)+1),j, label =i, linestyle ='solid', color = colors_c[c],alpha = 0.8)
            ax.add_artist(plt.legend(title = 'After_filtering',loc = 'upper right',bbox_to_anchor=(1.15, 1),frameon=False))
            
            d=-1
            for k, v in plt_dict_content['before'].items():
                d +=1
                p2, = ax.plot(range(1,len(v)+1),v, label =k,linestyle = 'None', marker = markers[d] ,color = colors[d], markevery = 5, ms =5 ,alpha = 0.7)
            h,l = ax.get_legend_handles_labels()
            plt.legend(handles=h[6:12],labels = l[6:12],title = 'Before_filtering',loc = 'lower right', bbox_to_anchor = (1.15,0.3),frameon = False)

            plt.axvline(x = opt['r1cycle'], color = 'black', label = 'axvline - full height',linewidth=4)

            
            title_text = f"{filename} base contents"
            yaxis = "Base content ratios"
        
            plt.ylim(-0.01, ymax+0.1)
            
        else :
            colors = ['royalblue', 'darkGreen', 'red', 'darkorange','black']
            #colors_c = ['goldenrod', 'crimson', 'mediumpurple', 'deepskyblue','dimgrey']  
            
            fig,ax = plt.subplots()
            plt.gcf().set_size_inches(16, 6)        
            c=-1
            for i, j in y['after'].items():
                c +=1
                p1, = ax.plot(range(1,len(j)+1),j, label =i, linestyle ='solid', color = colors[c],alpha = 0.5)
            ax.add_artist(plt.legend(title = 'After_filtering',loc = 'upper right',bbox_to_anchor=(1.1, 1),frameon=False))

            
            d=-1
            for k, v in y['before'].items():
                d +=1
                p2, = ax.plot(range(1,len(v)+1),v, label =k,linestyle = 'dashed',color = colors[d], alpha = 0.9) #marker = markers[d] , markevery = 5, ms =5 ,alpha = 0.7)
            h,l = ax.get_legend_handles_labels()
            plt.legend(handles=h[5:10],labels = l[5:10],title = 'Before_filtering',loc = 'lower right', bbox_to_anchor = (1.1,0.3),frameon = False)
            
            plt.axvline(x = opt['r1cycle'], color = 'black', label = 'axvline - full height', linewidth=4)
            title_text = f"{filename} base quality"
            yaxis = "Base quality"
            
            ymax = float(max([ymx.split(':')[1] for ymx in lim_quality['ymax']]))
            ymin = float(min([ymi.split(':')[1] for ymi in lim_quality['ymin']]))
            xmax = float(max([xmx.split(':')[1] for xmx in lim_quality['xmax']]))
            plt.ylim(ymin-2, ymax+2)
            vals = ax.get_yticks().tolist()
            ax.yaxis.set_major_locator(mticker.FixedLocator(vals))
            ax.set_yticklabels(['{:.1f}'.format(x) for x in vals])
            ax.yaxis.get_ticklocs(minor=True)
                
        plt.margins(x=0)
        plt.xlim(0, xmax)
        plt.title(title_text, y = 1.05, x = 0.5,fontsize=14,weight='bold')
        plt.text(0.25,0.9, "Read1", fontsize = 12,transform=ax.transAxes)
        plt.text(0.75,0.9, "Read2", fontsize = 12,transform=ax.transAxes)
        plt.ylabel(yaxis)
        plt.xlabel("Position")
        sns.set_style("ticks")
        sns.despine()
        plt.show()
        logging.info(f'{directory}/{filename}_base_{z}.png is saved')
        ax.get_figure().savefig(f'{directory}/{filename}_base_{z}.png', dpi=300,bbox_inches='tight')
        plt.close()
    except:
        logging.warning(f'Unable to plot {filename}_base_{z} !', exc_info=True)
plot_depth(plt_dict_content,'content')
plot_depth(plt_dict_quality,'quality')

# Parsing data from bam statistics

try: 
    bamdst_cov = f'{bamdst}/coverage.report'
    bamdst_depth = f'{bamdst}/depth.tsv.gz'

    bamdict = {}
    bamdict['Mapping_rate'] = os.popen(f'grep "Fraction of Mapped Reads" {bamdst_cov}|cut -f2').read().strip()
    print(f"Mapping_rate: {bamdict['Mapping_rate']}")
    bamdict['PE_mapping_rate'] = os.popen(f'grep "Fraction of Read and mate paired" {bamdst_cov}|cut -f2').read().strip()
    print(f"PE_mapping_rate: {bamdict['PE_mapping_rate']}")
    bamdict['Duplication_rate'] = os.popen(f'grep "Fraction of PCR duplicate reads" {bamdst_cov}|cut -f2').read().strip()
    print(f"Duplication_rate: {bamdict['Duplication_rate']}")
    bamdict['Mismatch_rate'] = '{:.2%}'.format(float(os.popen(f'grep "error rate" {samtools_stats}|cut -f3').read().strip()))
    print(f"Mismatch_rate : {bamdict['Mismatch_rate']}")
    chimeric_reads = int(os.popen(f'grep "mapQ>=5" {sambamba_flag}|cut -d " " -f1').read().strip())
    total_mapped_reads = int(os.popen(f'sed -n 5p {sambamba_flag}|cut -d " " -f1').read().strip())
    bamdict['Chimerical_rate'] = '{:.2%}'.format(chimeric_reads/total_mapped_reads)
    print(f"Chimerical_rate : {bamdict['Chimerical_rate']}")

    bamdict['Insert_size'] = os.popen(f"grep 'insert size average' {samtools_stats}|cut -f3").read().strip()
    print(f"Insert_size : {bamdict['Insert_size']}")
    
    bamdict['On_target_rate(reads)'] = os.popen(f'grep "Fraction of Target Reads in all reads" {bamdst_cov}|cut -f2').read().strip()
    print(f"Capture_rate_on_reads : {bamdict['Capture_rate_on_reads']}")
    
    bamdict['On_target_rate(bases)'] = os.popen(f'grep "Fraction of Target Data in all data" {bamdst_cov}|cut -f2').read().strip()
    print(f"On_target_rate(bases) : {bamdict['Capture_rate_on_bases']}")
    
    bamdict['Average_depth(rmdup)'] = os.popen(f'grep "\[Target\] Average depth(rmdup)" {bamdst_cov}|cut -f2').read().strip()
    print(f"Average_depth(rmdup) : {bamdict['Average_depth(rmdup)']}")
    bamdict['Coverage(>0X)'] = os.popen(f'grep "\[Target\] Coverage (>0x)" {bamdst_cov}|cut -f2').read().strip()
    print(f"Coverage(>0X) : {bamdict['Coverage(>0X)']}")
    bamdict['Coverage(>=4X)'] = os.popen(f'grep "\[Target\] Coverage (>=4x)" {bamdst_cov}|cut -f2').read().strip()
    print(f"Coverage(>=4X) : {bamdict['Coverage(>=4X)']}")
    bamdict['Coverage(>=10X)'] = os.popen(f'grep "\[Target\] Coverage (>=10x)" {bamdst_cov}|cut -f2').read().strip()
    print(f"Coverage(>=10X) : {bamdict['Coverage(>=10X)']}")
    
    if args.coverage == 20:
        bamdict['Coverage(>=20X)'] = os.popen(f'grep "\[Target\] Coverage (>=20x)" {bamdst_cov}|cut -f2').read().strip()
        print(f"Coverage(>=20X) : {bamdict['Coverage(>=20X)']}")
    
    bamdict['Coverage(>=30X)'] = os.popen(f'grep "\[Target\] Coverage (>=30x)" {bamdst_cov}|cut -f2').read().strip()
    print(f"Coverage(>=30X) : {bamdict['Coverage(>=30X)']}")
    bamdict['Coverage(>=100X)'] = os.popen(f'grep "\[Target\] Coverage (>=100x)" {bamdst_cov}|cut -f2').read().strip()
    print(f"Coverage(>=100X) : {bamdict['Coverage(>=100X)']}")
    
    if args.coverage == 500:
        bamdict['Coverage(>=500X)'] = os.popen(f'grep "\[Target\] Coverage (>=500x)" {bamdst_cov}|cut -f2').read().strip()
        print(f"Coverage(>=500X) : {bamdict['Coverage(>=500X)']}")

    cmd = r'''less %s |awk -v i=%s '{if ($4 > 0.2*i){print}}'|wc -l''' % (bamdst_depth,bamdict['Average_depth(rmdup)'])
    print(f"Commands: {cmd}")
    targetcounts = int(os.popen(cmd).read().strip())
    totalcounts = int(os.popen(f'grep "\[Target\] Len of region" {bamdst_cov}|cut -f2').read().strip())
    bamdict['Uniformity(>0.2f)'] = '{:.2%}'.format(targetcounts/totalcounts)

    print(bamdict)

    bamdict_item = [i for i in bamdict.keys()]
    bamdict_value = [j for j in bamdict.values()]
except:
    bamdict_item = ['bam_report']
    bamdict_value = ['N/A']
    logging.warning("Unable to catch data from bam statistics!",exc_info=True)

out_rowname = summary+items_raw+items_clean+bamdict_item
out_values = summary_value+items_value+bamdict_value

#vcf
out_rowname.append('Ti/Tv')
try:
    ti_tv = os.popen(f"cut -f5 {vcf_sum}|tail -n 1").read().strip()
    out_values.append(ti_tv)
    print(f'Ti/Tv : {ti_tv}')
except:
    logging.warning("Error while getting Ti/Tv !!!")
    out_values.append('Error')

with open(output,'w',newline="\n") as out:
    writer=csv.writer(out,delimiter='\t')
    writer.writerows(zip(out_rowname,out_values))
    logging.info(f"{output} is exported as the QC report")
    
# depth distribution and insert size

try:
    bamdst_dd = f"{bamdst}/depth_distribution.plot"
    
    df = pd.read_csv(bamdst_dd, sep='\t', names=["Depth", "Count of depth", "Percent of counts", "Cumulated depths","Cumulated percent"])

    print("import bamdst distribution data for plots...")

    df['Cumulated percent'] = df['Cumulated percent']*100
    cutoff_check = df.loc[(df['Cumulated percent'] >= 1), 'Depth']
    ymax_1 = float(df.loc[:,'Cumulated percent'].max(axis = 0))
    fig = sns.lineplot(data = df, x = "Depth", y = "Cumulated percent",color = 'red')
    
    if len(cutoff_check) >= 20:
        cutoff = int(cutoff_check.values[-1])
        plt.xlim(-0.5,cutoff)
        #fig.set_xticks(range(0, cutoff,20))
    elif len(cutoff_check) < 20:
        cutoff = int(df.loc[:, 'Depth'].values[-1])
    else:
        logging.warning("Unable to check cutoff value for depth plots !", exc_info=True)
    plt.ylim(-0.05*ymax_1,1.05*ymax_1)
    #fig.locator_params(axis='both', nbins=10)
    fig.xaxis.set_major_locator(mticker.MaxNLocator(10))
    plt.gcf().set_size_inches(8, 6)
    sns.set_style("ticks")
    sns.despine()
    fig.set(ylabel='Fraction of bases (%)', xlabel='Cumulative sequencing depth')
    fig.get_figure().savefig(f'{directory}/{filename}_cumDepth.png', dpi=300,bbox_inches='tight')
    logging.info(f"{directory}/{filename}_cumDepth_distibution.png is saved")
    plt.close()

    df['Percent of counts'] = df['Percent of counts']*100
    ymax_2 = float(df.loc[:cutoff,"Percent of counts"].max(axis = 0))

    fig2 = sns.lineplot(data = df, x = "Depth", y = "Percent of counts", color='darkblue')
    plt.ylim(-0.05*ymax_2,1.05*ymax_2)
    if len(cutoff_check) >= 20:
        if len(cutoff_check) >= 200:
            plt.xlim(-5,cutoff)
        else:
            plt.xlim(-0.5,cutoff)
    #fig2.locator_params(axis='both', nbins=10)
    fig2.xaxis.set_major_locator(mticker.MaxNLocator(10))
    plt.gcf().set_size_inches(8, 6)
    sns.set_style("ticks")
    sns.despine()
    fig2.fill_between(df['Depth'], df['Percent of counts'])
    fig2.set(ylabel='Fraction of bases (%)', xlabel='Sequencing depth')
    fig2.get_figure().savefig(f'{directory}/{filename}_pointDepth.png', dpi=300,bbox_inches='tight')
    logging.info(f"{directory}/{filename}_pointDepth.png is saved")
    plt.close()
except:
    logging.warning("Unable to create depth plots !", exc_info=True)

# Insert Size
try:
    bamdst_ins = f"{bamdst}/insertsize.plot"
    df = pd.read_csv(bamdst_ins, sep='\t', names=["InsertSize", "Counts", "Percent of counts", "Cumulated inserts","Cumulated percent"])
    maxcount = int(df.Counts.max())
    cutoff_insert_check = df.loc[(df['Cumulated percent'] >= 0.001), 'InsertSize']
    df['Cumulated percent'] = df['Cumulated percent']*100
    
    fig, ax = plt.subplots()
    plt.gcf().set_size_inches(8, 6)
    sns.set_style("ticks")
    sns.despine()
    #ax =sns.histplot(x=df["InsertSize"],weights = df["Counts"], discrete = True)
    
    p1 = ax.plot(df["InsertSize"],df["Counts"], color = 'forestgreen', linestyle = "solid", label = "Counts")
    
    if len(str(maxcount)) >= 7 :
        ax.yaxis.set_major_formatter(mticker.FormatStrFormatter('%.1e'))
    elif len(str(maxcount)) < 7 :
        plt.ticklabel_format(style='plain')
        
    #p1.set_ylim([-0.05*maxcount,1.05*maxcount])
    ax2 = ax.twinx()
    p2 = ax2.plot(df["InsertSize"], df["Cumulated percent"], color='tomato', linestyle = "dashed", label = "Cumulated percent")
    
    if len(cutoff_insert_check) >= 20:
        cutoff_insert = int(cutoff_insert_check.values[-1])
        plt.xlim(-5, cutoff_insert)
     
    ps = p1+p2
    labs = [l.get_label() for l in ps]
    ax.legend(ps, labs, loc='upper right', frameon = False)
    ax.locator_params(axis='both', nbins=10)
    #ax.legend(labels = 'Counts',loc = 'upper right', frameon = False)
    #ax2.legend(labels = 'Cumulated percent',loc = 'center right', frameon = False)
    ax.fill_between(df['InsertSize'], df['Counts'], color = "green")
    plt.text(0.75,0.85, f"Average size: {bamdict['Insert_size']}", fontsize = 10,transform=ax.transAxes)
    ax.set_xlabel("Insert Size")
    ax.set_ylabel("Counts")
    ax2.set_ylabel("Cumulated percent")
    #plt.show()
    logging.info(f"{directory}/{filename}_InsertSize.png is saved")
    ax.get_figure().savefig(f"{directory}/{filename}_InsertSize.png", dpi=300,bbox_inches='tight')
    plt.close()
except:
    logging.warning("Unable to plot Insert Size !", exc_info=True)

logging.info(f"Outputs are stored in {directory}")
logging.info("Done")
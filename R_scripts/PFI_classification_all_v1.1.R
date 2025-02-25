
#!/usr/bin/env Rscript --vanilla

start <- Sys.time()

if (!requireNamespace("dplyr", quietly = TRUE))
  install.packages("dplyr", repos = "http://cran.us.r-project.org")
if (!requireNamespace("plyr", quietly = TRUE))
  install.packages("plyr", repos = "http://cran.us.r-project.org")
if (!requireNamespace("utils", quietly = TRUE))
  install.packages("utils", repos = "http://cran.us.r-project.org")
if (!requireNamespace("janitor", quietly = TRUE))
  install.packages("janitor", repos = "http://cran.us.r-project.org")
if (!requireNamespace("rstudioapi", quietly = TRUE))
  install.packages("rstudioapi", repos = "http://cran.us.r-project.org")
if (!requireNamespace("tidyselect", quietly = TRUE))
  install.packages("tidyselect", repos = "http://cran.us.r-project.org")
if (!requireNamespace("openxlsx", quietly = TRUE))
  install.packages("openxlsx", repos = "http://cran.us.r-project.org")
if (!requireNamespace("data.table", quietly = TRUE))
  install.packages("data.table", repos = "http://cran.us.r-project.org")

suppressPackageStartupMessages(library(janitor))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyselect))
suppressPackageStartupMessages(library(utils))
suppressPackageStartupMessages(library(openxlsx))

argu <- commandArgs(trailingOnly = T)
workingPath <- argu[1]
sample_bracken <- argu[2]
libraryPath <- argu[3]
sampleID <- argu[4]
database <- argu[5]
confidence  <- argu[6]
print(argu)

phylum_sort_eupath <- function(){
  
  setwd(workingPath)
  
  print(paste("current worrking directory:",getwd()))
  
  bracken <-read.delim(sample_bracken, header = T, sep = "\t")
  
  total <- sum(bracken$new_est_reads)
  
  Rlog <- file(paste("Rlog", format(Sys.time(), "%m%d%H%M"),sep="_"))
  
  sink(Rlog, append = F, type = c("output","message"),split = T)
  
  assemblies <- list.files(libraryPath, recursive = T, pattern = "taxid.txt",full.names = T)
  
  print(paste("taxo assemblies: ",assemblies,sep = ""), quote =F)
  
  list.as <- lapply(assemblies, function(x){read.delim(x, quote = "",sep = "\t",header = T ,check.names=F,skipNul = T)})
  
  #http://www.endmemo.com/r/gsub.php
  
  phylumlist <- gsub(".*/([^.]+)[_].*[_].*","\\1",assemblies) 
  
  names(list.as) <- phylumlist
  
  list.tax <- lapply(list.as, function(x){dplyr::select(x, tidyselect::matches("^taxid$",ignore.case = T))})
  
  list.assign <- lapply(list.tax, function(x){merge(bracken, x, by.x = "taxonomy_id", by.y = "taxid", all = F)})
  
  
  for (i in 1:length(list.assign)){
    options(scipen = 999)
    assign(paste(database,"_",sampleID,"_",confidence,"_",phylumlist[i], sep = ""), list.assign[[i]] %>% arrange(desc(new_est_reads))  ) 
  }
  
  sample_psort <- mget(paste0(database,"_",sampleID,"_",confidence,"_",phylumlist, sep = ""))
  
  sample_psort_final <- lapply(sample_psort, function(x){
    if (nrow(x) > 0) {
      x$fraction_in_percent = formatC(signif(100*(as.numeric(x[,"new_est_reads"]/total)),4),digits = 4,format = "fg")
      x[nrow(x)+1,] = c("Sum", rep("",which(colnames(x)=="new_est_reads")-2), format(sum(as.numeric(x[,"new_est_reads"])),big.mark =",", big.interval =3L),rep("",2)) 
      for (i in c(4,5,7,8)){
        x[,c(i)]=as.numeric(as.character(x[,c(i)]))}
      return(x)
    } else {x[,"fraction_in_percent"]=character(0);return(x)}
  })
  
  library(utils)
  h=0
  for (i in names(sample_psort_final)){
    h=h+1
    write.table(sample_psort_final[[h]], file = sprintf("./%s.txt", i), sep = "\t", row.names = F, quote = F)
    if (nrow(sample_psort_final[[h]]) > 0){
      openxlsx::write.xlsx(sample_psort_final[[h]],file = sprintf("./%s.xlsx", i),overwrite = T, asTable = F)}
    }
  
  sp.number = nrow(bracken)
  
  k=0
  for (i in sample_psort){
    k=k+nrow(i)}
  
  if (k==sp.number){
    print("All kraken-identified species were successfully classified")
  } else {
    idlist <- lapply(list.as, function(x){dplyr::select(x, matches("taxid"))})
    all_as = data.frame(); for (i in idlist){all_as <- rbind(all_as,i)}
    check <- setdiff(bracken$taxonomy_id, all_as$taxid)
    print("WARNING!!! NOT all kraken-identified species were classified ! ");cat(paste("\n   >>> Check taxid",check,sep = " : "))
  }
  
  sink()
  
}

phylum_sort <- function(){
  
  setwd(workingPath)
  
  print(paste("current worrking directory:",getwd()))
  
  bracken <-read.delim(sample_bracken, header = T, sep = "\t")
  
  total <- sum(bracken$new_est_reads)
  
  Rlog <- file(paste("Rlog", format(Sys.time(), "%m%d%H%M"),sep="_"))
  
  sink(Rlog, append = F, type = c("output","message"),split = T)
  
  assemblies <- list.files(libraryPath, recursive = T, pattern = "assembly",full.names = T)
  
  print(paste("taxo assemblies:",assemblies))
  
  list.as <- lapply(assemblies, function(x){read.delim(x, quote = "",sep = "\t",header = T ,check.names=F)})
  
  #http://www.endmemo.com/r/gsub.php
  
  phylumlist <- gsub(".*/([^.]+)[_].*[_].*","\\1",assemblies) 
  
  print(phylumlist)
  
  names(list.as) <- phylumlist
  
  list.as$human[nrow(list.as$human)+1,] <- c(names(list.as$archaea)) 
  
  list.as$human <-rbind(list.as$human,colnames(list.as$human)) %>% janitor::row_to_names(.,1)
  
  list.tax <- lapply(list.as, function(x){dplyr::select(x, tidyselect::matches("taxid",ignore.case = T))})
  
  list.tax_nor <- lapply(list.tax, function(x){unique(x)})
  
  list.assign <- lapply(list.tax_nor, function(x){merge(bracken, x, by.x = "taxonomy_id", by.y = "taxid", all = F)})
  
  list.assign_s <- lapply(list.tax_nor, function(x){merge(bracken, x, by.x = "taxonomy_id", by.y = "species_taxid", all = F) %>% select(., -contains("taxid"))%>% unique})
  
  
  for (i in 1:length(list.assign)){
    options(scipen = 999)
    assign(paste(database,"_",sampleID,"_",confidence,"_",phylumlist[i], sep = ""), plyr::rbind.fill(list.assign[[i]], list.assign_s[[i]]) 
           %>% select(.,-contains("species_taxid"))%>% unique() %>% arrange(desc(new_est_reads))  ) 
  }
  
  sample_psort <- mget(paste0(database,"_",sampleID,"_",confidence,"_",phylumlist, sep = ""))
  
  sample_psort_final <- lapply(sample_psort, function(x){
    if (nrow(x) > 0) {
      x$fraction_in_percent = formatC(signif(100*(as.numeric(x[,"new_est_reads"]/total)),4),digits = 4,format = "fg")
      x[nrow(x)+1,] = c("Sum", rep("",which(colnames(x)=="new_est_reads")-2), format(sum(as.numeric(x[,"new_est_reads"])),big.mark =",", big.interval =3L),rep("",2)) 
      for (i in c(4,5,7,8)){
        x[,c(i)]=as.numeric(as.character(x[,c(i)]))}
      return(x)
    } else {x[,"fraction_in_percent"]=character(0);return(x)}
  })
  
  library(utils)
  h=0
  for (i in names(sample_psort_final)){
    h=h+1
    write.table(sample_psort_final[[h]], file = sprintf("./%s.txt", i), sep = "\t", row.names = F, quote = F)
    if (nrow(sample_psort_final[[h]]) > 0){
      openxlsx::write.xlsx(sample_psort_final[[h]],file = sprintf("./%s.xlsx", i),overwrite = T, asTable = F)}
  }
  
  sp.number = nrow(bracken)
  
  k=0
  for (i in sample_psort){
    k=k+nrow(i)}
  
  if (k==sp.number){
    print("All kraken-identified species were successfully classified")
  } else {
    idlist <- lapply(list.as, function(x){dplyr::select(x, matches("species_taxid")) %>% unique()})
    all_as = data.frame(); for (i in idlist){all_as <- rbind(all_as,i)}
    check <- setdiff(bracken$taxonomy_id, all_as$species_taxid)
    print("WARNING!!! NOT all kraken-identified species were classified ! ");cat(paste("\n   >>> Check taxid",check,sep = " : "))
  }
  
  sink()
  
}

if (database == "Eupath46"){
  phylum_sort_eupath()
} else {
  phylum_sort()
}

cat("\n");print(paste("running time:",Sys.time()-start))
